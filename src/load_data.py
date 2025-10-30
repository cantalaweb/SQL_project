"""
Script para cargar datos de alumnos y claustro en PostgreSQL
Usa pandas para leer CSVs y SQL directo para insertar en la BD
"""

import os
from datetime import datetime

import pandas as pd
import psycopg2
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Configuración de conexión
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432"),
    "database": os.getenv("DB_NAME", "the_bridge_db"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD"),
}
SCHEMA = os.getenv("DB_SCHEMA", "the_bridge")


def connect_db():
    """Establece conexión con PostgreSQL"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = False
        print(f"✓ Conexión exitosa a {DB_CONFIG['database']}")
        return conn
    except Exception as e:
        print(f"✗ Error al conectar a la base de datos: {e}")
        raise


def set_schema(cursor):
    """Establece el schema de trabajo"""
    cursor.execute(f"SET search_path TO {SCHEMA};")


def insert_lookup_table(cursor, table_name, values):
    """
    Inserta valores en tablas de lookup (calificacion, campus, rol, etc.)
    Retorna un diccionario {nombre: id}
    """
    ids = {}
    for value in values:
        cursor.execute(
            f"INSERT INTO {table_name} (nombre) VALUES (%s) "
            f"ON CONFLICT (nombre) DO UPDATE SET nombre = EXCLUDED.nombre "
            f"RETURNING id;",
            (value,),
        )
        ids[value] = cursor.fetchone()[0]

    print(f"  ✓ {table_name}: {len(ids)} registros")
    return ids


def load_base_tables(cursor):
    """Carga las tablas base sin foreign keys"""
    print("\n1. Cargando tablas base...")

    # Calificaciones
    calificaciones = ["Apto", "No Apto"]
    cal_ids = insert_lookup_table(cursor, "calificacion", calificaciones)

    # Campus
    campus_list = ["Madrid", "Valencia"]
    campus_ids = insert_lookup_table(cursor, "campus", campus_list)

    # Roles
    roles = ["TA", "LI"]
    rol_ids = insert_lookup_table(cursor, "rol", roles)

    # Modalidades
    modalidades = ["Presencial", "Online"]
    modalidad_ids = insert_lookup_table(cursor, "modalidad", modalidades)

    # Promociones
    promociones = ["Septiembre", "Febrero"]
    promocion_ids = insert_lookup_table(cursor, "promocion", promociones)

    # Verticales
    verticales = ["DS", "FS"]
    vertical_ids = insert_lookup_table(cursor, "vertical", verticales)

    # Proyectos DS
    proyectos_ds = ["HLF", "EDA", "BBDD", "ML", "Deployment"]
    # Proyectos FS
    proyectos_fs = ["WebDev", "FrontEnd", "Backend", "React", "FullStack"]

    proyecto_ids = {}
    for proyecto in proyectos_ds + proyectos_fs:
        cursor.execute(
            "INSERT INTO proyecto (nombre) VALUES (%s) "
            "ON CONFLICT (nombre) DO UPDATE SET nombre = EXCLUDED.nombre "
            "RETURNING id;",
            (proyecto,),
        )
        proyecto_ids[proyecto] = cursor.fetchone()[0]

    print(f"  ✓ proyecto: {len(proyecto_ids)} registros")

    return {
        "calificacion": cal_ids,
        "campus": campus_ids,
        "rol": rol_ids,
        "modalidad": modalidad_ids,
        "promocion": promocion_ids,
        "vertical": vertical_ids,
        "proyecto": proyecto_ids,
    }


def load_vertical_has_proyecto(cursor, lookups):
    """Carga la relación entre verticales y proyectos con su orden"""
    print("\n2. Cargando vertical_has_proyecto...")

    # Proyectos DS en orden
    proyectos_ds = [
        ("DS", "HLF", 1),
        ("DS", "EDA", 2),
        ("DS", "BBDD", 3),
        ("DS", "ML", 4),
        ("DS", "Deployment", 5),
    ]

    # Proyectos FS en orden
    proyectos_fs = [
        ("FS", "WebDev", 1),
        ("FS", "FrontEnd", 2),
        ("FS", "Backend", 3),
        ("FS", "React", 4),
        ("FS", "FullStack", 5),
    ]

    count = 0
    for vertical_nombre, proyecto_nombre, orden in proyectos_ds + proyectos_fs:
        vertical_id = lookups["vertical"][vertical_nombre]
        proyecto_id = lookups["proyecto"][proyecto_nombre]

        cursor.execute(
            "INSERT INTO vertical_has_proyecto (vertical_id, proyecto_id, orden) "
            "VALUES (%s, %s, %s) "
            "ON CONFLICT (vertical_id, proyecto_id) DO UPDATE SET orden = EXCLUDED.orden;",
            (vertical_id, proyecto_id, orden),
        )
        count += 1

    print(f"  ✓ vertical_has_proyecto: {count} registros")


def load_alumnos_from_csv(cursor, csv_file, vertical_nombre, lookups):
    """
    Carga alumnos desde un archivo CSV
    Retorna diccionario {email: alumno_id}
    """
    # Leer CSV con pandas (delimitador es punto y coma)
    df = pd.read_csv(csv_file, sep=";", encoding="utf-8")

    # Corregir typo en nombre de columna si existe
    df.columns = [col.replace("FullSatck", "FullStack") for col in df.columns]

    alumno_ids = {}

    for _, row in df.iterrows():
        nombre = row["Nombre"]
        email = row["Email"]

        # Insertar alumno
        cursor.execute(
            "INSERT INTO alumno (nombre, email) VALUES (%s, %s) "
            "ON CONFLICT (email) DO UPDATE SET nombre = EXCLUDED.nombre "
            "RETURNING id;",
            (nombre, email),
        )
        alumno_id = cursor.fetchone()[0]
        alumno_ids[email] = {"id": alumno_id, "data": row}

    return alumno_ids


def load_alumno_has_vertical(cursor, alumno_data, vertical_nombre, lookups):
    """Carga la relación alumno-vertical con campus, modalidad y promoción"""
    count = 0
    vertical_id = lookups["vertical"][vertical_nombre]
    modalidad_id = lookups["modalidad"]["Presencial"]  # Todos son presenciales

    for email, info in alumno_data.items():
        alumno_id = info["id"]
        row = info["data"]

        # Obtener datos del CSV
        promocion_nombre = row["Promoción"]
        campus_nombre = row["Campus"]
        fecha_str = row["Fecha_comienzo"]

        # Convertir fecha (formato DD/MM/YYYY)
        fecha_comienzo = datetime.strptime(fecha_str, "%d/%m/%Y")

        # Obtener IDs
        promocion_id = lookups["promocion"][promocion_nombre]
        campus_id = lookups["campus"][campus_nombre]

        cursor.execute(
            "INSERT INTO alumno_has_vertical "
            "(alumno_id, vertical_id, fecha_comienzo, campus_id, modalidad_id, promocion_id) "
            "VALUES (%s, %s, %s, %s, %s, %s) "
            "ON CONFLICT (alumno_id, vertical_id) DO UPDATE SET "
            "fecha_comienzo = EXCLUDED.fecha_comienzo;",
            (
                alumno_id,
                vertical_id,
                fecha_comienzo,
                campus_id,
                modalidad_id,
                promocion_id,
            ),
        )
        count += 1

    return count


def load_alumno_proyectos(cursor, alumno_data, vertical_nombre, lookups):
    """Carga las calificaciones de los proyectos de cada alumno"""
    count = 0
    vertical_id = lookups["vertical"][vertical_nombre]

    # Mapear nombres de columnas a nombres de proyectos
    if vertical_nombre == "DS":
        proyecto_mapping = {
            "Proyecto_HLF": "HLF",
            "Proyecto_EDA": "EDA",
            "Proyecto_BBDD": "BBDD",
            "Proyecto_ML": "ML",
            "Proyecto_Deployment": "Deployment",
        }
    else:  # FS
        proyecto_mapping = {
            "Proyecto_WebDev": "WebDev",
            "Proyecto_FrontEnd": "FrontEnd",
            "Proyecto_Backend": "Backend",
            "Proyecto_React": "React",
            "Proyecto_FullStack": "FullStack",
        }

    for email, info in alumno_data.items():
        alumno_id = info["id"]
        row = info["data"]

        for col_name, proyecto_nombre in proyecto_mapping.items():
            calificacion_texto = row[col_name]
            calificacion_id = lookups["calificacion"][calificacion_texto]
            proyecto_id = lookups["proyecto"][proyecto_nombre]

            cursor.execute(
                "INSERT INTO alumno_has_vertical_has_proyecto "
                "(alumno_id, vertical_has_proyecto_vertical_id, "
                "vertical_has_proyecto_proyecto_id, calificacion_id) "
                "VALUES (%s, %s, %s, %s) "
                "ON CONFLICT (alumno_id, vertical_has_proyecto_vertical_id, "
                "vertical_has_proyecto_proyecto_id) DO UPDATE SET "
                "calificacion_id = EXCLUDED.calificacion_id;",
                (alumno_id, vertical_id, proyecto_id, calificacion_id),
            )
            count += 1

    return count


def load_claustro(cursor, csv_file, lookups):
    """Carga los datos del claustro y sus relaciones"""
    print("\n4. Cargando claustro...")

    df = pd.read_csv(csv_file, sep=";", encoding="utf-8")

    claustro_count = 0
    relacion_count = 0

    for _, row in df.iterrows():
        nombre = row["Nombre"]
        rol_nombre = row["Rol"]
        vertical_nombre = row["Vertical"]
        promocion_nombre = row["Promocion"]
        campus_nombre = row["Campus"]
        modalidad_nombre = row["Modalidad"]

        # Obtener IDs
        rol_id = lookups["rol"][rol_nombre]
        vertical_id = lookups["vertical"][vertical_nombre]
        promocion_id = lookups["promocion"][promocion_nombre]
        campus_id = lookups["campus"][campus_nombre]
        modalidad_id = lookups["modalidad"][modalidad_nombre]

        # Insertar en claustro
        cursor.execute(
            "INSERT INTO claustro (nombre, rol_id) VALUES (%s, %s) RETURNING id;",
            (nombre, rol_id),
        )
        claustro_id = cursor.fetchone()[0]
        claustro_count += 1

        # Insertar relación claustro_has_vertical
        cursor.execute(
            "INSERT INTO claustro_has_vertical "
            "(claustro_id, vertical_id, promocion_id, modalidad_id, campus_id) "
            "VALUES (%s, %s, %s, %s, %s) "
            "ON CONFLICT (claustro_id, vertical_id) DO UPDATE SET "
            "promocion_id = EXCLUDED.promocion_id;",
            (claustro_id, vertical_id, promocion_id, modalidad_id, campus_id),
        )
        relacion_count += 1

    print(f"  ✓ claustro: {claustro_count} registros")
    print(f"  ✓ claustro_has_vertical: {relacion_count} registros")


def main():
    """Función principal"""
    print("=" * 60)
    print("CARGA DE DATOS - THE BRIDGE")
    print("=" * 60)

    conn = None
    try:
        # Conectar a la base de datos
        conn = connect_db()
        cursor = conn.cursor()
        set_schema(cursor)

        # 1. Cargar tablas base
        lookups = load_base_tables(cursor)

        # 2. Cargar vertical_has_proyecto
        load_vertical_has_proyecto(cursor, lookups)

        # 3. Cargar alumnos
        print("\n3. Cargando alumnos...")

        # Alumnos DS (clase_1 y clase_2)
        print("\n  Procesando clase_1.csv (DS)...")
        alumnos_ds_1 = load_alumnos_from_csv(
            cursor, "./data/clase_1.csv", "DS", lookups
        )
        ahv_count_1 = load_alumno_has_vertical(cursor, alumnos_ds_1, "DS", lookups)
        proyectos_count_1 = load_alumno_proyectos(cursor, alumnos_ds_1, "DS", lookups)
        print(
            f"    ✓ {len(alumnos_ds_1)} alumnos, {ahv_count_1} verticales, "
            f"{proyectos_count_1} calificaciones"
        )

        print("\n  Procesando clase_2.csv (DS)...")
        alumnos_ds_2 = load_alumnos_from_csv(
            cursor, "./data/clase_2.csv", "DS", lookups
        )
        ahv_count_2 = load_alumno_has_vertical(cursor, alumnos_ds_2, "DS", lookups)
        proyectos_count_2 = load_alumno_proyectos(cursor, alumnos_ds_2, "DS", lookups)
        print(
            f"    ✓ {len(alumnos_ds_2)} alumnos, {ahv_count_2} verticales, "
            f"{proyectos_count_2} calificaciones"
        )

        # Alumnos FS (clase_3 y clase_4)
        print("\n  Procesando clase_3.csv (FS)...")
        alumnos_fs_3 = load_alumnos_from_csv(
            cursor, "./data/clase_3.csv", "FS", lookups
        )
        ahv_count_3 = load_alumno_has_vertical(cursor, alumnos_fs_3, "FS", lookups)
        proyectos_count_3 = load_alumno_proyectos(cursor, alumnos_fs_3, "FS", lookups)
        print(
            f"    ✓ {len(alumnos_fs_3)} alumnos, {ahv_count_3} verticales, "
            f"{proyectos_count_3} calificaciones"
        )

        print("\n  Procesando clase_4.csv (FS)...")
        alumnos_fs_4 = load_alumnos_from_csv(
            cursor, "./data/clase_4.csv", "FS", lookups
        )
        ahv_count_4 = load_alumno_has_vertical(cursor, alumnos_fs_4, "FS", lookups)
        proyectos_count_4 = load_alumno_proyectos(cursor, alumnos_fs_4, "FS", lookups)
        print(
            f"    ✓ {len(alumnos_fs_4)} alumnos, {ahv_count_4} verticales, "
            f"{proyectos_count_4} calificaciones"
        )

        # 4. Cargar claustro
        load_claustro(cursor, "./data/claustro.csv", lookups)

        # Commit de toda la transacción
        conn.commit()

        print("\n" + "=" * 60)
        print("✓ CARGA COMPLETADA EXITOSAMENTE")
        print("=" * 60)

        # Resumen
        total_alumnos = (
            len(alumnos_ds_1)
            + len(alumnos_ds_2)
            + len(alumnos_fs_3)
            + len(alumnos_fs_4)
        )
        total_calificaciones = (
            proyectos_count_1
            + proyectos_count_2
            + proyectos_count_3
            + proyectos_count_4
        )

        print("\nResumen:")
        print(f"  • Total alumnos cargados: {total_alumnos}")
        print(f"  • Total calificaciones: {total_calificaciones}")
        print("  • Total claustro: 11")

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"\n✗ ERROR: {e}")
        import traceback

        traceback.print_exc()

    finally:
        if conn:
            conn.close()
            print("\n✓ Conexión cerrada")


if __name__ == "__main__":
    main()

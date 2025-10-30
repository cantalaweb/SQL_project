<!-- Title -->
<h1 align='center'> SQL_project </h1>


<!-- tag line -->
<h3 align='center'> Modelado y creación de una base de datos relacional para alumnos y profesores de The Bridge. </h3>

<!-- tech stack badges ---------------------------------- -->
<p align='center'>
    <!-- Python -->
    <a href="https://www.python.org"><img src="https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=fff" alt="Python"></a>
    <!-- Pandas -->
    <a href="https://pandas.pydata.org"><img src="https://img.shields.io/badge/Pandas-150458?logo=pandas&logoColor=fff" alt="Pandas"></a>
    <!-- PostgreSQL -->
    <a href="https://www.postgresql.org"><img src="https://img.shields.io/badge/Postgres-%23316192.svg?logo=postgresql&logoColor=white" alt="PostgreSQL"></a>
</p>
<br/>

## Introducción

<img src='home_screen.png' width='400' />

## Requerimientos
- [Python 3.11.9](https://www.python.org) must be installed.
- pandas>=2.0.0
- psycopg2-binary>=2.9.0
- python-dotenv>=1.0.0
- Archivos CSV con los datos:
  - `clase_1.csv` - Alumnos DS (Septiembre)
  - `clase_2.csv` - Alumnos DS (Febrero)
  - `clase_3.csv` - Alumnos FS (Septiembre)
  - `clase_4.csv` - Alumnos FS (Febrero)
  - `claustro.csv` - Profesores y TAs

## Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/cantalaweb/SQL_project.git
cd SQL_project
```

2. **Crear entorno virtual (recomendado)**
```bash
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

3. **Instalar dependencias**
```bash
pip install -r requirements.txt
```

4. **Configurar variables de entorno**

Copia el archivo `.env.example` a `.env` y configura tus credenciales:

```bash
cp .env.example .env
```

Edita el archivo `.env` con tus datos:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=the_bridge
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña
DB_SCHEMA=the_bridge
```

5. **Crear la base de datos**

Primero debes ejecutar el script SQL para crear las tablas:
```bash
psql -U postgres -d the_bridge_db -f create_tables_postgresql.sql
```

O copiar su contenido y pegarlo en el *Query Tool* de pgAdmin 4, una vez conectado al servidor de PostgreSQL, y ejecutarlo.

## Uso

Ejecuta:

```bash
python load_data.py
```

El script realizará las siguientes operaciones:

1. **Carga de tablas base**: calificaciones, campus, roles, modalidades, promociones, verticales y proyectos
2. **Relación vertical-proyectos**: asocia cada vertical con sus proyectos en orden secuencial
3. **Carga de alumnos**: procesa los 4 archivos CSV de alumnos
4. **Calificaciones de proyectos**: registra las calificaciones de cada alumno en cada proyecto
5. **Carga de claustro**: procesa profesores y TAs con sus asignaciones

## Estructura de Datos

### Verticales y Proyectos

**Data Science (DS)**:
1. HLF
2. EDA
3. BBDD
4. ML
5. Deployment

**Full Stack (FS)**:
1. WebDev
2. FrontEnd
3. Backend
4. React
5. FullStack

### Calificaciones
- Apto
- No Apto

### Campus
- Madrid
- Valencia

### Modalidades
- Presencial
- Online

### Promociones
- Septiembre
- Febrero

## Características

- Usa SQL directo (sin ORM)
- Manejo de transacciones
- Protección de credenciales con variables de entorno
- Corrección automática del typo "FullSatck" → "FullStack"
- Inserción idempotente (ON CONFLICT DO UPDATE)
- Validación de integridad referencial
- Mensajes de progreso detallados

## Notas Importantes

- **Todos los alumnos** en los CSV son de modalidad **Presencial**
- El script usa transacciones: si algo falla, no se insertará nada
- Los archivos CSV usan **punto y coma** (`;`) como separador
- Las fechas están en formato `DD/MM/YYYY`

## 🐛 Solución de Problemas

### Error de conexión
Verifica que PostgreSQL esté corriendo y que las credenciales en `.env` sean correctas.

### Error "schema does not exist"
Asegúrate de haber ejecutado primero el script `create_tables_postgresql.sql`.

### Error con archivos CSV
Verifica que:
- Los archivos CSV estén en el directorio /data y que el script está en /src
- Usen codificación UTF-8
- Usen punto y coma como separador

## 📄 Licencia

[Tu licencia aquí]
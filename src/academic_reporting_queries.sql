SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'the_bridge'
ORDER BY table_name;

#Total de alumnos por vertical
SELECT 
    the_bridge.vertical.nombre AS vertical,
    COUNT(DISTINCT the_bridge.alumno_has_vertical.alumno_id) AS total_alumnos
FROM the_bridge.alumno_has_vertical
JOIN the_bridge.vertical 
    ON the_bridge.vertical.id = the_bridge.alumno_has_vertical.vertical_id
GROUP BY the_bridge.vertical.nombre
ORDER BY total_alumnos DESC;

Docente asociado a vertical
SELECT
    the_bridge.claustro.nombre AS docente, 
    the_bridge.vertical.nombre AS vertical
FROM the_bridge.claustro
JOIN the_bridge.claustro_has_vertical 
    ON the_bridge.claustro.id = the_bridge.claustro_has_vertical.claustro_id
JOIN the_bridge.vertical 
    ON the_bridge.claustro_has_vertical.vertical_id = the_bridge.vertical.id;

#Alumnos y su campus, modalidad y promoción
SELECT 
    the_bridge.alumno.nombre AS alumno,
    the_bridge.campus.nombre AS campus,
    the_bridge.modalidad.nombre AS modalidad,
    the_bridge.promocion.nombre AS promocion
FROM the_bridge.alumno
JOIN the_bridge.alumno_has_vertical 
    ON the_bridge.alumno.id = the_bridge.alumno_has_vertical.alumno_id
JOIN the_bridge.campus 
    ON the_bridge.campus.id = the_bridge.alumno_has_vertical.campus_id
JOIN the_bridge.modalidad 
    ON the_bridge.modalidad.id = the_bridge.alumno_has_vertical.modalidad_id
JOIN the_bridge.promocion 
    ON the_bridge.promocion.id = the_bridge.alumno_has_vertical.promocion_id
ORDER BY the_bridge.alumno.nombre;

#Porcentaje de aprobación por alumno
SELECT 
    the_bridge.alumno.nombre AS alumno,
    the_bridge.campus.nombre AS campus,
    the_bridge.modalidad.nombre AS modalidad,
    the_bridge.promocion.nombre AS promocion,
    COUNT(*) FILTER (WHERE the_bridge.calificacion.nombre = 'Apto') AS total_apto,
    COUNT(*) AS total_proyectos,
    ROUND(100.0 * COUNT(*) FILTER (WHERE the_bridge.calificacion.nombre = 'Apto') / COUNT(*), 2) AS porcentaje_aprobacion
FROM the_bridge.alumno_has_vertical_has_proyecto
JOIN the_bridge.alumno 
    ON the_bridge.alumno_has_vertical_has_proyecto.alumno_id = the_bridge.alumno.id
JOIN the_bridge.calificacion 
    ON the_bridge.alumno_has_vertical_has_proyecto.calificacion_id = the_bridge.calificacion.id
JOIN the_bridge.alumno_has_vertical 
    ON the_bridge.alumno.id = the_bridge.alumno_has_vertical.alumno_id
    AND the_bridge.alumno_has_vertical.vertical_id = the_bridge.alumno_has_vertical_has_proyecto.vertical_has_proyecto_vertical_id
JOIN the_bridge.campus 
    ON the_bridge.alumno_has_vertical.campus_id = the_bridge.campus.id
JOIN the_bridge.modalidad 
    ON the_bridge.alumno_has_vertical.modalidad_id = the_bridge.modalidad.id
JOIN the_bridge.promocion 
    ON the_bridge.alumno_has_vertical.promocion_id = the_bridge.promocion.id
GROUP BY 
    the_bridge.alumno.nombre, 
    the_bridge.campus.nombre, 
    the_bridge.modalidad.nombre, 
    the_bridge.promocion.nombre
ORDER BY 
    porcentaje_aprobacion DESC, 
    the_bridge.alumno.nombre;

#Porcentaje de aprobacion por vertical
SELECT 
    the_bridge.vertical.nombre AS vertical,
    COUNT(*) FILTER (WHERE the_bridge.calificacion.nombre = 'Apto') AS total_apto,
    COUNT(*) AS total_proyectos,
    ROUND(100.0 * COUNT(*) FILTER (WHERE the_bridge.calificacion.nombre = 'Apto') / COUNT(*), 2) AS porcentaje_aprobacion
FROM the_bridge.alumno_has_vertical_has_proyecto
JOIN the_bridge.vertical 
    ON the_bridge.alumno_has_vertical_has_proyecto.vertical_has_proyecto_vertical_id = the_bridge.vertical.id
JOIN the_bridge.calificacion 
    ON the_bridge.alumno_has_vertical_has_proyecto.calificacion_id = the_bridge.calificacion.id
GROUP BY the_bridge.vertical.nombre
ORDER BY porcentaje_aprobacion DESC;

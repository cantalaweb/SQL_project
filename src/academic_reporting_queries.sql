SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'the_bridge'
ORDER BY table_name;

SELECT 
  v.nombre AS vertical,
  COUNT(DISTINCT av.alumno_id) AS total_alumnos
FROM the_bridge.alumno_has_vertical av
JOIN the_bridge.vertical v ON v.id = av.vertical_id
GROUP BY v.nombre
ORDER BY total_alumnos DESC;


SELECT cl.nombre AS docente, v.nombre AS vertical
FROM the_bridge.claustro cl
JOIN the_bridge.claustro_has_vertical cv ON cl.id = cv.claustro_id
JOIN the_bridge.vertical v ON cv.vertical_id = v.id;

SELECT 
  a.nombre AS alumno,
  c.nombre AS campus,
  m.nombre AS modalidad,
  p.nombre AS promocion
FROM the_bridge.alumno a
JOIN the_bridge.alumno_has_vertical av ON a.id = av.alumno_id
JOIN the_bridge.campus c ON c.id = av.campus_id
JOIN the_bridge.modalidad m ON m.id = av.modalidad_id
JOIN the_bridge.promocion p ON p.id = av.promocion_id
ORDER BY a.nombre;

SELECT 
    a.nombre AS alumno,
    c.nombre AS campus,
    m.nombre AS modalidad,
    pr.nombre AS promocion,
    COUNT(*) FILTER (WHERE cal.nombre = 'Apto') AS total_apto,
    COUNT(*) AS total_proyectos,
    ROUND(100.0 * COUNT(*) FILTER (WHERE cal.nombre = 'Apto') / COUNT(*), 2) AS porcentaje_aprobacion
FROM the_bridge.alumno_has_vertical_has_proyecto avp
JOIN the_bridge.alumno a ON avp.alumno_id = a.id
JOIN the_bridge.calificacion cal ON avp.calificacion_id = cal.id
JOIN the_bridge.alumno_has_vertical av 
    ON a.id = av.alumno_id 
    AND av.vertical_id = avp.vertical_has_proyecto_vertical_id
JOIN the_bridge.campus c ON av.campus_id = c.id
JOIN the_bridge.modalidad m ON av.modalidad_id = m.id
JOIN the_bridge.promocion pr ON av.promocion_id = pr.id
GROUP BY a.nombre, c.nombre, m.nombre, pr.nombre
ORDER BY porcentaje_aprobacion DESC, a.nombre;

SELECT 
    v.nombre AS vertical,
    COUNT(*) FILTER (WHERE cal.nombre = 'Apto') AS total_apto,
    COUNT(*) AS total_proyectos,
    ROUND(100.0 * COUNT(*) FILTER (WHERE cal.nombre = 'Apto') / COUNT(*),2) AS porcentaje_aprobacion
FROM the_bridge.alumno_has_vertical_has_proyecto avp
JOIN the_bridge.vertical v ON avp.vertical_has_proyecto_vertical_id = v.id
JOIN the_bridge.calificacion cal ON avp.calificacion_id = cal.id
GROUP BY v.nombre
ORDER BY porcentaje_aprobacion DESC;
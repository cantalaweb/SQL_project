-- PostgreSQL 18+ compatible DDL

-- 1) Schema
CREATE SCHEMA IF NOT EXISTS mydb;
SET search_path TO mydb;

-- 2) Drop in dependency-safe order (CASCADE to simplify rebuilds)
DROP TABLE IF EXISTS alumno_has_vertical_has_proyecto CASCADE;
DROP TABLE IF EXISTS alumno_has_vertical CASCADE;
DROP TABLE IF EXISTS claustro_has_vertical CASCADE;
DROP TABLE IF EXISTS vertical_has_proyecto CASCADE;
DROP TABLE IF EXISTS claustro CASCADE;
DROP TABLE IF EXISTS alumno CASCADE;
DROP TABLE IF EXISTS calificacion CASCADE;
DROP TABLE IF EXISTS campus CASCADE;
DROP TABLE IF EXISTS modalidad CASCADE;
DROP TABLE IF EXISTS promocion CASCADE;
DROP TABLE IF EXISTS proyecto CASCADE;
DROP TABLE IF EXISTS rol CASCADE;
DROP TABLE IF EXISTS vertical CASCADE;

-- 3) Base tables (no FKs)
CREATE TABLE alumno (
  id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre  VARCHAR(100) NOT NULL,
  email   VARCHAR(45)  NOT NULL UNIQUE
);

CREATE TABLE calificacion (
  id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL UNIQUE
);

CREATE TABLE campus (
  id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL UNIQUE
);

CREATE TABLE rol (
  id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL UNIQUE
);

CREATE TABLE modalidad (
  id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL UNIQUE
);

CREATE TABLE promocion (
  id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL UNIQUE
);

CREATE TABLE proyecto (
  id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL UNIQUE
);

CREATE TABLE vertical (
  id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(45) NOT NULL UNIQUE
);

-- 4) Dependent tables

-- vertical_has_proyecto
CREATE TABLE vertical_has_proyecto (
  vertical_id  INT NOT NULL,
  proyecto_id INT NOT NULL,
  orden        INT,
  PRIMARY KEY (vertical_id, proyecto_id),
  CONSTRAINT fk_vhp_vertical
    FOREIGN KEY (vertical_id)  REFERENCES vertical(id)  ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_vhp_proyecto
    FOREIGN KEY (proyecto_id) REFERENCES proyecto(id) ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- claustro (depends on rol)
CREATE TABLE claustro (
  id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(45),
  rol_id INT NOT NULL,
  CONSTRAINT fk_claustro_rol
    FOREIGN KEY (rol_id) REFERENCES rol(id) ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- claustro_has_vertical
CREATE TABLE claustro_has_vertical (
  claustro_id  INT NOT NULL,
  vertical_id  INT NOT NULL,
  promocion_id INT NOT NULL,
  modalidad_id INT NOT NULL,
  campus_id    INT NOT NULL,
  PRIMARY KEY (claustro_id, vertical_id),
  CONSTRAINT fk_chv_claustro
    FOREIGN KEY (claustro_id)  REFERENCES claustro(id)  ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_chv_vertical
    FOREIGN KEY (vertical_id)  REFERENCES vertical(id)  ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_chv_promocion
    FOREIGN KEY (promocion_id) REFERENCES promocion(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_chv_modalidad
    FOREIGN KEY (modalidad_id) REFERENCES modalidad(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_chv_campus
    FOREIGN KEY (campus_id)    REFERENCES campus(id)    ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- alumno_has_vertical
CREATE TABLE alumno_has_vertical (
  alumno_id       INT NOT NULL,
  vertical_id     INT NOT NULL,
  fecha_comienzo  TIMESTAMP WITHOUT TIME ZONE,
  campus_id       INT NOT NULL,
  modalidad_id    INT NOT NULL,
  promocion_id    INT NOT NULL,
  PRIMARY KEY (alumno_id, vertical_id),
  CONSTRAINT fk_ahv_alumno
    FOREIGN KEY (alumno_id)  REFERENCES alumno(id)   ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_ahv_vertical
    FOREIGN KEY (vertical_id) REFERENCES vertical(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_ahv_campus
    FOREIGN KEY (campus_id)   REFERENCES campus(id)   ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_ahv_modalidad
    FOREIGN KEY (modalidad_id) REFERENCES modalidad(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_ahv_promocion
    FOREIGN KEY (promocion_id) REFERENCES promocion(id) ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- alumno_has_vertical_has_proyecto
CREATE TABLE alumno_has_vertical_has_proyecto (
  alumno_id                           INT NOT NULL,
  vertical_has_proyecto_vertical_id  INT NOT NULL,
  vertical_has_proyecto_proyecto_id INT NOT NULL,
  calificacion_id                     INT NOT NULL,
  PRIMARY KEY (
    alumno_id,
    vertical_has_proyecto_vertical_id,
    vertical_has_proyecto_proyecto_id
  ),
  CONSTRAINT fk_ahv_hp_alumno
    FOREIGN KEY (alumno_id) REFERENCES alumno(id) ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_ahv_hp_vhp
    FOREIGN KEY (vertical_has_proyecto_vertical_id, vertical_has_proyecto_proyecto_id)
    REFERENCES vertical_has_proyecto(vertical_id, proyecto_id)
    ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_ahv_hp_calificacion
    FOREIGN KEY (calificacion_id) REFERENCES calificacion(id) ON UPDATE NO ACTION ON DELETE NO ACTION
);

-- 5) Helpful indexes for FK columns (Postgres does not auto-create these)
CREATE INDEX idx_ahv_vertical_id   ON alumno_has_vertical (vertical_id);
CREATE INDEX idx_ahv_alumno_id     ON alumno_has_vertical (alumno_id);
CREATE INDEX idx_ahv_campus_id     ON alumno_has_vertical (campus_id);
CREATE INDEX idx_ahv_modalidad_id  ON alumno_has_vertical (modalidad_id);
CREATE INDEX idx_ahv_promocion_id  ON alumno_has_vertical (promocion_id);

CREATE INDEX idx_ahvhp_vhp ON alumno_has_vertical_has_proyecto (vertical_has_proyecto_vertical_id, vertical_has_proyecto_proyecto_id);
CREATE INDEX idx_ahvhp_al  ON alumno_has_vertical_has_proyecto (alumno_id);
CREATE INDEX idx_ahvhp_cal ON alumno_has_vertical_has_proyecto (calificacion_id);

CREATE INDEX idx_chv_vertical_id   ON claustro_has_vertical (vertical_id);
CREATE INDEX idx_chv_claustro_id   ON claustro_has_vertical (claustro_id);
CREATE INDEX idx_chv_promocion_id  ON claustro_has_vertical (promocion_id);
CREATE INDEX idx_chv_modalidad_id  ON claustro_has_vertical (modalidad_id);
CREATE INDEX idx_chv_campus_id     ON claustro_has_vertical (campus_id);

CREATE INDEX idx_vhp_proyecto_id  ON vertical_has_proyecto (proyecto_id);
CREATE INDEX idx_vhp_vertical_id   ON vertical_has_proyecto (vertical_id);

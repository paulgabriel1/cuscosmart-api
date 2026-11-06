-- =====================================================================
--  CuscoSmart IA · schema.sql
--  Crea la base de datos y sus 11 tablas (diagrama ER aprobado por el profesor).
--  Motor: MySQL / MariaDB (XAMPP)
--
--  ATENCIÓN: borra la base "cuscosmart_db" si ya existe y la crea de nuevo.
-- =====================================================================

SET NAMES utf8mb4;  -- asegura que las tildes y la ñ se guarden bien

DROP DATABASE IF EXISTS cuscosmart_db;
CREATE DATABASE cuscosmart_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cuscosmart_db;

-- ---------------------------------------------------------------------
-- Catálogos
-- ---------------------------------------------------------------------
CREATE TABLE tbl_categoria (
  id          INT(11)      NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255),
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE tbl_zona (
  id     INT(11)      NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  ciudad VARCHAR(100),
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Usuarios
-- ---------------------------------------------------------------------
CREATE TABLE tbl_usuario (
  id              INT(11)      NOT NULL AUTO_INCREMENT,
  nombre_completo VARCHAR(150) NOT NULL,
  correo          VARCHAR(100) NOT NULL,
  contrasena      VARCHAR(255) NOT NULL,          -- se guarda encriptada (hash bcrypt), nunca el texto real
  telefono        VARCHAR(20),
  rol             ENUM('TURISTA','ADMIN') NOT NULL DEFAULT 'TURISTA',
  fecha_registro  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuario_correo (correo)           -- UQ: no se repite el correo
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Atractivos turísticos con sus horarios y fotos
-- ---------------------------------------------------------------------
CREATE TABLE tbl_atractivo (
  id             INT(11)       NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(200)  NOT NULL,
  descripcion    TEXT,
  direccion      VARCHAR(255),
  latitud        DECIMAL(10,6),
  longitud       DECIMAL(10,6),
  precio_entrada DECIMAL(8,2)  NOT NULL DEFAULT 0.00,
  calificacion   DECIMAL(3,2)  NOT NULL DEFAULT 0.00,  -- promedio de reseñas (lo calcula un trigger)
  fecha_registro DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  categoria_id   INT(11)       NOT NULL,
  zona_id        INT(11)       NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_atractivo_categoria FOREIGN KEY (categoria_id) REFERENCES tbl_categoria(id),
  CONSTRAINT fk_atractivo_zona      FOREIGN KEY (zona_id)      REFERENCES tbl_zona(id)
) ENGINE=InnoDB;

CREATE TABLE tbl_horario (
  id            INT(11)     NOT NULL AUTO_INCREMENT,
  dia_semana    VARCHAR(50) NOT NULL,
  hora_apertura TIME,
  hora_cierre   TIME,
  atractivo_id  INT(11)     NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_horario_atractivo FOREIGN KEY (atractivo_id) REFERENCES tbl_atractivo(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE tbl_foto (
  id           INT(11)      NOT NULL AUTO_INCREMENT,
  url_foto     VARCHAR(500) NOT NULL,
  descripcion  VARCHAR(255),
  fecha_subida DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  atractivo_id INT(11)      NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_foto_atractivo FOREIGN KEY (atractivo_id) REFERENCES tbl_atractivo(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Asistente: respuestas preparadas por el ADMIN (no guarda consultas de usuarios)
-- ---------------------------------------------------------------------
CREATE TABLE tbl_pregunta_frecuente (
  id             INT(11)      NOT NULL AUTO_INCREMENT,
  pregunta       VARCHAR(255) NOT NULL,
  respuesta      TEXT         NOT NULL,
  palabras_clave VARCHAR(255),
  atractivo_id   INT(11)      NULL,               -- opcional: si la pregunta es de un lugar
  PRIMARY KEY (id),
  FULLTEXT KEY ft_pregunta (pregunta, palabras_clave),
  CONSTRAINT fk_pregunta_atractivo FOREIGN KEY (atractivo_id) REFERENCES tbl_atractivo(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Favoritos, itinerarios y sus paradas
-- ---------------------------------------------------------------------
CREATE TABLE tbl_atractivo_favorito (
  id             INT(11)     NOT NULL AUTO_INCREMENT,
  fecha_guardado DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  atractivo_id   INT(11)     NOT NULL,
  usuario_id     INT(11)     NOT NULL,
  es_favorito    TINYINT(1)  NOT NULL DEFAULT 1,       -- 0 = solo está en un viaje (no aparece en "Favoritos")
  PRIMARY KEY (id),
  UNIQUE KEY uq_favorito (usuario_id, atractivo_id),   -- no repetir el mismo favorito
  CONSTRAINT fk_favorito_atractivo FOREIGN KEY (atractivo_id) REFERENCES tbl_atractivo(id) ON DELETE CASCADE,
  CONSTRAINT fk_favorito_usuario   FOREIGN KEY (usuario_id)   REFERENCES tbl_usuario(id)   ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE tbl_itinerario (
  id              INT(11)       NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(200)  NOT NULL,
  duracion_horas  DECIMAL(5,2)  NOT NULL DEFAULT 0.00,  -- suma de tiempos (la calcula el sistema)
  costo_total     DECIMAL(8,2)  NOT NULL DEFAULT 0.00,  -- suma de costos (la calcula el sistema)
  sugerido_ia     TINYINT(1)    NOT NULL DEFAULT 0,     -- 1 = ruta ordenada por la IA
  latitud_inicio  DECIMAL(10,6),                        -- punto de partida (ej. el hotel)
  longitud_inicio DECIMAL(10,6),
  fecha_creacion  DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  usuario_id      INT(11)       NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_itinerario_usuario FOREIGN KEY (usuario_id) REFERENCES tbl_usuario(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE tbl_detalle_itinerario (
  id                    INT(11)      NOT NULL AUTO_INCREMENT,
  orden                 INT(11)      NOT NULL,
  tiempo_estimado_horas DECIMAL(4,2) NOT NULL DEFAULT 1.00,
  costo_parada          DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  distancia_km          DECIMAL(6,2),                   -- distancia desde el punto de inicio
  visitado              TINYINT(1)   NOT NULL DEFAULT 0, -- 1 = el turista ya fue
  fecha_visita          DATETIME(6)  NULL,               -- cuándo lo marcó como visitado (línea de tiempo del perfil)
  itinerario_id         INT(11)      NOT NULL,
  atractivo_favorito_id INT(11)      NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_detalle_orden    (itinerario_id, orden),                 -- no repetir el orden
  UNIQUE KEY uq_detalle_favorito (itinerario_id, atractivo_favorito_id), -- no repetir la parada
  CONSTRAINT fk_detalle_itinerario FOREIGN KEY (itinerario_id)         REFERENCES tbl_itinerario(id)         ON DELETE CASCADE,
  CONSTRAINT fk_detalle_favorito   FOREIGN KEY (atractivo_favorito_id) REFERENCES tbl_atractivo_favorito(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Reseñas verificadas: ligadas a un itinerario (solo de lugares visitados)
-- ---------------------------------------------------------------------
CREATE TABLE tbl_resena (
  id            INT(11)      NOT NULL AUTO_INCREMENT,
  puntuacion    TINYINT(1)   NOT NULL,
  comentario    VARCHAR(500),
  fecha         DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  atractivo_id  INT(11)      NOT NULL,
  itinerario_id INT(11)      NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_resena (itinerario_id, atractivo_id),   -- una reseña por lugar en cada viaje
  CONSTRAINT chk_resena_puntuacion CHECK (puntuacion BETWEEN 1 AND 5),
  CONSTRAINT fk_resena_atractivo  FOREIGN KEY (atractivo_id)  REFERENCES tbl_atractivo(id)  ON DELETE CASCADE,
  CONSTRAINT fk_resena_itinerario FOREIGN KEY (itinerario_id) REFERENCES tbl_itinerario(id) ON DELETE CASCADE
) ENGINE=InnoDB;

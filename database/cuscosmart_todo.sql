-- =====================================================================
--  CuscoSmart IA · cuscosmart_todo.sql (ARCHIVO GENERADO: no editar a mano)
--  Une schema + logica + seed + usuario + verificacion en el orden correcto.
--  Uso: cmd /c "C:\xampp\mysql\bin\mysql.exe -u root < database\cuscosmart_todo.sql"
-- =====================================================================

-- >>> schema.sql
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

-- >>> logica.sql
-- =====================================================================
--  CuscoSmart IA · logica.sql
--  Toda la lógica que vive dentro de la base de datos:
--    1 función · 4 triggers · procedimientos almacenados (la API solo usa CALL)
--
--  Convención de errores (SIGNAL) que la API traduce a códigos HTTP:
--    SQLSTATE '45000' → 422 BUSINESS_RULE  (regla de negocio incumplida)
--    SQLSTATE '45404' → 404 NOT_FOUND      (no existe, o no es del usuario)
--    SQLSTATE '45409' → 409 DUPLICATE      (registro repetido)
--
--  Se puede ejecutar varias veces: primero borra lo que ya existía.
-- =====================================================================

USE cuscosmart_db;

DROP FUNCTION  IF EXISTS fn_distancia_km;
DROP TRIGGER   IF EXISTS trg_detalle_valida;
DROP TRIGGER   IF EXISTS trg_resena_valida;
DROP TRIGGER   IF EXISTS trg_resena_calificacion_ins;
DROP TRIGGER   IF EXISTS trg_resena_calificacion_del;

DROP PROCEDURE IF EXISTS sp_registrar_usuario;
DROP PROCEDURE IF EXISTS sp_usuario_por_correo;
DROP PROCEDURE IF EXISTS sp_usuario_por_id;
DROP PROCEDURE IF EXISTS sp_listar_usuarios;
DROP PROCEDURE IF EXISTS sp_cambiar_rol_usuario;
DROP PROCEDURE IF EXISTS sp_eliminar_usuario;
DROP PROCEDURE IF EXISTS sp_listar_categorias;
DROP PROCEDURE IF EXISTS sp_ver_categoria;
DROP PROCEDURE IF EXISTS sp_crear_categoria;
DROP PROCEDURE IF EXISTS sp_actualizar_categoria;
DROP PROCEDURE IF EXISTS sp_eliminar_categoria;
DROP PROCEDURE IF EXISTS sp_listar_zonas;
DROP PROCEDURE IF EXISTS sp_ver_zona;
DROP PROCEDURE IF EXISTS sp_crear_zona;
DROP PROCEDURE IF EXISTS sp_actualizar_zona;
DROP PROCEDURE IF EXISTS sp_eliminar_zona;
DROP PROCEDURE IF EXISTS sp_listar_atractivos;
DROP PROCEDURE IF EXISTS sp_ver_atractivo;
DROP PROCEDURE IF EXISTS sp_crear_atractivo;
DROP PROCEDURE IF EXISTS sp_actualizar_atractivo;
DROP PROCEDURE IF EXISTS sp_eliminar_atractivo;
DROP PROCEDURE IF EXISTS sp_atractivos_cercanos;
DROP PROCEDURE IF EXISTS sp_validar_atractivo;
DROP PROCEDURE IF EXISTS sp_listar_horarios;
DROP PROCEDURE IF EXISTS sp_agregar_horario;
DROP PROCEDURE IF EXISTS sp_eliminar_horario;
DROP PROCEDURE IF EXISTS sp_listar_fotos;
DROP PROCEDURE IF EXISTS sp_agregar_foto;
DROP PROCEDURE IF EXISTS sp_eliminar_foto;
DROP PROCEDURE IF EXISTS sp_agregar_favorito;
DROP PROCEDURE IF EXISTS sp_listar_favoritos;
DROP PROCEDURE IF EXISTS sp_quitar_favorito;
DROP PROCEDURE IF EXISTS sp_validar_itinerario;
DROP PROCEDURE IF EXISTS sp_crear_itinerario;
DROP PROCEDURE IF EXISTS sp_listar_itinerarios;
DROP PROCEDURE IF EXISTS sp_ver_itinerario;
DROP PROCEDURE IF EXISTS sp_actualizar_itinerario;
DROP PROCEDURE IF EXISTS sp_eliminar_itinerario;
DROP PROCEDURE IF EXISTS sp_actualizar_totales;
DROP PROCEDURE IF EXISTS sp_agregar_parada;
DROP PROCEDURE IF EXISTS sp_quitar_parada;
DROP PROCEDURE IF EXISTS sp_ordenar_itinerario_ia;
DROP PROCEDURE IF EXISTS sp_marcar_visitado;
DROP PROCEDURE IF EXISTS sp_registrar_resena;
DROP PROCEDURE IF EXISTS sp_listar_resenas_atractivo;
DROP PROCEDURE IF EXISTS sp_eliminar_resena;
DROP PROCEDURE IF EXISTS sp_buscar_pregunta_frecuente;
DROP PROCEDURE IF EXISTS sp_listar_preguntas;
DROP PROCEDURE IF EXISTS sp_crear_pregunta;
DROP PROCEDURE IF EXISTS sp_actualizar_pregunta;
DROP PROCEDURE IF EXISTS sp_eliminar_pregunta;

DELIMITER $$

-- =====================================================================
-- 1. FUNCIÓN: distancia en km entre dos coordenadas (fórmula de Haversine)
-- =====================================================================
CREATE FUNCTION fn_distancia_km(lat1 DECIMAL(10,6), lon1 DECIMAL(10,6),
                                lat2 DECIMAL(10,6), lon2 DECIMAL(10,6))
RETURNS DECIMAL(8,2)
DETERMINISTIC NO SQL
BEGIN
  RETURN ROUND(6371 * 2 * ASIN(SQRT(
           POW(SIN(RADIANS(lat2 - lat1) / 2), 2) +
           COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
           POW(SIN(RADIANS(lon2 - lon1) / 2), 2))), 2);
END$$

-- =====================================================================
-- 2. TRIGGERS (reglas automáticas: se cumplen aunque alguien use phpMyAdmin)
-- =====================================================================

-- Solo se pueden agregar al itinerario favoritos del MISMO usuario
CREATE TRIGGER trg_detalle_valida BEFORE INSERT ON tbl_detalle_itinerario
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM tbl_atractivo_favorito f
    JOIN tbl_itinerario i ON i.usuario_id = f.usuario_id
    WHERE f.id = NEW.atractivo_favorito_id AND i.id = NEW.itinerario_id
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ese favorito no pertenece al dueño del itinerario';
  END IF;
END$$

-- Anti reseñas falsas: solo se reseña un lugar que está en el itinerario y fue visitado
CREATE TRIGGER trg_resena_valida BEFORE INSERT ON tbl_resena
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM tbl_detalle_itinerario d
    JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
    WHERE d.itinerario_id = NEW.itinerario_id
      AND f.atractivo_id  = NEW.atractivo_id
      AND d.visitado = 1
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Solo puedes reseñar atractivos que visitaste en tu itinerario';
  END IF;
END$$

-- Recalcula la calificación (promedio) del atractivo al agregar o borrar una reseña
CREATE TRIGGER trg_resena_calificacion_ins AFTER INSERT ON tbl_resena
FOR EACH ROW
BEGIN
  UPDATE tbl_atractivo
     SET calificacion = (SELECT IFNULL(ROUND(AVG(puntuacion), 2), 0)
                           FROM tbl_resena WHERE atractivo_id = NEW.atractivo_id)
   WHERE id = NEW.atractivo_id;
END$$

CREATE TRIGGER trg_resena_calificacion_del AFTER DELETE ON tbl_resena
FOR EACH ROW
BEGIN
  UPDATE tbl_atractivo
     SET calificacion = (SELECT IFNULL(ROUND(AVG(puntuacion), 2), 0)
                           FROM tbl_resena WHERE atractivo_id = OLD.atractivo_id)
   WHERE id = OLD.atractivo_id;
END$$

-- =====================================================================
-- 3. USUARIOS Y AUTENTICACIÓN
-- =====================================================================

-- Registra un turista. La contraseña llega YA encriptada (bcrypt) desde la API.
CREATE PROCEDURE sp_registrar_usuario(
  IN p_nombre VARCHAR(150), IN p_correo VARCHAR(100),
  IN p_contrasena VARCHAR(255), IN p_telefono VARCHAR(20))
BEGIN
  IF EXISTS (SELECT 1 FROM tbl_usuario WHERE correo = p_correo) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ese correo ya está registrado';
  END IF;
  INSERT INTO tbl_usuario (nombre_completo, correo, contrasena, telefono)
  VALUES (p_nombre, p_correo, p_contrasena, p_telefono);
  SELECT LAST_INSERT_ID() AS usuario_id;
END$$

-- Para el login: es el ÚNICO procedimiento que devuelve el hash de la contraseña
CREATE PROCEDURE sp_usuario_por_correo(IN p_correo VARCHAR(100))
BEGIN
  SELECT id, nombre_completo, correo, contrasena, telefono, rol, fecha_registro
    FROM tbl_usuario WHERE correo = p_correo;
END$$

-- Perfil del usuario (sin la contraseña)
CREATE PROCEDURE sp_usuario_por_id(IN p_usuario_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_usuario WHERE id = p_usuario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Usuario no encontrado';
  END IF;
  SELECT id, nombre_completo, correo, telefono, rol, fecha_registro
    FROM tbl_usuario WHERE id = p_usuario_id;
END$$

-- ADMIN: lista paginada de usuarios. Devuelve 2 resultados: filas y total.
CREATE PROCEDURE sp_listar_usuarios(IN p_buscar VARCHAR(100), IN p_limit INT, IN p_offset INT)
BEGIN
  SELECT u.id, u.nombre_completo, u.correo, u.telefono, u.rol, u.fecha_registro,
         (SELECT COUNT(*) FROM tbl_itinerario i WHERE i.usuario_id = u.id) AS itinerarios
    FROM tbl_usuario u
   WHERE p_buscar IS NULL OR u.nombre_completo LIKE CONCAT('%', p_buscar, '%')
                          OR u.correo          LIKE CONCAT('%', p_buscar, '%')
   ORDER BY u.id
   LIMIT p_limit OFFSET p_offset;
  SELECT COUNT(*) AS total FROM tbl_usuario u
   WHERE p_buscar IS NULL OR u.nombre_completo LIKE CONCAT('%', p_buscar, '%')
                          OR u.correo          LIKE CONCAT('%', p_buscar, '%');
END$$

-- ADMIN: cambia el rol (TURISTA ↔ ADMIN)
CREATE PROCEDURE sp_cambiar_rol_usuario(IN p_usuario_id INT, IN p_rol VARCHAR(10))
BEGIN
  IF p_rol NOT IN ('TURISTA', 'ADMIN') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rol inválido: usa TURISTA o ADMIN';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM tbl_usuario WHERE id = p_usuario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Usuario no encontrado';
  END IF;
  UPDATE tbl_usuario SET rol = p_rol WHERE id = p_usuario_id;
  CALL sp_usuario_por_id(p_usuario_id);
END$$

-- ADMIN: elimina un usuario. Sus reseñas se borran primero para que el trigger
-- recalcule las calificaciones (los borrados en cascada NO disparan triggers).
CREATE PROCEDURE sp_eliminar_usuario(IN p_usuario_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_usuario WHERE id = p_usuario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Usuario no encontrado';
  END IF;
  DELETE r FROM tbl_resena r
    JOIN tbl_itinerario i ON i.id = r.itinerario_id
   WHERE i.usuario_id = p_usuario_id;
  DELETE FROM tbl_usuario WHERE id = p_usuario_id;   -- favoritos e itinerarios caen en cascada
END$$

-- =====================================================================
-- 4. CATEGORÍAS Y ZONAS
-- =====================================================================
CREATE PROCEDURE sp_listar_categorias()
BEGIN
  SELECT c.id, c.nombre, c.descripcion,
         (SELECT COUNT(*) FROM tbl_atractivo a WHERE a.categoria_id = c.id) AS atractivos
    FROM tbl_categoria c ORDER BY c.nombre;
END$$

CREATE PROCEDURE sp_ver_categoria(IN p_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_categoria WHERE id = p_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Categoría no encontrada';
  END IF;
  SELECT id, nombre, descripcion FROM tbl_categoria WHERE id = p_id;
END$$

CREATE PROCEDURE sp_crear_categoria(IN p_nombre VARCHAR(100), IN p_descripcion VARCHAR(255))
BEGIN
  IF EXISTS (SELECT 1 FROM tbl_categoria WHERE nombre = p_nombre) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya existe una categoría con ese nombre';
  END IF;
  INSERT INTO tbl_categoria (nombre, descripcion) VALUES (p_nombre, p_descripcion);
  CALL sp_ver_categoria(LAST_INSERT_ID());
END$$

CREATE PROCEDURE sp_actualizar_categoria(IN p_id INT, IN p_nombre VARCHAR(100), IN p_descripcion VARCHAR(255))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_categoria WHERE id = p_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Categoría no encontrada';
  END IF;
  IF EXISTS (SELECT 1 FROM tbl_categoria WHERE nombre = p_nombre AND id <> p_id) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya existe una categoría con ese nombre';
  END IF;
  UPDATE tbl_categoria SET nombre = p_nombre, descripcion = p_descripcion WHERE id = p_id;
  CALL sp_ver_categoria(p_id);
END$$

-- Si tiene atractivos, la FK (RESTRICT) impide borrarla → la API responde 409 IN_USE
CREATE PROCEDURE sp_eliminar_categoria(IN p_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_categoria WHERE id = p_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Categoría no encontrada';
  END IF;
  DELETE FROM tbl_categoria WHERE id = p_id;
END$$

CREATE PROCEDURE sp_listar_zonas()
BEGIN
  SELECT z.id, z.nombre, z.ciudad,
         (SELECT COUNT(*) FROM tbl_atractivo a WHERE a.zona_id = z.id) AS atractivos
    FROM tbl_zona z ORDER BY z.nombre;
END$$

CREATE PROCEDURE sp_ver_zona(IN p_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_zona WHERE id = p_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Zona no encontrada';
  END IF;
  SELECT id, nombre, ciudad FROM tbl_zona WHERE id = p_id;
END$$

CREATE PROCEDURE sp_crear_zona(IN p_nombre VARCHAR(100), IN p_ciudad VARCHAR(100))
BEGIN
  IF EXISTS (SELECT 1 FROM tbl_zona WHERE nombre = p_nombre) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya existe una zona con ese nombre';
  END IF;
  INSERT INTO tbl_zona (nombre, ciudad) VALUES (p_nombre, p_ciudad);
  CALL sp_ver_zona(LAST_INSERT_ID());
END$$

CREATE PROCEDURE sp_actualizar_zona(IN p_id INT, IN p_nombre VARCHAR(100), IN p_ciudad VARCHAR(100))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_zona WHERE id = p_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Zona no encontrada';
  END IF;
  IF EXISTS (SELECT 1 FROM tbl_zona WHERE nombre = p_nombre AND id <> p_id) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya existe una zona con ese nombre';
  END IF;
  UPDATE tbl_zona SET nombre = p_nombre, ciudad = p_ciudad WHERE id = p_id;
  CALL sp_ver_zona(p_id);
END$$

CREATE PROCEDURE sp_eliminar_zona(IN p_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_zona WHERE id = p_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Zona no encontrada';
  END IF;
  DELETE FROM tbl_zona WHERE id = p_id;
END$$

-- =====================================================================
-- 5. ATRACTIVOS, HORARIOS Y FOTOS
-- =====================================================================

-- Uso interno: falla con 404 si el atractivo no existe
CREATE PROCEDURE sp_validar_atractivo(IN p_atractivo_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_atractivo WHERE id = p_atractivo_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Atractivo no encontrado';
  END IF;
END$$

-- Lista con filtros opcionales (NULL = sin filtro) y paginación.
-- Devuelve 2 resultados: 1) las filas de la página, 2) el total.
CREATE PROCEDURE sp_listar_atractivos(
  IN p_categoria_id INT, IN p_zona_id INT, IN p_buscar VARCHAR(100),
  IN p_limit INT, IN p_offset INT)
BEGIN
  SELECT a.id, a.nombre, a.direccion, a.latitud, a.longitud, a.precio_entrada, a.calificacion,
         a.categoria_id, c.nombre AS categoria, a.zona_id, z.nombre AS zona,
         (SELECT f.url_foto FROM tbl_foto f WHERE f.atractivo_id = a.id ORDER BY f.id LIMIT 1) AS foto
    FROM tbl_atractivo a
    JOIN tbl_categoria c ON c.id = a.categoria_id
    JOIN tbl_zona z      ON z.id = a.zona_id
   WHERE (p_categoria_id IS NULL OR a.categoria_id = p_categoria_id)
     AND (p_zona_id      IS NULL OR a.zona_id      = p_zona_id)
     AND (p_buscar       IS NULL OR a.nombre LIKE CONCAT('%', p_buscar, '%')
                                 OR a.descripcion LIKE CONCAT('%', p_buscar, '%'))
   ORDER BY a.calificacion DESC, a.nombre
   LIMIT p_limit OFFSET p_offset;

  SELECT COUNT(*) AS total
    FROM tbl_atractivo a
   WHERE (p_categoria_id IS NULL OR a.categoria_id = p_categoria_id)
     AND (p_zona_id      IS NULL OR a.zona_id      = p_zona_id)
     AND (p_buscar       IS NULL OR a.nombre LIKE CONCAT('%', p_buscar, '%')
                                 OR a.descripcion LIKE CONCAT('%', p_buscar, '%'));
END$$

-- Un atractivo completo. Devuelve 3 resultados: datos, horarios y fotos.
CREATE PROCEDURE sp_ver_atractivo(IN p_atractivo_id INT)
BEGIN
  CALL sp_validar_atractivo(p_atractivo_id);
  SELECT a.*, c.nombre AS categoria, z.nombre AS zona,
         (SELECT COUNT(*) FROM tbl_resena r WHERE r.atractivo_id = a.id) AS total_resenas
    FROM tbl_atractivo a
    JOIN tbl_categoria c ON c.id = a.categoria_id
    JOIN tbl_zona z      ON z.id = a.zona_id
   WHERE a.id = p_atractivo_id;
  SELECT id, dia_semana, hora_apertura, hora_cierre
    FROM tbl_horario WHERE atractivo_id = p_atractivo_id ORDER BY id;
  SELECT id, url_foto, descripcion
    FROM tbl_foto WHERE atractivo_id = p_atractivo_id ORDER BY id;
END$$

-- La calificación no se recibe: la calcula el trigger a partir de las reseñas.
CREATE PROCEDURE sp_crear_atractivo(
  IN p_nombre VARCHAR(200), IN p_descripcion TEXT, IN p_direccion VARCHAR(255),
  IN p_latitud DECIMAL(10,6), IN p_longitud DECIMAL(10,6), IN p_precio DECIMAL(8,2),
  IN p_categoria_id INT, IN p_zona_id INT)
BEGIN
  INSERT INTO tbl_atractivo (nombre, descripcion, direccion, latitud, longitud, precio_entrada, categoria_id, zona_id)
  VALUES (p_nombre, p_descripcion, p_direccion, p_latitud, p_longitud, p_precio, p_categoria_id, p_zona_id);
  SELECT LAST_INSERT_ID() AS atractivo_id;
END$$

CREATE PROCEDURE sp_actualizar_atractivo(
  IN p_id INT, IN p_nombre VARCHAR(200), IN p_descripcion TEXT, IN p_direccion VARCHAR(255),
  IN p_latitud DECIMAL(10,6), IN p_longitud DECIMAL(10,6), IN p_precio DECIMAL(8,2),
  IN p_categoria_id INT, IN p_zona_id INT)
BEGIN
  CALL sp_validar_atractivo(p_id);
  UPDATE tbl_atractivo
     SET nombre = p_nombre, descripcion = p_descripcion, direccion = p_direccion,
         latitud = p_latitud, longitud = p_longitud, precio_entrada = p_precio,
         categoria_id = p_categoria_id, zona_id = p_zona_id
   WHERE id = p_id;
END$$

-- Al borrar un atractivo caen en cascada sus horarios, fotos, favoritos, paradas y reseñas.
-- Después se recalculan los totales de los itinerarios que lo tenían como parada.
CREATE PROCEDURE sp_eliminar_atractivo(IN p_id INT)
BEGIN
  CALL sp_validar_atractivo(p_id);

  DROP TEMPORARY TABLE IF EXISTS tmp_itinerarios;
  CREATE TEMPORARY TABLE tmp_itinerarios AS
    SELECT DISTINCT d.itinerario_id AS id
      FROM tbl_detalle_itinerario d
      JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
     WHERE f.atractivo_id = p_id;

  DELETE FROM tbl_atractivo WHERE id = p_id;

  UPDATE tbl_itinerario i JOIN tmp_itinerarios t ON t.id = i.id
     SET i.duracion_horas = (SELECT IFNULL(SUM(tiempo_estimado_horas), 0) FROM tbl_detalle_itinerario WHERE itinerario_id = i.id),
         i.costo_total    = (SELECT IFNULL(SUM(costo_parada), 0)          FROM tbl_detalle_itinerario WHERE itinerario_id = i.id);
  DROP TEMPORARY TABLE IF EXISTS tmp_itinerarios;
END$$

-- Atractivos dentro de un radio (km) desde un punto, del más cercano al más lejano
CREATE PROCEDURE sp_atractivos_cercanos(
  IN p_latitud DECIMAL(10,6), IN p_longitud DECIMAL(10,6), IN p_radio_km DECIMAL(6,2), IN p_limit INT)
BEGIN
  SELECT * FROM (
    SELECT a.id, a.nombre, a.latitud, a.longitud, a.precio_entrada, a.calificacion,
           c.nombre AS categoria, z.nombre AS zona,
           fn_distancia_km(p_latitud, p_longitud, a.latitud, a.longitud) AS distancia_km
      FROM tbl_atractivo a
      JOIN tbl_categoria c ON c.id = a.categoria_id
      JOIN tbl_zona z      ON z.id = a.zona_id
     WHERE a.latitud IS NOT NULL AND a.longitud IS NOT NULL
  ) AS t
   WHERE t.distancia_km <= p_radio_km
   ORDER BY t.distancia_km
   LIMIT p_limit;
END$$

CREATE PROCEDURE sp_listar_horarios(IN p_atractivo_id INT)
BEGIN
  CALL sp_validar_atractivo(p_atractivo_id);
  SELECT id, dia_semana, hora_apertura, hora_cierre
    FROM tbl_horario WHERE atractivo_id = p_atractivo_id ORDER BY id;
END$$

CREATE PROCEDURE sp_agregar_horario(
  IN p_atractivo_id INT, IN p_dia VARCHAR(50), IN p_apertura TIME, IN p_cierre TIME)
BEGIN
  CALL sp_validar_atractivo(p_atractivo_id);
  IF p_cierre <= p_apertura THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La hora de cierre debe ser posterior a la de apertura';
  END IF;
  INSERT INTO tbl_horario (atractivo_id, dia_semana, hora_apertura, hora_cierre)
  VALUES (p_atractivo_id, p_dia, p_apertura, p_cierre);
  SELECT id, dia_semana, hora_apertura, hora_cierre FROM tbl_horario WHERE id = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_eliminar_horario(IN p_atractivo_id INT, IN p_horario_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_horario WHERE id = p_horario_id AND atractivo_id = p_atractivo_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Horario no encontrado';
  END IF;
  DELETE FROM tbl_horario WHERE id = p_horario_id;
END$$

CREATE PROCEDURE sp_listar_fotos(IN p_atractivo_id INT)
BEGIN
  CALL sp_validar_atractivo(p_atractivo_id);
  SELECT id, url_foto, descripcion, fecha_subida
    FROM tbl_foto WHERE atractivo_id = p_atractivo_id ORDER BY id;
END$$

CREATE PROCEDURE sp_agregar_foto(IN p_atractivo_id INT, IN p_url VARCHAR(500), IN p_descripcion VARCHAR(255))
BEGIN
  CALL sp_validar_atractivo(p_atractivo_id);
  INSERT INTO tbl_foto (atractivo_id, url_foto, descripcion) VALUES (p_atractivo_id, p_url, p_descripcion);
  SELECT id, url_foto, descripcion, fecha_subida FROM tbl_foto WHERE id = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_eliminar_foto(IN p_atractivo_id INT, IN p_foto_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_foto WHERE id = p_foto_id AND atractivo_id = p_atractivo_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Foto no encontrada';
  END IF;
  DELETE FROM tbl_foto WHERE id = p_foto_id;
END$$

-- =====================================================================
-- 6. FAVORITOS
-- =====================================================================
CREATE PROCEDURE sp_agregar_favorito(IN p_usuario_id INT, IN p_atractivo_id INT)
BEGIN
  CALL sp_validar_atractivo(p_atractivo_id);
  IF EXISTS (SELECT 1 FROM tbl_atractivo_favorito
              WHERE usuario_id = p_usuario_id AND atractivo_id = p_atractivo_id) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ese atractivo ya está en tus favoritos';
  END IF;
  INSERT INTO tbl_atractivo_favorito (usuario_id, atractivo_id)
  VALUES (p_usuario_id, p_atractivo_id);
  SELECT LAST_INSERT_ID() AS favorito_id;
END$$

CREATE PROCEDURE sp_listar_favoritos(IN p_usuario_id INT)
BEGIN
  SELECT f.id AS favorito_id, f.fecha_guardado,
         a.id AS atractivo_id, a.nombre, a.latitud, a.longitud, a.precio_entrada, a.calificacion,
         c.nombre AS categoria, z.nombre AS zona,
         (SELECT ft.url_foto FROM tbl_foto ft WHERE ft.atractivo_id = a.id ORDER BY ft.id LIMIT 1) AS foto
    FROM tbl_atractivo_favorito f
    JOIN tbl_atractivo a ON a.id = f.atractivo_id
    JOIN tbl_categoria c ON c.id = a.categoria_id
    JOIN tbl_zona z      ON z.id = a.zona_id
   WHERE f.usuario_id = p_usuario_id
   ORDER BY f.fecha_guardado DESC;
END$$

-- Quitar un favorito también lo quita de los itinerarios (cascada); se recalculan sus totales.
CREATE PROCEDURE sp_quitar_favorito(IN p_usuario_id INT, IN p_favorito_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_atractivo_favorito WHERE id = p_favorito_id AND usuario_id = p_usuario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Favorito no encontrado';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS tmp_itinerarios;
  CREATE TEMPORARY TABLE tmp_itinerarios AS
    SELECT DISTINCT itinerario_id AS id FROM tbl_detalle_itinerario WHERE atractivo_favorito_id = p_favorito_id;

  DELETE FROM tbl_atractivo_favorito WHERE id = p_favorito_id;

  UPDATE tbl_itinerario i JOIN tmp_itinerarios t ON t.id = i.id
     SET i.duracion_horas = (SELECT IFNULL(SUM(tiempo_estimado_horas), 0) FROM tbl_detalle_itinerario WHERE itinerario_id = i.id),
         i.costo_total    = (SELECT IFNULL(SUM(costo_parada), 0)          FROM tbl_detalle_itinerario WHERE itinerario_id = i.id);
  DROP TEMPORARY TABLE IF EXISTS tmp_itinerarios;
END$$

-- =====================================================================
-- 7. ITINERARIOS Y PARADAS
-- =====================================================================

-- Uso interno: 404 si el itinerario no existe O no es del usuario
-- (así nadie puede adivinar ni tocar itinerarios ajenos).
CREATE PROCEDURE sp_validar_itinerario(IN p_usuario_id INT, IN p_itinerario_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_itinerario WHERE id = p_itinerario_id AND usuario_id = p_usuario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Itinerario no encontrado';
  END IF;
END$$

CREATE PROCEDURE sp_crear_itinerario(
  IN p_usuario_id INT, IN p_nombre VARCHAR(200),
  IN p_latitud_inicio DECIMAL(10,6), IN p_longitud_inicio DECIMAL(10,6))
BEGIN
  INSERT INTO tbl_itinerario (usuario_id, nombre, latitud_inicio, longitud_inicio)
  VALUES (p_usuario_id, p_nombre, p_latitud_inicio, p_longitud_inicio);
  SELECT LAST_INSERT_ID() AS itinerario_id;
END$$

CREATE PROCEDURE sp_listar_itinerarios(IN p_usuario_id INT)
BEGIN
  SELECT i.id, i.nombre, i.duracion_horas, i.costo_total, i.sugerido_ia,
         i.latitud_inicio, i.longitud_inicio, i.fecha_creacion,
         (SELECT COUNT(*) FROM tbl_detalle_itinerario d WHERE d.itinerario_id = i.id) AS paradas,
         (SELECT COUNT(*) FROM tbl_detalle_itinerario d WHERE d.itinerario_id = i.id AND d.visitado = 1) AS visitadas
    FROM tbl_itinerario i
   WHERE i.usuario_id = p_usuario_id
   ORDER BY i.fecha_creacion DESC;
END$$

-- Un itinerario con sus paradas en orden. Devuelve 2 resultados: cabecera y paradas.
CREATE PROCEDURE sp_ver_itinerario(IN p_usuario_id INT, IN p_itinerario_id INT)
BEGIN
  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  SELECT i.id, i.nombre, u.nombre_completo AS turista, i.duracion_horas, i.costo_total, i.sugerido_ia,
         i.latitud_inicio, i.longitud_inicio, i.fecha_creacion
    FROM tbl_itinerario i JOIN tbl_usuario u ON u.id = i.usuario_id
   WHERE i.id = p_itinerario_id;
  SELECT d.id AS parada_id, d.orden, d.distancia_km, d.tiempo_estimado_horas, d.costo_parada, d.visitado,
         f.id AS favorito_id, a.id AS atractivo_id, a.nombre AS atractivo, a.latitud, a.longitud,
         EXISTS (SELECT 1 FROM tbl_resena r
                  WHERE r.itinerario_id = d.itinerario_id AND r.atractivo_id = a.id) AS resenado
    FROM tbl_detalle_itinerario d
    JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
    JOIN tbl_atractivo a          ON a.id = f.atractivo_id
   WHERE d.itinerario_id = p_itinerario_id
   ORDER BY d.orden;
END$$

-- Si cambia el punto de inicio, la ruta deja de estar ordenada por la IA.
CREATE PROCEDURE sp_actualizar_itinerario(
  IN p_usuario_id INT, IN p_itinerario_id INT, IN p_nombre VARCHAR(200),
  IN p_latitud_inicio DECIMAL(10,6), IN p_longitud_inicio DECIMAL(10,6))
BEGIN
  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  UPDATE tbl_itinerario
     SET sugerido_ia = IF(latitud_inicio <=> p_latitud_inicio AND longitud_inicio <=> p_longitud_inicio, sugerido_ia, 0),
         nombre = p_nombre, latitud_inicio = p_latitud_inicio, longitud_inicio = p_longitud_inicio
   WHERE id = p_itinerario_id;
  CALL sp_ver_itinerario(p_usuario_id, p_itinerario_id);
END$$

-- Las reseñas se borran antes para que el trigger recalcule las calificaciones
-- (los borrados en cascada NO disparan triggers).
CREATE PROCEDURE sp_eliminar_itinerario(IN p_usuario_id INT, IN p_itinerario_id INT)
BEGIN
  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  DELETE FROM tbl_resena WHERE itinerario_id = p_itinerario_id;
  DELETE FROM tbl_itinerario WHERE id = p_itinerario_id;   -- las paradas caen en cascada
END$$

-- Recalcula la duración y el costo total del itinerario
CREATE PROCEDURE sp_actualizar_totales(IN p_itinerario_id INT)
BEGIN
  UPDATE tbl_itinerario i
     SET i.duracion_horas = (SELECT IFNULL(SUM(tiempo_estimado_horas), 0)
                               FROM tbl_detalle_itinerario WHERE itinerario_id = p_itinerario_id),
         i.costo_total    = (SELECT IFNULL(SUM(costo_parada), 0)
                               FROM tbl_detalle_itinerario WHERE itinerario_id = p_itinerario_id)
   WHERE i.id = p_itinerario_id;
END$$

-- Agrega una parada desde un favorito. El orden va al final y el costo se toma
-- del precio de entrada. El trigger trg_detalle_valida comprueba que el favorito sea del dueño.
CREATE PROCEDURE sp_agregar_parada(
  IN p_usuario_id INT, IN p_itinerario_id INT, IN p_favorito_id INT, IN p_tiempo_horas DECIMAL(4,2))
BEGIN
  DECLARE v_orden INT;
  DECLARE v_costo DECIMAL(8,2);

  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  IF p_tiempo_horas IS NOT NULL AND (p_tiempo_horas <= 0 OR p_tiempo_horas > 24) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tiempo estimado debe estar entre 0 y 24 horas';
  END IF;

  SELECT IFNULL(MAX(orden), 0) + 1 INTO v_orden
    FROM tbl_detalle_itinerario WHERE itinerario_id = p_itinerario_id;
  SELECT a.precio_entrada INTO v_costo
    FROM tbl_atractivo_favorito f JOIN tbl_atractivo a ON a.id = f.atractivo_id
   WHERE f.id = p_favorito_id;

  INSERT INTO tbl_detalle_itinerario (itinerario_id, atractivo_favorito_id, orden, tiempo_estimado_horas, costo_parada)
  VALUES (p_itinerario_id, p_favorito_id, v_orden, IFNULL(p_tiempo_horas, 1.00), IFNULL(v_costo, 0));

  UPDATE tbl_itinerario SET sugerido_ia = 0 WHERE id = p_itinerario_id;  -- hay una parada nueva sin ordenar
  CALL sp_actualizar_totales(p_itinerario_id);
  CALL sp_ver_itinerario(p_usuario_id, p_itinerario_id);
END$$

-- Quita una parada y "compacta" el orden (1,2,4 → 1,2,3)
CREATE PROCEDURE sp_quitar_parada(IN p_usuario_id INT, IN p_itinerario_id INT, IN p_parada_id INT)
BEGIN
  DECLARE v_orden INT;

  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  SELECT orden INTO v_orden FROM tbl_detalle_itinerario
   WHERE id = p_parada_id AND itinerario_id = p_itinerario_id;
  IF v_orden IS NULL THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Parada no encontrada';
  END IF;

  DELETE FROM tbl_detalle_itinerario WHERE id = p_parada_id;
  UPDATE tbl_detalle_itinerario SET orden = orden - 1
   WHERE itinerario_id = p_itinerario_id AND orden > v_orden
   ORDER BY orden;   -- de menor a mayor para no chocar con la regla UNIQUE

  CALL sp_actualizar_totales(p_itinerario_id);
  CALL sp_ver_itinerario(p_usuario_id, p_itinerario_id);
END$$

-- "IA": ordena la ruta de la parada más cercana a la más lejana desde el punto de partida
CREATE PROCEDURE sp_ordenar_itinerario_ia(IN p_usuario_id INT, IN p_itinerario_id INT)
BEGIN
  DECLARE v_lat DECIMAL(10,6);
  DECLARE v_lon DECIMAL(10,6);

  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  SELECT latitud_inicio, longitud_inicio INTO v_lat, v_lon
    FROM tbl_itinerario WHERE id = p_itinerario_id;
  IF v_lat IS NULL OR v_lon IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El itinerario no tiene punto de inicio';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM tbl_detalle_itinerario WHERE itinerario_id = p_itinerario_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Agrega al menos una parada antes de ordenar la ruta';
  END IF;

  -- 1) Calcular la distancia de cada parada al punto de inicio
  UPDATE tbl_detalle_itinerario d
    JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
    JOIN tbl_atractivo a          ON a.id = f.atractivo_id
     SET d.distancia_km = fn_distancia_km(v_lat, v_lon, a.latitud, a.longitud)
   WHERE d.itinerario_id = p_itinerario_id;

  -- 2) Calcular el nuevo orden en una tabla temporal
  DROP TEMPORARY TABLE IF EXISTS tmp_orden;
  CREATE TEMPORARY TABLE tmp_orden AS
    SELECT id, ROW_NUMBER() OVER (ORDER BY distancia_km, id) AS nuevo_orden
      FROM tbl_detalle_itinerario WHERE itinerario_id = p_itinerario_id;

  -- 3) Aplicar el orden (primero se mueve fuera de rango para no chocar con la regla UNIQUE)
  UPDATE tbl_detalle_itinerario SET orden = orden + 100000 WHERE itinerario_id = p_itinerario_id;
  UPDATE tbl_detalle_itinerario d JOIN tmp_orden t ON t.id = d.id SET d.orden = t.nuevo_orden;
  DROP TEMPORARY TABLE IF EXISTS tmp_orden;

  UPDATE tbl_itinerario SET sugerido_ia = 1 WHERE id = p_itinerario_id;
  CALL sp_ver_itinerario(p_usuario_id, p_itinerario_id);
END$$

-- Marca una parada como visitada (necesario antes de reseñar)
CREATE PROCEDURE sp_marcar_visitado(IN p_usuario_id INT, IN p_itinerario_id INT, IN p_parada_id INT)
BEGIN
  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  IF NOT EXISTS (SELECT 1 FROM tbl_detalle_itinerario WHERE id = p_parada_id AND itinerario_id = p_itinerario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Parada no encontrada';
  END IF;
  UPDATE tbl_detalle_itinerario SET visitado = 1 WHERE id = p_parada_id;
  CALL sp_ver_itinerario(p_usuario_id, p_itinerario_id);
END$$

-- =====================================================================
-- 8. RESEÑAS
-- =====================================================================

-- El trigger trg_resena_valida exige que el lugar se haya visitado en ese itinerario.
CREATE PROCEDURE sp_registrar_resena(
  IN p_usuario_id INT, IN p_itinerario_id INT, IN p_atractivo_id INT,
  IN p_puntuacion TINYINT, IN p_comentario VARCHAR(500))
BEGIN
  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  IF p_puntuacion < 1 OR p_puntuacion > 5 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La puntuación debe ser de 1 a 5';
  END IF;
  IF EXISTS (SELECT 1 FROM tbl_resena WHERE itinerario_id = p_itinerario_id AND atractivo_id = p_atractivo_id) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya reseñaste este atractivo en este itinerario';
  END IF;
  INSERT INTO tbl_resena (itinerario_id, atractivo_id, puntuacion, comentario)
  VALUES (p_itinerario_id, p_atractivo_id, p_puntuacion, p_comentario);
  SELECT r.id, r.puntuacion, r.comentario, r.fecha, r.atractivo_id,
         a.nombre AS atractivo, a.calificacion AS nueva_calificacion
    FROM tbl_resena r JOIN tbl_atractivo a ON a.id = r.atractivo_id
   WHERE r.id = LAST_INSERT_ID();
END$$

-- Reseñas públicas de un atractivo. Devuelve 2 resultados: filas y total.
CREATE PROCEDURE sp_listar_resenas_atractivo(IN p_atractivo_id INT, IN p_limit INT, IN p_offset INT)
BEGIN
  CALL sp_validar_atractivo(p_atractivo_id);
  SELECT r.id, r.puntuacion, r.comentario, r.fecha, u.nombre_completo AS autor
    FROM tbl_resena r
    JOIN tbl_itinerario i ON i.id = r.itinerario_id
    JOIN tbl_usuario u    ON u.id = i.usuario_id
   WHERE r.atractivo_id = p_atractivo_id
   ORDER BY r.fecha DESC
   LIMIT p_limit OFFSET p_offset;
  SELECT COUNT(*) AS total FROM tbl_resena WHERE atractivo_id = p_atractivo_id;
END$$

-- ADMIN: modera (borra) una reseña; el trigger recalcula la calificación
CREATE PROCEDURE sp_eliminar_resena(IN p_resena_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_resena WHERE id = p_resena_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Reseña no encontrada';
  END IF;
  DELETE FROM tbl_resena WHERE id = p_resena_id;
END$$

-- =====================================================================
-- 9. ASISTENTE Y PREGUNTAS FRECUENTES
-- =====================================================================

-- Busca la respuesta preparada más parecida (búsqueda FULLTEXT)
CREATE PROCEDURE sp_buscar_pregunta_frecuente(IN p_texto VARCHAR(255))
BEGIN
  SELECT p.id, p.pregunta, p.respuesta, p.atractivo_id, a.nombre AS atractivo,
         MATCH(p.pregunta, p.palabras_clave) AGAINST (p_texto IN NATURAL LANGUAGE MODE) AS relevancia
    FROM tbl_pregunta_frecuente p
    LEFT JOIN tbl_atractivo a ON a.id = p.atractivo_id
   WHERE MATCH(p.pregunta, p.palabras_clave) AGAINST (p_texto IN NATURAL LANGUAGE MODE)
   ORDER BY relevancia DESC
   LIMIT 1;
END$$

CREATE PROCEDURE sp_listar_preguntas()
BEGIN
  SELECT p.id, p.pregunta, p.respuesta, p.palabras_clave, p.atractivo_id, a.nombre AS atractivo
    FROM tbl_pregunta_frecuente p
    LEFT JOIN tbl_atractivo a ON a.id = p.atractivo_id
   ORDER BY p.id;
END$$

CREATE PROCEDURE sp_crear_pregunta(
  IN p_pregunta VARCHAR(255), IN p_respuesta TEXT, IN p_palabras VARCHAR(255), IN p_atractivo_id INT)
BEGIN
  IF p_atractivo_id IS NOT NULL THEN
    CALL sp_validar_atractivo(p_atractivo_id);
  END IF;
  INSERT INTO tbl_pregunta_frecuente (pregunta, respuesta, palabras_clave, atractivo_id)
  VALUES (p_pregunta, p_respuesta, p_palabras, p_atractivo_id);
  SELECT id, pregunta, respuesta, palabras_clave, atractivo_id
    FROM tbl_pregunta_frecuente WHERE id = LAST_INSERT_ID();
END$$

CREATE PROCEDURE sp_actualizar_pregunta(
  IN p_id INT, IN p_pregunta VARCHAR(255), IN p_respuesta TEXT, IN p_palabras VARCHAR(255), IN p_atractivo_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_pregunta_frecuente WHERE id = p_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Pregunta no encontrada';
  END IF;
  IF p_atractivo_id IS NOT NULL THEN
    CALL sp_validar_atractivo(p_atractivo_id);
  END IF;
  UPDATE tbl_pregunta_frecuente
     SET pregunta = p_pregunta, respuesta = p_respuesta, palabras_clave = p_palabras, atractivo_id = p_atractivo_id
   WHERE id = p_id;
  SELECT id, pregunta, respuesta, palabras_clave, atractivo_id FROM tbl_pregunta_frecuente WHERE id = p_id;
END$$

CREATE PROCEDURE sp_eliminar_pregunta(IN p_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_pregunta_frecuente WHERE id = p_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Pregunta no encontrada';
  END IF;
  DELETE FROM tbl_pregunta_frecuente WHERE id = p_id;
END$$

DELIMITER ;

-- >>> seed.sql
-- =====================================================================
--  CuscoSmart IA · seed.sql
--  Datos de prueba. Ejecutar DESPUÉS de schema.sql y logica.sql.
--  Coordenadas y precios son referenciales (precios en soles).
-- =====================================================================

USE cuscosmart_db;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- Catálogos
-- ---------------------------------------------------------------------
INSERT INTO tbl_categoria (nombre, descripcion) VALUES
 ('Sitio arqueológico', 'Restos incas y preincas'),          -- 1
 ('Museo',              'Museos y centros culturales'),       -- 2
 ('Iglesia',            'Templos coloniales'),                -- 3
 ('Mirador',            'Vistas panorámicas de la ciudad'),   -- 4
 ('Barrio y mercado',   'Vida local, artesanía y comida');    -- 5

INSERT INTO tbl_zona (nombre, ciudad) VALUES
 ('Centro Histórico',      'Cusco'),      -- 1
 ('Valle Sagrado',         'Urubamba'),   -- 2
 ('Parque Arqueológico',   'Cusco');      -- 3

-- ---------------------------------------------------------------------
-- Atractivos (los 4 primeros son los del diseño original del grupo)
-- ---------------------------------------------------------------------
INSERT INTO tbl_atractivo (nombre, descripcion, direccion, latitud, longitud, precio_entrada, categoria_id, zona_id) VALUES
 ('Sacsayhuamán',          'Fortaleza inca con muros de piedra gigantes.',                     'Carretera a Sacsayhuamán',   -13.509800, -71.981800, 70.00, 1, 3),  -- 1
 ('Qorikancha',            'Templo del Sol inca y convento de Santo Domingo.',                 'Plazoleta Santo Domingo',    -13.520100, -71.975300, 15.00, 2, 1),  -- 2
 ('Catedral del Cusco',    'Catedral colonial en la Plaza de Armas.',                          'Plaza de Armas',             -13.516300, -71.978500, 25.00, 3, 1),  -- 3
 ('Pisac',                 'Complejo arqueológico con andenes.',                               'Pisac, Calca',               -13.410000, -71.850000, 70.00, 1, 2),  -- 4
 ('Plaza de Armas',        'Corazón de la ciudad, rodeada de portales y templos.',             'Plaza de Armas',             -13.516700, -71.978800,  0.00, 5, 1),  -- 5
 ('Barrio de San Blas',    'Barrio de artesanos con calles empinadas y talleres.',             'Cuesta de San Blas',         -13.514600, -71.974900,  0.00, 5, 1),  -- 6
 ('Mercado de San Pedro',  'Mercado tradicional: jugos, frutas y comida típica.',              'Calle Thupaq Amaru',         -13.521800, -71.984300,  0.00, 5, 1),  -- 7
 ('Museo Inka',            'Colección de cerámica, textiles y momias incas.',                  'Cuesta del Almirante 103',   -13.515700, -71.977700, 10.00, 2, 1),  -- 8
 ('Cristo Blanco',         'Mirador con la mejor vista de la ciudad.',                         'Cerro Pukamoqo',             -13.509400, -71.977600,  0.00, 4, 3),  -- 9
 ('Qenqo',                 'Adoratorio inca tallado en roca, con canales y cuevas.',           'Carretera a Pisac km 4',     -13.509800, -71.966700, 70.00, 1, 3),  -- 10
 ('Tambomachay',           'Baños del Inca con fuentes de agua que aún funcionan.',            'Carretera a Pisac km 8',     -13.482100, -71.965100, 70.00, 1, 3),  -- 11
 ('Ollantaytambo',         'Pueblo inca vivo y fortaleza con terrazas monumentales.',          'Ollantaytambo, Urubamba',    -13.258800, -72.262900, 70.00, 1, 2),  -- 12
 ('Moray',                 'Andenes circulares usados como laboratorio agrícola.',             'Maras, Urubamba',            -13.329700, -72.196300, 70.00, 1, 2),  -- 13
 ('Salineras de Maras',    'Miles de pozos de sal en la ladera del cerro.',                    'Maras, Urubamba',            -13.304700, -72.153900, 20.00, 1, 2);  -- 14

INSERT INTO tbl_horario (dia_semana, hora_apertura, hora_cierre, atractivo_id) VALUES
 ('Lunes a Domingo', '07:00', '17:30', 1),
 ('Lunes a Sábado',  '08:30', '17:30', 2),
 ('Domingo',         '14:00', '17:00', 2),
 ('Lunes a Domingo', '10:00', '18:00', 3),
 ('Lunes a Domingo', '07:00', '17:30', 4),
 ('Lunes a Domingo', '06:00', '18:00', 7),
 ('Lunes a Sábado',  '08:00', '18:00', 8),
 ('Lunes a Domingo', '07:00', '17:30', 10),
 ('Lunes a Domingo', '07:00', '17:30', 11),
 ('Lunes a Domingo', '07:00', '17:30', 12),
 ('Lunes a Domingo', '07:00', '17:30', 13),
 ('Lunes a Domingo', '08:30', '17:00', 14);

INSERT INTO tbl_foto (url_foto, descripcion, atractivo_id) VALUES
 ('img/sacsayhuaman.jpg', 'Muros principales',          1),
 ('img/qorikancha.jpg',   'Patio del templo',           2),
 ('img/catedral.jpg',     'Fachada de la catedral',     3),
 ('img/pisac.jpg',        'Andenes de Pisac',           4),
 ('img/plaza-armas.jpg',  'Vista de la plaza',          5),
 ('img/san-blas.jpg',     'Calle de San Blas',          6),
 ('img/san-pedro.jpg',    'Puestos del mercado',        7),
 ('img/cristo-blanco.jpg','Vista desde el mirador',     9),
 ('img/ollantaytambo.jpg','Terrazas de la fortaleza',   12),
 ('img/moray.jpg',        'Andenes circulares',         13),
 ('img/maras.jpg',        'Pozos de sal',               14);

-- ---------------------------------------------------------------------
-- Preguntas frecuentes del asistente
-- ---------------------------------------------------------------------
INSERT INTO tbl_pregunta_frecuente (pregunta, respuesta, palabras_clave, atractivo_id) VALUES
 ('¿Necesito boleto turístico para Sacsayhuamán?', 'Sí. Se ingresa con el Boleto Turístico del Cusco (integral o parcial del circuito I).', 'boleto entrada ticket precio cuesta', 1),
 ('¿Cuál es la mejor época para visitar Cusco?', 'De mayo a setiembre, en la temporada seca. De diciembre a marzo llueve casi todos los días.', 'epoca clima lluvia temporada mes', NULL),
 ('¿Qué llevar para evitar el mal de altura?', 'Hidrátate, come ligero, descansa el primer día y toma mate de coca. Cusco está a 3 399 m s. n. m.', 'altura soroche mareo salud', NULL),
 ('¿Cuánto cuesta el boleto turístico del Cusco?', 'El boleto integral cuesta S/ 130 para extranjeros (S/ 70 para nacionales) y vale 10 días en 16 lugares.', 'boleto turistico precio costo integral', NULL),
 ('¿Cómo llego al Valle Sagrado?', 'En colectivo desde la calle Pavitos (Urubamba, Pisac) o con un tour de día completo que sale de la Plaza de Armas.', 'valle sagrado transporte colectivo llegar bus', NULL),
 ('¿A qué hora abre el Qorikancha?', 'De lunes a sábado de 8:30 a 17:30 y los domingos de 14:00 a 17:00.', 'qorikancha horario abre hora', 2),
 ('¿Es seguro caminar de noche por el Centro Histórico?', 'Sí, en las calles principales y con iluminación. Evita calles vacías y lleva tus objetos de valor a la vista.', 'seguridad noche caminar seguro', NULL),
 ('¿Dónde puedo comer comida típica barata?', 'En el Mercado de San Pedro: menús, jugos y caldos a precios económicos.', 'comida comer barato mercado tipica', 7);

-- ---------------------------------------------------------------------
-- Usuarios de prueba (contraseñas encriptadas con bcrypt):
--   admin@cuscosmart.pe  ->  Admin12345   (rol ADMIN)
--   ana@mail.com         ->  Turista123   (rol TURISTA)
-- ---------------------------------------------------------------------
INSERT INTO tbl_usuario (nombre_completo, correo, contrasena, rol) VALUES
 ('Administrador', 'admin@cuscosmart.pe', '$2a$10$Q0sekcIlIaoRAmLoirABMO5YNbmAqy4g0QXdu00ZbNvyZDsd4Nn.S', 'ADMIN'),
 ('Ana Quispe',    'ana@mail.com',        '$2a$10$VtTjjf95cV3QrkrPrfnMj.bsTKmVi5Pii8kmzjZF.6g..TnvAOG.a', 'TURISTA');

-- ---------------------------------------------------------------------
-- Un viaje de ejemplo de Ana (se arma con los procedimientos, igual que lo hará la API)
-- ---------------------------------------------------------------------
CALL sp_agregar_favorito(2, 1);    -- favorito 1: Sacsayhuamán
CALL sp_agregar_favorito(2, 2);    -- favorito 2: Qorikancha
CALL sp_agregar_favorito(2, 3);    -- favorito 3: Catedral
CALL sp_agregar_favorito(2, 9);    -- favorito 4: Cristo Blanco

-- Punto de inicio: un hotel cerca de la Plaza Regocijo
CALL sp_crear_itinerario(2, 'Mi primer día en Cusco', -13.517500, -71.980000);   -- itinerario 1
CALL sp_agregar_parada(2, 1, 1, 2.00);
CALL sp_agregar_parada(2, 1, 2, 1.50);
CALL sp_agregar_parada(2, 1, 3, 1.00);
CALL sp_ordenar_itinerario_ia(2, 1);
CALL sp_marcar_visitado(2, 1, (SELECT d.id FROM tbl_detalle_itinerario d JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id WHERE d.itinerario_id = 1 AND f.atractivo_id = 3));
CALL sp_registrar_resena(2, 1, 3, 5, 'Impresionante por dentro, vale cada sol.');

-- >>> usuario.sql
-- =====================================================================
--  CuscoSmart IA · usuario.sql
--  Usuario de MySQL que usa la API. La API NUNCA se conecta como root.
--  Permisos mínimos: leer, escribir y EJECUTAR procedimientos.
-- =====================================================================

CREATE USER IF NOT EXISTS 'cuscosmart_user'@'localhost' IDENTIFIED BY 'Cusco2026*';
CREATE USER IF NOT EXISTS 'cuscosmart_user'@'127.0.0.1' IDENTIFIED BY 'Cusco2026*';

-- Si el usuario ya existía con otra clave, la deja igual a la del .env.example
ALTER USER 'cuscosmart_user'@'localhost' IDENTIFIED BY 'Cusco2026*';
ALTER USER 'cuscosmart_user'@'127.0.0.1' IDENTIFIED BY 'Cusco2026*';

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON cuscosmart_db.* TO 'cuscosmart_user'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON cuscosmart_db.* TO 'cuscosmart_user'@'127.0.0.1';
FLUSH PRIVILEGES;

-- >>> verificacion.sql
-- =====================================================================
--  CuscoSmart IA · verificacion.sql
--  Resumen rápido para confirmar que todo se creó bien.
-- =====================================================================
USE cuscosmart_db;

SELECT 'tablas' AS objeto, COUNT(*) AS cantidad FROM information_schema.TABLES
 WHERE TABLE_SCHEMA = 'cuscosmart_db'
UNION ALL SELECT 'procedimientos', COUNT(*) FROM information_schema.ROUTINES
 WHERE ROUTINE_SCHEMA = 'cuscosmart_db' AND ROUTINE_TYPE = 'PROCEDURE'
UNION ALL SELECT 'funciones', COUNT(*) FROM information_schema.ROUTINES
 WHERE ROUTINE_SCHEMA = 'cuscosmart_db' AND ROUTINE_TYPE = 'FUNCTION'
UNION ALL SELECT 'triggers', COUNT(*) FROM information_schema.TRIGGERS
 WHERE TRIGGER_SCHEMA = 'cuscosmart_db'
UNION ALL SELECT 'atractivos', COUNT(*) FROM tbl_atractivo
UNION ALL SELECT 'usuarios', COUNT(*) FROM tbl_usuario
UNION ALL SELECT 'preguntas', COUNT(*) FROM tbl_pregunta_frecuente;

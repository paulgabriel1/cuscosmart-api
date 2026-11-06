-- =====================================================================
--  CuscoSmart IA · cuscosmart_todo.sql (ARCHIVO GENERADO: no editar a mano)
--  Une schema + logica + seed + usuario + verificacion. Se arma con: npm run db:armar
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

-- Modo estricto: si un valor no cabe en su columna, MySQL da error en vez de recortarlo en silencio.
-- (Los procedimientos y triggers guardan el modo con el que se crearon.)
SET SESSION sql_mode = 'STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

DROP FUNCTION  IF EXISTS fn_distancia_km;
DROP TRIGGER   IF EXISTS trg_detalle_valida;
DROP TRIGGER   IF EXISTS trg_resena_valida;
DROP TRIGGER   IF EXISTS trg_resena_calificacion_ins;
DROP TRIGGER   IF EXISTS trg_resena_calificacion_del;

DROP PROCEDURE IF EXISTS sp_registrar_usuario;
DROP PROCEDURE IF EXISTS sp_usuario_por_correo;
DROP PROCEDURE IF EXISTS sp_usuario_por_id;
DROP PROCEDURE IF EXISTS sp_actualizar_perfil;
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
DROP PROCEDURE IF EXISTS sp_limpiar_lugares_de_viaje;
DROP PROCEDURE IF EXISTS sp_agregar_parada_lugar;
DROP PROCEDURE IF EXISTS sp_desmarcar_visitado;
DROP PROCEDURE IF EXISTS sp_mi_recorrido;
DROP PROCEDURE IF EXISTS sp_eliminar_mi_resena;
DROP PROCEDURE IF EXISTS sp_nombres_atractivos;
DROP PROCEDURE IF EXISTS sp_validar_itinerario;
DROP PROCEDURE IF EXISTS sp_crear_itinerario;
DROP PROCEDURE IF EXISTS sp_listar_itinerarios;
DROP PROCEDURE IF EXISTS sp_ver_itinerario;
DROP PROCEDURE IF EXISTS sp_actualizar_itinerario;
DROP PROCEDURE IF EXISTS sp_eliminar_itinerario;
DROP PROCEDURE IF EXISTS sp_actualizar_totales;
DROP PROCEDURE IF EXISTS sp_recalcular_itinerarios;
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
  -- Además de los datos, devuelve sus totales (para la pantalla "Mi perfil")
  SELECT u.id, u.nombre_completo, u.correo, u.telefono, u.rol, u.fecha_registro,
         (SELECT COUNT(*) FROM tbl_atractivo_favorito f WHERE f.usuario_id = u.id AND f.es_favorito = 1) AS favoritos,
         (SELECT COUNT(*) FROM tbl_itinerario i WHERE i.usuario_id = u.id)         AS viajes,
         (SELECT COUNT(*) FROM tbl_resena r JOIN tbl_itinerario ir ON ir.id = r.itinerario_id WHERE ir.usuario_id = u.id) AS resenas
    FROM tbl_usuario u WHERE u.id = p_usuario_id;
END$$

-- El usuario edita su nombre y su teléfono (el correo y el rol no se cambian aquí)
CREATE PROCEDURE sp_actualizar_perfil(
  IN p_usuario_id INT, IN p_nombre VARCHAR(150), IN p_telefono VARCHAR(20))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_usuario WHERE id = p_usuario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Usuario no encontrado';
  END IF;
  UPDATE tbl_usuario SET nombre_completo = p_nombre, telefono = p_telefono WHERE id = p_usuario_id;
  CALL sp_usuario_por_id(p_usuario_id);
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
-- Búsqueda: sin importar tildes ni mayúsculas (collation unicode_ci), por palabras en orden
-- ("plaza armas" encuentra "Plaza de Armas") y también en categoría, zona y dirección.
-- Los que coinciden por NOMBRE salen primero.
CREATE PROCEDURE sp_listar_atractivos(
  IN p_categoria_id INT, IN p_zona_id INT, IN p_buscar VARCHAR(100),
  IN p_limit INT, IN p_offset INT)
BEGIN
  DECLARE v_patron VARCHAR(220) DEFAULT NULL;
  IF p_buscar IS NOT NULL AND TRIM(p_buscar) <> '' THEN
    SET v_patron = CONCAT('%', REPLACE(TRIM(p_buscar), ' ', '%'), '%');
  END IF;

  SELECT a.id, a.nombre, a.direccion, a.latitud, a.longitud, a.precio_entrada, a.calificacion,
         a.categoria_id, c.nombre AS categoria, a.zona_id, z.nombre AS zona,
         (SELECT f.url_foto FROM tbl_foto f WHERE f.atractivo_id = a.id ORDER BY f.id LIMIT 1) AS foto
    FROM tbl_atractivo a
    JOIN tbl_categoria c ON c.id = a.categoria_id
    JOIN tbl_zona z      ON z.id = a.zona_id
   WHERE (p_categoria_id IS NULL OR a.categoria_id = p_categoria_id)
     AND (p_zona_id      IS NULL OR a.zona_id      = p_zona_id)
     AND (v_patron       IS NULL OR a.nombre LIKE v_patron OR a.descripcion LIKE v_patron
                                 OR a.direccion LIKE v_patron OR c.nombre LIKE v_patron OR z.nombre LIKE v_patron)
   ORDER BY (v_patron IS NOT NULL AND a.nombre LIKE v_patron) DESC, a.calificacion DESC, a.nombre
   LIMIT p_limit OFFSET p_offset;

  SELECT COUNT(*) AS total
    FROM tbl_atractivo a
    JOIN tbl_categoria c ON c.id = a.categoria_id
    JOIN tbl_zona z      ON z.id = a.zona_id
   WHERE (p_categoria_id IS NULL OR a.categoria_id = p_categoria_id)
     AND (p_zona_id      IS NULL OR a.zona_id      = p_zona_id)
     AND (v_patron       IS NULL OR a.nombre LIKE v_patron OR a.descripcion LIKE v_patron
                                 OR a.direccion LIKE v_patron OR c.nombre LIKE v_patron OR z.nombre LIKE v_patron);
END$$

-- Nombres de todos los atractivos: la API los usa para sugerir "¿Quisiste decir…?" cuando hay errores de tipeo
CREATE PROCEDURE sp_nombres_atractivos()
BEGIN
  SELECT a.id, a.nombre, c.nombre AS categoria
    FROM tbl_atractivo a JOIN tbl_categoria c ON c.id = a.categoria_id
   ORDER BY a.nombre;
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
  DECLARE v_se_movio BOOLEAN;

  CALL sp_validar_atractivo(p_id);
  SELECT NOT (latitud <=> p_latitud AND longitud <=> p_longitud) INTO v_se_movio
    FROM tbl_atractivo WHERE id = p_id;

  UPDATE tbl_atractivo
     SET nombre = p_nombre, descripcion = p_descripcion, direccion = p_direccion,
         latitud = p_latitud, longitud = p_longitud, precio_entrada = p_precio,
         categoria_id = p_categoria_id, zona_id = p_zona_id
   WHERE id = p_id;

  -- Si el atractivo cambió de ubicación, las rutas que lo usan ya no están ordenadas
  IF v_se_movio THEN
    UPDATE tbl_itinerario SET sugerido_ia = 0
     WHERE id IN (SELECT d.itinerario_id FROM tbl_detalle_itinerario d
                    JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
                   WHERE f.atractivo_id = p_id);
    UPDATE tbl_detalle_itinerario d
      JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
       SET d.distancia_km = NULL
     WHERE f.atractivo_id = p_id;
  END IF;
END$$

-- Al borrar un atractivo caen en cascada sus horarios, fotos, favoritos, paradas y reseñas.
-- Después se recalculan el orden y los totales de los itinerarios que lo tenían como parada.
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

  CALL sp_recalcular_itinerarios();
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
-- Si el lugar ya estaba guardado solo como parada de un viaje (es_favorito = 0), se vuelve favorito.
CREATE PROCEDURE sp_agregar_favorito(IN p_usuario_id INT, IN p_atractivo_id INT)
BEGIN
  DECLARE v_id INT;
  DECLARE v_es TINYINT;

  CALL sp_validar_atractivo(p_atractivo_id);
  SET v_id = (SELECT id FROM tbl_atractivo_favorito WHERE usuario_id = p_usuario_id AND atractivo_id = p_atractivo_id);
  SET v_es = (SELECT es_favorito FROM tbl_atractivo_favorito WHERE id = v_id);
  IF v_es = 1 THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ese atractivo ya está en tus favoritos';
  END IF;

  IF v_id IS NOT NULL THEN
    UPDATE tbl_atractivo_favorito SET es_favorito = 1, fecha_guardado = CURRENT_TIMESTAMP(6) WHERE id = v_id;
    SELECT v_id AS favorito_id;
  ELSE
    INSERT INTO tbl_atractivo_favorito (usuario_id, atractivo_id) VALUES (p_usuario_id, p_atractivo_id);
    SELECT LAST_INSERT_ID() AS favorito_id;
  END IF;
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
   WHERE f.usuario_id = p_usuario_id AND f.es_favorito = 1
   ORDER BY f.fecha_guardado DESC;
END$$

-- Quitar un favorito NO toca los viajes: si el lugar es parada de algún viaje, solo deja de
-- mostrarse en "Favoritos" (es_favorito = 0); si no se usa en ningún viaje, se borra.
CREATE PROCEDURE sp_quitar_favorito(IN p_usuario_id INT, IN p_favorito_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_atractivo_favorito
                  WHERE id = p_favorito_id AND usuario_id = p_usuario_id AND es_favorito = 1) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Favorito no encontrado';
  END IF;

  IF EXISTS (SELECT 1 FROM tbl_detalle_itinerario WHERE atractivo_favorito_id = p_favorito_id) THEN
    UPDATE tbl_atractivo_favorito SET es_favorito = 0 WHERE id = p_favorito_id;
  ELSE
    DELETE FROM tbl_atractivo_favorito WHERE id = p_favorito_id;
  END IF;
END$$

-- Uso interno: borra los lugares que solo existían para un viaje (es_favorito = 0)
-- y que ya no son parada de ningún viaje.
CREATE PROCEDURE sp_limpiar_lugares_de_viaje(IN p_usuario_id INT)
BEGIN
  DELETE f FROM tbl_atractivo_favorito f
    LEFT JOIN tbl_detalle_itinerario d ON d.atractivo_favorito_id = f.id
   WHERE f.usuario_id = p_usuario_id AND f.es_favorito = 0 AND d.id IS NULL;
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
  -- distancia_km se calcula siempre al vuelo desde el punto de inicio (aunque la ruta no esté ordenada)
  SELECT d.id AS parada_id, d.orden,
         fn_distancia_km(i.latitud_inicio, i.longitud_inicio, a.latitud, a.longitud) AS distancia_km,
         d.tiempo_estimado_horas, d.costo_parada, d.visitado, d.fecha_visita,
         f.id AS favorito_id, f.es_favorito, a.id AS atractivo_id, a.nombre AS atractivo, a.latitud, a.longitud,
         c.nombre AS categoria,
         (SELECT ft.url_foto FROM tbl_foto ft WHERE ft.atractivo_id = a.id ORDER BY ft.id LIMIT 1) AS foto,
         r.id AS resena_id, r.puntuacion,
         r.id IS NOT NULL AS resenado
    FROM tbl_detalle_itinerario d
    JOIN tbl_itinerario i         ON i.id = d.itinerario_id
    JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
    JOIN tbl_atractivo a          ON a.id = f.atractivo_id
    JOIN tbl_categoria c          ON c.id = a.categoria_id
    LEFT JOIN tbl_resena r        ON r.itinerario_id = d.itinerario_id AND r.atractivo_id = a.id
   WHERE d.itinerario_id = p_itinerario_id
   ORDER BY d.orden;
END$$

-- "Mi recorrido" (perfil): todas las paradas de todos mis viajes, como checklist / línea de tiempo.
-- Primero lo visitado (lo más reciente arriba) y después lo pendiente.
CREATE PROCEDURE sp_mi_recorrido(IN p_usuario_id INT)
BEGIN
  SELECT d.id AS parada_id, d.visitado, d.fecha_visita, d.orden,
         i.id AS itinerario_id, i.nombre AS itinerario,
         a.id AS atractivo_id, a.nombre AS atractivo, c.nombre AS categoria, z.nombre AS zona,
         (SELECT ft.url_foto FROM tbl_foto ft WHERE ft.atractivo_id = a.id ORDER BY ft.id LIMIT 1) AS foto,
         r.id AS resena_id, r.puntuacion
    FROM tbl_detalle_itinerario d
    JOIN tbl_itinerario i         ON i.id = d.itinerario_id
    JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
    JOIN tbl_atractivo a          ON a.id = f.atractivo_id
    JOIN tbl_categoria c          ON c.id = a.categoria_id
    JOIN tbl_zona z               ON z.id = a.zona_id
    LEFT JOIN tbl_resena r        ON r.itinerario_id = d.itinerario_id AND r.atractivo_id = a.id
   WHERE i.usuario_id = p_usuario_id
   ORDER BY d.visitado DESC, d.fecha_visita DESC, i.fecha_creacion DESC, d.orden;
END$$

-- Si cambia el punto de inicio, la ruta deja de estar ordenada por la IA.
CREATE PROCEDURE sp_actualizar_itinerario(
  IN p_usuario_id INT, IN p_itinerario_id INT, IN p_nombre VARCHAR(200),
  IN p_latitud_inicio DECIMAL(10,6), IN p_longitud_inicio DECIMAL(10,6))
BEGIN
  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  IF NOT EXISTS (SELECT 1 FROM tbl_itinerario
                  WHERE id = p_itinerario_id
                    AND latitud_inicio <=> p_latitud_inicio AND longitud_inicio <=> p_longitud_inicio) THEN
    UPDATE tbl_detalle_itinerario SET distancia_km = NULL WHERE itinerario_id = p_itinerario_id;
  END IF;
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
  CALL sp_limpiar_lugares_de_viaje(p_usuario_id);
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

-- Uso interno: tras borrar paradas EN CASCADA (al quitar un favorito o un atractivo),
-- vuelve a numerar el orden (1,2,4 → 1,2,3) y recalcula los totales de los itinerarios
-- listados en la tabla temporal tmp_itinerarios (la crea quien llama a este procedimiento).
CREATE PROCEDURE sp_recalcular_itinerarios()
BEGIN
  DROP TEMPORARY TABLE IF EXISTS tmp_orden_nuevo;
  CREATE TEMPORARY TABLE tmp_orden_nuevo AS
    SELECT d.id, ROW_NUMBER() OVER (PARTITION BY d.itinerario_id ORDER BY d.orden) AS nuevo_orden
      FROM tbl_detalle_itinerario d JOIN tmp_itinerarios t ON t.id = d.itinerario_id;
  UPDATE tbl_detalle_itinerario d JOIN tmp_orden_nuevo o ON o.id = d.id SET d.orden = d.orden + 100000;
  UPDATE tbl_detalle_itinerario d JOIN tmp_orden_nuevo o ON o.id = d.id SET d.orden = o.nuevo_orden;
  DROP TEMPORARY TABLE IF EXISTS tmp_orden_nuevo;

  UPDATE tbl_itinerario i JOIN tmp_itinerarios t ON t.id = i.id
     SET i.duracion_horas = (SELECT IFNULL(SUM(tiempo_estimado_horas), 0) FROM tbl_detalle_itinerario WHERE itinerario_id = i.id),
         i.costo_total    = (SELECT IFNULL(SUM(costo_parada), 0)          FROM tbl_detalle_itinerario WHERE itinerario_id = i.id);
END$$

-- Agrega una parada desde un favorito. El orden va al final y el costo se toma
-- del precio de entrada. El favorito debe ser del dueño (y el trigger trg_detalle_valida lo vuelve a exigir).
CREATE PROCEDURE sp_agregar_parada(
  IN p_usuario_id INT, IN p_itinerario_id INT, IN p_favorito_id INT, IN p_tiempo_horas DECIMAL(4,2))
BEGIN
  DECLARE v_orden INT;
  DECLARE v_costo DECIMAL(8,2);

  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  IF NOT EXISTS (SELECT 1 FROM tbl_atractivo_favorito WHERE id = p_favorito_id AND usuario_id = p_usuario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Favorito no encontrado';
  END IF;
  IF EXISTS (SELECT 1 FROM tbl_detalle_itinerario
              WHERE itinerario_id = p_itinerario_id AND atractivo_favorito_id = p_favorito_id) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ese lugar ya está en el itinerario';
  END IF;
  IF p_tiempo_horas IS NOT NULL AND (p_tiempo_horas <= 0 OR p_tiempo_horas > 24) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tiempo estimado debe estar entre 0 y 24 horas';
  END IF;

  SELECT IFNULL(MAX(orden), 0) + 1 INTO v_orden
    FROM tbl_detalle_itinerario WHERE itinerario_id = p_itinerario_id;
  SELECT a.precio_entrada INTO v_costo
    FROM tbl_atractivo_favorito f JOIN tbl_atractivo a ON a.id = f.atractivo_id
   WHERE f.id = p_favorito_id;

  -- Que los totales no superen lo que cabe en las columnas del itinerario
  IF (SELECT duracion_horas FROM tbl_itinerario WHERE id = p_itinerario_id) + IFNULL(p_tiempo_horas, 1) > 999.99
     OR (SELECT costo_total FROM tbl_itinerario WHERE id = p_itinerario_id) + IFNULL(v_costo, 0) > 999999.99 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El itinerario superó el máximo de horas o de costo';
  END IF;

  INSERT INTO tbl_detalle_itinerario (itinerario_id, atractivo_favorito_id, orden, tiempo_estimado_horas, costo_parada)
  VALUES (p_itinerario_id, p_favorito_id, v_orden, IFNULL(p_tiempo_horas, 1.00), IFNULL(v_costo, 0));

  UPDATE tbl_itinerario SET sugerido_ia = 0 WHERE id = p_itinerario_id;  -- hay una parada nueva sin ordenar
  CALL sp_actualizar_totales(p_itinerario_id);
  CALL sp_ver_itinerario(p_usuario_id, p_itinerario_id);
END$$

-- Agrega una parada a partir de CUALQUIER atractivo, sin guardarlo en "Favoritos".
-- Por dentro el viaje sigue apuntando a tbl_atractivo_favorito (diagrama ER), pero con es_favorito = 0.
CREATE PROCEDURE sp_agregar_parada_lugar(
  IN p_usuario_id INT, IN p_itinerario_id INT, IN p_atractivo_id INT, IN p_tiempo_horas DECIMAL(4,2))
BEGIN
  DECLARE v_fav INT;

  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  CALL sp_validar_atractivo(p_atractivo_id);
  IF p_tiempo_horas IS NOT NULL AND (p_tiempo_horas <= 0 OR p_tiempo_horas > 24) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El tiempo estimado debe estar entre 0 y 24 horas';
  END IF;

  SET v_fav = (SELECT id FROM tbl_atractivo_favorito WHERE usuario_id = p_usuario_id AND atractivo_id = p_atractivo_id);
  IF v_fav IS NOT NULL AND EXISTS (SELECT 1 FROM tbl_detalle_itinerario
                                    WHERE itinerario_id = p_itinerario_id AND atractivo_favorito_id = v_fav) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ese lugar ya está en el itinerario';
  END IF;
  IF v_fav IS NULL THEN
    INSERT INTO tbl_atractivo_favorito (usuario_id, atractivo_id, es_favorito) VALUES (p_usuario_id, p_atractivo_id, 0);
    SET v_fav = LAST_INSERT_ID();
  END IF;

  CALL sp_agregar_parada(p_usuario_id, p_itinerario_id, v_fav, p_tiempo_horas);
END$$

-- Quita una parada y "compacta" el orden (1,2,4 → 1,2,3).
-- Si ese lugar tenía reseña en este viaje, se borra también: ya no hay visita que la respalde.
CREATE PROCEDURE sp_quitar_parada(IN p_usuario_id INT, IN p_itinerario_id INT, IN p_parada_id INT)
BEGIN
  DECLARE v_orden INT;
  DECLARE v_atractivo INT;

  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  SET v_orden = (SELECT orden FROM tbl_detalle_itinerario WHERE id = p_parada_id AND itinerario_id = p_itinerario_id);
  IF v_orden IS NULL THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Parada no encontrada';
  END IF;
  SET v_atractivo = (SELECT f.atractivo_id FROM tbl_detalle_itinerario d
                       JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id WHERE d.id = p_parada_id);

  DELETE FROM tbl_resena WHERE itinerario_id = p_itinerario_id AND atractivo_id = v_atractivo;  -- el trigger recalcula
  DELETE FROM tbl_detalle_itinerario WHERE id = p_parada_id;
  UPDATE tbl_detalle_itinerario SET orden = orden - 1
   WHERE itinerario_id = p_itinerario_id AND orden > v_orden
   ORDER BY orden;   -- de menor a mayor para no chocar con la regla UNIQUE

  CALL sp_limpiar_lugares_de_viaje(p_usuario_id);
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
    SELECT id, ROW_NUMBER() OVER (ORDER BY distancia_km IS NULL, distancia_km, id) AS nuevo_orden  -- sin coordenadas: al final
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
  UPDATE tbl_detalle_itinerario
     SET visitado = 1, fecha_visita = IFNULL(fecha_visita, CURRENT_TIMESTAMP(6))
   WHERE id = p_parada_id;
  CALL sp_ver_itinerario(p_usuario_id, p_itinerario_id);
END$$

-- Desmarca una visita (checklist del perfil). No se permite si ya la reseñaste.
CREATE PROCEDURE sp_desmarcar_visitado(IN p_usuario_id INT, IN p_itinerario_id INT, IN p_parada_id INT)
BEGIN
  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  IF NOT EXISTS (SELECT 1 FROM tbl_detalle_itinerario WHERE id = p_parada_id AND itinerario_id = p_itinerario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Parada no encontrada';
  END IF;
  IF EXISTS (SELECT 1 FROM tbl_resena r
               JOIN tbl_atractivo_favorito f ON f.atractivo_id = r.atractivo_id
               JOIN tbl_detalle_itinerario d ON d.atractivo_favorito_id = f.id
              WHERE d.id = p_parada_id AND r.itinerario_id = p_itinerario_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya reseñaste este lugar: borra la reseña antes de desmarcarlo';
  END IF;
  UPDATE tbl_detalle_itinerario SET visitado = 0, fecha_visita = NULL WHERE id = p_parada_id;
  CALL sp_ver_itinerario(p_usuario_id, p_itinerario_id);
END$$

-- =====================================================================
-- 8. RESEÑAS
-- =====================================================================

-- El trigger trg_resena_valida exige que el lugar se haya visitado en ese itinerario.
-- Cada turista reseña un atractivo UNA sola vez (aunque lo visite en varios itinerarios),
-- para que nadie pueda inflar la calificación creando itinerarios repetidos.
CREATE PROCEDURE sp_registrar_resena(
  IN p_usuario_id INT, IN p_itinerario_id INT, IN p_atractivo_id INT,
  IN p_puntuacion TINYINT, IN p_comentario VARCHAR(500))
BEGIN
  CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);
  CALL sp_validar_atractivo(p_atractivo_id);
  IF p_puntuacion < 1 OR p_puntuacion > 5 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La puntuación debe ser de 1 a 5';
  END IF;
  IF EXISTS (SELECT 1 FROM tbl_resena r JOIN tbl_itinerario i ON i.id = r.itinerario_id
              WHERE i.usuario_id = p_usuario_id AND r.atractivo_id = p_atractivo_id) THEN
    SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya reseñaste este atractivo';
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
  SELECT r.id, r.puntuacion, r.comentario, r.fecha, u.nombre_completo AS autor, u.id AS autor_id
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

-- El turista borra SU propia reseña (404 si no existe o es de otra persona); el trigger recalcula
CREATE PROCEDURE sp_eliminar_mi_resena(IN p_usuario_id INT, IN p_resena_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_resena r JOIN tbl_itinerario i ON i.id = r.itinerario_id
                  WHERE r.id = p_resena_id AND i.usuario_id = p_usuario_id) THEN
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
 ('Barrio y mercado',   'Vida local, artesanía y comida'),    -- 5
 ('Calle y plaza',      'Calles incas, arcos y plazas para recorrer a pie');  -- 6

INSERT INTO tbl_zona (nombre, ciudad) VALUES
 ('Centro Histórico',      'Cusco'),      -- 1
 ('Valle Sagrado',         'Urubamba'),   -- 2
 ('Parque Arqueológico',   'Cusco');      -- 3

-- ---------------------------------------------------------------------
-- Atractivos (los 4 primeros son los del diseño original del grupo)
-- ---------------------------------------------------------------------
INSERT INTO tbl_atractivo (nombre, descripcion, direccion, latitud, longitud, precio_entrada, categoria_id, zona_id) VALUES
 ('Sacsayhuamán', 'Fortaleza ceremonial inca que domina la ciudad desde lo alto. Sus muros en zigzag tienen piedras de más de 100 toneladas encajadas sin argamasa. Cada 24 de junio se celebra aquí el Inti Raymi.', 'Carretera a Sacsayhuamán', -13.509800, -71.981800, 70.00, 1, 3),  -- 1
 ('Qorikancha', 'Fue el templo más importante del imperio, dedicado al Sol y cubierto de láminas de oro. Sobre sus muros los españoles construyeron el convento de Santo Domingo, y hoy se ven ambas épocas juntas.', 'Plazoleta Santo Domingo', -13.520100, -71.975300, 15.00, 2, 1),  -- 2
 ('Catedral del Cusco', 'Templo colonial levantado sobre el palacio del inca Wiracocha. Guarda más de 400 pinturas de la Escuela Cusqueña, entre ellas una Última Cena con cuy como plato principal.', 'Plaza de Armas', -13.516300, -71.978500, 25.00, 3, 1),  -- 3
 ('Pisac', 'Complejo arqueológico sobre el pueblo de Pisac, en el Valle Sagrado. Tiene andenes que bajan por la montaña, templos y el cementerio inca más grande conocido.', 'Pisac, Calca', -13.410000, -71.850000, 70.00, 1, 2),  -- 4
 ('Plaza de Armas', 'Corazón de la ciudad desde la época inca, cuando se llamaba Huacaypata. La rodean la Catedral, la Compañía de Jesús y portales con cafés y tiendas.', 'Plaza de Armas', -13.516700, -71.978800, 0.00, 5, 1),  -- 5
 ('Barrio de San Blas', 'Barrio de artesanos con calles empinadas, muros incas y casas blancas de puertas azules. Es ideal para comprar arte local y ver la ciudad desde arriba.', 'Cuesta de San Blas', -13.514600, -71.974900, 0.00, 5, 1),  -- 6
 ('Mercado de San Pedro', 'El mercado tradicional más grande del Cusco. Aquí se toman jugos de frutas, se prueban caldos y panes típicos y se compran tejidos a buen precio.', 'Calle Thupaq Amaru', -13.521800, -71.984300, 0.00, 5, 1),  -- 7
 ('Museo Inka', 'Funciona en la casona del Almirante y muestra cerámica, textiles, quipus y momias incas. En su patio, tejedoras de comunidades andinas trabajan en vivo.', 'Cuesta del Almirante 103', -13.515700, -71.977700, 10.00, 2, 1),  -- 8
 ('Cristo Blanco', 'Estatua de 8 metros en el cerro Pukamoqo, regalo de palestinos refugiados en 1945. Es el mirador con la vista más amplia de la ciudad, de día y de noche.', 'Cerro Pukamoqo', -13.509400, -71.977600, 0.00, 4, 3),  -- 9
 ('Qenqo', 'Adoratorio inca tallado en una gran roca, con canales en zigzag y una cueva con un altar. Se cree que allí se hacían ofrendas y se preparaba a los difuntos.', 'Carretera a Pisac km 4', -13.509800, -71.966700, 70.00, 1, 3),  -- 10
 ('Tambomachay', 'Conocido como el Baño del Inca. Sus fuentes de piedra siguen llevando agua de manantial después de 500 años, lo que muestra la ingeniería hidráulica inca.', 'Carretera a Pisac km 8', -13.482100, -71.965100, 70.00, 1, 3),  -- 11
 ('Ollantaytambo', 'Pueblo inca que todavía se habita con su trazado original. Su fortaleza tiene terrazas monumentales y el Templo del Sol, hecho con seis bloques de granito.', 'Ollantaytambo, Urubamba', -13.258800, -72.262900, 70.00, 1, 2),  -- 12
 ('Moray', 'Andenes circulares en forma de anfiteatro. Entre el nivel más alto y el más bajo cambia la temperatura, por eso se cree que fue un laboratorio agrícola inca.', 'Maras, Urubamba', -13.329700, -72.196300, 70.00, 1, 2),  -- 13
 ('Salineras de Maras', 'Más de 3 000 pozos de sal en la ladera del cerro, alimentados por un manantial salado. Las familias de la zona los trabajan desde antes de los incas.', 'Maras, Urubamba', -13.304700, -72.153900, 20.00, 1, 2),  -- 14
 ('Calle Hatun Rumiyoc', 'Calle peatonal con el muro del palacio del inca Roca. Allí está la famosa Piedra de los 12 Ángulos, ejemplo perfecto del encaje de piedras inca.', 'Calle Hatun Rumiyoc', -13.516900, -71.976400, 0.00, 6, 1),  -- 15
 ('Iglesia de la Compañía de Jesús', 'Templo jesuita del siglo XVII en la Plaza de Armas, considerado uno de los mejores ejemplos del barroco andino. Su fachada compite en belleza con la de la Catedral.', 'Plaza de Armas', -13.517300, -71.978000, 15.00, 3, 1),  -- 16
 ('Arco de Santa Clara', 'Arco de piedra de estilo neoclásico construido en el siglo XIX. Marca la entrada a la calle Santa Clara, camino al Mercado de San Pedro.', 'Calle Santa Clara', -13.519700, -71.982300, 0.00, 6, 1),  -- 17
 ('Arco de Santa Ana', 'Arco colonial en lo alto del barrio de Santa Ana, por donde entraban los viajeros que llegaban desde Lima. Desde aquí se ve todo el centro histórico.', 'Calle Arco Punku', -13.515100, -71.986800, 0.00, 6, 1),  -- 18
 ('Casa del Inca Garcilaso', 'Casona colonial donde nació el Inca Garcilaso de la Vega, el primer escritor mestizo del Perú. Hoy es el Museo Histórico Regional, con pinturas cusqueñas y piezas preincas.', 'Plaza Regocijo', -13.517900, -71.980600, 10.00, 2, 1),  -- 19
 ('Planetario Cusco', 'Muestra cómo los incas leían el cielo: las constelaciones oscuras de la Vía Láctea, como la llama y la serpiente. Tiene charlas y observación con telescopios de noche.', 'Carretera a Sacsayhuamán', -13.506500, -71.983000, 50.00, 2, 3),  -- 20
 ('Plaza San Francisco', 'Plaza con jardines y una fuente frente al templo y convento de San Francisco. Es un lugar tranquilo para descansar a pocas cuadras de la Plaza de Armas.', 'Plaza San Francisco', -13.519100, -71.981600, 0.00, 6, 1),  -- 21
 ('Museo de Arte Precolombino (MAP)', 'Museo con piezas de oro, plata y cerámica de culturas anteriores a los incas, como Nazca, Mochica y Chimú. Ocupa una casona colonial en la plazoleta Nazarenas.', 'Plazoleta Nazarenas 231', -13.515300, -71.977500, 30.00, 2, 1),  -- 22
 ('Calle Siete Culebras', 'Callejón angosto con muros incas que une la plazoleta Nazarenas con la calle Choquechaca. Su nombre viene de las serpientes talladas en una de sus portadas.', 'Calle Siete Culebras', -13.515700, -71.977000, 0.00, 6, 1),  -- 23
 ('Calle Siete Borreguitos', 'Calle de escalones en San Blas, llena de macetas con flores y casas blancas. Es uno de los rincones más fotografiados del barrio.', 'Calle Siete Borreguitos', -13.514000, -71.973700, 0.00, 6, 1),  -- 24
 ('Puka Pukara', 'Su nombre significa fortaleza roja, por el color de sus piedras al atardecer. Se cree que fue un puesto de control y descanso en el camino del inca hacia el Valle Sagrado.', 'Carretera a Pisac km 7', -13.483900, -71.962900, 70.00, 1, 3),  -- 25
 ('Acueducto de Sapantiana', 'Acueducto colonial de piedra levantado sobre canales incas, en lo alto de San Blas. Sus arcos y su caída de agua forman un rincón poco conocido por los turistas.', 'Calle Sapantiana', -13.513000, -71.973500, 0.00, 1, 1),  -- 26
 ('Templo de la Luna', 'Adoratorio inca tallado en roca, en las afueras de la ciudad. Tiene cuevas con altares y figuras talladas, y se cree que se usaba en ritos dedicados a la Luna.', 'Cerca de Qenqo', -13.502800, -71.960900, 0.00, 1, 3);  -- 27

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
 ('Lunes a Domingo', '08:30', '17:00', 14),
 ('Lunes a Sábado',  '09:00', '17:30', 16),
 ('Lunes a Domingo', '08:00', '17:00', 19),
 ('Lunes a Domingo', '18:00', '21:00', 20),
 ('Lunes a Domingo', '08:00', '22:00', 22),
 ('Lunes a Domingo', '07:00', '17:30', 25);

-- Hasta 5 fotos por atractivo; la primera es la portada
INSERT INTO tbl_foto (url_foto, descripcion, atractivo_id) VALUES
 ('img/sacsayhuaman.jpg',        'Muros principales',                1),
 ('img/sacsayhuaman-2.jpg',      'Muros en zigzag',                  1),
 ('img/sacsayhuaman-3.jpg',      'Explanada y terrazas',             1),
 ('img/sacsayhuaman-4.jpg',      'Portada de piedra',                1),
 ('img/sacsayhuaman-5.jpg',      'Vista general de la fortaleza',    1),
 ('img/qorikancha.jpg',          'Entrada al templo',                2),
 ('img/qorikancha-2.jpg',        'Fachada con muro inca',            2),
 ('img/qorikancha-3.jpg',        'Claustro del convento',            2),
 ('img/qorikancha-4.jpg',        'Jardines del templo',              2),
 ('img/qorikancha-5.jpg',        'Entrada al museo de sitio',        2),
 ('img/catedral.jpg',            'Fachada de la catedral',           3),
 ('img/catedral-2.jpg',          'La catedral desde la plaza',       3),
 ('img/pisac.jpg',               'Andenes de Pisac',                 4),
 ('img/plaza-armas.jpg',         'Vista de la plaza',                5),
 ('img/plaza-armas-2.jpg',       'Catedral y fuente',                5),
 ('img/plaza-armas-3.jpg',       'Fuente central',                   5),
 ('img/plaza-armas-4.jpg',       'La plaza de noche desde el aire',  5),
 ('img/plaza-armas-5.jpg',       'La plaza iluminada',               5),
 ('img/san-blas.jpg',            'Calle de San Blas',                6),
 ('img/san-blas-2.jpg',          'Plazoleta de San Blas',            6),
 ('img/san-blas-3.jpg',          'Templo y plaza al atardecer',      6),
 ('img/san-blas-4.jpg',          'Casas blancas del barrio',         6),
 ('img/san-blas-5.jpg',          'San Blas de noche',                6),
 ('img/san-pedro.jpg',           'Puestos del mercado',              7),
 ('img/san-pedro-2.jpg',         'Productos del mercado',            7),
 ('img/san-pedro-3.jpg',         'Entrada del mercado',              7),
 ('img/san-pedro-4.jpg',         'Fachada del mercado',              7),
 ('img/san-pedro-5.jpg',         'Templo de San Pedro',              7),
 ('img/museo-inka.jpg',          'Patio del museo',                  8),
 ('img/museo-inka-2.jpg',        'Fachada de la casona',             8),
 ('img/museo-inka-3.jpg',        'Patio con balcones',               8),
 ('img/cristo-blanco.jpg',       'Vista desde el mirador',           9),
 ('img/cristo-blanco-2.jpg',     'El Cristo y el paisaje',           9),
 ('img/cristo-blanco-3.jpg',     'El Cristo sobre la ciudad',        9),
 ('img/cristo-blanco-4.jpg',     'El Cristo iluminado de noche',     9),
 ('img/qenqo.jpg',               'Roca tallada del adoratorio',     10),
 ('img/qenqo-2.jpg',             'Vista general de Qenqo',          10),
 ('img/qenqo-3.jpg',             'Monolito de Qenqo',               10),
 ('img/qenqo-4.jpg',             'Pasaje entre las rocas',          10),
 ('img/qenqo-5.jpg',             'Cueva con el altar',              10),
 ('img/tambomachay.jpg',         'Fuentes de agua inca',            11),
 ('img/tambomachay-2.jpg',       'Fuente del Baño del Inca',        11),
 ('img/tambomachay-3.jpg',       'Muros y terrazas',                11),
 ('img/tambomachay-4.jpg',       'Hornacinas y fuente',             11),
 ('img/ollantaytambo.jpg',       'Terrazas de la fortaleza',        12),
 ('img/moray.jpg',               'Andenes circulares',              13),
 ('img/maras.jpg',               'Pozos de sal',                    14),
 ('img/hatun-rumiyoc.jpg',       'Muro inca de la calle',           15),
 ('img/hatun-rumiyoc-2.jpg',     'Piedra de los 12 Ángulos',        15),
 ('img/hatun-rumiyoc-3.jpg',     'La calle de noche',               15),
 ('img/hatun-rumiyoc-4.jpg',     'Muro del palacio de Inca Roca',   15),
 ('img/hatun-rumiyoc-5.jpg',     'Calle iluminada',                 15),
 ('img/compania-jesus.jpg',      'Fachada barroca',                 16),
 ('img/compania-jesus-2.jpg',    'El templo desde la plaza',        16),
 ('img/compania-jesus-3.jpg',    'Torres de la iglesia',            16),
 ('img/compania-jesus-4.jpg',    'La iglesia de noche',             16),
 ('img/compania-jesus-5.jpg',    'Retablo mayor',                   16),
 ('img/arco-santa-clara.jpg',    'El arco al atardecer',            17),
 ('img/arco-santa-clara-2.jpg',  'El arco de noche',                17),
 ('img/arco-santa-clara-3.jpg',  'Detalle del arco',                17),
 ('img/arco-santa-ana.jpg',      'Vista de la ciudad desde el arco',18),
 ('img/arco-santa-ana-2.jpg',    'Calle hacia el arco',             18),
 ('img/arco-santa-ana-3.jpg',    'El arco y la ciudad',             18),
 ('img/casa-garcilaso.jpg',      'Fachada de la casona',            19),
 ('img/planetario.jpg',          'Cúpula del planetario',           20),
 ('img/planetario-2.jpg',        'El cielo inca en la cúpula',      20),
 ('img/plaza-san-francisco.jpg', 'La fuente de noche',              21),
 ('img/plaza-san-francisco-2.jpg','Jardines de la plaza',           21),
 ('img/plaza-san-francisco-3.jpg','La plaza desde el aire',         21),
 ('img/plaza-san-francisco-4.jpg','Templo de San Francisco',        21),
 ('img/museo-precolombino.jpg',  'Sala del museo',                  22),
 ('img/siete-culebras.jpg',      'El callejón con muros incas',     23),
 ('img/siete-culebras-2.jpg',    'Muro inca del callejón',          23),
 ('img/siete-culebras-3.jpg',    'Letrero de la calle',             23),
 ('img/siete-borreguitos.jpg',   'Escalones con flores',            24),
 ('img/siete-borreguitos-2.jpg', 'Casas blancas y macetas',         24),
 ('img/siete-borreguitos-3.jpg', 'Subida por la calle',             24),
 ('img/puka-pukara.jpg',         'Puerta de la fortaleza',          25),
 ('img/puka-pukara-2.jpg',       'Vista aérea del recinto',         25),
 ('img/puka-pukara-3.jpg',       'Portada de piedra',               25),
 ('img/sapantiana.jpg',          'Arcos del acueducto',             26),
 ('img/sapantiana-2.jpg',        'Caída de agua',                   26),
 ('img/sapantiana-3.jpg',        'Camino al acueducto',             26),
 ('img/sapantiana-4.jpg',        'Canal de agua',                   26),
 ('img/templo-luna.jpg',         'Roca tallada del templo',         27);

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
 ('¿Dónde puedo comer comida típica barata?', 'En el Mercado de San Pedro: menús, jugos y caldos a precios económicos.', 'comida comer barato mercado tipica', 7),
 ('¿Dónde está la Piedra de los 12 Ángulos?', 'En la calle Hatun Rumiyoc, a dos cuadras de la Plaza de Armas subiendo hacia San Blas. Se puede ver gratis a cualquier hora.', 'piedra doce 12 angulos hatun rumiyoc', 15),
 ('¿Cuánto cuesta entrar a la Catedral?', 'La entrada general cuesta S/ 25 y también se puede ingresar con el Boleto Religioso, que incluye San Blas y el Museo de Arte Religioso.', 'catedral precio entrada boleto religioso', 3),
 ('¿Cuándo es el Inti Raymi?', 'Cada 24 de junio. Empieza en el Qorikancha, pasa por la Plaza de Armas y termina en Sacsayhuamán. Las entradas a la tribuna se compran con meses de anticipación.', 'inti raymi fiesta sol junio celebracion', 1),
 ('¿Cómo llego a Machu Picchu desde Cusco?', 'En tren desde Poroy u Ollantaytambo hasta Aguas Calientes, y luego en bus 30 minutos hasta la ciudadela. Compra la entrada y el tren con anticipación.', 'machu picchu tren aguas calientes llegar', NULL),
 ('¿Qué moneda se usa y dónde cambio dinero?', 'Se usa el sol peruano (S/). Hay casas de cambio en la calle Portal Comercio y Avenida El Sol; evita cambiar en la calle.', 'dinero moneda cambio soles dolares', NULL),
 ('¿Necesito un taxi para ir a Sacsayhuamán?', 'Se puede subir a pie desde la Plaza de Armas en unos 30 minutos por la calle Suecia. Para Qenqo, Puka Pukara y Tambomachay conviene un taxi o un tour.', 'taxi caminar subir sacsayhuaman llegar', 1),
 ('¿Qué incluye el boleto turístico parcial?', 'Hay tres circuitos parciales de S/ 70 (S/ 40 nacionales) que valen 1 o 2 días. El circuito I incluye Sacsayhuamán, Qenqo, Puka Pukara y Tambomachay.', 'boleto parcial circuito precio', NULL),
 ('¿Dónde veo la ciudad de noche?', 'En el mirador del Cristo Blanco o en la plazoleta de San Blas. La Plaza de Armas iluminada también es muy bonita.', 'noche mirador vista ciudad fotos', 9),
 ('¿Qué hago si me siento mal por la altura?', 'Descansa, toma agua y mate de coca. Si tienes dolor de cabeza fuerte o te falta el aire, acude a una clínica: el número de emergencias es 105 (policía) o 116 (bomberos).', 'emergencia salud doctor clinica mal', NULL),
 ('¿Qué comida típica debo probar?', 'El chiri uchu, el cuy al horno, el adobo cusqueño, el chicharrón y el pan chuta. De beber, chicha morada o mate de coca.', 'comida tipica platos probar cuy', NULL),
 ('¿Cuál es el horario del Planetario?', 'Las funciones son por la noche, desde las 18:00. Conviene reservar porque los grupos son pequeños.', 'planetario horario estrellas noche', 20),
 ('¿Dónde compro artesanía?', 'En el barrio de San Blas hay talleres de artistas, y en el Mercado de San Pedro y el Centro Artesanal Cusco los precios son más bajos.', 'artesania comprar recuerdos souvenir tejidos', 6);

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
--
--  Privilegio MÍNIMO: solo EXECUTE (ejecutar procedimientos).
--  Como la API únicamente hace CALL sp_..., no necesita leer ni escribir tablas directamente:
--  aunque alguien robe la contraseña del .env, no puede hacer SELECT, UPDATE, DELETE ni DROP;
--  solo puede usar los procedimientos, que ya validan las reglas de negocio y al dueño.
-- =====================================================================

CREATE USER IF NOT EXISTS 'cuscosmart_user'@'localhost' IDENTIFIED BY 'Cusco2026*';
CREATE USER IF NOT EXISTS 'cuscosmart_user'@'127.0.0.1' IDENTIFIED BY 'Cusco2026*';

-- Si el usuario ya existía, deja la clave igual a la del .env.example
ALTER USER 'cuscosmart_user'@'localhost' IDENTIFIED BY 'Cusco2026*';
ALTER USER 'cuscosmart_user'@'127.0.0.1' IDENTIFIED BY 'Cusco2026*';

-- Quita cualquier permiso anterior y deja solo EXECUTE sobre cuscosmart_db
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'cuscosmart_user'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'cuscosmart_user'@'127.0.0.1';
GRANT EXECUTE ON cuscosmart_db.* TO 'cuscosmart_user'@'localhost';
GRANT EXECUTE ON cuscosmart_db.* TO 'cuscosmart_user'@'127.0.0.1';
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

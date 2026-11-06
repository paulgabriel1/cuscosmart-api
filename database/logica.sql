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

-- Quitar un favorito también lo quita de los itinerarios (cascada); se recalculan su orden y totales.
CREATE PROCEDURE sp_quitar_favorito(IN p_usuario_id INT, IN p_favorito_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM tbl_atractivo_favorito WHERE id = p_favorito_id AND usuario_id = p_usuario_id) THEN
    SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Favorito no encontrado';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS tmp_itinerarios;
  CREATE TEMPORARY TABLE tmp_itinerarios AS
    SELECT DISTINCT itinerario_id AS id FROM tbl_detalle_itinerario WHERE atractivo_favorito_id = p_favorito_id;

  DELETE FROM tbl_atractivo_favorito WHERE id = p_favorito_id;

  CALL sp_recalcular_itinerarios();
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
  UPDATE tbl_detalle_itinerario SET visitado = 1 WHERE id = p_parada_id;
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

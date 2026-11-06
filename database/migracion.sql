-- =====================================================================
--  CuscoSmart IA · migracion.sql
--  Actualiza una base YA EXISTENTE sin borrar usuarios, viajes ni reseñas.
--  Se ejecuta con:  npm run db:migrar   (después vuelve a cargar logica.sql y usuario.sql)
--  Se puede ejecutar varias veces.
-- =====================================================================
USE cuscosmart_db;

-- Lugares que están en un viaje pero NO en "Favoritos"
ALTER TABLE tbl_atractivo_favorito
  ADD COLUMN IF NOT EXISTS es_favorito TINYINT(1) NOT NULL DEFAULT 1 AFTER usuario_id;

-- Fecha en que se marcó la visita (línea de tiempo del perfil)
ALTER TABLE tbl_detalle_itinerario
  ADD COLUMN IF NOT EXISTS fecha_visita DATETIME(6) NULL AFTER visitado;

-- Las visitas anteriores a esta versión no tenían fecha: se usa la del viaje
UPDATE tbl_detalle_itinerario d
  JOIN tbl_itinerario i ON i.id = d.itinerario_id
   SET d.fecha_visita = i.fecha_creacion
 WHERE d.visitado = 1 AND d.fecha_visita IS NULL;

-- Reseñas "huérfanas": su parada se quitó del viaje antes de esta versión (antes la reseña seguía
-- apareciendo). Se borran fila por fila para que el trigger recalcule la calificación.
DELETE r FROM tbl_resena r
 WHERE NOT EXISTS (SELECT 1 FROM tbl_detalle_itinerario d
                     JOIN tbl_atractivo_favorito f ON f.id = d.atractivo_favorito_id
                    WHERE d.itinerario_id = r.itinerario_id AND f.atractivo_id = r.atractivo_id);

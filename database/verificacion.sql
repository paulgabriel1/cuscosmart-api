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

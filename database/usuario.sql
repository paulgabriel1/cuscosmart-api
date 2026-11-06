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

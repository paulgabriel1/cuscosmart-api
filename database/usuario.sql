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

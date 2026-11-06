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
 ('img/museo-inka.jpg',   'Patio del museo',            8),
 ('img/cristo-blanco.jpg','Vista desde el mirador',     9),
 ('img/qenqo.jpg',        'Roca tallada del adoratorio',10),
 ('img/tambomachay.jpg',  'Fuentes de agua inca',       11),
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

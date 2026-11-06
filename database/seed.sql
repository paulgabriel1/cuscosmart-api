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

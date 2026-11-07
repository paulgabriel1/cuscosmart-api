// Genera postman/cuscosmart.collection.json (colección Postman v2.1 con pruebas automáticas).
// Uso: npm run postman     → luego en Postman: Import → postman/cuscosmart.collection.json → Run collection
// Requisito antes de correrla: npm run db:reset y reiniciar la API (la colección cambia datos y prueba el 429).
import fs from 'node:fs';

const TOKENS = { admin: '{{tokenAdmin}}', ana: '{{tokenAna}}', nuevo: '{{tokenNuevo}}', malo: '{{tokenFalso}}' };
// El token falso se arma en el pre-request de la colección: si estuviera escrito en la autenticación,
// Postman lo confunde con una contraseña real ("Unlock your vault") y el import falla.

// ---------- Ayudantes para escribir pruebas cortas ----------
const D = 'pm.response.json().data';
const M = 'pm.response.json().meta';
const t = (nombre, expr) => `pm.test(${JSON.stringify(nombre)}, () => { ${expr}; });`;
const eq = (nombre, actual, esperado) => t(nombre, `pm.expect(${actual}).to.eql(${JSON.stringify(esperado)})`);
const code = (c) => eq(`Código ${c}`, 'pm.response.json().error.code', c);
const guardar = (clave, expr) => t(`Guarda ${clave}`, `pm.collectionVariables.set('${clave}', ${expr})`);

function req(nombre, metodo, url, { auth = 'none', body, status, tests = [], pre = [] } = {}) {
  const exec = [`pm.test('Responde ${status}', () => pm.response.to.have.status(${status}));`];
  if (status < 300 && status !== 204) exec.push(eq('Formato ok:true', 'pm.response.json().ok', true));
  if (status >= 400) exec.push(eq('Formato ok:false', 'pm.response.json().ok', false));
  exec.push(...tests);
  const [ruta, query] = url.split('?');
  const item = {
    name: nombre,
    event: [{ listen: 'test', script: { type: 'text/javascript', exec } }],
    request: {
      method: metodo,
      header: [],
      url: {
        raw: `{{baseUrl}}${url}`,
        host: ['{{baseUrl}}'],
        path: ruta.split('/').filter(Boolean),
        ...(query && { query: query.split('&').map((kv) => ({ key: kv.split('=')[0], value: kv.split('=')[1] })) }),
      },
      auth: auth === 'none' ? { type: 'noauth' } : { type: 'bearer', bearer: [{ key: 'token', value: TOKENS[auth], type: 'string' }] },
    },
  };
  if (pre.length) item.event.push({ listen: 'prerequest', script: { type: 'text/javascript', exec: pre } });
  if (body !== undefined) {
    item.request.header.push({ key: 'Content-Type', value: 'application/json' });
    item.request.body = { mode: 'raw', raw: typeof body === 'string' ? body : JSON.stringify(body, null, 2), options: { raw: { language: 'json' } } };
  }
  return item;
}
const carpeta = (name, description, item) => ({ name, description, item });

// ---------- 00 Autenticación ----------
const auth = carpeta('00 Autenticación', 'Genera los tokens de admin, Ana (turista) y un usuario nuevo.', [
  req('GET /health', 'GET', '/health', { status: 200, tests: [eq('Base de datos arriba', `${D}.db`, 'up')] }),
  req('Login admin', 'POST', '/auth/login', {
    status: 200, body: { correo: 'admin@cuscosmart.pe', contrasena: 'Admin12345' },
    tests: [guardar('tokenAdmin', `${D}.token`), eq('Rol ADMIN', `${D}.usuario.rol`, 'ADMIN'),
      t('No devuelve la contraseña', `pm.expect('contrasena' in ${D}.usuario).to.eql(false)`)],
  }),
  req('Login Ana (correo en mayúsculas)', 'POST', '/auth/login', {
    status: 200, body: { correo: 'ANA@mail.com', contrasena: 'Turista123' },
    tests: [guardar('tokenAna', `${D}.token`), eq('Rol TURISTA', `${D}.usuario.rol`, 'TURISTA')],
  }),
  req('Registro de usuario nuevo', 'POST', '/auth/registro', {
    status: 201, body: '{\n  "nombre_completo": "Luis Mamani",\n  "correo": "{{correoNuevo}}",\n  "contrasena": "Cusco2026",\n  "telefono": "984123456"\n}',
    tests: [guardar('tokenNuevo', `${D}.token`), guardar('idNuevo', `${D}.usuario.id`), eq('Nace como TURISTA', `${D}.usuario.rol`, 'TURISTA')],
  }),
  req('Registro con correo repetido', 'POST', '/auth/registro', {
    status: 409, body: '{\n  "nombre_completo": "Otro",\n  "correo": "{{correoNuevo}}",\n  "contrasena": "Cusco2026"\n}', tests: [code('DUPLICATE')],
  }),
  req('Registro con datos inválidos', 'POST', '/auth/registro', {
    status: 400, body: { nombre_completo: 'L', correo: 'no-es-correo', contrasena: 'corta' },
    tests: [code('VALIDATION_ERROR'), t('Detalla los 3 campos', `pm.expect(pm.response.json().error.details.length).to.be.above(2)`)],
  }),
  req('Login con contraseña incorrecta', 'POST', '/auth/login', {
    status: 401, body: { correo: 'ana@mail.com', contrasena: 'incorrecta' }, tests: [code('INVALID_CREDENTIALS')],
  }),
  req('Login con correo inexistente (mismo mensaje)', 'POST', '/auth/login', {
    status: 401, body: { correo: 'nadie@mail.com', contrasena: 'incorrecta' }, tests: [code('INVALID_CREDENTIALS')],
  }),
  req('GET /auth/me', 'GET', '/auth/me', { auth: 'ana', status: 200, tests: [eq('Es Ana', `${D}.correo`, 'ana@mail.com')] }),
  req('GET /auth/me sin token', 'GET', '/auth/me', { status: 401, tests: [code('NO_TOKEN')] }),
  req('GET /auth/me con token inválido', 'GET', '/auth/me', { auth: 'malo', status: 401, tests: [code('INVALID_TOKEN')] }),
  req('GET /auth/me trae totales', 'GET', '/auth/me', {
    auth: 'ana', status: 200, tests: [t('Tiene favoritos, viajes y reseñas', `['favoritos','viajes','resenas'].forEach((k) => pm.expect(typeof ${D}[k]).to.eql('number'))`)],
  }),
  req('PUT /auth/me (editar perfil)', 'PUT', '/auth/me', {
    auth: 'ana', status: 200, body: { nombre_completo: 'Ana Quispe', telefono: '984123456' },
    tests: [eq('Guarda el teléfono', `${D}.telefono`, '984123456')],
  }),
  req('PUT /auth/me con nombre corto', 'PUT', '/auth/me', { auth: 'ana', status: 400, body: { nombre_completo: 'A' }, tests: [code('VALIDATION_ERROR')] }),
  req('GET /auth/config', 'GET', '/auth/config', { status: 200, tests: [t('Informa el ID de Google', `pm.expect('googleClientId' in ${D}).to.eql(true)`)] }),
  req('POST /auth/google sin credential', 'POST', '/auth/google', { status: 400, body: {}, tests: [code('VALIDATION_ERROR')] }),
]);

// ---------- 01 Catálogo ----------
const atractivoNuevo = { nombre: 'Mirador de San Cristóbal', descripcion: 'Vista del centro histórico.', latitud: -13.5128, longitud: -71.9822, precio_entrada: 0, categoria_id: 4, zona_id: 1 };
const catalogo = carpeta('01 Catálogo', 'Categorías, zonas y atractivos: leer es público, escribir es solo ADMIN.', [
  req('GET /categorias', 'GET', '/categorias', { status: 200, tests: [eq('6 categorías', `${D}.length`, 6)] }),
  req('GET /categorias/1', 'GET', '/categorias/1', { status: 200, tests: [eq('Sitio arqueológico', `${D}.nombre`, 'Sitio arqueológico')] }),
  req('GET /categorias/999', 'GET', '/categorias/999', { status: 404, tests: [code('NOT_FOUND')] }),
  req('POST /categorias sin token', 'POST', '/categorias', { status: 401, body: { nombre: 'Parque' }, tests: [code('NO_TOKEN')] }),
  req('POST /categorias como turista', 'POST', '/categorias', { auth: 'ana', status: 403, body: { nombre: 'Parque' }, tests: [code('FORBIDDEN')] }),
  req('POST /categorias (admin)', 'POST', '/categorias', {
    auth: 'admin', status: 201, body: { nombre: 'Parque natural', descripcion: 'Áreas verdes y lagunas' },
    tests: [guardar('idCategoria', `${D}.id`), eq('Guarda tildes', `${D}.descripcion`, 'Áreas verdes y lagunas')],
  }),
  req('POST /categorias repetida', 'POST', '/categorias', { auth: 'admin', status: 409, body: { nombre: 'Parque natural' }, tests: [code('DUPLICATE')] }),
  req('PUT /categorias/{{idCategoria}}', 'PUT', '/categorias/{{idCategoria}}', {
    auth: 'admin', status: 200, body: { nombre: 'Naturaleza', descripcion: null }, tests: [eq('Renombrada', `${D}.nombre`, 'Naturaleza')],
  }),
  req('DELETE /categorias/1 (en uso)', 'DELETE', '/categorias/1', { auth: 'admin', status: 409, tests: [code('IN_USE')] }),
  req('DELETE /categorias/{{idCategoria}}', 'DELETE', '/categorias/{{idCategoria}}', { auth: 'admin', status: 204 }),
  req('GET /zonas', 'GET', '/zonas', { status: 200, tests: [eq('3 zonas', `${D}.length`, 3)] }),
  req('POST /zonas (admin)', 'POST', '/zonas', { auth: 'admin', status: 201, body: { nombre: 'Sur del Cusco', ciudad: 'Cusco' }, tests: [guardar('idZona', `${D}.id`)] }),
  req('DELETE /zonas/{{idZona}}', 'DELETE', '/zonas/{{idZona}}', { auth: 'admin', status: 204 }),
  req('DELETE /zonas/{{idZona}} otra vez', 'DELETE', '/zonas/{{idZona}}', { auth: 'admin', status: 404, tests: [code('NOT_FOUND')] }),

  req('GET /atractivos', 'GET', '/atractivos', { status: 200, tests: [eq('Total 27', `${M}.total`, 27), eq('10 por página', `${D}.length`, 10), eq('3 páginas', `${M}.totalPages`, 3)] }),
  req('GET /atractivos?page=2&limit=5', 'GET', '/atractivos?page=2&limit=5', { status: 200, tests: [eq('5 en la página 2', `${D}.length`, 5)] }),
  req('GET /atractivos?categoria_id=4', 'GET', '/atractivos?categoria_id=4', {
    status: 200, tests: [t('Todos son miradores', `${D}.forEach((a) => pm.expect(a.categoria_id).to.eql(4))`)],
  }),
  req('GET /atractivos?buscar=sal', 'GET', '/atractivos?buscar=sal', { status: 200, tests: [eq('Encuentra las Salineras', `${D}[0].nombre`, 'Salineras de Maras')] }),
  req('GET /atractivos?buscar=plaza armas (por palabras)', 'GET', '/atractivos?buscar=plaza%20armas', { status: 200, tests: [eq('Encuentra la Plaza de Armas', `${D}[0].nombre`, 'Plaza de Armas')] }),
  req('GET /atractivos?buscar=sacsayhuaman (sin tilde)', 'GET', '/atractivos?buscar=sacsayhuaman', { status: 200, tests: [eq('Encuentra Sacsayhuamán', `${D}[0].nombre`, 'Sacsayhuamán')] }),
  req('GET /atractivos?buscar=sieterrrrr (sugiere)', 'GET', '/atractivos?buscar=sieterrrrr', {
    status: 200, tests: [eq('Sin resultados', `${M}.total`, 0), t('Sugiere las calles Siete…', `pm.expect(${M}.sugerencias.map((s) => s.nombre).join()).to.include('Siete')`)],
  }),
  req('GET /atractivos?page=1e308 (no rompe la API)', 'GET', '/atractivos?page=1e308', { status: 400, tests: [code('VALIDATION_ERROR')] }),
  req('GET /atractivos con filtros inválidos', 'GET', '/atractivos?limit=500&categoria_id=abc', { status: 400, tests: [code('VALIDATION_ERROR')] }),
  req('GET /atractivos/cercanos (Plaza, 0.5 km)', 'GET', '/atractivos/cercanos?lat=-13.5167&lng=-71.9788&radio_km=0.5', {
    status: 200, tests: [eq('El primero es la Plaza', `${D}[0].nombre`, 'Plaza de Armas'),
      t('Ordenados del más cercano al más lejano', `const d = ${D}.map((a) => a.distancia_km); pm.expect(d).to.eql([...d].sort((x, y) => x - y))`),
      t('Ninguno a más de 0.5 km', `${D}.forEach((a) => pm.expect(a.distancia_km <= 0.5).to.eql(true))`)],
  }),
  req('GET /atractivos/cercanos sin coordenadas', 'GET', '/atractivos/cercanos', { status: 400, tests: [code('VALIDATION_ERROR')] }),
  req('GET /atractivos/2 (con horarios y fotos)', 'GET', '/atractivos/2', {
    status: 200, tests: [eq('Qorikancha', `${D}.nombre`, 'Qorikancha'), eq('2 horarios', `${D}.horarios.length`, 2), eq('5 fotos', `${D}.fotos.length`, 5)],
  }),
  req('GET /atractivos/999', 'GET', '/atractivos/999', { status: 404, tests: [code('NOT_FOUND')] }),
  req('GET /atractivos/abc', 'GET', '/atractivos/abc', { status: 400, tests: [code('VALIDATION_ERROR')] }),
  req('POST /atractivos (admin)', 'POST', '/atractivos', {
    auth: 'admin', status: 201, body: atractivoNuevo,
    tests: [guardar('idAtractivo', `${D}.id`), eq('Calificación inicial 0', `${D}.calificacion`, 0)],
  }),
  req('POST /atractivos con categoría inexistente', 'POST', '/atractivos', {
    auth: 'admin', status: 400, body: { ...atractivoNuevo, categoria_id: 999 }, tests: [code('INVALID_REFERENCE')],
  }),
  req('POST /atractivos solo con latitud', 'POST', '/atractivos', {
    auth: 'admin', status: 400, body: { nombre: 'Prueba', latitud: -13.5, categoria_id: 1, zona_id: 1 }, tests: [code('VALIDATION_ERROR')],
  }),
  req('PUT /atractivos/{{idAtractivo}}', 'PUT', '/atractivos/{{idAtractivo}}', {
    auth: 'admin', status: 200, body: { ...atractivoNuevo, precio_entrada: 5 }, tests: [eq('Precio 5', `${D}.precio_entrada`, 5)],
  }),
  req('POST horario', 'POST', '/atractivos/{{idAtractivo}}/horarios', {
    auth: 'admin', status: 201, body: { dia_semana: 'Lunes a Domingo', hora_apertura: '06:00', hora_cierre: '19:00' }, tests: [guardar('idHorario', `${D}.id`)],
  }),
  req('POST horario con cierre antes de apertura', 'POST', '/atractivos/{{idAtractivo}}/horarios', {
    auth: 'admin', status: 422, body: { dia_semana: 'Lunes', hora_apertura: '18:00', hora_cierre: '08:00' }, tests: [code('BUSINESS_RULE')],
  }),
  req('POST foto con javascript:', 'POST', '/atractivos/{{idAtractivo}}/fotos', {
    auth: 'admin', status: 400, body: { url_foto: 'javascript:alert(1)' }, tests: [code('VALIDATION_ERROR')],
  }),
  req('POST foto', 'POST', '/atractivos/{{idAtractivo}}/fotos', {
    auth: 'admin', status: 201, body: { url_foto: 'img/san-cristobal.jpg', descripcion: 'Vista al atardecer' }, tests: [guardar('idFoto', `${D}.id`)],
  }),
  req('GET fotos', 'GET', '/atractivos/{{idAtractivo}}/fotos', { status: 200, tests: [eq('1 foto', `${D}.length`, 1)] }),
  req('DELETE foto', 'DELETE', '/atractivos/{{idAtractivo}}/fotos/{{idFoto}}', { auth: 'admin', status: 204 }),
  req('DELETE horario', 'DELETE', '/atractivos/{{idAtractivo}}/horarios/{{idHorario}}', { auth: 'admin', status: 204 }),
  req('DELETE horario otra vez', 'DELETE', '/atractivos/{{idAtractivo}}/horarios/{{idHorario}}', { auth: 'admin', status: 404, tests: [code('NOT_FOUND')] }),
  req('DELETE /atractivos/{{idAtractivo}}', 'DELETE', '/atractivos/{{idAtractivo}}', { auth: 'admin', status: 204 }),
]);

// ---------- 02 Favoritos ----------
const favoritos = carpeta('02 Favoritos', 'Cada turista ve y toca solo sus favoritos (el usuario sale del token).', [
  req('GET /favoritos (Ana)', 'GET', '/favoritos', { auth: 'ana', status: 200, tests: [eq('Ana tiene 4', `${D}.length`, 4)] }),
  req('GET /favoritos (usuario nuevo)', 'GET', '/favoritos', { auth: 'nuevo', status: 200, tests: [eq('Vacío', `${D}.length`, 0)] }),
  req('GET /favoritos sin token', 'GET', '/favoritos', { status: 401 }),
  req('POST favorito: Plaza de Armas', 'POST', '/favoritos', { auth: 'ana', status: 201, body: { atractivo_id: 5 }, tests: [guardar('favPlaza', `${D}.favorito_id`), eq('Es la Plaza', `${D}.nombre`, 'Plaza de Armas')] }),
  req('POST favorito: Qenqo', 'POST', '/favoritos', { auth: 'ana', status: 201, body: { atractivo_id: 10 }, tests: [guardar('favQenqo', `${D}.favorito_id`)] }),
  req('POST favorito repetido', 'POST', '/favoritos', { auth: 'ana', status: 409, body: { atractivo_id: 5 }, tests: [code('DUPLICATE')] }),
  req('POST favorito de atractivo inexistente', 'POST', '/favoritos', { auth: 'ana', status: 404, body: { atractivo_id: 999 }, tests: [code('NOT_FOUND')] }),
  req('POST favorito del usuario nuevo', 'POST', '/favoritos', { auth: 'nuevo', status: 201, body: { atractivo_id: 1 }, tests: [guardar('favNuevo', `${D}.favorito_id`)] }),
  req('DELETE favorito ajeno (nuevo borra uno de Ana)', 'DELETE', '/favoritos/{{favPlaza}}', { auth: 'nuevo', status: 404, tests: [code('NOT_FOUND')] }),
]);

// ---------- 03 Itinerarios ----------
const hotel = { latitud_inicio: -13.5175, longitud_inicio: -71.98 };
const itinerarios = carpeta('03 Itinerarios e IA', 'Paradas desde favoritos, orden por distancia (Haversine), visitas y reseñas verificadas.', [
  req('GET /itinerarios (Ana)', 'GET', '/itinerarios', { auth: 'ana', status: 200, tests: [eq('Ana tiene 1', `${D}.length`, 1)] }),
  req('GET /itinerarios/1 (viaje de ejemplo)', 'GET', '/itinerarios/1', {
    auth: 'ana', status: 200, tests: [eq('3 paradas', `${D}.paradas.length`, 3), eq('Ordenado por IA', `${D}.sugerido_ia`, true), eq('Primero la Catedral', `${D}.paradas[0].atractivo`, 'Catedral del Cusco')],
  }),
  req('POST /itinerarios', 'POST', '/itinerarios', {
    auth: 'ana', status: 201, body: { nombre: 'Tarde de ruinas', ...hotel },
    tests: [guardar('idIti', `${D}.id`), eq('Sin paradas', `${D}.paradas.length`, 0), eq('Costo 0', `${D}.costo_total`, 0)],
  }),
  req('POST /itinerarios sin nombre', 'POST', '/itinerarios', { auth: 'ana', status: 400, body: { ...hotel }, tests: [code('VALIDATION_ERROR')] }),
  req('POST /itinerarios con inicio fuera del Perú', 'POST', '/itinerarios', {
    auth: 'ana', status: 400, body: { nombre: 'Madrid', latitud_inicio: 40.4168, longitud_inicio: -3.7038 }, tests: [code('VALIDATION_ERROR')],
  }),
  req('POST /itinerarios solo con latitud', 'POST', '/itinerarios', { auth: 'ana', status: 400, body: { nombre: 'Prueba', latitud_inicio: -13.5 }, tests: [code('VALIDATION_ERROR')] }),
  req('Agregar parada Qenqo (1.5 h)', 'POST', '/itinerarios/{{idIti}}/paradas', {
    auth: 'ana', status: 201, body: '{\n  "favorito_id": {{favQenqo}},\n  "tiempo_estimado_horas": 1.5\n}',
    tests: [eq('Duración 1.5', `${D}.duracion_horas`, 1.5), eq('Costo 70 (precio de entrada)', `${D}.costo_total`, 70)],
  }),
  req('Agregar parada Plaza', 'POST', '/itinerarios/{{idIti}}/paradas', {
    auth: 'ana', status: 201, body: '{\n  "favorito_id": {{favPlaza}}\n}',
    tests: [eq('Duración 2.5 (1 h por defecto)', `${D}.duracion_horas`, 2.5), eq('Plaza al final (orden 2)', `${D}.paradas[1].atractivo`, 'Plaza de Armas')],
  }),
  req('Agregar parada repetida', 'POST', '/itinerarios/{{idIti}}/paradas', { auth: 'ana', status: 409, body: '{\n  "favorito_id": {{favPlaza}}\n}', tests: [code('DUPLICATE')] }),
  req('Ver itinerario ajeno', 'GET', '/itinerarios/{{idIti}}', { auth: 'nuevo', status: 404, tests: [code('NOT_FOUND')] }),
  req('Itinerario del nuevo sin punto de inicio', 'POST', '/itinerarios', { auth: 'nuevo', status: 201, body: { nombre: 'Sin rumbo' }, tests: [guardar('idItiNuevo', `${D}.id`)] }),
  req('Parada con favorito de otra persona (404: no es tuyo)', 'POST', '/itinerarios/{{idItiNuevo}}/paradas', {
    auth: 'nuevo', status: 404, body: '{\n  "favorito_id": {{favPlaza}}\n}', tests: [code('NOT_FOUND')],
  }),
  req('Ordenar sin paradas', 'POST', '/itinerarios/{{idItiNuevo}}/ordenar-ia', { auth: 'nuevo', status: 422, tests: [code('BUSINESS_RULE')] }),
  req('Parada propia en el itinerario del nuevo', 'POST', '/itinerarios/{{idItiNuevo}}/paradas', { auth: 'nuevo', status: 201, body: '{\n  "favorito_id": {{favNuevo}}\n}' }),
  req('Ordenar sin punto de inicio', 'POST', '/itinerarios/{{idItiNuevo}}/ordenar-ia', {
    auth: 'nuevo', status: 422, tests: [t('Pide el punto de inicio', `pm.expect(pm.response.json().error.message).to.include('punto de inicio')`)],
  }),
  req('Ordenar con IA', 'POST', '/itinerarios/{{idIti}}/ordenar-ia', {
    auth: 'ana', status: 200,
    tests: [eq('Marcado como sugerido por IA', `${D}.sugerido_ia`, true),
      eq('La Plaza (más cerca) pasa primero', `${D}.paradas[0].atractivo`, 'Plaza de Armas'),
      t('Distancias de menor a mayor', `const d = ${D}.paradas.map((p) => p.distancia_km); pm.expect(d).to.eql([...d].sort((x, y) => x - y))`),
      guardar('paradaPlaza', `${D}.paradas[0].parada_id`), guardar('paradaQenqo', `${D}.paradas[1].parada_id`)],
  }),
  req('Reseñar sin haber visitado (trigger)', 'POST', '/itinerarios/{{idIti}}/resenas', {
    auth: 'ana', status: 422, body: { atractivo_id: 5, puntuacion: 4 }, tests: [code('BUSINESS_RULE')],
  }),
  req('Marcar Plaza como visitada', 'PATCH', '/itinerarios/{{idIti}}/paradas/{{paradaPlaza}}/visitado', {
    auth: 'ana', status: 200, tests: [eq('Visitada', `${D}.paradas[0].visitado`, true)],
  }),
  req('Reseña con puntuación 6', 'POST', '/itinerarios/{{idIti}}/resenas', { auth: 'ana', status: 400, body: { atractivo_id: 5, puntuacion: 6 }, tests: [code('VALIDATION_ERROR')] }),
  req('Reseñar la Plaza', 'POST', '/itinerarios/{{idIti}}/resenas', {
    auth: 'ana', status: 201, body: { atractivo_id: 5, puntuacion: 4, comentario: 'Había música en la pileta' },
    tests: [eq('Calificación nueva 4', `${D}.nueva_calificacion`, 4), guardar('resenaPlaza', `${D}.id`)],
  }),
  req('Reseña repetida', 'POST', '/itinerarios/{{idIti}}/resenas', { auth: 'ana', status: 409, body: { atractivo_id: 5, puntuacion: 5 }, tests: [code('DUPLICATE')] }),
  req('GET reseñas públicas de la Plaza', 'GET', '/atractivos/5/resenas', {
    status: 200, tests: [eq('1 reseña', `${M}.total`, 1), eq('Autora Ana', `${D}[0].autor`, 'Ana Quispe')],
  }),
  req('Cambiar punto de inicio (deja de estar ordenado)', 'PUT', '/itinerarios/{{idIti}}', {
    auth: 'ana', status: 200, body: { nombre: 'Tarde de ruinas', latitud_inicio: -13.5098, longitud_inicio: -71.9667 },
    tests: [eq('sugerido_ia vuelve a false', `${D}.sugerido_ia`, false)],
  }),
  req('Quitar parada Qenqo (compacta el orden)', 'DELETE', '/itinerarios/{{idIti}}/paradas/{{paradaQenqo}}', {
    auth: 'ana', status: 200, tests: [eq('Queda 1 parada', `${D}.paradas.length`, 1), eq('Con orden 1', `${D}.paradas[0].orden`, 1), eq('Costo 0', `${D}.costo_total`, 0)],
  }),
  req('Agregar parada Catedral (favorito 3 de Ana)', 'POST', '/itinerarios/{{idIti}}/paradas', {
    auth: 'ana', status: 201, body: { favorito_id: 3 }, tests: [guardar('paradaCatedral', `${D}.paradas[1].parada_id`)],
  }),
  req('Marcar Catedral visitada', 'PATCH', '/itinerarios/{{idIti}}/paradas/{{paradaCatedral}}/visitado', { auth: 'ana', status: 200 }),
  req('Reseñar otra vez la Catedral en otro viaje (anti inflado)', 'POST', '/itinerarios/{{idIti}}/resenas', {
    auth: 'ana', status: 409, body: { atractivo_id: 3, puntuacion: 5 },
    tests: [code('DUPLICATE'), t('Una reseña por turista', `pm.expect(pm.response.json().error.message).to.eql('Ya reseñaste este atractivo')`)],
  }),
  req('Quitar el favorito Plaza (el viaje no cambia)', 'DELETE', '/favoritos/{{favPlaza}}', { auth: 'ana', status: 204 }),
  req('La Plaza ya no está en favoritos', 'GET', '/favoritos', {
    auth: 'ana', status: 200, tests: [t('Sin la Plaza', `pm.expect(${D}.map((f) => f.atractivo_id)).to.not.include(5)`)],
  }),
  req('Pero sigue como parada del viaje', 'GET', '/itinerarios/{{idIti}}', {
    auth: 'ana', status: 200,
    tests: [eq('Siguen 2 paradas', `${D}.paradas.length`, 2), eq('La Plaza sigue primera', `${D}.paradas[0].atractivo`, 'Plaza de Armas'),
      t('Distancia del inicio en todas (aunque no esté ordenado)', `pm.expect(${D}.paradas.every((p) => p.distancia_km != null)).to.eql(true)`)],
  }),
  req('Agregar Pisac sin guardarlo en favoritos (atractivo_id)', 'POST', '/itinerarios/{{idIti}}/paradas', {
    auth: 'ana', status: 201, body: { atractivo_id: 4 },
    tests: [eq('3 paradas', `${D}.paradas.length`, 3), eq('Pisac al final', `${D}.paradas[2].atractivo`, 'Pisac'), eq('No es favorito', `${D}.paradas[2].es_favorito`, false),
      guardar('paradaPisac', `${D}.paradas[2].parada_id`)],
  }),
  req('Pisac NO aparece en favoritos', 'GET', '/favoritos', {
    auth: 'ana', status: 200, tests: [t('Sin Pisac', `pm.expect(${D}.map((f) => f.atractivo_id)).to.not.include(4)`)],
  }),
  req('Agregar Pisac repetido', 'POST', '/itinerarios/{{idIti}}/paradas', { auth: 'ana', status: 409, body: { atractivo_id: 4 }, tests: [code('DUPLICATE')] }),
  req('Parada con favorito_id y atractivo_id a la vez', 'POST', '/itinerarios/{{idIti}}/paradas', { auth: 'ana', status: 400, body: { favorito_id: 3, atractivo_id: 4 }, tests: [code('VALIDATION_ERROR')] }),
  req('Parada de atractivo inexistente', 'POST', '/itinerarios/{{idIti}}/paradas', { auth: 'ana', status: 404, body: { atractivo_id: 999 }, tests: [code('NOT_FOUND')] }),
  req('Mi recorrido (checklist del perfil)', 'GET', '/itinerarios/recorrido', {
    auth: 'ana', status: 200,
    tests: [t('Primero lo visitado', `const v = ${D}.map((p) => p.visitado); pm.expect(v).to.eql([...v].sort((x, y) => y - x))`),
      t('Visitadas con fecha', `pm.expect(${D}.filter((p) => p.visitado).every((p) => p.fecha_visita)).to.eql(true)`)],
  }),
  req('Desmarcar la Plaza ya reseñada', 'DELETE', '/itinerarios/{{idIti}}/paradas/{{paradaPlaza}}/visitado', { auth: 'ana', status: 422, tests: [code('BUSINESS_RULE')] }),
  req('Borrar reseña ajena como turista', 'DELETE', '/resenas/{{resenaPlaza}}/propia', { auth: 'nuevo', status: 404, tests: [code('NOT_FOUND')] }),
  req('Ana borra su reseña de la Plaza', 'DELETE', '/resenas/{{resenaPlaza}}/propia', { auth: 'ana', status: 204 }),
  req('La reseña ya no aparece', 'GET', '/atractivos/5/resenas', { status: 200, tests: [eq('0 reseñas', `${M}.total`, 0)] }),
  req('Ahora sí se puede desmarcar la Plaza', 'DELETE', '/itinerarios/{{idIti}}/paradas/{{paradaPlaza}}/visitado', {
    auth: 'ana', status: 200, tests: [eq('No visitada', `${D}.paradas[0].visitado`, false)],
  }),
  req('Quitar Pisac', 'DELETE', '/itinerarios/{{idIti}}/paradas/{{paradaPisac}}', { auth: 'ana', status: 200, tests: [eq('Quedan 2', `${D}.paradas.length`, 2)] }),
  // ---- Marcar visitado sin abrir un viaje (desde Favoritos / Mapa / ficha) y reseñar ----
  req('Marcar Moray como visitado (sin viaje)', 'POST', '/itinerarios/visitar', {
    auth: 'ana', status: 200, body: { atractivo_id: 13 },
    tests: [guardar('itiVisitas', `${D}.itinerario_id`), guardar('paradaMoray', `${D}.parada_id`)],
  }),
  req('Se creó "Lugares visitados" con Moray visitado', 'GET', '/itinerarios/{{itiVisitas}}', {
    auth: 'ana', status: 200, tests: [eq('Nombre', `${D}.nombre`, 'Lugares visitados'), eq('Moray visitado', `${D}.paradas[0].visitado`, true), eq('No es favorito', `${D}.paradas[0].es_favorito`, false)],
  }),
  req('Marcar Moray otra vez (misma parada)', 'POST', '/itinerarios/visitar', {
    auth: 'ana', status: 200, body: { atractivo_id: 13 }, tests: [t('Misma parada', `pm.expect(${D}.parada_id).to.eql(Number(pm.collectionVariables.get('paradaMoray')))`)],
  }),
  req('Reseñar Moray tras marcarlo visitado', 'POST', '/itinerarios/{{itiVisitas}}/resenas', {
    auth: 'ana', status: 201, body: { atractivo_id: 13, puntuacion: 5, comentario: 'Los andenes circulares son increíbles' }, tests: [eq('Calificación 5', `${D}.nueva_calificacion`, 5)],
  }),
  req('Marcar visitado un lugar inexistente', 'POST', '/itinerarios/visitar', { auth: 'ana', status: 404, body: { atractivo_id: 999 }, tests: [code('NOT_FOUND')] }),
  req('Marcar visitado sin token', 'POST', '/itinerarios/visitar', { status: 401, body: { atractivo_id: 13 } }),
  // ---- "Armar un viaje" con todos mis favoritos ----
  req('Nuevo viaje para mis favoritos', 'POST', '/itinerarios', { auth: 'ana', status: 201, body: { nombre: 'Ruta de favoritos', ...hotel }, tests: [guardar('itiFavs', `${D}.id`)] }),
  req('Agregar todos mis favoritos', 'POST', '/itinerarios/{{itiFavs}}/favoritos', {
    auth: 'ana', status: 200,
    tests: [t('Tiene paradas', `pm.expect(${D}.paradas.length).to.be.above(0)`), eq('Ordenado por IA', `${D}.sugerido_ia`, true),
      t('De la más cercana a la más lejana', `const d = ${D}.paradas.map((p) => Number(p.distancia_km)); pm.expect(d).to.eql([...d].sort((x, y) => x - y))`)],
  }),
  req('Agregar favoritos otra vez (ya están todos)', 'POST', '/itinerarios/{{itiFavs}}/favoritos', { auth: 'ana', status: 422, tests: [code('BUSINESS_RULE')] }),
  req('Agregar favoritos a viaje ajeno', 'POST', '/itinerarios/{{itiFavs}}/favoritos', { auth: 'nuevo', status: 404, tests: [code('NOT_FOUND')] }),
  req('DELETE viaje de favoritos', 'DELETE', '/itinerarios/{{itiFavs}}', { auth: 'ana', status: 204 }),
  req('DELETE "Lugares visitados"', 'DELETE', '/itinerarios/{{itiVisitas}}', { auth: 'ana', status: 204 }),
  req('DELETE /itinerarios/{{idIti}}', 'DELETE', '/itinerarios/{{idIti}}', { auth: 'ana', status: 204 }),
  req('La calificación de la Plaza se recalcula', 'GET', '/atractivos/5', { status: 200, tests: [eq('Vuelve a 0', `${D}.calificacion`, 0)] }),
]);

// ---------- 04 Asistente ----------
const asistente = carpeta('04 Asistente y preguntas frecuentes', 'Búsqueda FULLTEXT; si no hay respuesta, sugiere preguntas.', [
  req('Preguntar por el boleto', 'POST', '/asistente/preguntar', {
    status: 200, body: { pregunta: '¿Cuánto cuesta el boleto turístico?' },
    tests: [eq('Encontrada', `${D}.encontrada`, true), t('Habla del precio', `pm.expect(${D}.respuesta).to.include('S/ 130')`)],
  }),
  req('Pregunta sin respuesta', 'POST', '/asistente/preguntar', {
    status: 200, body: { pregunta: 'xyzzy plutón' }, tests: [eq('No encontrada', `${D}.encontrada`, false), eq('3 sugerencias', `${D}.sugerencias.length`, 3)],
  }),
  req('Pregunta muy corta', 'POST', '/asistente/preguntar', { status: 400, body: { pregunta: 'a' }, tests: [code('VALIDATION_ERROR')] }),
  req('GET /preguntas-frecuentes', 'GET', '/preguntas-frecuentes', { status: 200, tests: [eq('20 preguntas', `${D}.length`, 20)] }),
  req('POST pregunta como turista', 'POST', '/preguntas-frecuentes', { auth: 'ana', status: 403, body: { pregunta: '¿Hay wifi?', respuesta: 'No' } }),
  req('POST pregunta (admin)', 'POST', '/preguntas-frecuentes', {
    auth: 'admin', status: 201, body: { pregunta: '¿Hay wifi en Moray?', respuesta: 'No, lleva datos móviles.', palabras_clave: 'wifi internet señal', atractivo_id: 13 },
    tests: [guardar('idPregunta', `${D}.id`)],
  }),
  req('El asistente ya la responde', 'POST', '/asistente/preguntar', {
    status: 200, body: { pregunta: 'hay wifi o internet en moray' }, tests: [t('Responde la nueva', `pm.expect(${D}.respuesta).to.include('datos móviles')`)],
  }),
  req('PUT pregunta con atractivo inexistente', 'PUT', '/preguntas-frecuentes/{{idPregunta}}', {
    auth: 'admin', status: 404, body: { pregunta: '¿Hay wifi en Moray?', respuesta: 'No.', atractivo_id: 999 }, tests: [code('NOT_FOUND')],
  }),
  req('DELETE pregunta', 'DELETE', '/preguntas-frecuentes/{{idPregunta}}', { auth: 'admin', status: 204 }),
  req('DELETE pregunta otra vez', 'DELETE', '/preguntas-frecuentes/{{idPregunta}}', { auth: 'admin', status: 404 }),
]);

// ---------- 05 Administración ----------
const admin = carpeta('05 Administración', 'Usuarios y moderación de reseñas (solo ADMIN).', [
  req('GET /usuarios', 'GET', '/usuarios', { auth: 'admin', status: 200, tests: [eq('3 usuarios', `${M}.total`, 3)] }),
  req('GET /usuarios?buscar=ana', 'GET', '/usuarios?buscar=ana', { auth: 'admin', status: 200, tests: [eq('Encuentra a Ana', `${D}[0].correo`, 'ana@mail.com')] }),
  req('GET /usuarios como turista', 'GET', '/usuarios', { auth: 'ana', status: 403, tests: [code('FORBIDDEN')] }),
  req('PATCH rol inválido', 'PATCH', '/usuarios/{{idNuevo}}/rol', { auth: 'admin', status: 400, body: { rol: 'JEFE' }, tests: [code('VALIDATION_ERROR')] }),
  req('PATCH rol del nuevo a ADMIN', 'PATCH', '/usuarios/{{idNuevo}}/rol', { auth: 'admin', status: 200, body: { rol: 'ADMIN' }, tests: [eq('Ahora ADMIN', `${D}.rol`, 'ADMIN')] }),
  req('El admin no se quita su propio rol', 'PATCH', '/usuarios/1/rol', { auth: 'admin', status: 422, body: { rol: 'TURISTA' }, tests: [code('BUSINESS_RULE')] }),
  req('El admin no se elimina a sí mismo', 'DELETE', '/usuarios/1', { auth: 'admin', status: 422, tests: [code('BUSINESS_RULE')] }),
  req('Moderar reseña como turista', 'DELETE', '/resenas/1', { auth: 'ana', status: 403 }),
  req('Moderar (borrar) reseña de la Catedral', 'DELETE', '/resenas/1', { auth: 'admin', status: 204 }),
  req('La Catedral recalcula su calificación', 'GET', '/atractivos/3', { status: 200, tests: [eq('Vuelve a 0', `${D}.calificacion`, 0)] }),
  req('DELETE /resenas/999', 'DELETE', '/resenas/999', { auth: 'admin', status: 404 }),
  req('DELETE usuario nuevo', 'DELETE', '/usuarios/{{idNuevo}}', { auth: 'admin', status: 204 }),
  req('DELETE usuario nuevo otra vez', 'DELETE', '/usuarios/{{idNuevo}}', { auth: 'admin', status: 404 }),
  req('El token de una cuenta eliminada deja de servir', 'GET', '/auth/me', { auth: 'nuevo', status: 401, tests: [code('INVALID_TOKEN')] }),
]);

// ---------- 06 Seguridad ----------
const rafaga = [
  '// Agota el límite (10 intentos fallidos / 15 min por IP y correo) con un correo de prueba: así no bloquea a los usuarios reales',
  "const url = pm.collectionVariables.get('baseUrl') + '/auth/login';",
  'for (let i = 0; i < 10; i++) {',
  "  pm.sendRequest({ url, method: 'POST', header: { 'Content-Type': 'application/json' },",
  "    body: { mode: 'raw', raw: JSON.stringify({ correo: 'fuerza.bruta@prueba.pe', contrasena: 'mala' }) } }, () => {});",
  '}',
];
const seguridad = carpeta('06 Seguridad', 'Errores generales y límite de intentos. El 429 solo bloquea el correo de prueba fuerza.bruta@prueba.pe por 15 minutos.', [
  req('JSON mal formado', 'POST', '/auth/login', { status: 400, body: '{"correo": ', tests: [code('INVALID_JSON')] }),
  req('Ruta inexistente', 'GET', '/no-existe', { status: 404, tests: [code('NOT_FOUND')] }),
  req('Login tras muchos intentos (429)', 'POST', '/auth/login', {
    status: 429, body: { correo: 'fuerza.bruta@prueba.pe', contrasena: 'mala' }, pre: rafaga, tests: [code('TOO_MANY_REQUESTS')],
  }),
]);

// Correo único por ejecución para el usuario nuevo
const preColeccion = [
  "if (!pm.collectionVariables.get('correoNuevo')) {",
  "  pm.collectionVariables.set('correoNuevo', 'luis' + Date.now() + '@mail.com');",
  '}',
  "pm.collectionVariables.set('tokenFalso', ['token', 'invalido', 'de', 'prueba'].join('.'));",
];

const coleccion = {
  info: {
    name: 'CuscoSmart IA API',
    description: 'Pruebas automáticas de la API. Antes de ejecutarla: npm run db:reset y reinicia la API (npm run dev).',
    schema: 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
  },
  event: [{ listen: 'prerequest', script: { type: 'text/javascript', exec: preColeccion } }],
  variable: [
    { key: 'baseUrl', value: 'http://localhost:3000/api/v1' },
    ...['tokenAdmin', 'tokenAna', 'tokenNuevo', 'tokenFalso', 'correoNuevo', 'idNuevo', 'idCategoria', 'idZona', 'idAtractivo', 'idHorario', 'idFoto',
      'favPlaza', 'favQenqo', 'favNuevo', 'idIti', 'idItiNuevo', 'paradaPlaza', 'paradaQenqo', 'paradaCatedral', 'idPregunta'].map((key) => ({ key, value: '' })),
  ],
  item: [auth, catalogo, favoritos, itinerarios, asistente, admin, seguridad],
};

fs.mkdirSync('postman', { recursive: true });
fs.writeFileSync('postman/cuscosmart.collection.json', JSON.stringify(coleccion, null, 2));
const total = coleccion.item.reduce((s, c) => s + c.item.length, 0);
console.log(`✅ postman/cuscosmart.collection.json: ${coleccion.item.length} carpetas, ${total} peticiones`);

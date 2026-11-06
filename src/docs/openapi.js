// Especificación OpenAPI 3 de la API (se ve en http://localhost:3000/api/v1/docs)

// ---------- Ayudantes ----------
const ref = (n) => ({ $ref: `#/components/schemas/${n}` });
const resp = (...codigos) => Object.fromEntries(codigos.map((c) => [c, { $ref: `#/components/responses/E${c}` }]));
const ok = (description, status = 200) => ({ [status]: { description, content: { 'application/json': { schema: ref('Ok') } } } });
const lista = (description) => ({ 200: { description, content: { 'application/json': { schema: ref('OkPaginado') } } } });
const borrado = { 204: { description: 'Eliminado (sin contenido)' } };
const cuerpo = (schema, example) => ({ required: true, content: { 'application/json': { schema: ref(schema), example } } });
const pid = (name = 'id', description = 'Identificador') => ({ name, in: 'path', required: true, schema: { type: 'integer', minimum: 1 }, description });
const q = (name, description, schema = { type: 'string' }) => ({ name, in: 'query', required: false, description, schema });
const pag = [q('page', 'Página (desde 1)', { type: 'integer', default: 1 }), q('limit', 'Por página (máx. 50)', { type: 'integer', default: 10 })];
const publico = { security: [] };
const ADMIN = 'Requiere token de **ADMIN**.';
const TOKEN = 'Requiere token (cualquier rol). Solo ve y modifica lo suyo: el usuario sale del token.';

// CRUD simple de catálogo (categorías y zonas)
function crudCatalogo(tag, schema, ejemplo) {
  return {
    [`/${tag.toLowerCase()}`]: {
      get: { tags: [tag], summary: `Listar ${tag.toLowerCase()}`, ...publico, responses: ok('Lista con el conteo de atractivos') },
      post: { tags: [tag], summary: 'Crear', description: ADMIN, requestBody: cuerpo(schema, ejemplo), responses: { ...ok('Creada', 201), ...resp(400, 401, 403, 409) } },
    },
    [`/${tag.toLowerCase()}/{id}`]: {
      parameters: [pid()],
      get: { tags: [tag], summary: 'Ver una', ...publico, responses: { ...ok('Detalle'), ...resp(400, 404) } },
      put: { tags: [tag], summary: 'Editar', description: ADMIN, requestBody: cuerpo(schema, ejemplo), responses: { ...ok('Actualizada'), ...resp(400, 401, 403, 404, 409) } },
      delete: { tags: [tag], summary: 'Eliminar', description: `${ADMIN} 409 IN_USE si tiene atractivos.`, responses: { ...borrado, ...resp(401, 403, 404, 409) } },
    },
  };
}

const paths = {
  '/health': { get: { tags: ['Sistema'], summary: 'Estado de la API y de la base de datos', ...publico, responses: ok('API y base arriba') } },

  // ---------- Autenticación ----------
  '/auth/registro': {
    post: {
      tags: ['Autenticación'], summary: 'Registrar turista', description: 'Devuelve el token. Límite: 20 intentos cada 15 minutos.', ...publico,
      requestBody: cuerpo('Registro', { nombre_completo: 'Luis Mamani', correo: 'luis@mail.com', contrasena: 'Cusco2026', telefono: '984123456' }),
      responses: { ...ok('Registrado', 201), ...resp(400, 409, 429) },
    },
  },
  '/auth/login': {
    post: {
      tags: ['Autenticación'], summary: 'Iniciar sesión', description: 'Copia `data.token` y pégalo en **Authorize**.', ...publico,
      requestBody: cuerpo('Login', { correo: 'ana@mail.com', contrasena: 'Turista123' }),
      responses: { ...ok('Token y usuario'), ...resp(400, 401, 429) },
    },
  },
  '/auth/me': { get: { tags: ['Autenticación'], summary: 'Mi perfil', responses: { ...ok('Usuario del token'), ...resp(401) } } },

  // ---------- Catálogo ----------
  ...crudCatalogo('Categorias', 'Categoria', { nombre: 'Mirador', descripcion: 'Vistas panorámicas' }),
  ...crudCatalogo('Zonas', 'Zona', { nombre: 'Valle Sagrado', ciudad: 'Urubamba' }),

  '/atractivos': {
    get: {
      tags: ['Atractivos'], summary: 'Listar con filtros y paginación', ...publico,
      parameters: [q('categoria_id', 'Filtrar por categoría', { type: 'integer' }), q('zona_id', 'Filtrar por zona', { type: 'integer' }), q('buscar', 'Texto en nombre o descripción'), ...pag],
      responses: { ...lista('Página de atractivos'), ...resp(400) },
    },
    post: {
      tags: ['Atractivos'], summary: 'Crear', description: `${ADMIN} La calificación no se envía: la calculan los triggers.`,
      requestBody: cuerpo('Atractivo', { nombre: 'Mirador de San Cristóbal', latitud: -13.5128, longitud: -71.9822, precio_entrada: 0, categoria_id: 4, zona_id: 1 }),
      responses: { ...ok('Creado con horarios y fotos vacíos', 201), ...resp(400, 401, 403) },
    },
  },
  '/atractivos/cercanos': {
    get: {
      tags: ['Atractivos'], summary: 'Atractivos cerca de un punto (Haversine)', ...publico,
      parameters: [q('lat', 'Latitud', { type: 'number', example: -13.5167 }), q('lng', 'Longitud', { type: 'number', example: -71.9788 }),
        q('radio_km', 'Radio en km (por defecto 2)', { type: 'number' }), q('limit', 'Máximo de resultados', { type: 'integer' })],
      responses: { ...ok('Del más cercano al más lejano, con distancia_km'), ...resp(400) },
    },
  },
  '/atractivos/{id}': {
    parameters: [pid()],
    get: { tags: ['Atractivos'], summary: 'Detalle con horarios y fotos', ...publico, responses: { ...ok('Detalle'), ...resp(400, 404) } },
    put: { tags: ['Atractivos'], summary: 'Editar', description: ADMIN, requestBody: cuerpo('Atractivo'), responses: { ...ok('Actualizado'), ...resp(400, 401, 403, 404) } },
    delete: { tags: ['Atractivos'], summary: 'Eliminar', description: `${ADMIN} Borra en cascada horarios, fotos, favoritos, paradas y reseñas, y recalcula los itinerarios afectados.`, responses: { ...borrado, ...resp(401, 403, 404) } },
  },
  '/atractivos/{id}/horarios': {
    parameters: [pid()],
    get: { tags: ['Atractivos'], summary: 'Horarios', ...publico, responses: { ...ok('Lista'), ...resp(404) } },
    post: { tags: ['Atractivos'], summary: 'Agregar horario', description: `${ADMIN} 422 si el cierre no es posterior a la apertura.`, requestBody: cuerpo('Horario', { dia_semana: 'Lunes a Domingo', hora_apertura: '07:00', hora_cierre: '17:30' }), responses: { ...ok('Creado', 201), ...resp(400, 401, 403, 404, 422) } },
  },
  '/atractivos/{id}/horarios/{horarioId}': {
    parameters: [pid(), pid('horarioId')],
    delete: { tags: ['Atractivos'], summary: 'Eliminar horario', description: ADMIN, responses: { ...borrado, ...resp(401, 403, 404) } },
  },
  '/atractivos/{id}/fotos': {
    parameters: [pid()],
    get: { tags: ['Atractivos'], summary: 'Fotos', ...publico, responses: { ...ok('Lista'), ...resp(404) } },
    post: { tags: ['Atractivos'], summary: 'Agregar foto', description: ADMIN, requestBody: cuerpo('Foto', { url_foto: 'img/moray.jpg', descripcion: 'Andenes circulares' }), responses: { ...ok('Creada', 201), ...resp(400, 401, 403, 404) } },
  },
  '/atractivos/{id}/fotos/{fotoId}': {
    parameters: [pid(), pid('fotoId')],
    delete: { tags: ['Atractivos'], summary: 'Eliminar foto', description: ADMIN, responses: { ...borrado, ...resp(401, 403, 404) } },
  },
  '/atractivos/{id}/resenas': {
    parameters: [pid()],
    get: { tags: ['Reseñas'], summary: 'Reseñas públicas de un atractivo', ...publico, parameters: pag, responses: { ...lista('Página de reseñas con autor'), ...resp(404) } },
  },

  // ---------- Favoritos ----------
  '/favoritos': {
    get: { tags: ['Favoritos'], summary: 'Mis favoritos', description: TOKEN, responses: { ...ok('Lista'), ...resp(401) } },
    post: { tags: ['Favoritos'], summary: 'Guardar favorito', description: TOKEN, requestBody: cuerpo('FavoritoInput', { atractivo_id: 5 }), responses: { ...ok('Guardado', 201), ...resp(400, 401, 404, 409) } },
  },
  '/favoritos/{id}': {
    parameters: [pid('id', 'favorito_id')],
    delete: { tags: ['Favoritos'], summary: 'Quitar favorito', description: `${TOKEN} También lo quita de tus itinerarios.`, responses: { ...borrado, ...resp(401, 404) } },
  },

  // ---------- Itinerarios ----------
  '/itinerarios': {
    get: { tags: ['Itinerarios'], summary: 'Mis itinerarios', description: TOKEN, responses: { ...ok('Lista con paradas y visitadas'), ...resp(401) } },
    post: { tags: ['Itinerarios'], summary: 'Crear itinerario', description: `${TOKEN} El punto de inicio (ej. el hotel) es opcional, pero se necesita para ordenar con IA.`, requestBody: cuerpo('Itinerario', { nombre: 'Mi primer día', latitud_inicio: -13.5175, longitud_inicio: -71.98 }), responses: { ...ok('Creado', 201), ...resp(400, 401) } },
  },
  '/itinerarios/{id}': {
    parameters: [pid()],
    get: { tags: ['Itinerarios'], summary: 'Ver con paradas en orden', description: `${TOKEN} 404 si no es tuyo.`, responses: { ...ok('Itinerario'), ...resp(401, 404) } },
    put: { tags: ['Itinerarios'], summary: 'Editar nombre o punto de inicio', description: `${TOKEN} Si cambia el punto, sugerido_ia vuelve a false.`, requestBody: cuerpo('Itinerario'), responses: { ...ok('Actualizado'), ...resp(400, 401, 404) } },
    delete: { tags: ['Itinerarios'], summary: 'Eliminar', description: `${TOKEN} Sus reseñas se borran y las calificaciones se recalculan.`, responses: { ...borrado, ...resp(401, 404) } },
  },
  '/itinerarios/{id}/paradas': {
    parameters: [pid()],
    post: {
      tags: ['Itinerarios'], summary: 'Agregar parada desde un favorito', description: `${TOKEN} Va al final; el costo se copia del precio de entrada. 422 si el favorito no es tuyo; 409 si ya está.`,
      requestBody: cuerpo('ParadaInput', { favorito_id: 1, tiempo_estimado_horas: 1.5 }), responses: { ...ok('Itinerario actualizado', 201), ...resp(400, 401, 404, 409, 422) },
    },
  },
  '/itinerarios/{id}/paradas/{paradaId}': {
    parameters: [pid(), pid('paradaId')],
    delete: { tags: ['Itinerarios'], summary: 'Quitar parada', description: `${TOKEN} El orden se compacta (1,2,4 → 1,2,3).`, responses: { ...ok('Itinerario actualizado'), ...resp(401, 404) } },
  },
  '/itinerarios/{id}/paradas/{paradaId}/visitado': {
    parameters: [pid(), pid('paradaId')],
    patch: { tags: ['Itinerarios'], summary: 'Marcar parada como visitada', description: `${TOKEN} Necesario antes de reseñar.`, responses: { ...ok('Itinerario actualizado'), ...resp(401, 404) } },
  },
  '/itinerarios/{id}/ordenar-ia': {
    parameters: [pid()],
    post: {
      tags: ['Itinerarios'], summary: 'Ordenar la ruta con IA', description: `${TOKEN} Ordena las paradas de la más cercana a la más lejana desde el punto de inicio (Haversine) y marca sugerido_ia. 422 sin punto de inicio o sin paradas.`,
      responses: { ...ok('Itinerario ordenado con distancia_km'), ...resp(401, 404, 422) },
    },
  },
  '/itinerarios/{id}/resenas': {
    parameters: [pid()],
    post: {
      tags: ['Reseñas'], summary: 'Reseñar un lugar visitado', description: `${TOKEN} El trigger exige que la parada esté visitada (422). Una reseña por lugar y viaje (409).`,
      requestBody: cuerpo('ResenaInput', { atractivo_id: 3, puntuacion: 5, comentario: 'Impresionante' }), responses: { ...ok('Creada con la nueva calificación', 201), ...resp(400, 401, 404, 409, 422) },
    },
  },

  // ---------- Asistente ----------
  '/asistente/preguntar': {
    post: {
      tags: ['Asistente'], summary: 'Preguntar al asistente', description: 'Busca la respuesta preparada más parecida (FULLTEXT). Si no hay, sugiere preguntas. Límite: 20 por minuto.', ...publico,
      requestBody: cuerpo('Pregunta', { pregunta: '¿Cuánto cuesta el boleto turístico?' }), responses: { ...ok('Respuesta o sugerencias'), ...resp(400, 429) },
    },
  },
  '/preguntas-frecuentes': {
    get: { tags: ['Asistente'], summary: 'Listar preguntas frecuentes', ...publico, responses: ok('Lista') },
    post: { tags: ['Asistente'], summary: 'Crear pregunta', description: ADMIN, requestBody: cuerpo('PreguntaFrecuente', { pregunta: '¿Hay wifi en Moray?', respuesta: 'No, lleva datos móviles.', palabras_clave: 'wifi internet', atractivo_id: 13 }), responses: { ...ok('Creada', 201), ...resp(400, 401, 403, 404) } },
  },
  '/preguntas-frecuentes/{id}': {
    parameters: [pid()],
    put: { tags: ['Asistente'], summary: 'Editar pregunta', description: ADMIN, requestBody: cuerpo('PreguntaFrecuente'), responses: { ...ok('Actualizada'), ...resp(400, 401, 403, 404) } },
    delete: { tags: ['Asistente'], summary: 'Eliminar pregunta', description: ADMIN, responses: { ...borrado, ...resp(401, 403, 404) } },
  },

  // ---------- Administración ----------
  '/resenas/{id}': {
    parameters: [pid()],
    delete: { tags: ['Reseñas'], summary: 'Moderar (borrar) una reseña', description: `${ADMIN} El trigger recalcula la calificación.`, responses: { ...borrado, ...resp(401, 403, 404) } },
  },
  '/usuarios': {
    get: { tags: ['Usuarios'], summary: 'Listar usuarios', description: ADMIN, parameters: [q('buscar', 'Nombre o correo'), ...pag], responses: { ...lista('Página de usuarios'), ...resp(401, 403) } },
  },
  '/usuarios/{id}/rol': {
    parameters: [pid()],
    patch: { tags: ['Usuarios'], summary: 'Cambiar rol', description: `${ADMIN} No puedes quitarte tu propio rol (422).`, requestBody: cuerpo('Rol', { rol: 'ADMIN' }), responses: { ...ok('Usuario actualizado'), ...resp(400, 401, 403, 404, 422) } },
  },
  '/usuarios/{id}': {
    parameters: [pid()],
    delete: { tags: ['Usuarios'], summary: 'Eliminar usuario', description: `${ADMIN} No puedes eliminarte a ti mismo (422).`, responses: { ...borrado, ...resp(401, 403, 404, 422) } },
  },
};

// ---------- Esquemas (reflejan las validaciones zod de src/schemas) ----------
const txt = (extra = {}) => ({ type: 'string', ...extra });
const num = (extra = {}) => ({ type: 'number', ...extra });
const ent = (extra = {}) => ({ type: 'integer', minimum: 1, ...extra });
const obj = (properties, required) => ({ type: 'object', properties, ...(required && { required }) });

const schemas = {
  Ok: obj({ ok: { type: 'boolean', example: true }, data: {} }),
  OkPaginado: obj({ ok: { type: 'boolean' }, data: { type: 'array', items: { type: 'object' } }, meta: obj({ page: ent(), limit: ent(), total: { type: 'integer' }, totalPages: { type: 'integer' } }) }),
  Error: obj({ ok: { type: 'boolean', example: false }, error: obj({ code: txt(), message: txt(), details: { type: 'array', items: obj({ campo: txt(), mensaje: txt() }) } }) }),
  Registro: obj({ nombre_completo: txt({ minLength: 3, maxLength: 150 }), correo: txt({ format: 'email' }), contrasena: txt({ minLength: 8, maxLength: 72, description: 'Con letras y números' }), telefono: txt({ maxLength: 20 }) }, ['nombre_completo', 'correo', 'contrasena']),
  Login: obj({ correo: txt({ format: 'email' }), contrasena: txt() }, ['correo', 'contrasena']),
  Categoria: obj({ nombre: txt({ minLength: 2, maxLength: 100 }), descripcion: txt({ maxLength: 255, nullable: true }) }, ['nombre']),
  Zona: obj({ nombre: txt({ minLength: 2, maxLength: 100 }), ciudad: txt({ maxLength: 100, nullable: true }) }, ['nombre']),
  Atractivo: obj({
    nombre: txt({ minLength: 2, maxLength: 200 }), descripcion: txt({ nullable: true }), direccion: txt({ maxLength: 255, nullable: true }),
    latitud: num({ minimum: -90, maximum: 90, nullable: true }), longitud: num({ minimum: -180, maximum: 180, nullable: true }),
    precio_entrada: num({ minimum: 0, default: 0 }), categoria_id: ent(), zona_id: ent(),
  }, ['nombre', 'categoria_id', 'zona_id']),
  Horario: obj({ dia_semana: txt({ minLength: 3, maxLength: 50 }), hora_apertura: txt({ example: '07:00' }), hora_cierre: txt({ example: '17:30' }) }, ['dia_semana', 'hora_apertura', 'hora_cierre']),
  Foto: obj({ url_foto: txt({ maxLength: 500 }), descripcion: txt({ maxLength: 255, nullable: true }) }, ['url_foto']),
  FavoritoInput: obj({ atractivo_id: ent() }, ['atractivo_id']),
  Itinerario: obj({ nombre: txt({ minLength: 3, maxLength: 200 }), latitud_inicio: num({ nullable: true }), longitud_inicio: num({ nullable: true }) }, ['nombre']),
  ParadaInput: obj({ favorito_id: ent(), tiempo_estimado_horas: num({ exclusiveMinimum: 0, maximum: 24, default: 1 }) }, ['favorito_id']),
  ResenaInput: obj({ atractivo_id: ent(), puntuacion: { type: 'integer', minimum: 1, maximum: 5 }, comentario: txt({ maxLength: 500, nullable: true }) }, ['atractivo_id', 'puntuacion']),
  Pregunta: obj({ pregunta: txt({ minLength: 3, maxLength: 255 }) }, ['pregunta']),
  PreguntaFrecuente: obj({ pregunta: txt({ minLength: 5, maxLength: 255 }), respuesta: txt({ minLength: 3 }), palabras_clave: txt({ maxLength: 255, nullable: true }), atractivo_id: ent({ nullable: true }) }, ['pregunta', 'respuesta']),
  Rol: obj({ rol: txt({ enum: ['TURISTA', 'ADMIN'] }) }, ['rol']),
};

const error = (description, code, message) => ({
  description, content: { 'application/json': { schema: ref('Error'), example: { ok: false, error: { code, message } } } },
});
const responses = {
  E400: error('Datos inválidos', 'VALIDATION_ERROR', 'Datos inválidos'),
  E401: error('Falta el token o no es válido', 'NO_TOKEN', 'Token requerido'),
  E403: error('Tu rol no tiene permiso', 'FORBIDDEN', 'No tienes permiso para esta acción'),
  E404: error('No existe o no es tuyo', 'NOT_FOUND', 'Itinerario no encontrado'),
  E409: error('Repetido o en uso', 'DUPLICATE', 'Ese atractivo ya está en tus favoritos'),
  E422: error('Regla de negocio (procedimiento o trigger)', 'BUSINESS_RULE', 'Solo puedes reseñar atractivos que visitaste en tu itinerario'),
  E429: error('Demasiados intentos', 'TOO_MANY_REQUESTS', 'Demasiados intentos. Espera 15 minutos.'),
};

export const openapi = {
  openapi: '3.0.3',
  info: {
    title: 'CuscoSmart IA API',
    version: '1.0.0',
    description: [
      'Guía turística inteligente del Cusco: atractivos, favoritos, itinerarios ordenados por IA (Haversine), reseñas verificadas y asistente.',
      '',
      '**Cómo probar:** `POST /auth/login` → *Try it out* → *Execute* → copia `data.token` → botón **Authorize** → pégalo.',
      '',
      'Usuarios de prueba: `admin@cuscosmart.pe` / `Admin12345` (ADMIN) · `ana@mail.com` / `Turista123` (TURISTA).',
    ].join('\n'),
  },
  servers: [{ url: '/api/v1' }],
  security: [{ bearerAuth: [] }],
  tags: ['Sistema', 'Autenticación', 'Categorias', 'Zonas', 'Atractivos', 'Favoritos', 'Itinerarios', 'Reseñas', 'Asistente', 'Usuarios'].map((name) => ({ name })),
  paths,
  components: {
    securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } },
    schemas,
    responses,
  },
};

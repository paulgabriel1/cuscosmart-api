# CuscoSmart IA — API REST

Guía turística inteligente del Cusco: atractivos con mapa, favoritos, **itinerarios ordenados por IA** (de la parada más cercana a la más lejana), **reseñas verificadas** (solo de lugares visitados) y un **asistente** de preguntas frecuentes.

> Proyecto del curso **Fullstack Developer Software, SENATI**.
> Integrantes: **Gabriel Paul Alata Condori** · **Rodrigo Ccahuana Mayo** · **Elizabeth Flores Vargas**

## Tabla de contenido
1. [Tecnologías](#tecnologías)
2. [Arquitectura](#arquitectura)
3. [Estructura](#estructura)
4. [Instalación](#instalación)
5. [Usuarios de prueba](#usuarios-de-prueba)
6. [Endpoints](#endpoints)
7. [Reglas de negocio](#reglas-de-negocio)
8. [Formato de respuestas y códigos](#formato-de-respuestas-y-códigos)
9. [Pruebas](#pruebas)
10. [Seguridad](#seguridad)
11. [Guía de construcción por fases](#guía-de-construcción-por-fases)

## Tecnologías

| Capa | Herramienta |
| --- | --- |
| Base de datos | MySQL / MariaDB (XAMPP): 11 tablas, **51 procedimientos almacenados**, 4 triggers, 1 función |
| Servidor | Node.js (ESM) + Express 5 |
| Conexión | mysql2 (pool de conexiones, solo `CALL`) |
| Validación | zod |
| Autenticación | JWT (jsonwebtoken) + bcryptjs |
| Seguridad | helmet, cors, express-rate-limit |
| Documentación | Swagger (OpenAPI 3) en `/api/v1/docs` |
| Pruebas | Colección Postman con 368 pruebas automáticas |

## Arquitectura

```
Cliente (React / Postman)
      │  HTTP + JSON
      ▼
 routes ──▶ middlewares ──▶ controllers ──▶ services ──▶ utils/sp.js ──▶ MySQL
 (URL)      (token, rol,     (HTTP ↔ datos)   (qué          (CALL sp_...)   (tablas, triggers,
            validación)                        procedimiento)                procedimientos)
      ▲
      └── errorHandler traduce cualquier error a { ok:false, error:{ code, message } }
```

**Regla de oro:** la API **no escribe SQL**. Toda la lógica de datos y de negocio vive en la base de datos (`database/logica.sql`), y la API solo la llama con `CALL`. Así cada regla se cumple igual desde la API, desde phpMyAdmin o desde otra app, y el usuario de la base de la API no puede borrar tablas.

## Estructura

```
cuscosmart-api/
├── database/
│   ├── schema.sql          # base y 11 tablas (diagrama ER)
│   ├── logica.sql          # función Haversine, 4 triggers, 51 procedimientos
│   ├── seed.sql            # datos de prueba (14 atractivos reales del Cusco)
│   ├── usuario.sql         # usuario cuscosmart_user con permisos mínimos
│   ├── verificacion.sql    # conteo de objetos creados
│   └── cuscosmart_todo.sql # todo unido (se genera con npm run db:armar)
├── docs/guia/              # guía de construcción paso a paso (fases 0 a 9)
├── postman/                # colección de pruebas (se genera con npm run postman)
├── scripts/                # crearAdmin, armarSql, generarPostman, probarColeccion, verificarDocs
└── src/
    ├── config/             # env.js (valida el .env) · db.js (pool)
    ├── middlewares/        # auth · validate · errorHandler · limitadores
    ├── utils/              # AppError · sp.js (única puerta a MySQL)
    ├── schemas/            # validaciones zod por módulo
    ├── services/           # llaman a los procedimientos
    ├── controllers/        # arman las respuestas HTTP
    ├── routes/             # URL → middlewares → controlador
    ├── docs/openapi.js     # Swagger
    ├── app.js · server.js
```

## Instalación

> Instalación completa en otra PC, paso a paso: **[docs/INSTALACION.md](docs/INSTALACION.md)**.

Resumen (con MySQL de XAMPP encendido):

```powershell
git clone https://github.com/paulgabriel1/cuscosmart-api.git
cd cuscosmart-api
npm install
Copy-Item .env.example .env      # y pon un JWT_SECRET propio
npm run db:reset                 # crea cuscosmart_db, el usuario y los datos de prueba
npm run dev                      # http://localhost:3000/api/v1
```

| Script | Qué hace |
| --- | --- |
| `npm run dev` | Inicia la API y la reinicia al guardar cambios |
| `npm run db:reset` | Arma `cuscosmart_todo.sql` y **recrea** la base con los datos de prueba |
| `npm run db:armar` | Solo arma `cuscosmart_todo.sql` desde los archivos de `database/` |
| `npm run admin -- "Nombre" correo "Clave123"` | Crea un administrador |
| `npm run postman` | Regenera la colección de Postman |
| `npm run test:api` | Ejecuta la colección desde la consola (como el Runner de Postman) |
| `npm run docs:verificar` | Comprueba que Swagger documenta todas las rutas |

## Usuarios de prueba

| Rol | Correo | Contraseña |
| --- | --- | --- |
| ADMIN | admin@cuscosmart.pe | Admin12345 |
| TURISTA | ana@mail.com | Turista123 |

Ana ya tiene 4 favoritos y un itinerario de ejemplo ("Mi primer día en Cusco"), ordenado por la IA y con una reseña.

## Endpoints

Prefijo: `/api/v1` · Documentación interactiva: **http://localhost:3000/api/v1/docs**

| Método y ruta | Descripción | Acceso |
| --- | --- | --- |
| `GET /health` | Estado de la API y de la base | Público |
| `POST /auth/registro` · `POST /auth/login` | Registro de turista y login (JWT) | Público, 20 intentos / 15 min |
| `GET /auth/me` | Mi perfil | Token |
| `GET /categorias` · `GET /categorias/:id` | Categorías | Público |
| `POST · PUT · DELETE /categorias` | Gestionar categorías | ADMIN |
| `GET /zonas` · `GET /zonas/:id` | Zonas | Público |
| `POST · PUT · DELETE /zonas` | Gestionar zonas | ADMIN |
| `GET /atractivos?categoria_id&zona_id&buscar&page&limit` | Lista filtrada y paginada | Público |
| `GET /atractivos/cercanos?lat&lng&radio_km&limit` | Cercanos a un punto (Haversine) | Público |
| `GET /atractivos/:id` | Detalle con horarios y fotos | Público |
| `POST · PUT · DELETE /atractivos` | Gestionar atractivos | ADMIN |
| `GET · POST /atractivos/:id/horarios` · `DELETE …/horarios/:horarioId` | Horarios | Leer público, cambiar ADMIN |
| `GET · POST /atractivos/:id/fotos` · `DELETE …/fotos/:fotoId` | Fotos | Leer público, cambiar ADMIN |
| `GET /atractivos/:id/resenas` | Reseñas públicas | Público |
| `GET · POST /favoritos` · `DELETE /favoritos/:id` | Mis favoritos | Token (lo propio) |
| `GET · POST /itinerarios` · `GET · PUT · DELETE /itinerarios/:id` | Mis itinerarios | Token (lo propio) |
| `POST /itinerarios/:id/paradas` · `DELETE …/paradas/:paradaId` | Paradas desde favoritos | Token (lo propio) |
| `PATCH /itinerarios/:id/paradas/:paradaId/visitado` | Marcar visitado | Token (lo propio) |
| `POST /itinerarios/:id/ordenar-ia` | **Ordenar la ruta con IA** | Token (lo propio) |
| `POST /itinerarios/:id/resenas` | Reseñar un lugar visitado | Token (lo propio) |
| `POST /asistente/preguntar` | Preguntar al asistente | Público, 20 / min |
| `GET /preguntas-frecuentes` | Preguntas del asistente | Público |
| `POST · PUT · DELETE /preguntas-frecuentes` | Gestionar preguntas | ADMIN |
| `DELETE /resenas/:id` | Moderar reseñas | ADMIN |
| `GET /usuarios` · `PATCH /usuarios/:id/rol` · `DELETE /usuarios/:id` | Usuarios | ADMIN |

## Reglas de negocio

Cada regla dice **dónde vive**, porque es ahí donde se cambia.

| N.º | Regla | Dónde se cumple |
| --- | --- | --- |
| RN-01 | El correo es único | `sp_registrar_usuario` (45409) + `UNIQUE uq_usuario_correo` |
| RN-02 | La contraseña se guarda cifrada (bcrypt); mínimo 8 caracteres, con letras y números | `auth.service.js` + `auth.schema.js` |
| RN-03 | Solo el ADMIN gestiona el catálogo, las preguntas frecuentes y los usuarios, y modera reseñas | `authorize('ADMIN')` en las rutas |
| RN-04 | No se elimina una categoría o zona que tiene atractivos | FK `RESTRICT` → 409 IN_USE |
| RN-05 | No hay dos categorías ni dos zonas con el mismo nombre | `sp_crear_*` / `sp_actualizar_*` (45409) |
| RN-06 | La hora de cierre es posterior a la de apertura | `sp_agregar_horario` (45000) |
| RN-07 | Un atractivo está una sola vez en los favoritos de cada turista | `sp_agregar_favorito` (45409) + `UNIQUE uq_favorito` |
| RN-08 | Cada turista solo ve y modifica sus favoritos, itinerarios y reseñas; lo ajeno responde 404 | `usuario_id` del token + `sp_validar_itinerario` |
| RN-09 | Las paradas se arman solo con favoritos del dueño del itinerario (uno ajeno responde 404) | `sp_agregar_parada` + trigger `trg_detalle_valida` |
| RN-10 | Un lugar aparece una sola vez por itinerario | `sp_agregar_parada` (45409) + `UNIQUE uq_detalle_favorito` |
| RN-11 | La duración, el costo, el orden y el costo de cada parada los calcula el sistema; al quitar paradas (también en cascada) el orden se vuelve a numerar | `sp_agregar_parada`, `sp_actualizar_totales`, `sp_quitar_parada`, `sp_recalcular_itinerarios` |
| RN-12 | Ordenar con IA exige un punto de inicio (dentro del Perú) y al menos una parada. El orden va por distancia (Haversine), y las paradas sin coordenadas van al final. Al agregar paradas, cambiar el punto o mover un atractivo, `sugerido_ia` vuelve a 0 | `sp_ordenar_itinerario_ia`, `fn_distancia_km`, `sp_actualizar_itinerario`, `sp_actualizar_atractivo` |
| RN-13 | Solo se reseña un lugar que está en el itinerario y fue **visitado** (anti reseñas falsas) | Trigger `trg_resena_valida` |
| RN-14 | **Una reseña por turista y atractivo** (aunque lo visite en varios viajes, para que nadie infle la calificación); puntuación de 1 a 5 | `sp_registrar_resena` + `UNIQUE uq_resena` + `CHECK` + zod |
| RN-15 | La calificación es el promedio de las reseñas y se recalcula sola, también al borrar itinerarios o usuarios | Triggers `trg_resena_calificacion_*` + `sp_eliminar_itinerario` / `sp_eliminar_usuario` |
| RN-16 | El ADMIN no puede quitarse su propio rol ni eliminar su cuenta. Si a alguien le quitan el rol o la cuenta, pierde el acceso al instante (el rol se lee de la base en cada petición) | `admin.service.js`, `authenticate` |
| RN-17 | Límites: 300 peticiones por minuto en toda la API, 20 logins o registros cada 15 min y 20 preguntas al asistente por minuto | `limitadores.js` |
| RN-18 | El asistente no guarda lo que preguntan los usuarios | `sp_buscar_pregunta_frecuente` (solo lectura) |

### ¿Cómo se cambia una regla de negocio?

1. Ubica la regla en la tabla de arriba y busca en qué **capa** vive: base de datos, servicio, esquema o ruta.
2. Cambia **solo esa capa**:
   - **Procedimiento o trigger:** edita `database/logica.sql` → `npm run db:reset`, o ejecuta solo `logica.sql` en phpMyAdmin si no quieres perder datos.
   - **Validación de formato:** edita el esquema zod en `src/schemas/`.
   - **Permiso:** cambia `authorize(...)` en `src/routes/`.
3. Actualiza la **prueba de Postman** de esa regla en `scripts/generarPostman.js` → `npm run postman` → `npm run test:api`.
4. Actualiza esta tabla, Swagger (`src/docs/openapi.js`) y haz el commit (`feat:` o `fix:`).

## Formato de respuestas y códigos

```json
{ "ok": true,  "data": { }, "meta": { "page": 1, "limit": 10, "total": 14, "totalPages": 2 } }
{ "ok": false, "error": { "code": "BUSINESS_RULE", "message": "Solo puedes reseñar atractivos que visitaste en tu itinerario" } }
```

| HTTP | `code` | Cuándo |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` · `INVALID_JSON` · `INVALID_REFERENCE` | Datos mal formados o una referencia a algo inexistente |
| 401 | `NO_TOKEN` · `INVALID_TOKEN` · `INVALID_CREDENTIALS` | Sin sesión o con credenciales incorrectas |
| 403 | `FORBIDDEN` | El rol no tiene permiso |
| 404 | `NOT_FOUND` | No existe, o no es tuyo (SQLSTATE `45404`) |
| 409 | `DUPLICATE` · `IN_USE` | Repetido (SQLSTATE `45409`) o en uso (FK) |
| 422 | `BUSINESS_RULE` | Regla de negocio (SQLSTATE `45000` de procedimientos y triggers) |
| 429 | `TOO_MANY_REQUESTS` | Demasiados intentos |
| 503 | `DB_UNAVAILABLE` | MySQL apagado |

## Pruebas

```powershell
npm run db:reset     # datos limpios
npm run dev          # (en otra ventana) API recién iniciada
npm run test:api     # 121 peticiones · 368 pruebas
```

En Postman: **Import** → `postman/cuscosmart.collection.json` → **Run collection**. La colección ya trae la URL y guarda sola los tokens y los IDs.

> La última prueba agota el límite de intentos (429). Antes de volver a correrla, reinicia la API y ejecuta `npm run db:reset`.

## Seguridad

- **Mínimo privilegio:** la API usa `cuscosmart_user`, que **solo tiene permiso EXECUTE**. No puede leer, modificar ni borrar tablas directamente: únicamente ejecutar los procedimientos, que ya validan las reglas y al dueño.
- **Modo estricto de MySQL:** si un valor no cabe en su columna, se rechaza en vez de recortarse en silencio.
- **JWT con algoritmo fijo (HS256)**, y el rol se comprueba contra la base en cada petición.
- **Sin SQL armado con texto:** todo pasa por `CALL` con parámetros `?`, así que no hay inyección SQL.
- **Contraseñas:** se guardan con bcrypt. El login responde igual (y tarda lo mismo) si falla el correo o la contraseña.
- **Lo ajeno se trata como inexistente:** un itinerario de otra persona responde 404, no 403.
- **Configuración y cabeceras:** helmet, CORS limitado al front, límite de tamaño del JSON, `.env` validado al arrancar y fuera de Git, y Swagger desactivado con `NODE_ENV=production`.
- **Entradas acotadas:** las coordenadas deben estar dentro del Perú, la paginación tiene topes, los comodines `%` y `_` de las búsquedas se escapan y las fotos solo aceptan `https://` o `img/`.

**Revisión:** los agentes *tester* y *security* del equipo revisaron la API. No hubo hallazgos críticos ni altos, y las mejoras sugeridas están aplicadas.

**Aceptado a propósito:** el registro avisa "Ese correo ya está registrado", porque es más claro para el usuario. Esto permite saber si un correo existe; el límite de 20 intentos lo mitiga.

## Guía de construcción por fases

El paso a paso para entender y rehacer el proyecto está en **[docs/guia](docs/guia/README.md)**, con preguntas del profesor y sus respuestas en cada fase.

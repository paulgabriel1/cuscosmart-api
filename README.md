# CuscoSmart IA · API REST

Guía turística del Cusco: atractivos con mapa, favoritos, **viajes ordenados por IA** (de la parada más cercana a la más lejana), **reseñas verificadas** (solo de lugares visitados) y un **asistente** de preguntas frecuentes.

> Proyecto del curso **Fullstack Developer Software, SENATI**.
> Integrantes: **Gabriel Paul Alata Condori** · **Rodrigo Ccahuana Mayo** · **Elizabeth Flores Vargas**
> Web (frontend): <https://github.com/paulgabriel1/cuscosmart-web>

| Documento | Para qué |
| --- | --- |
| [docs/INSTALACION.md](docs/INSTALACION.md) | Instalar y correr todo **desde cero**, paso a paso |
| [docs/Guia-practica-CuscoSmart.pdf](docs/Guia-practica-CuscoSmart.pdf) | **Guía práctica en PDF** (API y front) con evidencias de cada función |
| [docs/diagrama-er.md](docs/diagrama-er.md) | Diagrama entidad-relación y reglas de la base |
| [docs/guia/](docs/guia/README.md) | Cómo se construyó, fase por fase (con preguntas del profesor) |
| <http://localhost:3000/api/v1/docs> | Swagger: probar cada endpoint (con la API prendida) |

## Arrancar (si ya está instalado)

```powershell
cd $HOME\Desktop\cuscosmart-api
npm install          # solo la primera vez o después de un git pull
npm run db:reset     # crea la base con datos de prueba (XAMPP → MySQL en Start)
npm run dev          # API en http://localhost:3000/api/v1
```

| Rol | Correo | Contraseña |
| --- | --- | --- |
| Administrador | admin@cuscosmart.pe | Admin12345 |
| Turista | ana@mail.com | Turista123 |

## Comandos

| Comando | Qué hace |
| --- | --- |
| `npm run dev` | Prende la API y se reinicia sola al guardar cambios |
| `npm start` | Prende la API sin reinicio automático (para presentar o correr pruebas) |
| `npm run db:reset` | Borra y crea la base con los datos de prueba |
| `npm run db:migrar` | Actualiza una base vieja **sin borrar datos** |
| `npm run test:api` | Corre las pruebas automáticas (149 peticiones · 456 pruebas) |
| `npm run postman` | Regenera la colección de Postman |
| `npm run docs:verificar` | Revisa que Swagger documente todas las rutas |
| `npm run admin` | Crea un administrador nuevo |

## Tecnologías

Node.js + Express 5 · MySQL/MariaDB (XAMPP) con **11 tablas, 61 procedimientos, 4 triggers y 1 función** · zod (validación) · JWT + bcrypt (sesión) · helmet, CORS y límites de peticiones · multer (subir imágenes) · Swagger (OpenAPI 3).

## Cómo está organizada

```
Petición → routes → middlewares → controllers → services → utils/sp.js → MySQL (CALL)
```

Toda la lógica de datos vive en **procedimientos almacenados**: la API nunca escribe SQL, solo hace `CALL`.

```
database/
├── schema.sql        # 11 tablas (diagrama ER)
├── logica.sql        # función Haversine, triggers y procedimientos
├── seed.sql          # datos de prueba: 27 atractivos, 20 preguntas, 2 usuarios
├── usuario.sql       # usuario de MySQL con permisos mínimos (solo EXECUTE)
├── migracion.sql     # cambios para bases antiguas (npm run db:migrar)
└── cuscosmart_todo.sql   # todo junto (lo genera db:reset; sirve para phpMyAdmin)
src/
├── routes/           # URL → middlewares → controlador (index.js monta cada recurso)
├── middlewares/      # auth (token y rol) · validate (zod) · limitadores · subidas · errorHandler
├── schemas/          # reglas de formato de cada dato (zod)
├── controllers/      # arman la respuesta HTTP
├── services/         # llaman a los procedimientos
│   (en las 4 carpetas: un archivo por recurso → auth, categorias, zonas, atractivos,
│    favoritos, itinerarios, resenas, preguntas, asistente, usuarios; ej. atractivos.routes.js)
├── utils/            # sp.js (única puerta a MySQL) · imagenes.js · AppError
├── config/           # env.js (valida el .env) · db.js (conexión)
└── docs/openapi.js   # Swagger
scripts/              # comandos de npm (db:reset, test:api, postman…)
postman/              # colección de pruebas
uploads/              # fotos subidas desde la web (no se sube a GitHub)
```

## Endpoints

Base: `http://localhost:3000/api/v1` · 🔓 público · 🔑 con sesión · 🛡️ solo ADMIN

| Recurso | Endpoints |
| --- | --- |
| Sesión | 🔓 `POST /auth/registro`, `POST /auth/login`, `POST /auth/google`, `GET /auth/config` · 🔑 `GET·PUT /auth/me`, `PUT·DELETE /auth/me/foto` |
| Catálogo | 🔓 `GET /categorias`, `/zonas`, `/atractivos`, `/atractivos/cercanos`, `/atractivos/:id` · 🛡️ crear, editar y borrar |
| Fotos y horarios | 🔓 `GET /atractivos/:id/fotos` · 🛡️ `POST …/fotos/subir` (desde la PC), `POST …/fotos/url` (desde un link), `DELETE …/fotos/:fotoId`, horarios |
| Favoritos | 🔑 `GET·POST /favoritos`, `DELETE /favoritos/:id` |
| Viajes | 🔑 `/itinerarios`: crear, editar, paradas, `ordenar-ia`, visitado, reseñas, `recorrido`, `visitar` |
| Reseñas | 🔓 `GET /atractivos/:id/resenas` · 🔑 borrar la propia · 🛡️ moderar |
| Asistente | 🔓 `POST /asistente/preguntar`, `GET /preguntas-frecuentes` · 🛡️ crear, editar y borrar preguntas |
| Usuarios | 🛡️ `GET /usuarios`, `PATCH /usuarios/:id/rol`, `DELETE /usuarios/:id` |

El detalle de cada uno (cuerpo, respuestas y errores) está en **Swagger**.

## Respuestas

```json
{ "ok": true,  "data": { }, "meta": { "page": 1, "limit": 10, "total": 27, "totalPages": 3 } }
{ "ok": false, "error": { "code": "BUSINESS_RULE", "message": "Solo puedes reseñar atractivos que visitaste" } }
```

| HTTP | `code` | Cuándo |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR`, `NOT_AN_IMAGE`… | Datos mal enviados |
| 401 | `NO_TOKEN`, `INVALID_TOKEN`, `INVALID_CREDENTIALS` | Sin sesión o datos de acceso incorrectos |
| 403 | `FORBIDDEN` | Tu rol no tiene permiso |
| 404 | `NOT_FOUND` | No existe, **o no es tuyo** |
| 409 | `DUPLICATE`, `IN_USE` | Repetido, o en uso por otro registro |
| 422 | `BUSINESS_RULE` | Rompe una regla de negocio |
| 429 | `TOO_MANY_REQUESTS` | Demasiados intentos |
| 503 | `DB_UNAVAILABLE` | MySQL está apagado |

## Reglas de negocio

Cada regla dice **dónde vive**, porque ahí es donde se cambia.

| N.º | Regla | Dónde |
| --- | --- | --- |
| RN-01 | El correo es único | `sp_registrar_usuario` + `UNIQUE` |
| RN-02 | Contraseña cifrada con bcrypt; mínimo 8 caracteres, con letras y números | `auth.service.js`, `auth.schema.js` |
| RN-03 | Solo el ADMIN gestiona catálogo, preguntas y usuarios, y modera reseñas | `authorize('ADMIN')` en las rutas |
| RN-04 | No se borra una categoría o zona que tiene atractivos | llave foránea → 409 `IN_USE` |
| RN-05 | No se repiten nombres de categorías ni de zonas | `sp_crear_*`, `sp_actualizar_*` |
| RN-06 | La hora de cierre es posterior a la de apertura | `sp_agregar_horario` |
| RN-07 | Un atractivo está una sola vez en los favoritos de cada turista | `sp_agregar_favorito` + `UNIQUE` |
| RN-08 | Cada turista solo ve y cambia lo suyo; lo ajeno responde 404 | `usuario_id` del token + `sp_validar_itinerario` |
| RN-09 | Un lugar aparece una sola vez por viaje | `sp_agregar_parada` + `UNIQUE` |
| RN-10 | Duración, costo y orden de las paradas los calcula el sistema | `sp_actualizar_totales`, `sp_recalcular_itinerarios` |
| RN-11 | Ordenar con IA exige punto de inicio; ordena por distancia (Haversine) | `sp_ordenar_itinerario_ia`, `fn_distancia_km` |
| RN-12 | Solo se reseña un lugar **visitado** (anti reseñas falsas), con puntuación de 1 a 5 | trigger `trg_resena_valida`, `sp_registrar_resena`, `CHECK` |
| RN-13 | La calificación es el promedio de reseñas y se recalcula sola | triggers `trg_resena_calificacion_*` |
| RN-14 | El ADMIN no puede quitarse su rol ni borrar su cuenta; el rol se revisa en cada petición | `usuarios.service.js`, `authenticate` |
| RN-15 | Límites: 300 peticiones por minuto; 10 logins fallidos por correo cada 15 min; 20 preguntas al asistente por minuto | `limitadores.js` |
| RN-16 | Las fotos subidas deben ser imágenes reales (JPG, PNG, WEBP o GIF) de hasta 5 MB | `utils/imagenes.js`, `subidas.js` |

**Cambiar una regla:**
1. Busca en la tabla dónde vive.
2. Cambia solo esa parte:
   - Procedimiento o trigger → `database/logica.sql` y luego `npm run db:reset`.
   - Formato de un dato → `src/schemas/`.
   - Permiso → `authorize(...)` en `src/routes/`.
3. Ajusta su prueba en `scripts/generarPostman.js`, luego `npm run postman` y `npm run test:api`.

## Seguridad

- La API entra a MySQL con un usuario que **solo puede ejecutar procedimientos** (no lee ni borra tablas directo).
- Sin SQL armado con texto: todo es `CALL` con parámetros, así que no hay inyección SQL.
- Contraseñas con bcrypt; el login responde igual si falla el correo o la contraseña.
- Token JWT con algoritmo fijo; el rol se lee de la base en cada petición.
- Lo ajeno responde 404 (no revela que existe).
- helmet, CORS limitado a la web, límite de tamaño del JSON y `.env` fuera de Git.
- Fotos: se revisa el contenido real del archivo, y al descargar desde un link no se permiten direcciones de la red interna (SSRF).

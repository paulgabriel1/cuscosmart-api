# Fase 9: front con React y mapa

**Objetivo:** la web que usa el turista y el administrador, conectada a la API. Vive en su propio repositorio: **`cuscosmart-web`**.

**Commits:** `chore: proyecto React con Vite` · `feat: …` (uno por pantalla)

---

## 9.1 Crear el proyecto

```powershell
cd $HOME\Desktop
mkdir cuscosmart-web; cd cuscosmart-web
npm init -y
npm install react@19 react-dom@19 react-router@7 @phosphor-icons/react leaflet react-leaflet
npm install -D vite@7 @vitejs/plugin-react@5
```

`vite.config.js` fija el **puerto 5173**. Tiene que coincidir con `CORS_ORIGIN` del `.env` de la API; si no coinciden, el navegador bloquea las peticiones.

## 9.2 La arquitectura del front

```
pages (pantallas) ──▶ hooks (useCarga / useAccion) ──▶ api.js ──HTTP──▶ API
        │                                               (token + errores)
        └──▶ components (Mapa, Tarjeta, Layout) + ui (Modal, Feedback, piezas)
```

| Archivo | Qué hace |
| --- | --- |
| `src/api.js` | **La única puerta a la API.** Agrega `Authorization: Bearer <token>`. Si la API falla, lanza `{ code, message }`. Si responde 401, cierra la sesión. |
| `src/auth.jsx` | Contexto de sesión: `login`, `registro`, `logout`, `usuario`, `esAdmin`… Además guarda los **favoritos**, así el ♥ sabe en cualquier pantalla si un lugar ya está guardado. |
| `src/hooks.js` | `useCarga(fn, deps)` lee datos (con `cargando`, `error` y `recargar`). `useAccion()` envía formularios (con `ocupado` y `error`). |
| `src/ui/Feedback.jsx` | Notificaciones (`toast.ok` / `toast.error`), ventana de confirmación (`await confirmar({...})`) y `useOperacion()`. |
| `src/components/Mapa.jsx` | Leaflet con OpenStreetMap: marcadores numerados, punto de inicio ★, línea de la ruta y clic para elegir un punto. |

## 9.3 Las pantallas y qué endpoint usa cada una

| Pantalla | Endpoints |
| --- | --- |
| Explorar `/` | `GET /atractivos?…`, `GET /categorias`, `GET /zonas`, `GET /atractivos/cercanos` |
| Detalle `/atractivos/:id` | `GET /atractivos/:id`, `GET /atractivos/:id/resenas`, `DELETE /resenas/:id` (admin) |
| ♥ (en todas) | `GET · POST /favoritos`, `DELETE /favoritos/:id` |
| Mis viajes `/viajes` | `GET · POST /itinerarios`, `DELETE /itinerarios/:id` |
| Viaje `/viajes/:id` | `GET · PUT /itinerarios/:id`, `POST …/paradas`, `DELETE …/paradas/:p`, `PATCH …/visitado`, `POST …/ordenar-ia`, `POST …/resenas` |
| Asistente `/asistente` | `POST /asistente/preguntar`, `GET /preguntas-frecuentes` |
| Acceso `/acceso` | `POST /auth/login`, `POST /auth/registro` |
| Admin `/admin` | CRUD de atractivos (más fotos y horarios), categorías, zonas, preguntas y usuarios |

**Patrón clave:** cada acción sobre un viaje **devuelve el viaje completo actualizado**. Por eso la pantalla solo hace `viaje.setData(respuesta.data)` y se redibuja todo de una vez: lista, mapa y totales.

## 9.4 Detalles que valen nota

- **Filtros en la URL** (`/?categoria=4&buscar=sal&vista=mapa`): se pueden compartir y sobreviven al recargar.
- **Búsqueda con pausa** de 350 ms: no se llama a la API en cada tecla.
- **Rutas protegidas:** `<Privado>` lleva a `/acceso` si no hay sesión, y `<Privado rol="ADMIN">` saca de `/admin` a quien no es administrador. Ojo: esto es solo **visual**; la seguridad real la aplica la API.
- **Fotos:** las guardadas como `img/...` se sirven desde `public/img`. Si una no carga, se muestra un fondo con montañas.
- **Mapa sin animación** al ajustar la vista: cerrar una ventana a mitad de un zoom animado rompía Leaflet (`_leaflet_pos`). Lo encontró la prueba E2E.
- **Un efecto de React solo puede devolver una función.** En navegadores nuevos `scrollIntoView()` devuelve una Promesa, así que `useEffect(() => ref.scrollIntoView())` rompía la página al salir del asistente. Se escribe con llaves. También lo encontró la prueba E2E.

## 9.5 Probar

```powershell
# Ventana 1 (API)
cd $HOME\Desktop\cuscosmart-api; npm run dev
# Ventana 2 (web)
cd $HOME\Desktop\cuscosmart-web; npm run dev
```

Recorrido sugerido:
1. **Turista** (botón de prueba) → ♥ en Catedral, Qorikancha y Sacsayhuamán.
2. **Mis viajes** → Nuevo viaje → toca el mapa en tu hotel.
3. Agrega las 3 paradas → **Ordenar con IA**.
4. **Visitado** → **Reseñar**.
5. **Asistente** → "¿cuánto cuesta el boleto?".

## 🎓 Preguntas del profesor

**1. ¿Cómo se comunica el front con el back?**
> Con `fetch` a la API REST, centralizado en `api.js`. Cada petición manda el JWT en la cabecera `Authorization: Bearer`. El back responde JSON con `{ ok, data }` o `{ ok:false, error }`.

**2. ¿Por qué el mapa no necesita clave?**
> Usamos Leaflet con las capas de OpenStreetMap, que son gratuitas para proyectos de bajo tráfico y piden citar la fuente (lo hacemos en el mapa y en el pie de página). Google Maps exige una tarjeta de crédito y una clave.

**3. ¿Qué pasa si alguien entra a `/admin` sin ser administrador?**
> El front lo redirige al inicio. Pero aunque alguien modifique el JavaScript, la API responde **403** a cualquier operación de ADMIN, porque `authorize('ADMIN')` revisa el rol en la base de datos en cada petición.

**4. ¿Dónde se guarda la sesión?**
> El token y los datos del usuario se guardan en `localStorage`. Es simple y suficiente para el curso; en producción convendría una cookie `httpOnly` para protegerlo de ataques XSS.

**5. ¿Cómo saben que la web funciona?**
> Con una prueba de punta a punta (Playwright en Edge) que hace 23 pasos como un usuario real, además de revisiones automáticas de imágenes rotas y desbordes en computadora y celular.

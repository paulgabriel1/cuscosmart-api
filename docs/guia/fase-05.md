# Fase 5: catálogo (categorías, zonas y atractivos)

**Objetivo:** el catálogo turístico completo. **Leer es público** (cualquiera, sin cuenta) y **escribir es solo ADMIN**.

**Commit:** `feat: catálogo de categorías, zonas y atractivos`

---

## 5.1 Archivos (el patrón de cada módulo)

| Capa | Archivo | Ejemplo |
| --- | --- | --- |
| Validación | `src/schemas/catalogo.schema.js` | `atractivoSchema`: latitud y longitud van juntas |
| Servicio | `src/services/catalogo.service.js` | `verAtractivo(id)` → `CALL sp_ver_atractivo(?)` |
| Controlador | `src/controllers/catalogo.controller.js` | Arma `{ ok, data, meta }` |
| Rutas | `src/routes/catalogo.routes.js` | `atractivos.get('/:id', conId, c.verAtractivo)` |

**Este mismo patrón (esquema → servicio → controlador → rutas) se repite en las fases 6 y 7.** Si entiendes un módulo, entiendes todos.

## 5.2 Endpoints

| Ruta | Procedimiento |
| --- | --- |
| `GET /categorias` · `/zonas` | `sp_listar_categorias` · `sp_listar_zonas` (incluyen cuántos atractivos tiene cada una) |
| `POST · PUT · DELETE /categorias/:id` | `sp_crear_categoria` · `sp_actualizar_categoria` · `sp_eliminar_categoria` |
| `GET /atractivos?categoria_id&zona_id&buscar&page&limit` | `sp_listar_atractivos` (2 resultados: filas y total) |
| `GET /atractivos/cercanos?lat&lng&radio_km` | `sp_atractivos_cercanos` (usa `fn_distancia_km`) |
| `GET /atractivos/:id` | `sp_ver_atractivo` (3 resultados: datos, horarios y fotos) |
| `POST · PUT · DELETE /atractivos/:id` | `sp_crear_atractivo` · `sp_actualizar_atractivo` · `sp_eliminar_atractivo` |
| `GET · POST · DELETE /atractivos/:id/horarios(/:horarioId)` | `sp_listar_horarios` · `sp_agregar_horario` · `sp_eliminar_horario` |
| `GET · POST · DELETE /atractivos/:id/fotos(/:fotoId)` | `sp_listar_fotos` · `sp_agregar_foto` · `sp_eliminar_foto` |

## 5.3 Cómo funciona la paginación

```
GET /atractivos?page=2&limit=5
→ servicio: CALL sp_listar_atractivos(NULL, NULL, NULL, 5, 5)     -- offset = (page - 1) × limit
→ respuesta: { ok:true, data:[…5 atractivos…], meta:{ page:2, limit:5, total:14, totalPages:3 } }
```

El total lo calcula el **mismo procedimiento**, en su segundo `SELECT`. Así el front sabe cuántas páginas hay.

## 5.4 El orden de las rutas importa

```js
atractivos.get('/cercanos', …);   // primero
atractivos.get('/:id', …);        // después
```

Si `/:id` fuera primero, Express tomaría "cercanos" como un id, y zod respondería 400 "Debe ser un número".

## 5.5 Probar

| Prueba | Esperado |
| --- | --- |
| `GET /atractivos` | 10 atractivos, `meta.total` 14 |
| `GET /atractivos?buscar=sal` | Salineras de Maras |
| `GET /atractivos/cercanos?lat=-13.5167&lng=-71.9788&radio_km=0.5` | Plaza (0 km), Catedral (0.06 km)… |
| `POST /categorias` sin token / con el token de Ana / con el del admin | 401 / 403 / 201 |
| `DELETE /categorias/1` (tiene atractivos) | 409 `IN_USE` |
| `POST /atractivos` con `categoria_id: 999` | 400 `INVALID_REFERENCE` |
| `POST /atractivos/:id/horarios` con el cierre antes de la apertura | 422 `BUSINESS_RULE` |

## 🎓 Preguntas del profesor

**1. ¿Por qué leer es público?**
> Un turista debe poder explorar los lugares antes de crear una cuenta. Solo lo personal (favoritos, itinerarios, reseñas) exige iniciar sesión.

**2. ¿Cómo calculan los lugares cercanos?**
> Con la fórmula de Haversine, en la función `fn_distancia_km` de MySQL. Calcula la distancia en km sobre la superficie de la Tierra entre dos coordenadas. El procedimiento filtra por el radio y ordena de menor a mayor.

**3. ¿Qué pasa si borran un atractivo que está en itinerarios?**
> Se borran en cascada sus horarios, fotos, favoritos, paradas y reseñas. Además, `sp_eliminar_atractivo` recalcula la duración y el costo de los itinerarios que lo tenían como parada, para que los totales no queden desactualizados.

**4. ¿Por qué no se puede enviar la calificación al crear un atractivo?**
> Porque la calcula el sistema: es el promedio de las reseñas, y la mantienen los triggers. Si el cliente pudiera enviarla, podría inventar calificaciones.

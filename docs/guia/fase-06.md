# Fase 6: favoritos, itinerarios y la "IA"

**Objetivo:** el corazón del proyecto. El turista guarda favoritos, arma itinerarios con ellos, la **IA ordena la ruta** por cercanía, marca lo que visitó y deja reseñas verificadas.

**Commit:** `feat: favoritos e itinerarios con orden IA y reseñas verificadas`

---

## 6.1 Archivos

| Archivo | Contenido |
| --- | --- |
| `src/schemas/viaje.schema.js` | Favorito, itinerario (punto de inicio opcional, pero latitud y longitud juntas), parada y reseña |
| `src/services/viaje.service.js` | Llama a los procedimientos con `usuarioId` = **el del token** |
| `src/controllers/viaje.controller.js` | `const yo = (req) => req.user.id` |
| `src/routes/viaje.routes.js` | `router.use(authenticate)`: todo exige token |

## 6.2 El flujo completo de un viaje

```
1. POST /favoritos {atractivo_id: 5}                          → guarda la Plaza en favoritos
2. POST /itinerarios {nombre, latitud_inicio, longitud_inicio} → el punto de inicio es el hotel
3. POST /itinerarios/7/paradas {favorito_id: 6}               → cada parada sale de un favorito
4. POST /itinerarios/7/ordenar-ia                             → la IA ordena por distancia
5. PATCH /itinerarios/7/paradas/12/visitado                   → "ya fui"
6. POST /itinerarios/7/resenas {atractivo_id: 5, puntuacion: 4} → solo si fue visitado
```

## 6.3 ¿Quién comprueba que el itinerario es mío?

Las rutas **no** comprueban el dueño. Lo hace la base: cada procedimiento recibe `p_usuario_id` (del token) y llama primero a:

```sql
CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);   -- SIGNAL 45404 si no es tuyo
```

Así la regla se escribe **una sola vez** y no hay forma de olvidarla en alguna ruta.

## 6.4 La "IA" paso a paso (`POST /itinerarios/:id/ordenar-ia`)

1. Comprueba que el itinerario tenga punto de inicio y al menos una parada (si no: 422).
2. Calcula `distancia_km` de cada parada al punto de inicio con `fn_distancia_km` (Haversine).
3. Las numera de la más cercana a la más lejana (`ROW_NUMBER() OVER (ORDER BY distancia_km)`).
4. Marca `sugerido_ia = 1`.

Si después **agregas una parada** o **cambias el punto de inicio**, `sugerido_ia` vuelve a 0, porque la ruta ya no está optimizada. El front lo muestra como "Ruta sin ordenar".

Ejemplo real con los datos de prueba (inicio: un hotel junto a la Plaza Regocijo):

```
1. Catedral del Cusco   0.21 km
2. Qorikancha           0.58 km
3. Sacsayhuamán         0.88 km
```

## 6.5 Reglas que protegen los datos

| Intento | Quién lo frena | Respuesta |
| --- | --- | --- |
| Ver el itinerario de otra persona | `sp_validar_itinerario` | 404 |
| Usar como parada un favorito de otra persona | Trigger `trg_detalle_valida` | 422 |
| Repetir un lugar en el mismo itinerario | `sp_agregar_parada` | 409 |
| Reseñar sin haber visitado | Trigger `trg_resena_valida` | 422 |
| Reseñar dos veces el mismo lugar en el mismo viaje | `sp_registrar_resena` + UNIQUE | 409 |
| Ordenar sin punto de inicio | `sp_ordenar_itinerario_ia` | 422 |

## 🎓 Preguntas del profesor

**1. ¿Por qué las paradas salen de los favoritos y no de cualquier atractivo?**
> Así el turista primero elige qué le interesa y luego arma rutas con eso. Además, la relación favorito → parada permite que el trigger compruebe que el favorito es del dueño del itinerario.

**2. ¿Es realmente IA?**
> Es una heurística de optimización de rutas: "del más cercano al más lejano desde el origen". Usa la geometría de la Tierra (Haversine) y funciona al instante, sin servicios pagados. Como mejora futura podría usarse el problema del viajante (TSP) o la API de rutas de un mapa.

**3. ¿Qué pasa si el turista quita un favorito que está en un itinerario?**
> La parada se borra en cascada y `sp_quitar_favorito` recalcula los totales de esos itinerarios.

**4. ¿Por qué un itinerario ajeno responde 404 y no 403?**
> Porque 403 confirmaría que existe. Con 404, nadie puede averiguar qué IDs de itinerario están en uso.

# Fase 11: mi recorrido, paradas sin favoritos y búsqueda tolerante

**Objetivo:** que el viaje sea más útil. Agregar un lugar no lo guarda en favoritos, el perfil muestra tu recorrido con fechas, la búsqueda acepta errores de escritura y puedes borrar tus propias reseñas.

**Commits:** API `feat: paradas sin favoritos, mi recorrido, búsqueda tolerante y reseñas propias` · Web `feat: mi recorrido en el perfil, viajes por distancia y búsqueda con sugerencias`

---

## 11.1 Lo que cambió en la API

| Cambio | Dónde | Por qué |
| --- | --- | --- |
| Paradas sin favorito | `tbl_atractivo_favorito.es_favorito = 0` | Un lugar puede estar en un viaje sin aparecer en Favoritos. |
| Distancia en cada parada | Respuesta del viaje | Cada parada muestra la distancia desde el punto de inicio. |
| `GET /itinerarios/recorrido` | `sp_mi_recorrido` | Lista lo visitado (con fecha) y lo pendiente. |
| `DELETE /itinerarios/:id/paradas/:paradaId/visitado` | `sp_desmarcar_visitado` | Quita la marca de visita si te equivocaste. |
| Búsqueda sin tildes y por palabras | `catalogo.service.js` | "compania" encuentra "Compañía de Jesús". |
| "¿Quisiste decir…?" | `catalogo.service.js` | Si no hay resultados, sugiere un nombre parecido (distancia de Levenshtein). |
| `DELETE /resenas/:id/propia` | `sp_eliminar_mi_resena` | El turista borra **su** reseña. El procedimiento revisa que sea suya. |
| Quitar una parada borra su reseña | `sp_quitar_parada` | La reseña solo es válida si el lugar sigue en el viaje. |

**Migración:** si ya tienes la base de la fase 10, no la borres. Ejecuta:

```powershell
cd $HOME\Desktop\cuscosmart-api; npm run db:migrar
```

Este comando actualiza las tablas y limpia reseñas huérfanas. No borra tus datos.

## 11.2 Lo que cambió en la web

| Archivo | Qué hace |
| --- | --- |
| `Perfil.jsx` | **Mi recorrido**: línea de tiempo con los lugares visitados (y su fecha) y los pendientes. |
| `Viaje.jsx` | Agrega cualquier lugar (sin guardarlo en favoritos). La lista se ordena por distancia y muestra los km del recorrido. |
| `Explorar.jsx` | Muestra "¿Quisiste decir…?" y un botón para quitar los filtros. |
| `Acceso.jsx` | Quita los botones de usuarios de prueba. Agrega **Explorar como invitado**. |
| `Atractivo.jsx`, `Viaje.jsx` | Borran tu propia reseña desde el lugar o desde el viaje. |

Los textos nuevos se escribieron en los 6 idiomas. La fase 12 dejó solo español e inglés.

## 11.3 Probar

1. Abre un lugar sin ♥ → **Agregar a un viaje** → ese lugar **no** aparece en Favoritos.
2. En Explorar escribe `catedrl`. Aparece "¿Quisiste decir…?" con **Catedral**.
3. Escribe `compania` (sin tilde). Encuentra **Iglesia de la Compañía de Jesús**.
4. En un viaje marca una parada como **Visitado**. Revisa **Mi perfil → Mi recorrido**.
5. Escribe una reseña y bórrala desde el mismo lugar.

## 🎓 Preguntas del profesor

**1. ¿Por qué agregar un lugar a un viaje no lo guarda en favoritos?**
> Porque la columna `es_favorito` vale `0` para esa fila. La pantalla Favoritos solo muestra las filas con `es_favorito = 1`. Así un viaje puede tener lugares que no son favoritos.

**2. ¿Cómo encuentra la búsqueda "compania" a la Compañía?**
> La API quita las tildes con `normalize('NFD')` y pasa todo a minúsculas antes de comparar. Busca también por palabras separadas.

**3. ¿Qué pasa con la reseña si quitas el lugar del viaje?**
> El procedimiento `sp_quitar_parada` borra también esa reseña. Una reseña es verificada solo si el lugar está en tu viaje.

**4. ¿Puede un turista borrar la reseña de otra persona?**
> No. `sp_eliminar_mi_resena` busca la reseña dentro de los viajes del usuario que hace la petición. Si no la encuentra, responde 404.

**5. ¿Qué hace `npm run db:migrar` y por qué no borra la base?**
> Ejecuta cambios de tablas y procedimientos sobre la base que ya existe. Por eso conserva los datos. Para empezar de cero se usa `npm run db:reset`, que sí borra todo.

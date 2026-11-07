# Fase 12: visitar desde favoritos y mapa, y armar viaje con favoritos

**Objetivo:** que marcar un lugar como visitado sea fácil desde cualquier pantalla: Favoritos, Mapa o la ficha del lugar. La web queda solo en español e inglés.

**Commits:** API `feat: marcar lugares visitados sin viaje y armar viaje con favoritos` · API `docs: diagrama entidad-relación verificado contra la base real` · Web `feat: visitar y reseñar desde favoritos y mapa, armar viaje, solo es/en`

---

## 12.1 Lo que cambió en la API

| Cambio | Dónde | Por qué |
| --- | --- | --- |
| `POST /itinerarios/visitar` | `sp_marcar_visitado` | Marca un lugar como visitado desde cualquier pantalla. Body: `{ "atractivo_id": 1 }`. |
| Viaje "Lugares visitados" | `sp_marcar_visitado` | Si el lugar no está en ningún viaje, la API crea ese viaje solo. La reseña necesita una parada para ser verificada. |
| `POST /itinerarios/:id/favoritos` | Viaje existente | Agrega **todos** tus favoritos como paradas. Si el viaje tiene punto de inicio, la IA ordena la ruta. |
| Columna `es_favorito` | `tbl_atractivo_favorito` | Vale `0` si el lugar solo está en un viaje (fase 11). |
| Columna `fecha_visita` | `tbl_detalle_itinerario` | Guarda cuándo marcaste la parada como visitada. |

Las dos columnas nuevas están dibujadas en el [diagrama entidad-relación](../diagrama-er.md). Ese diagrama se revisó contra la base real.

**Migración:** si ya tienes la base de la fase 11, ejecuta después de `git pull`:

```powershell
cd $HOME\Desktop\cuscosmart-api; npm install; npm run db:migrar
```

## 12.2 Lo que cambió en la web

| Archivo | Qué hace |
| --- | --- |
| `AccionesVisita.jsx` | Botones **Visitado** y **Reseñar** en cada tarjeta. Se usan en Favoritos, Mapa y la ficha. |
| `ArmarViaje.jsx` | **Armar un viaje** con tus favoritos: crea la ruta nueva o la suma a un viaje que ya tienes. |
| `Favoritos.jsx` | Botón **Armar un viaje** y botones de visita y reseña en cada lugar. |
| `MapaCerca.jsx` | Filtros **Todos / Mis favoritos / Visitados**, marcadores ♥ y ✓, leyenda y botón **Ruta con mis favoritos**. |
| `Viaje.jsx` | Botón **Agregar mis favoritos (n)**. |
| `Atractivo.jsx` | Marcar visitado y reseñar. Al agregar a un viaje, no se ofrecen los viajes que ya tienen ese lugar. |
| `es.js` y `en.js` | Quedan solo estos dos idiomas. Se borran los demás. |

Los errores de la API se traducen en `errores.js`. Las fechas siguen el idioma elegido.

## 12.3 Probar

1. **Favoritos** → ♥ en Catedral y en Qorikancha.
2. En Catedral toca **Visitado**. Como no está en ningún viaje, aparece en **Mis viajes → Lugares visitados**.
3. En Favoritos toca **Armar un viaje**. Se crea la ruta con los dos lugares.
4. **Mapa** → filtro **Visitados** → botón **Ruta con mis favoritos**.
5. Abre la ficha de Catedral → **Reseñar**.

## 🎓 Preguntas del profesor

**1. ¿Por qué "Visitado" puede crear un viaje?**
> La reseña verificada solo se acepta si el lugar es parada de un viaje tuyo. Si no hay ningún viaje con ese lugar, `sp_marcar_visitado` crea "Lugares visitados" con el inicio en la Plaza de Armas.

**2. ¿Qué hace `es_favorito` y dónde vive?**
> Está en `tbl_atractivo_favorito`. Vale `1` si el lugar es tu favorito y `0` si solo está en un viaje. Así Favoritos no muestra lugares que agregaste solo a una ruta.

**3. ¿Qué pasa si marcas como visitado un lugar que ya está en uno de tus viajes?**
> El procedimiento marca esa misma parada. No crea otra.

**4. ¿Cómo sabe la base cuándo visitaste una parada?**
> La columna `fecha_visita` de `tbl_detalle_itinerario` guarda la fecha. Con ella el perfil arma la línea de tiempo **Mi recorrido**.

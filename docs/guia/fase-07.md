# Fase 7: reseñas, asistente, preguntas frecuentes y usuarios

**Objetivo:** reseñas públicas y su moderación, el asistente que responde preguntas, el CRUD de preguntas frecuentes y la administración de usuarios.

**Commit:** `feat: asistente, preguntas frecuentes, reseñas públicas y usuarios`

---

## 7.1 Archivos

| Archivo | Contenido |
| --- | --- |
| `src/schemas/admin.schema.js` | Pregunta, pregunta frecuente, paginación de reseñas y usuarios, rol |
| `src/services/admin.service.js` | Asistente, preguntas, reseñas y usuarios |
| `src/controllers/admin.controller.js` | Respuestas HTTP |
| `src/routes/admin.routes.js` | `/asistente`, `/preguntas-frecuentes`, `/atractivos/:id/resenas`, `/resenas`, `/usuarios` |

## 7.2 El asistente (`POST /asistente/preguntar`)

```
pregunta del turista
   └─ CALL sp_buscar_pregunta_frecuente(texto)     -- MATCH … AGAINST (FULLTEXT)
        ├─ hay coincidencia → { encontrada:true, pregunta, respuesta, atractivo }
        └─ no hay           → { encontrada:false, respuesta:"Aún no tengo…", sugerencias:[3 preguntas] }
```

- **FULLTEXT** es un índice de MySQL que busca por **palabras** y ordena por relevancia. "cuanto cuesta el boleto" encuentra "¿Cuánto cuesta el boleto turístico del Cusco?".
- **No sobrecarga la web:** no llama a servicios externos, responde en milisegundos y tiene un límite de 20 preguntas por minuto.
- **No guarda las consultas:** es solo lectura (decisión del diseño, sugerida por el profesor).
- Para que el asistente "aprenda" algo nuevo, el ADMIN agrega una pregunta con `POST /preguntas-frecuentes`, y se responde al instante.

## 7.3 Reseñas

- `GET /atractivos/:id/resenas` es público, paginado y muestra el autor.
- `DELETE /resenas/:id` es la **moderación** del ADMIN. Al borrarla, el trigger recalcula la calificación.

## 7.4 Usuarios (solo ADMIN)

| Ruta | Regla extra |
| --- | --- |
| `GET /usuarios?buscar&page&limit` | Incluye cuántos itinerarios tiene cada uno |
| `PATCH /usuarios/:id/rol` | El ADMIN **no puede quitarse su propio rol**, para no quedar sin administradores (422) |
| `DELETE /usuarios/:id` | No puede eliminarse a sí mismo (422). Las reseñas del usuario se borran primero, para recalcular calificaciones |

Estas dos reglas viven en **Node** (`admin.service.js`) y no en MySQL, porque dependen de **quién hace la petición** (el token), algo que la base no conoce.

## 🎓 Preguntas del profesor

**1. ¿Por qué no usan ChatGPT para el asistente?**
> Por costo, velocidad y control. Las preguntas frecuentes son respuestas **verificadas** por el administrador, con FULLTEXT responden al instante y no requieren claves de API. Como mejora futura, si no hay coincidencia, se podría consultar un modelo de IA.

**2. ¿Cómo evitan que alguien sature el asistente?**
> Con `express-rate-limit`: 20 preguntas por minuto por IP. Pasado el límite, responde 429.

**3. ¿Por qué algunas reglas están en Node y no en la base?**
> La base protege las reglas sobre los **datos** (reseñas válidas, dueño, duplicados). Node protege lo que depende de **la petición**: quién la hace (su token), su rol y el formato de lo que envía.

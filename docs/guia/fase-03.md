# Fase 3: manejo de errores y validación

**Objetivo:** que **todo** error, venga de donde venga, responda con el mismo formato, y que los datos inválidos se rechacen antes de llegar a la base.

**Commit:** `feat: manejo de errores y validación`

---

## 3.1 Un solo formato de error

```json
{ "ok": false, "error": { "code": "BUSINESS_RULE", "message": "…", "details": [ ] } }
```

El front muestra siempre `error.message`, y si existe `details`, marca cada campo.

## 3.2 Archivos

| Archivo | Qué hace |
| --- | --- |
| `src/utils/AppError.js` | Un error "conocido" con código HTTP: `throw new AppError(401, 'Token requerido', 'NO_TOKEN')` |
| `src/middlewares/errorHandler.js` | Atrapa **cualquier** error y lo traduce. `notFound` responde 404 a las rutas que no existen. |
| `src/middlewares/validate.js` | Valida `body`, `query` o `params` con zod. Si falla: 400 con la lista de campos. |
| `src/schemas/comunes.js` | Piezas reutilizables: `id`, paginación, latitud y longitud, texto opcional |

## 3.3 Cómo traduce los errores el `errorHandler`

| Origen del error | Ejemplo | Respuesta |
| --- | --- | --- |
| `AppError` lanzado en Node | Token inválido | El status y el code que traiga |
| `SIGNAL SQLSTATE '45000'` en un procedimiento o trigger | "Solo puedes reseñar atractivos que visitaste" | **422** BUSINESS_RULE |
| `SIGNAL SQLSTATE '45404'` | "Itinerario no encontrado" | **404** NOT_FOUND |
| `SIGNAL SQLSTATE '45409'` | "Ese correo ya está registrado" | **409** DUPLICATE |
| MySQL `ER_DUP_ENTRY` | Un UNIQUE repetido | 409 DUPLICATE |
| MySQL `ER_ROW_IS_REFERENCED_2` | Borrar una categoría con atractivos | 409 IN_USE |
| MySQL `ER_NO_REFERENCED_ROW_2` | `categoria_id` inexistente | 400 INVALID_REFERENCE |
| MySQL apagado | `ECONNREFUSED` | 503 DB_UNAVAILABLE |
| JSON mal escrito | `{"correo": ` | 400 INVALID_JSON |
| Cualquier otro | Un error de programación | 500, **sin detalles** (el detalle queda en la consola) |

> **El mensaje de los SIGNAL viene en español desde MySQL** (`err.sqlMessage`). Por eso, si cambias un mensaje en `logica.sql`, la API lo muestra sin tocar Node.

## 3.4 `validate`: un detalle de Express 5

En Express 5, `req.query` y `req.params` son **de solo lectura**. Por eso `validate` deja los datos limpios en `req.validado.query` y `req.validado.params` (con los números ya convertidos), y en `req.body` cuando valida el cuerpo.

```js
router.get('/:id', validate(idParam, 'params'), controlador);   // en el controlador: req.validado.params.id
```

## 3.5 Probar

| Petición | Esperado |
| --- | --- |
| `GET /api/v1/no-existe` | 404 `NOT_FOUND` "Ruta no encontrada: GET /api/v1/no-existe" |
| `POST /api/v1/auth/login` con el cuerpo `{"correo": ` | 400 `INVALID_JSON` |

## 🎓 Preguntas del profesor

**1. ¿Por qué el error 500 no muestra el detalle?**
> Porque el detalle técnico (consultas, rutas de archivos) ayuda a un atacante. Al usuario se le muestra un mensaje genérico, y el detalle queda en la consola del servidor.

**2. ¿Cómo sabe la API que un error de MySQL es una regla de negocio?**
> Los procedimientos usan `SIGNAL` con SQLSTATE propios: 45000, 45404 y 45409. mysql2 entrega ese código en `err.sqlState`, y el `errorHandler` tiene una tabla que lo convierte en 422, 404 o 409.

**3. ¿Por qué validar en Node si la base ya valida?**
> Son dos niveles. zod rechaza rápido lo **mal formado** (un correo inválido, un texto de 10 000 caracteres) sin gastar una consulta, y da mensajes por campo. La base protege las **reglas de negocio** aunque alguien la use sin la API.

**4. ¿Por qué Express necesita los 4 parámetros `(err, req, res, next)`?**
> Así distingue un manejador de errores de un middleware normal. Sin `next`, Express no lo reconoce como manejador de errores.

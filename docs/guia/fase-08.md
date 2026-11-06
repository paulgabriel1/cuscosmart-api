# Fase 8: Postman, Swagger y documentación

**Objetivo:** probar **toda** la API de forma automática y documentarla para que cualquiera la entienda y la use.

**Commits:** `test: colección Postman con pruebas automáticas` · `docs: Swagger, README y guías`

---

## 8.1 La colección de Postman

- **Generador:** `scripts/generarPostman.js`. Escribimos las pruebas en JavaScript y él arma el JSON de Postman.
- **Resultado:** `postman/cuscosmart.collection.json`, con **107 peticiones** y **326 pruebas automáticas** en 7 carpetas.

| Carpeta | Qué prueba |
| --- | --- |
| 00 Autenticación | Login, registro, 401, credenciales y que no se devuelva la contraseña |
| 01 Catálogo | CRUD, filtros, paginación, cercanos, 403, 409 IN_USE |
| 02 Favoritos | Lo propio vs. lo ajeno, duplicados |
| 03 Itinerarios e IA | Orden por distancia, triggers anti trampa, recálculo de calificación |
| 04 Asistente | FULLTEXT, sugerencias y que una pregunta nueva se responda al instante |
| 05 Administración | Roles, moderación y que el admin no se borre a sí mismo |
| 06 Seguridad | JSON inválido, ruta inexistente y 429 |

**Las variables se guardan solas:** la petición de login ejecuta `pm.collectionVariables.set('tokenAna', …)`, y las siguientes usan `{{tokenAna}}`. Lo mismo pasa con los IDs creados (`{{idIti}}`, `{{favPlaza}}`…).

### Correrla

```powershell
npm run db:reset        # datos limpios (la colección modifica datos)
# reinicia la API: Ctrl + C y npm run dev   (la última prueba bloquea el login 15 min)
npm run test:api        # 107 peticiones · 326 pruebas · 0 fallidas
```

O en Postman: **Import** → `postman/cuscosmart.collection.json` → clic derecho → **Run collection**.

## 8.2 Swagger (OpenAPI 3)

- Archivo: `src/docs/openapi.js`. Se ve en **http://localhost:3000/api/v1/docs**.
- Cómo usarlo: `POST /auth/login` → **Try it out** → **Execute** → copia `data.token` → **Authorize** → pégalo. Desde ahí puedes probar cualquier endpoint.
- `npm run docs:verificar` compara las rutas reales con las documentadas. Hoy: **49 de 49** y 0 referencias rotas.

## 8.3 README e INSTALACION

- `README.md`: tecnologías, arquitectura, endpoints, **tabla de reglas de negocio** (con dónde vive cada una) y códigos de error.
- `docs/INSTALACION.md`: cómo levantar todo en otra PC.

## 🎓 Preguntas del profesor

**1. ¿Cómo saben que todo funciona?**
> Con 326 pruebas automáticas que revisan el código de estado, el formato y los datos de cada respuesta, incluidos los casos de error. Se corren con un comando después de cada cambio.

**2. ¿Qué diferencia hay entre Swagger y Postman?**
> Swagger **documenta** la API: qué rutas hay, qué reciben y qué devuelven, y permite probarlas desde el navegador. Postman **prueba** la API de forma repetible, con aserciones automáticas.

**3. ¿Por qué la colección se genera con código?**
> Para mantenerla al día sin errores de copiado: si cambia una regla, se cambia la prueba en un solo lugar y se regenera el JSON.

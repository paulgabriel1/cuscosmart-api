# Fase 2: proyecto base de Node

**Objetivo:** tener una API que arranca, se conecta a MySQL y responde `GET /api/v1/health`.

**Commit:** `feat: estructura base, conexión MySQL y health`

---

## 2.1 `package.json`

```json
"type": "module",                         // usamos import/export (ESM), no require
"scripts": {
  "dev": "node --watch src/server.js",    // se reinicia solo al guardar un archivo
  "db:reset": "node scripts/armarSql.js --importar"
}
```

Las dependencias se instalaron con:

```powershell
npm install express@5.1.0 mysql2@3.11.3 dotenv cors helmet morgan express-rate-limit bcryptjs jsonwebtoken zod@3.23.8
```

| Librería | Para qué |
| --- | --- |
| express | Servidor HTTP y rutas |
| mysql2 | Conexión a MySQL (con `async/await`) |
| dotenv | Lee el archivo `.env` |
| cors | Permite que el front (puerto 5173) llame a la API (puerto 3000) |
| helmet | Agrega cabeceras HTTP de seguridad |
| morgan | Muestra cada petición en la consola |
| express-rate-limit | Limita intentos (fase 4) |
| bcryptjs | Cifra contraseñas (fase 4) |
| jsonwebtoken | Crea y verifica tokens JWT (fase 4) |
| zod | Valida datos de entrada (fase 3) |

## 2.2 `.env` y `.env.example`

- `.env` tiene los valores **reales**: la clave de la base y el secreto JWT. Está en `.gitignore` y **nunca** se sube a Git.
- `.env.example` es la **plantilla**, sin secretos. Sí se sube, para que cualquiera sepa qué variables hacen falta.

## 2.3 Los archivos y qué hace cada uno

| Archivo | Responsabilidad |
| --- | --- |
| `src/config/env.js` | Lee `.env` **una sola vez** y valida que no falte nada. Si falta `DB_PASSWORD` o el `JWT_SECRET` es corto, la API **no arranca** y dice qué falta. |
| `src/config/db.js` | Crea el **pool** de conexiones: 10 conexiones reutilizables en lugar de abrir una por petición. `decimalNumbers` convierte `70.00` en el número 70. |
| `src/utils/sp.js` | **La única puerta a MySQL.** `llamar('sp_x', [params])` ejecuta `CALL sp_x(?, ?)` y devuelve los resultados. |
| `src/app.js` | Configura Express: helmet, cors, lectura de JSON y morgan; monta las rutas en `/api/v1`. |
| `src/server.js` | Comprueba MySQL con un `ping` y luego abre el puerto 3000. |
| `src/routes/index.js` | El mapa de rutas. Por ahora, solo `/health`. |
| `scripts/armarSql.js` | Une los `.sql` en `cuscosmart_todo.sql` y, con `--importar`, recrea la base. |

### Por qué `sp.js` filtra el resultado
Con mysql2, un `CALL` devuelve algo como:

```js
[ [filas del SELECT 1], [filas del SELECT 2], ResultSetHeader ]
```

El último elemento es información técnica (filas afectadas, etc.). `llamar()` lo quita y deja solo los resultados:

```js
const [filas, [{ total }]] = await llamar('sp_listar_atractivos', [null, null, 'inca', 10, 0]);
```

## 2.4 Probar

```powershell
npm run dev
```

Debe mostrar `✅ Conectado a MySQL` y `🚀 API en http://localhost:3000/api/v1`. En el navegador o en Postman:

```
GET http://localhost:3000/api/v1/health   →   {"ok":true,"data":{"status":"up","db":"up"}}
```

Apaga MySQL en XAMPP y vuelve a pedir `/health`: responde **503** con `"db":"down"`. Así funciona un *health check* real.

## 🎓 Preguntas del profesor

**1. ¿Qué es un pool de conexiones?**
> Un grupo de conexiones abiertas que se reutilizan. Abrir una conexión es lento; con el pool, cada petición toma una libre y la devuelve al terminar.

**2. ¿Por qué validan el `.env` al arrancar?**
> Para fallar pronto y con un mensaje claro. Si falta una variable, es mejor que la API no arranque a que falle a mitad de un login.

**3. ¿Por qué `DB_HOST=127.0.0.1` y no `localhost`?**
> En Windows, `localhost` puede resolverse a IPv6 (`::1`), y MySQL de XAMPP escucha en IPv4. Con `127.0.0.1` no hay ambigüedad.

**4. ¿Qué hace `--watch`?**
> Node vigila los archivos y reinicia la API al guardar. Ojo: no vuelve a leer el `.env`; si lo cambias, hay que reiniciar a mano.

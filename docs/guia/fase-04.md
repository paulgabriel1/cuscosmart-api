# Fase 4: autenticación y roles

**Objetivo:** registro de turistas, login con JWT, `/auth/me`, protección de rutas por token (401) y por rol (403), límite de intentos y un script para crear administradores.

**Commit:** `feat: autenticación JWT y roles`

---

## 4.1 Archivos

| Archivo | Qué hace |
| --- | --- |
| `src/schemas/auth.schema.js` | Reglas del registro: nombre de 3 a 150 caracteres, correo válido (en minúsculas), contraseña de 8 o más caracteres **con letras y números** |
| `src/services/auth.service.js` | Cifra con bcrypt, llama a `sp_registrar_usuario`, `sp_usuario_por_correo` y `sp_usuario_por_id`, y firma el token |
| `src/controllers/auth.controller.js` | `registro` (201), `login` (200), `me` (200) |
| `src/routes/auth.routes.js` | `POST /registro`, `POST /login` (con límite) y `GET /me` (con token) |
| `src/middlewares/auth.js` | `authenticate` (401) y `authorize('ADMIN')` (403) |
| `src/middlewares/limitadores.js` | 20 intentos cada 15 min para auth y 20 preguntas por minuto para el asistente |
| `scripts/crearAdmin.js` | `npm run admin -- "Nombre" correo "Clave123"` |

## 4.2 El flujo del login

```
POST /auth/login {correo, contrasena}
   │
   ├─ validate(loginSchema)        → 400 si el correo está mal escrito
   ├─ sp_usuario_por_correo        → trae el hash (el ÚNICO procedimiento que lo devuelve)
   ├─ bcrypt.compare(clave, hash)  → si el correo no existe, compara contra un hash falso
   │                                 (tarda lo mismo: no revela qué correos existen)
   └─ jwt.sign({ sub: id, rol, nombre }, JWT_SECRET, { expiresIn: '8h' })
```

Respuesta:

```json
{ "ok": true, "data": { "token": "eyJ…", "usuario": { "id": 2, "nombre_completo": "Ana Quispe", "rol": "TURISTA" } } }
```

## 4.3 Proteger rutas

```js
router.get('/me', authenticate, ctrl.me);                                     // cualquier usuario con token
router.post('/', authenticate, authorize('ADMIN'), validate(...), ctrl.crear); // solo ADMIN
```

- `authenticate` lee `Authorization: Bearer <token>`, lo verifica con el `JWT_SECRET` y deja `req.user = { id, rol, nombre }`.
- `authorize('ADMIN')` compara `req.user.rol` con los roles permitidos.

**Regla de oro:** el `usuario_id` **siempre** se toma de `req.user.id` (del token), nunca del cuerpo. Si lo tomáramos del cuerpo, cualquiera podría crear cosas a nombre de otro.

## 4.4 Probar en Postman

1. `POST /auth/login` con `{"correo":"ana@mail.com","contrasena":"Turista123"}` → copia `data.token`.
2. `GET /auth/me` → pestaña **Authorization** → tipo **Bearer Token** → pega el token → 200.
3. Sin token → 401 `NO_TOKEN`. Con un token alterado → 401 `INVALID_TOKEN`.
4. `POST /categorias` con el token de Ana → 403 `FORBIDDEN`.
5. Registra un usuario y repite el mismo correo → 409 `DUPLICATE`.

Crear un administrador nuevo:

```powershell
npm run admin -- "Rodrigo Ccahuana" rodrigo@cuscosmart.pe "Rodrigo2026"
```

## 🎓 Preguntas del profesor

**1. ¿Qué es un JWT y qué contiene?**
> Un token firmado con tres partes: cabecera, datos (*payload*) y firma. Nuestro payload lleva `sub` (el id del usuario), `rol`, `nombre` y la fecha de vencimiento. No está cifrado: cualquiera puede leerlo. Pero **no se puede modificar** sin el `JWT_SECRET`, porque la firma dejaría de coincidir.

**2. ¿Por qué no se guarda la contraseña?**
> Se guarda su **hash bcrypt**, que no se puede revertir. Al iniciar sesión, bcrypt compara la contraseña escrita con el hash. Si alguien roba la base, no obtiene las contraseñas.

**3. ¿Diferencia entre 401 y 403?**
> **401**: no sé quién eres (falta el token o no es válido). **403**: sé quién eres, pero tu rol no tiene permiso.

**4. ¿Por qué el mismo mensaje si falla el correo o la contraseña?**
> Para no revelar qué correos están registrados. Por la misma razón, si el correo no existe se compara igual contra un hash falso: el tiempo de respuesta es el mismo.

**5. ¿Para qué sirve el límite de 20 intentos?**
> Frena los ataques de fuerza bruta (probar miles de contraseñas). Pasado el límite responde 429 durante 15 minutos.

**6. ¿Cómo se crea el primer administrador si el registro solo crea turistas?**
> Con el script `npm run admin`, que se ejecuta en el servidor: registra al usuario y le cambia el rol con `sp_cambiar_rol_usuario`. Desde la web nadie puede volverse ADMIN solo.

# Fase 10: login con Google, más lugares y un front moderno

**Objetivo:** que la web se sienta como una app real: entrar con Google, ver hasta 5 fotos por lugar con zoom, un mapa grande con "cerca de mí", chat flotante, modo oscuro y 6 idiomas.

**Commits:** API `feat: login con Google, perfil editable, 27 atractivos…` · Web `feat: galería, mapa cerca de mí, chat flotante, idiomas y modo oscuro`

---

## 10.1 Lo que cambió en la API

| Cambio | Dónde | Por qué |
| --- | --- | --- |
| `POST /auth/google` | `auth.service.js` | Recibe el *ID token* de Google, **verifica su firma** con `google-auth-library` y entra (o crea la cuenta). |
| `GET /auth/config` | `auth.controller.js` | Le dice al front si Google está activo (si hay `GOOGLE_CLIENT_ID`). |
| `PUT /auth/me` | `sp_actualizar_perfil` | Editar nombre y teléfono. |
| `GET /auth/me` con totales | `sp_usuario_por_id` | Devuelve cuántos favoritos, viajes y reseñas tienes. |
| Límite de login por IP **y correo** | `limitadores.js` | Antes, la prueba del 429 de Postman bloqueaba a todos 15 minutos. Ahora solo cuentan los intentos **fallidos** de ese correo. |
| 27 atractivos, categoría "Calle y plaza", 5 fotos por lugar, 20 preguntas | `seed.sql` | Más contenido para el turista. |

### Activar el login con Google (5 minutos)

1. Entra a <https://console.cloud.google.com/apis/credentials> → **Crear credenciales → ID de cliente de OAuth**.
2. Tipo: **Aplicación web**. En *Orígenes de JavaScript autorizados* agrega `http://localhost:5173`.
3. Copia el ID (termina en `.apps.googleusercontent.com`) y pégalo en el `.env` de la API:
   ```
   GOOGLE_CLIENT_ID=123456-abc.apps.googleusercontent.com
   ```
4. Reinicia la API. El botón "Continuar con Google" se activa solo.

> Sin ese ID la web funciona igual: el botón aparece desactivado con el aviso "Falta configurar el ID de Google".

## 10.2 Lo que cambió en el front

| Archivo nuevo | Qué hace |
| --- | --- |
| `src/i18n.jsx` + `src/idiomas/*.js` | 6 idiomas (es, en, pt, fr, de, zh). `t('clave')` devuelve el texto en el idioma elegido. |
| `src/tema.jsx` + `src/tema.css` | Modo claro/oscuro. Solo se cambian los **tokens de color** (`--canvas`, `--tinta`…), por eso todo el sitio cambia a la vez. |
| `src/geo.js` | Pide tu ubicación y calcula distancias con Haversine (si no estás en Cusco, mide desde la Plaza de Armas). |
| `components/Galeria.jsx` | Mosaico de hasta 5 fotos y visor a pantalla completa con zoom (clic, rueda, arrastrar, flechas). |
| `pages/MapaCerca.jsx` | Sección **Mapa**: lista de lugares por cercanía a la izquierda; al elegir uno, el mapa vuela hasta él. |
| `components/ChatFlotante.jsx` | El asistente ahora es un chat flotante (¼ de pantalla) disponible en todas las páginas. |
| `components/BotonGoogle.jsx` | Botón oficial de Google (Google Identity Services). |
| `pages/Perfil.jsx` | Se abre al tocar tu nombre: datos, totales y edición. |
| `ui/Desplegable.jsx` | Desplegable propio con efecto vidrio, usable con teclado (↑ ↓ Enter Esc). |

**Efecto "liquid glass":** es la clase `.vidrio` = fondo semitransparente + `backdrop-filter: blur() saturate()` + un borde claro + un brillo interior (`inset` box-shadow). Se ve mejor porque detrás hay un fondo con degradados suaves.

**Mapa:** zoom con la rueda del ratón (antes estaba desactivado), botones de zoom grandes, tu ubicación con un punto azul que late y ventanitas con foto. En modo oscuro las capas de OpenStreetMap se oscurecen con un filtro CSS (`invert + hue-rotate`), sin pedir otra capa.

## 10.3 Probar

```powershell
cd $HOME\Desktop\cuscosmart-api; npm run db:reset; npm run dev     # ventana 1
cd $HOME\Desktop\cuscosmart-web; npm run dev                       # ventana 2
```

1. Explorar → orden **Más cercanos** (cada tarjeta muestra los metros o km).
2. Abre **Iglesia de la Compañía** → toca una foto → acerca con la rueda.
3. **Mapa** → elige un lugar de la lista.
4. Botón **¿Dudas?** → "¿cuánto cuesta el boleto turístico?".
5. Idioma **EN** y la luna (modo oscuro).
6. Ingresa como Turista → toca tu nombre → **Mi perfil** → Editar.

## 🎓 Preguntas del profesor

**1. ¿Cómo sabe la API que el token de Google es real?**
> `verifyIdToken` descarga las claves públicas de Google y comprueba la firma, la fecha de vencimiento y que el token sea para **nuestro** `GOOGLE_CLIENT_ID`. Si alguien inventa un token, la firma no coincide y respondemos 401.

**2. ¿Y la contraseña de quien entra con Google?**
> Se guarda una contraseña aleatoria encriptada con bcrypt que nadie conoce. Esa persona siempre entra con Google.

**3. ¿Por qué el límite de intentos es por IP y correo?**
> Para frenar la fuerza bruta contra **una cuenta** sin castigar a todos los que comparten la misma red (el wifi del aula). Y los intentos correctos no cuentan.

**4. ¿Cómo se traduce la página?**
> Los textos de la interfaz están en un archivo por idioma con las mismas claves. Los datos de la base (nombres y descripciones) siguen en español; en el detalle hay un enlace para traducir la descripción con Google Translate.

**5. ¿Cómo cambia todo el sitio a modo oscuro?**
> El CSS usa variables (`var(--canvas)`, `var(--tinta)`…). El modo oscuro solo redefine esas variables bajo `[data-theme='dark']`, y un script pequeño en `index.html` aplica el tema guardado antes de pintar para que no haya un destello blanco.

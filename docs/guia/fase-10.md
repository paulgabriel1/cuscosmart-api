# Fase 10: login con Google, más lugares y un front moderno

**Objetivo:** que la web se sienta como una app real: entrar con Google, ver hasta 5 fotos por lugar con zoom, un mapa grande con "cerca de mí", chat flotante y modo oscuro.

**Commits:** API `feat: login con Google, perfil editable, 27 atractivos y límite de intentos por correo` · Web `feat: galería con zoom, mapa cerca de mí, chat flotante, 6 idiomas y modo oscuro`

---

## 10.1 Lo que cambió en la API

| Cambio | Dónde | Por qué |
| --- | --- | --- |
| `POST /auth/google` | `auth.service.js` | Recibe el *ID token* de Google, **verifica su firma** con `google-auth-library` y entra (o crea la cuenta). |
| `GET /auth/config` | `auth.controller.js` | Le dice al front si Google está activo (si hay `GOOGLE_CLIENT_ID`). |
| `PUT /auth/me` | `sp_actualizar_perfil` | Editar nombre y teléfono. |
| `GET /auth/me` con totales | `sp_usuario_por_id` | Devuelve cuántos favoritos, viajes y reseñas tienes. |
| Límite de login por IP **y correo** | `limitadores.js` | Antes, la prueba del 429 de Postman bloqueaba a todos. Ahora solo cuentan los intentos **fallidos** de ese correo. |
| 27 atractivos, categoría "Calle y plaza", hasta 5 fotos por lugar, 20 preguntas | `seed.sql` | Más contenido para el turista. |

### Activar el login con Google (5 minutos)

1. Entra a <https://console.cloud.google.com/apis/credentials> → **Crear credenciales → ID de cliente de OAuth**.
2. Tipo: **Aplicación web**. En *Orígenes de JavaScript autorizados* agrega `http://localhost:5173`.
3. Copia el ID (termina en `.apps.googleusercontent.com`) y pégalo en el `.env` de la API:
   ```
   GOOGLE_CLIENT_ID=123456-abc.apps.googleusercontent.com
   ```
4. Reinicia la API. El botón "Continuar con Google" aparece solo.

> Sin ese ID la web funciona igual. El botón de Google no aparece y puedes entrar con correo y contraseña.

## 10.2 Lo que cambió en la web

| Archivo nuevo | Qué hace |
| --- | --- |
| `i18n.jsx` + `es.js` y `en.js` | Textos en español e inglés. `t('clave')` devuelve el texto del idioma elegido. Se empezó con 6 idiomas; la fase 12 dejó estos dos. |
| `tema.jsx` + `tema.css` | Modo claro/oscuro. Solo cambian los **tokens de color** (`--canvas`, `--tinta`…), así todo el sitio cambia a la vez. |
| `geo.js` | Pide tu ubicación y calcula distancias con Haversine. Si no estás en Cusco, mide desde la Plaza de Armas. |
| `Galeria.jsx` | Mosaico de hasta 5 fotos y visor a pantalla completa con zoom (clic, rueda, arrastrar, flechas). |
| `MapaCerca.jsx` | Sección **Mapa**: lista por cercanía a la izquierda. Al elegir un lugar, el mapa vuela hasta él. |
| `ChatFlotante.jsx` | El asistente es un chat flotante disponible en todas las páginas. |
| `BotonGoogle.jsx` | Botón oficial de Google (Google Identity Services). |
| `Perfil.jsx` | Se abre al tocar tu nombre: datos, totales y edición. |
| `Desplegable.jsx` | Desplegable con efecto vidrio, usable con teclado (↑ ↓ Enter Esc). |

**Efecto "liquid glass":** es la clase `.vidrio`. Tiene fondo semitransparente, `backdrop-filter: blur() saturate()`, un borde claro y un brillo interior (`inset` en `box-shadow`). Se ve mejor porque detrás hay degradados suaves.

**Mapa:** usa OpenStreetMap, que es gratis y no pide clave. El zoom funciona con la rueda del ratón y hay botones grandes. Tu ubicación aparece como un punto azul, y los lugares tienen ventanitas con foto. En modo oscuro, un filtro CSS (`invert + hue-rotate`) oscurece el mapa sin pedir otra capa.

## 10.3 Probar

```powershell
cd $HOME\Desktop\cuscosmart-api; npm run db:reset; npm run dev     # ventana 1
cd $HOME\Desktop\cuscosmart-web; npm run dev                       # ventana 2
```

1. Explorar → orden **Más cercanos**. Cada tarjeta muestra los metros o km.
2. Abre **Iglesia de la Compañía de Jesús** → toca una foto → acerca con la rueda.
3. **Mapa** → elige un lugar de la lista.
4. Botón **¿Dudas?** → "¿cuánto cuesta el boleto turístico?".
5. Cambia el idioma a **EN** y usa el icono de luna (modo oscuro).
6. Crea una cuenta o entra con Google → toca tu nombre → **Mi perfil** → **Editar perfil**.

## 🎓 Preguntas del profesor

**1. ¿Cómo sabe la API que el token de Google es real?**
> `verifyIdToken` descarga las claves públicas de Google y comprueba la firma, la fecha de vencimiento y que el token sea para **nuestro** `GOOGLE_CLIENT_ID`. Si el token no es válido, respondemos 401.

**2. ¿Y la contraseña de quien entra con Google?**
> Se guarda una contraseña aleatoria encriptada con bcrypt que nadie conoce. Esa persona siempre entra con Google.

**3. ¿Por qué el límite de intentos es por IP y correo?**
> Para frenar la fuerza bruta contra **una cuenta** sin castigar a quienes comparten la misma red (el wifi del aula). Los intentos correctos no cuentan.

**4. ¿Cómo se traduce la página?**
> Hay un archivo por idioma (`es.js` y `en.js`) con las mismas claves. Si falta una clave en inglés, se usa la de español. Los datos de la base (nombres y descripciones) siguen en español. En el detalle hay un enlace para traducir la descripción con Google Translate.

**5. ¿Cómo cambia todo el sitio a modo oscuro?**
> El CSS usa variables (`var(--canvas)`, `var(--tinta)`…). El modo oscuro solo redefine esas variables bajo `[data-theme='dark']`. Un script pequeño en `index.html` aplica el tema guardado antes de pintar, así no hay un destello blanco.

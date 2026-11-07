# Fase 13: fotos desde la PC o desde un link, foto de perfil y la web en el celular

**Objetivo:** que el admin suba fotos reales, que el turista ponga su foto de perfil y que la web se pruebe desde un celular.

**Commits:** API `feat: subir fotos desde la PC o desde un link, y foto de perfil opcional` · API `docs: cómo probar la web desde el celular (Wi-Fi y túnel HTTPS)` · Web `feat: admin sube fotos (PC + links), carrusel de portada, mapa con estilos y foto de perfil` · Web `feat: abrir la web desde el celular (proxy de Vite a la API y túnel HTTPS con npm run celular)`

---

## 13.1 Lo que cambió en la API

| Endpoint | Quién | Qué hace |
| --- | --- | --- |
| `POST /atractivos/:id/fotos/subir` | ADMIN | Recibe hasta 5 imágenes en el campo `fotos`, de 5 MB cada una. |
| `POST /atractivos/:id/fotos/url` | ADMIN | La API **descarga** la imagen desde un link. |
| `PUT /auth/me/foto` | Con sesión | Sube tu foto de perfil (campo `foto`). |
| `DELETE /auth/me/foto` | Con sesión | Quita tu foto de perfil. |

**Cómo se guardan:** las fotos van a la carpeta `uploads/fotos/`. La base solo guarda la ruta, por ejemplo `uploads/fotos/abc.jpg`. La carpeta `uploads/` está en `.gitignore`, así que las fotos no se suben a GitHub.

**Cómo se revisa el archivo:** la API no confía en la extensión ni en el tipo que dice el navegador. Mira los **primeros bytes** del archivo (su firma). Si no es JPG, PNG, WEBP o GIF, responde 400.

**Foto desde un link:**

- Si el link es una imagen, se descarga.
- Si el link es una página, la API usa su `og:image`, la foto que WhatsApp muestra en la vista previa.
- Si no hay foto, responde 400 y explica cómo copiar la dirección de la imagen.

**Protección SSRF:** un usuario malintencionado podría hacer que la API descargue algo de su propia red (`localhost`, `192.168.x.x`). Por eso la API:

1. Resuelve el nombre del sitio y **rechaza** las IP privadas.
2. Revisa cada redirección (máximo 3) y corta la descarga a los 10 segundos.

## 13.2 Lo que cambió en la web

| Archivo | Qué hace |
| --- | --- |
| `SubirFotos.jsx` | El admin arrastra o elige varias fotos de la PC, o pega links. Muestra una vista previa y el resultado de cada foto. |
| `AdminAtractivos.jsx` | Mosaico de fotos con **portada**. Al crear un lugar se abre directo la ventana de fotos. |
| `CarruselPortada.jsx` | La portada de Explorar es un carrusel con fotos de los lugares. Se pausa al pasar el mouse. |
| `Mapa.jsx` | Estilos **Calles**, **Satélite** y **Relieve**. Botón **mi ubicación** y zoom arriba a la izquierda. Cada lugar tiene enlaces a **Google Maps** y a **Google Earth** (vista 3D). |
| `Perfil.jsx` | Foto de perfil opcional: subir o quitar. También se ve en el menú (`Avatar.jsx`). |

## 13.3 Probar la web desde el celular

**Opción 1: misma red Wi-Fi.** Con la API y la web encendidas, abre en el celular `http://IP-de-la-PC:5173`. La IP de la PC se ve con `ipconfig`.

**Opción 2: túnel HTTPS.** En una tercera ventana:

```powershell
cd $HOME\Desktop\cuscosmart-web; npm run celular
```

La ventana muestra una dirección `https://...trycloudflare.com`. Ábrela en el celular, aunque no estés en la misma red.

Los pasos completos están en la [guía de instalación](../INSTALACION.md).

## 13.4 Probar

1. Como admin: **Admin → Atractivos** → edita un lugar → sube 2 fotos de la PC.
2. Pega un link de una página con foto. La API la descarga.
3. **Explorar**: el carrusel cambia solo y se pausa al pasar el mouse.
4. **Mapa** → **Satélite** → **Relieve** → **mi ubicación**.
5. **Mi perfil** → sube una foto. Mírala en el menú. Luego prueba la web en el celular.

## 🎓 Preguntas del profesor

**1. ¿Cómo sabe la API que un archivo es una imagen?**
> Revisa los primeros bytes (la firma). La extensión `.jpg` o el tipo que envía el navegador se pueden falsificar.

**2. ¿Qué es SSRF y cómo lo evita la API?**
> Es cuando el servidor descarga algo de su propia red. La API rechaza IP privadas antes de descargar y revisa cada redirección.

**3. ¿Por qué la foto de perfil no cambió el diagrama ER?**
> El archivo se llama con el id del usuario: `uploads/perfiles/<id>.<ext>`. La API busca esa foto con ese nombre, así que no hace falta una columna nueva.

**4. ¿Por qué la web pide `/api` y `/uploads` a su mismo servidor?**
> Vite reenvía esas rutas a la API (puerto 3000). Así no hay problemas de CORS, y funciona igual desde la PC, el celular o el túnel.

**5. ¿Quién puede subir fotos de un atractivo?**
> Solo el ADMIN. La ruta usa el middleware `soloAdmin`. Cualquier turista puede cambiar su propia foto de perfil.

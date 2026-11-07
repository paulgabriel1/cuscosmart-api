# Instalar y correr CuscoSmart IA (desde cero)

Sigue los pasos **en orden**. Copia **un comando a la vez** en PowerShell y presiona **Enter**.
✅ = lo que debe salir · ❌ = si sale un error, mira la tabla [Problemas](#7-problemas).

| Parte | Carpeta | Dirección |
| --- | --- | --- |
| API (el cerebro) | `cuscosmart-api` | `http://localhost:3000` |
| Web (lo que ves) | `cuscosmart-web` | `http://localhost:5173` ← esta abres en el navegador |

---

## 1. Instalar programas (una sola vez)

| Programa | Descarga | Para qué |
| --- | --- | --- |
| XAMPP | <https://www.apachefriends.org/es/> | Base de datos MySQL. Instálalo en `C:\xampp` |
| Node.js **LTS** | <https://nodejs.org/es> | Corre la API y la web |
| Git | <https://git-scm.com/download/win> | Descarga el proyecto |
| VS Code (opcional) | <https://code.visualstudio.com/> | Editar archivos |

En todos: **Siguiente** con las opciones por defecto. Luego **cierra y vuelve a abrir PowerShell** y comprueba:

```powershell
node -v
npm -v
git --version
```
✅ Salen números de versión (Node 20 o más).
❌ `npm.ps1 no se puede cargar…` → ejecuta esto, escribe `S` y Enter:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## 2. Descargar el proyecto (una sola vez)

Primero acepta la invitación de GitHub que llegó a tu correo (los repos son privados).

```powershell
cd $HOME\Desktop
git clone https://github.com/paulgabriel1/cuscosmart-api.git
git clone https://github.com/paulgabriel1/cuscosmart-web.git
```
✅ En el Escritorio aparecen las carpetas `cuscosmart-api` y `cuscosmart-web`.
(Si te lo pasaron en un USB: copia las dos carpetas al Escritorio y sigue en el paso 3.)

## 3. Prender MySQL

Abre **XAMPP Control Panel** → en **MySQL** clic en **Start**.
✅ MySQL se pone **verde**. No cierres XAMPP.

## 4. Preparar y prender la API — ventana 1

```powershell
cd $HOME\Desktop\cuscosmart-api
npm install
Copy-Item .env.example .env
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```
Copia el texto largo que salió y abre el `.env`:
```powershell
notepad .env
```
En la línea `JWT_SECRET=` borra lo que hay después del `=` y pega tu texto. Guarda (Ctrl + S) y cierra. No cambies nada más.

```powershell
npm run db:reset
```
✅ Termina con `atractivos 27` … `Base cuscosmart_db recreada`.

```powershell
npm run dev
```
✅ `Conectado a MySQL` y `API en http://localhost:3000/api/v1`.
**No cierres esta ventana.**

> `npm install`, el `.env` y `db:reset` se hacen **una sola vez** por PC.

## 5. Prender la web — ventana 2

Abre **otra** ventana de PowerShell:

```powershell
cd $HOME\Desktop\cuscosmart-web
npm install
npm run dev
```
✅ `Local: http://localhost:5173/`. **No cierres esta ventana.**

Abre **<http://localhost:5173>** en Chrome o Edge. También puedes **Explorar como invitado**, sin cuenta.

| Rol | Correo | Contraseña |
| --- | --- | --- |
| Administrador | admin@cuscosmart.pe | Admin12345 |
| Turista | ana@mail.com | Turista123 |

**Recorrido para presentar (5 min):**
1. **Explorar** → orden **Más cercanos** (distancias en m / km).
2. Abre un lugar → toca una foto → acerca con la rueda del ratón.
3. **Mapa** → elige un lugar → **Satélite** → **Google Maps** o **Ver en 3D**.
4. **¿Dudas?** → "¿cuánto cuesta el boleto turístico?".
5. Entra como **Turista** → **Mis viajes** → **Ordenar con IA** → **Marcar visitado** → **Reseñar**.
6. Toca tu nombre → **Mi perfil** (foto y **Mi recorrido**).
7. Entra como **Administrador** → **Admin** → crea un lugar y súbele fotos desde la PC o con un link.

**Para apagar:** Ctrl + C en cada ventana y **Stop** en MySQL.

## 6. Las siguientes veces

1. XAMPP → **Start** en MySQL.
2. Ventana 1: `cd $HOME\Desktop\cuscosmart-api` → `git pull` → `npm install` → `npm run dev`
3. Ventana 2: `cd $HOME\Desktop\cuscosmart-web` → `git pull` → `npm install` → `npm run dev`
4. Si el `git pull` trajo cambios en `database/`: apaga la API y ejecuta `npm run db:migrar` (actualiza **sin borrar** tus datos). Si igual no ves los 27 lugares, usa `npm run db:reset`.

> ⚠️ `db:reset` **borra** lo que creaste a mano (usuarios, viajes, fotos subidas) y deja los datos de prueba. Úsalo antes de presentar.

## 7. Problemas

| Lo que ves | Solución |
| --- | --- |
| `node` / `npm` / `git` "no se reconoce" | No está instalado, o no reabriste PowerShell |
| `npm.ps1 no se puede cargar` | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| `Repository not found` | Acepta la invitación de GitHub o inicia sesión con la cuenta invitada |
| `Faltan variables en el archivo .env` / `JWT_SECRET es muy corto` | Repite el paso 4 (`.env` y la clave larga) |
| `ECONNREFUSED` / no conecta a MySQL | XAMPP → Start en MySQL |
| MySQL no arranca (puerto 3306 ocupado) | Administrador de tareas → finaliza `mysqld.exe` → Start |
| `No se encontró MySQL en C:\xampp…` | `$env:MYSQL_BIN="D:\xampp\mysql\bin\mysql.exe"; npm run db:reset` (con tu ruta) |
| `Access denied for user 'cuscosmart_user'` | `npm run db:reset` |
| `Cannot find package …` | Falta `npm install` en esa carpeta |
| `EADDRINUSE 3000` o `Port 5173 is in use` | Ya está prendida en otra ventana |
| La web dice "No se pudo conectar con la API" | La ventana 1 (API) está cerrada o con error |
| Solo hay 14 lugares o faltan fotos | `npm run db:reset` y reinicia la API |
| "Demasiados intentos fallidos" | Espera 15 min o reinicia la API |
| El mapa sale gris | Falta internet (el mapa se descarga de OpenStreetMap) |
| La API se reinicia sola durante las pruebas | Usa `npm start` en lugar de `npm run dev` |

**Sin consola:** también puedes crear la base en <http://localhost/phpmyadmin> (Apache en Start) → **Importar** → `database/cuscosmart_todo.sql`.

---

## 8. Probar desde el celular

Con la API y la web prendidas en la PC:

**Opción A · mismo Wi-Fi (rápida, sin GPS)**
1. En la PC: `ipconfig` → copia la **Dirección IPv4** del Wi-Fi (ej. `192.168.100.4`).
2. En el celular: `http://192.168.100.4:5173`
3. Si Windows pregunta por Node.js → **Permitir**.

**Opción B · HTTPS (funciona el GPS y desde cualquier red)**
```powershell
cd $HOME\Desktop\cuscosmart-web
npm run celular
```
Abre en el celular el link `https://…trycloudflare.com` que aparece. Ciérralo con Ctrl + C al terminar: mientras esté abierto, el link es **público**.

> Los Wi-Fi de institutos suelen bloquear la opción A: usa la B.

## 9. (Opcional) "Continuar con Google"

Sin esto todo funciona; el botón de Google simplemente no aparece.

1. <https://console.cloud.google.com/> → **Proyecto nuevo** (`CuscoSmart`).
2. **APIs y servicios → Pantalla de consentimiento de OAuth** → Externo → nombre de la app y tu correo → guarda. En **Usuarios de prueba** agrega los Gmail que van a probar.
3. **Credenciales → Crear credenciales → ID de cliente de OAuth** → **Aplicación web** → en *Orígenes de JavaScript autorizados* agrega `http://localhost:5173`.
4. Copia el ID (termina en `.apps.googleusercontent.com`) en el `.env` de la API: `GOOGLE_CLIENT_ID=…`
5. Reinicia la API.

## 10. Pruebas automáticas (para el profesor)

```powershell
cd $HOME\Desktop\cuscosmart-api
npm run db:reset
npm start            # en la ventana 1, en lugar de npm run dev
npm run test:api     # en otra ventana
```
✅ `Peticiones: 149 · Pruebas: 456 aprobadas, 0 fallidas`

**En Postman:** **Import** → `postman/cuscosmart.collection.json` → **Run collection**.
Las pruebas cambian datos: al terminar, ejecuta `npm run db:reset` otra vez.

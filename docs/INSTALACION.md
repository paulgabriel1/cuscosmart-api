# Cómo correr CuscoSmart IA paso a paso (desde cero)

Esta guía es para alguien que **nunca** ha hecho esto. Sigue los pasos **en orden** y no te saltes ninguno.
Al final tendrás la web abierta en el navegador. Toma entre 20 y 40 minutos la primera vez y 2 minutos las siguientes.

> **Cómo leer esta guía**
> - Lo que está en un recuadro gris es un **comando**: cópialo, pégalo en PowerShell y presiona **Enter**.
> - Pega **un comando a la vez** y espera a que termine (vuelve a aparecer `PS C:\...>`).
> - ✅ = lo que deberías ver si todo salió bien. ❌ = qué hacer si sale un error.
> - Si algo falla, busca el mensaje en la tabla **[Problemas comunes](#9-problemas-comunes)** al final.

---

## 0. Lo que vas a usar (en palabras simples)

| Programa | Para qué sirve |
| --- | --- |
| **XAMPP** | Trae **MySQL**, la base de datos donde se guardan los lugares, usuarios y viajes. |
| **Node.js** | Ejecuta el código JavaScript de la **API** (el "cerebro") y de la **web**. |
| **Git** | Descarga el proyecto desde GitHub y trae las actualizaciones. |
| **VS Code** | Editor para abrir y modificar archivos (lo usamos para el `.env`). |
| **PowerShell** | La ventana azul/negra donde escribes los comandos. Ya viene con Windows. |

El proyecto tiene **dos partes** que se prenden por separado:
- **API** (`cuscosmart-api`) → corre en `http://localhost:3000`
- **Web** (`cuscosmart-web`) → corre en `http://localhost:5173` ← esta es la que abres en el navegador

---

## 1. Instalar los programas (solo la primera vez)

> En las PC de SENATI, revisa primero si ya están instalados (paso 1.5). Si ya están, salta al paso 2.

### 1.1 XAMPP
1. Entra a <https://www.apachefriends.org/es/> y descarga **XAMPP para Windows**.
2. Abre el instalador → **Next** en todo. Déjalo en `C:\xampp` (no cambies la carpeta).
3. Si Windows pregunta por el Firewall, marca **Permitir acceso**.

### 1.2 Node.js
1. Entra a <https://nodejs.org/es> y descarga la versión **LTS** (botón verde).
2. Instala con **Siguiente** en todo.

### 1.3 Git
1. Entra a <https://git-scm.com/download/win> → **Click here to download**.
2. Instala con **Next** en todo (las opciones por defecto están bien).

### 1.4 VS Code (opcional pero recomendado)
1. <https://code.visualstudio.com/> → **Download for Windows** → instala.
2. Marca la casilla **"Agregar a PATH"** durante la instalación.

### 1.5 Comprobar que todo quedó instalado
1. **Cierra** todas las ventanas de PowerShell que tengas abiertas (importante: así reconocen los programas nuevos).
2. Abre PowerShell: tecla **Windows** → escribe `powershell` → **Enter**.
3. Pega estos comandos uno por uno:

```powershell
node -v
```
✅ Sale algo como `v20.11.0` o `v22.x.x` (cualquier número desde 20 sirve).

```powershell
npm -v
```
✅ Sale un número como `10.2.4`.
❌ Si sale **"npm.ps1 no se puede cargar porque la ejecución de scripts está deshabilitada"**, pega esto, presiona Enter y escribe `S` si pregunta:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```
Luego vuelve a probar `npm -v`.

```powershell
git --version
```
✅ Sale `git version 2.xx.x`.

❌ Si dice **"no se reconoce como nombre de un cmdlet"**: ese programa no se instaló bien, o no cerraste PowerShell después de instalarlo. Ciérralo, ábrelo de nuevo y prueba otra vez.

---

## 2. Descargar el proyecto (solo la primera vez)

> Los repositorios son **privados**. Primero acepta la invitación de GitHub que te llegó al correo (o pídela a Gabriel).

En PowerShell, pega uno por uno:

```powershell
cd $HOME\Desktop
```
(Esto te lleva al Escritorio.)

```powershell
git clone https://github.com/paulgabriel1/cuscosmart-api.git
```
```powershell
git clone https://github.com/paulgabriel1/cuscosmart-web.git
```

- Si se abre una ventana de GitHub pidiendo iniciar sesión → elige **Sign in with your browser** y acepta.
- ✅ En tu Escritorio aparecen **dos carpetas**: `cuscosmart-api` y `cuscosmart-web`.
- ❌ `Repository not found` → todavía no aceptaste la invitación, o iniciaste sesión con otra cuenta de GitHub.
- ❌ `already exists and is not an empty directory` → ya lo habías descargado antes: ve al **paso 8** (actualizar).

---

## 3. Prender la base de datos (MySQL)

1. Abre **XAMPP Control Panel** (búscalo en el menú Inicio como "XAMPP").
2. En la fila **MySQL**, haz clic en **Start**.
3. ✅ La palabra **MySQL** se pone **verde** y aparece un número de puerto (`3306`).

❌ Si se pone roja o dice `Port 3306 in use`: ya hay otro MySQL abierto. Abre el **Administrador de tareas** (Ctrl + Shift + Esc), busca `mysqld.exe`, clic derecho → **Finalizar tarea**, y vuelve a dar **Start**.

> **No cierres XAMPP** mientras uses el proyecto. Apache **no** hace falta.

---

## 4. Preparar la API (solo la primera vez)

### 4.1 Instalar las librerías

En PowerShell:

```powershell
cd $HOME\Desktop\cuscosmart-api
```
```powershell
npm install
```
✅ Tarda 1-2 minutos y termina con algo como `added 250 packages` (puede decir `found 0 vulnerabilities`).
Los avisos amarillos (`npm warn`) **no son errores**, ignóralos.

### 4.2 Crear el archivo de configuración `.env`

El `.env` guarda las contraseñas y claves. No viene en GitHub por seguridad: lo creas tú copiando el ejemplo.

```powershell
Copy-Item .env.example .env
```

Ahora genera una clave secreta para los inicios de sesión:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```
✅ Sale una línea larga de letras y números, por ejemplo `3f9a1c...e07b`. **Selecciónala y cópiala** (Ctrl + C, o clic derecho).

Abre el `.env` para pegarla:

```powershell
code .env
```
(Si no tienes VS Code, usa: `notepad .env`)

Busca la línea:
```
JWT_SECRET=pega_aqui_un_texto_largo_aleatorio_de_al_menos_32_caracteres
```
y reemplaza **todo lo que está después del `=`** por lo que copiaste. Debe quedar así (con tu propio texto):
```
JWT_SECRET=3f9a1c8b...e07b
```
**Guarda** el archivo (Ctrl + S) y ciérralo. **No cambies nada más**: los demás valores ya sirven.

> `GOOGLE_CLIENT_ID` puede quedar **vacío**. Solo hace falta para el botón "Continuar con Google" (ver [paso 10](#10-opcional-activar-continuar-con-google)).

### 4.3 Crear la base de datos con todos los datos

```powershell
npm run db:reset
```
✅ Debe terminar así:
```
✅ database/cuscosmart_todo.sql armado (5 archivos)
objeto          cantidad
tablas          11
procedimientos  53
...
atractivos      27
usuarios        2
preguntas       20
✅ Base cuscosmart_db recreada. Reinicia la API si estaba encendida.
```
❌ `No se encontró MySQL en C:\xampp\mysql\bin\mysql.exe` → tu XAMPP está en otra carpeta. Ejemplo si está en el disco D:
```powershell
$env:MYSQL_BIN="D:\xampp\mysql\bin\mysql.exe"; npm run db:reset
```
❌ `Can't connect to MySQL server` → MySQL no está prendido (vuelve al **paso 3**).

> **Plan B sin consola:** abre <http://localhost/phpmyadmin> (necesita Apache en Start), pestaña **Importar** → elige el archivo `database/cuscosmart_todo.sql` → **Continuar**.

---

## 5. Prender la API

En la **misma** ventana de PowerShell:

```powershell
npm run dev
```
✅ Debe decir:
```
✅ Conectado a MySQL
🚀 API en http://localhost:3000/api/v1
```

> ⚠️ **Deja esta ventana abierta** todo el tiempo. Si la cierras, la API se apaga y la web dirá "No se pudo conectar con la API".

Compruébalo en el navegador (Chrome o Edge):
- <http://localhost:3000/api/v1/health> → ✅ `{"ok":true,"data":{"status":"up","db":"up"}}`
- <http://localhost:3000/api/v1/docs> → ✅ la documentación Swagger (para mostrar al profesor).

---

## 6. Preparar y prender la web

Abre una **segunda** ventana de PowerShell (Windows → `powershell` → Enter). No uses la de la API.

```powershell
cd $HOME\Desktop\cuscosmart-web
```
```powershell
npm install
```
✅ Termina con `added ... packages`.

```powershell
npm run dev
```
✅ Debe decir:
```
  VITE v7.x  ready in 500 ms
  ➜  Local:   http://localhost:5173/
```

> ⚠️ **Deja también esta ventana abierta.** Ahora tienes **dos** ventanas de PowerShell abiertas: una con la API y otra con la web.

---

## 7. Usar la web

Abre **<http://localhost:5173>** en Chrome o Edge.

Usuarios de prueba (escríbelos en **Ingresar**; también puedes **Explorar como invitado** sin cuenta):

| Rol | Correo | Contraseña |
| --- | --- | --- |
| Administrador | admin@cuscosmart.pe | Admin12345 |
| Turista | ana@mail.com | Turista123 |

### Recorrido para la presentación (5 minutos)
1. **Explorar** → en el desplegable **Recomendados** elige **Más cercanos**: cada tarjeta muestra los metros o km. (Si el navegador pide tu ubicación, dale **Permitir**.)
2. Abre **Iglesia de la Compañía de Jesús** → haz clic en una foto → acerca con la **rueda del ratón** y arrastra. Flechas ← → para cambiar de foto. **Esc** para cerrar.
3. Menú **Mapa** → toca un lugar de la lista de la izquierda: el mapa vuela hasta él.
4. Botón naranja **¿Dudas?** (abajo a la derecha) → escribe `¿cuánto cuesta el boleto turístico?`.
5. Arriba a la derecha: **ES** → cambia a **English**; la **luna** → modo oscuro.
6. **Ingresar** → escribe `ana@mail.com` / `Turista123` → toca **Ana** (arriba a la derecha) → **Mi perfil**: ahí está **Mi recorrido**, la línea de tiempo con los lugares visitados (toca el círculo para marcar o desmarcar).
7. **Mis viajes** → abre "Mi primer día en Cusco" → **Ordenar con IA** → **Visitado** → **Reseñar**.
8. Cierra sesión y entra como **Administrador** → menú **Admin** (crear/editar lugares, fotos y preguntas).

### Apagar todo al terminar
1. En cada ventana de PowerShell presiona **Ctrl + C** (si pregunta, escribe `S` y Enter).
2. En XAMPP, clic en **Stop** en MySQL.

---

## 8. Las siguientes veces (o después de que alguien subió cambios)

1. XAMPP → **Start** en MySQL.
2. **Ventana 1 (API):**
   ```powershell
   cd $HOME\Desktop\cuscosmart-api
   git pull
   npm install
   npm run dev
   ```
3. **Ventana 2 (web):**
   ```powershell
   cd $HOME\Desktop\cuscosmart-web
   git pull
   npm install
   npm run dev
   ```
4. Abre <http://localhost:5173>.

> Si `git pull` trajo cambios en la carpeta `database`, apaga la API (Ctrl + C), ejecuta **una vez** `npm run db:migrar` (actualiza la base **sin borrar** tus datos) y vuelve a `npm run dev`. Si no ves los 27 lugares, usa `npm run db:reset`.
> ⚠️ `db:reset` **borra y recrea** la base: se pierden los usuarios, viajes y reseñas que creaste a mano.

❌ `git pull` dice `Your local changes would be overwritten`: modificaste algún archivo. Si no te importa perder tus cambios:
```powershell
git stash
git pull
```

---

## 9. Problemas comunes

| Lo que ves | Qué hacer |
| --- | --- |
| `npm.ps1 no se puede cargar ... ejecución de scripts está deshabilitada` | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` (escribe `S`) y vuelve a intentar |
| `node`, `npm` o `git` "no se reconoce como nombre de un cmdlet" | No está instalado o no reabriste PowerShell después de instalarlo (paso 1) |
| `Faltan variables en el archivo .env` | No creaste el `.env`: paso 4.2 |
| `JWT_SECRET es muy corto` | No pegaste la clave larga en `.env`: paso 4.2 |
| `No se pudo conectar a MySQL` / `ECONNREFUSED` | XAMPP → **Start** en MySQL (paso 3) |
| `Access denied for user 'cuscosmart_user'` | Ejecuta `npm run db:reset` (crea ese usuario) |
| MySQL no arranca / `Port 3306 in use` / `ibdata1 must be writable` | Hay otro MySQL abierto: Administrador de tareas → finaliza `mysqld.exe` → Start de nuevo |
| `EADDRINUSE :::3000` | Ya hay una API abierta en otra ventana: ciérrala o usa esa |
| `Port 5173 is in use` | Ya hay una web abierta en otra ventana: ciérrala o usa esa |
| `Cannot find package 'google-auth-library'` (o cualquier `Cannot find package`) | Faltó `npm install` después del `git pull` |
| La web dice **"No se pudo conectar con la API"** | La ventana de la API está cerrada o con error: paso 5 |
| La web carga pero sin lugares / faltan fotos / solo hay 14 lugares | `npm run db:reset` en la API y reinicia la API |
| Login dice **"Demasiados intentos fallidos con este correo"** | Fallaste 10 veces con ese correo: espera 15 minutos o reinicia la API (Ctrl + C y `npm run dev`) |
| El botón **Continuar con Google** sale gris | Es normal: falta `GOOGLE_CLIENT_ID` en el `.env` (opcional, paso 10) |
| El mapa sale gris o sin calles | Falta internet: el mapa se descarga de OpenStreetMap |
| "Cerca de ti" mide desde la Plaza de Armas | No diste permiso de ubicación o no estás en Cusco: es lo esperado |
| Cambié el `.env` y no hace caso | Apaga la API (Ctrl + C) y vuelve a `npm run dev` |
| `npm run test:api` da muchos `429` | La corriste dos veces seguidas: reinicia la API y córrela una sola vez |

---

## 10. (Opcional) Activar "Continuar con Google"

Hazlo **una sola vez** con tu cuenta de Google (toma unos 5 minutos):

1. Entra a <https://console.cloud.google.com/> e inicia sesión con tu Gmail.
2. Arriba, en el selector de proyectos → **Proyecto nuevo** → nombre `CuscoSmart` → **Crear** → selecciónalo.
3. Menú ☰ → **APIs y servicios** → **Pantalla de consentimiento de OAuth** → tipo **Externo** → llena el nombre de la app (`CuscoSmart IA`) y tu correo → **Guardar y continuar** hasta terminar. En **Usuarios de prueba** agrega los Gmail que van a probar.
4. Menú ☰ → **APIs y servicios** → **Credenciales** → **+ Crear credenciales** → **ID de cliente de OAuth**.
5. Tipo de aplicación: **Aplicación web**. En **Orígenes de JavaScript autorizados** → **+ Agregar URI** → `http://localhost:5173` → **Crear**.
6. Copia el **ID de cliente** (termina en `.apps.googleusercontent.com`).
7. Abre `cuscosmart-api\.env` y pégalo:
   ```
   GOOGLE_CLIENT_ID=123456789-abcdef.apps.googleusercontent.com
   ```
8. Guarda, apaga la API (Ctrl + C) y vuelve a `npm run dev`.
9. ✅ En <http://localhost:5173/acceso> aparece el botón azul/blanco de Google con tus cuentas.

> Si lo usas en otra PC, copia la misma línea en el `.env` de esa PC. El ID no es secreto, pero igual **no lo subas** a GitHub (el `.env` ya está ignorado).

---

## 11. Probar la API automáticamente (para el profesor)

Con la API prendida, en una **tercera** ventana:

```powershell
cd $HOME\Desktop\cuscosmart-api
npm run db:reset
```
Reinicia la API (en su ventana: Ctrl + C y `npm run dev`). Luego, en la tercera ventana:
```powershell
npm run test:api
```
✅ Al final: `Peticiones: 121 · Pruebas: 368 aprobadas, 0 fallidas`

**En Postman:** **Import** → elige `postman/cuscosmart.collection.json` → clic derecho en la colección → **Run collection** → **Run**. Deja **No Environment**.

> Las pruebas modifican la base. Antes de la presentación vuelve a ejecutar `npm run db:reset` para dejar los datos limpios.

---

## 12. Probar desde el celular

La web ya está preparada: el celular solo abre la web y ella le pasa los pedidos a la API por dentro (proxy de Vite). **La API y la web deben estar prendidas en la PC** (pasos 5 y 6).

### Opción A — Mismo Wi-Fi (rápida)
1. La PC y el celular deben estar en el **mismo Wi-Fi**.
2. Averigua la IP de la PC en PowerShell:
   ```powershell
   ipconfig
   ```
   Busca **"Adaptador de LAN inalámbrica Wi-Fi" → Dirección IPv4**, por ejemplo `192.168.100.4`.
   (También la ves cuando haces `npm run dev` en la web, en la línea `➜  Network: http://192.168.x.x:5173/`.)
3. En el navegador del celular abre: **`http://192.168.100.4:5173`** (con tu IP).
4. Si Windows pregunta si permites el acceso a **Node.js**, marca **Redes privadas y públicas** → **Permitir**.

> Con la opción A todo funciona **menos "Usar mi ubicación"**: los celulares solo dan el GPS a páginas con **https://**. Para el GPS usa la opción B.

### Opción B — Con HTTPS (funciona el GPS y desde cualquier red, incluso con datos móviles)
1. Con la API y la web prendidas, abre una **tercera** ventana de PowerShell:
   ```powershell
   cd $HOME\Desktop\cuscosmart-web
   npm run celular
   ```
2. La primera vez descarga la herramienta (1 minuto). Luego aparece un recuadro con un link como:
   ```
   https://palabras-al-azar.trycloudflare.com
   ```
3. Abre **ese link** en el celular. Cuando pregunte por la ubicación → **Permitir**.
4. Para cerrarlo: **Ctrl + C** en esa ventana. El link deja de funcionar y cada vez sale uno nuevo.

> ⚠️ El link de la opción B es **público** mientras esté abierto: cualquiera que lo tenga puede ver la web. Ciérralo al terminar de probar.

| Problema en el celular | Solución |
| --- | --- |
| No carga `http://IP:5173` | Mismo Wi-Fi en los dos; revisa la IP con `ipconfig`; permite Node.js en el Firewall; algunos Wi-Fi públicos (como el de un instituto) bloquean conexiones entre equipos: usa la opción B |
| Carga pero dice "No se pudo conectar con la API" | La API (paso 5) está apagada en la PC |
| "Usar mi ubicación" no hace nada | Abriste por `http://`: usa la opción B (https) y acepta el permiso |

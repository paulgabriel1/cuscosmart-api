# Instalación de CuscoSmart IA en otra PC

Esta guía levanta la **API** (`cuscosmart-api`) y la **web** (`cuscosmart-web`) en cualquier computadora con Windows. Toma unos 15 minutos.

## 1. Requisitos

| Programa | Comprobar en PowerShell |
| --- | --- |
| [XAMPP](https://www.apachefriends.org/es/) (MySQL/MariaDB) | Abre el XAMPP Control Panel |
| [Node.js 20 o superior (LTS)](https://nodejs.org/es) | `node -v` |
| [Git](https://git-scm.com/download/win) | `git --version` |
| [Postman](https://www.postman.com/downloads/) | Abre Postman |

## 2. Descargar

Los repositorios son privados: primero acepta la invitación de GitHub que te llegó por correo.

```powershell
cd $HOME\Desktop
git clone https://github.com/paulgabriel1/cuscosmart-api.git
git clone https://github.com/paulgabriel1/cuscosmart-web.git
```

## 3. API

1. **XAMPP → Start MySQL** (debe quedar en verde).
2. En PowerShell:

```powershell
cd $HOME\Desktop\cuscosmart-api
npm install
Copy-Item .env.example .env
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

3. Abre el archivo `.env` (`code .env`) y pega el texto que imprimió el último comando en `JWT_SECRET=`. Los demás valores ya sirven tal cual.
4. Crea la base de datos y arranca la API:

```powershell
npm run db:reset
npm run dev
```

Resultado esperado:

```
✅ Base cuscosmart_db recreada.
✅ Conectado a MySQL
🚀 API en http://localhost:3000/api/v1
```

Comprueba en el navegador:
- http://localhost:3000/api/v1/health
- http://localhost:3000/api/v1/docs (Swagger)

> Si tu XAMPP no está en `C:\xampp`: `$env:MYSQL_BIN="D:\xampp\mysql\bin\mysql.exe"; npm run db:reset`.
> Sin consola: en phpMyAdmin → **Importar** → `database/cuscosmart_todo.sql`.

## 4. Web

En **otra** ventana de PowerShell (deja la API abierta):

```powershell
cd $HOME\Desktop\cuscosmart-web
npm install
npm run dev
```

Abre **http://localhost:5173**.

| Rol | Correo | Contraseña |
| --- | --- | --- |
| ADMIN | admin@cuscosmart.pe | Admin12345 |
| TURISTA | ana@mail.com | Turista123 |

## 5. Pruebas

```powershell
cd $HOME\Desktop\cuscosmart-api
npm run db:reset
# reinicia la API (Ctrl + C y npm run dev)
npm run test:api       # Esperado: 116 peticiones · 353 pruebas aprobadas · 0 fallidas
```

Para usar Postman: **Import** → `postman/cuscosmart.collection.json` → **Run collection**. Deja seleccionado **No Environment**.

## 6. Cada día de trabajo

1. XAMPP → **Start** MySQL.
2. `cd $HOME\Desktop\cuscosmart-api` y luego `git pull` y `npm run dev`.
3. En otra ventana: `cd $HOME\Desktop\cuscosmart-web` y luego `git pull` y `npm run dev`.

## 7. Problemas comunes

| Síntoma | Solución |
| --- | --- |
| `Faltan variables en el archivo .env` | Copia `.env.example` como `.env` (paso 3) |
| `JWT_SECRET es muy corto` | Genera uno con el comando del paso 3 |
| `No se pudo conectar a MySQL` / `ECONNREFUSED` | XAMPP → Start MySQL |
| `Access denied for user 'cuscosmart_user'` | Ejecuta `npm run db:reset`, que crea el usuario |
| MySQL no arranca o dice `ibdata1 must be writable` | Hay otro MySQL abierto: ciérralo en XAMPP o en el Administrador de tareas (`mysqld.exe`) |
| `EADDRINUSE :::3000` | Ya hay otra API abierta: cierra esa ventana |
| Login responde 429 | Pasaste el límite de intentos: reinicia la API |
| La web dice "No se pudo conectar con la API" | La API no está encendida (paso 3) |
| Cambié `.env` y no lo toma | Detén la API con **Ctrl + C** y vuelve a `npm run dev` |

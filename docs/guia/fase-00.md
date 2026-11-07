# Fase 0: preparar la PC, la carpeta y el repositorio

**Objetivo:** dejar listas las herramientas, la carpeta `cuscosmart-api` con su estructura y un repositorio **privado** en GitHub con el primer commit.

**Tiempo estimado:** 20 minutos.

---

## 0.1 Verificar las herramientas

Abre **PowerShell** y ejecuta una línea a la vez:

```powershell
node -v
npm -v
git --version
gh --version
C:\xampp\mysql\bin\mysql.exe --version
```

**Resultado esperado** (los números pueden variar):

```
v24.x.x            ← Node 20 o superior
10.x.x
git version 2.x
gh version 2.x
mysql  Ver 15.1 Distrib 10.x-MariaDB
```

| Herramienta | Para qué la usamos |
| --- | --- |
| **Node.js** | Ejecuta JavaScript fuera del navegador. Con él corre la API. |
| **npm** | Instala librerías (Express, mysql2…). Viene con Node. |
| **Git** | Guarda la historia del proyecto en *commits*. |
| **gh** (GitHub CLI) | Maneja GitHub desde la terminal: crea repos e invita compañeros. |
| **MariaDB (XAMPP)** | La base de datos. XAMPP trae MariaDB, que es compatible con MySQL. |

Revisa también la identidad de Git. Es la firma que aparece en cada commit:

```powershell
git config --global user.name
git config --global user.email
```

Si sale vacío, configúrala una sola vez:

```powershell
git config --global user.name "Gabriel"
git config --global user.email "tu_correo@gmail.com"
```

Y confirma que `gh` tiene tu sesión iniciada:

```powershell
gh auth status
```

Debe decir `Logged in to github.com account paulgabriel1`. Si no, ejecuta `gh auth login` y sigue los pasos: **GitHub.com → HTTPS → Login with a web browser**.

---

## 0.2 Crear la estructura de carpetas

La carpeta `cuscosmart-api` ya existe, porque aquí está esta guía. Crea las demás carpetas:

```powershell
cd $HOME\Desktop\cuscosmart-api
New-Item -ItemType Directory -Force database, postman, scripts, src\config, src\middlewares, src\utils, src\schemas, src\services, src\controllers, src\routes | Out-Null
code .
```

`code .` abre la carpeta en VS Code. Debes ver esto:

```
cuscosmart-api/
├── database/        ← archivos .sql (fase 1)
├── docs/guia/       ← esta guía
├── postman/         ← colección de pruebas (fase 4 en adelante)
├── scripts/         ← utilidades, como crear el admin (fase 4)
└── src/
    ├── config/      ← lectura del .env y conexión a MySQL
    ├── middlewares/ ← filtros que corren antes del controlador: token, rol, validación, errores
    ├── utils/       ← funciones de apoyo
    ├── schemas/     ← reglas de validación de datos (zod)
    ├── services/    ← llaman a los procedimientos de MySQL
    ├── controllers/ ← reciben la petición y arman la respuesta
    └── routes/      ← qué URL va a qué controlador
```

> **Por qué tantas carpetas:** cada capa tiene **una sola responsabilidad**. Si algo falla en la base de datos, sabes que el problema está en `services` o en el `.sql`, no en las rutas. A esto se le llama **arquitectura en capas**.

Git no guarda carpetas vacías. Para que se suban desde ya, crea un archivo `.gitkeep` en cada una:

```powershell
"database","postman","scripts","src\config","src\middlewares","src\utils","src\schemas","src\services","src\controllers","src\routes" | ForEach-Object { New-Item -ItemType File -Force "$_\.gitkeep" | Out-Null }
```

---

## 0.3 Crear `.gitignore`

En VS Code, crea el archivo **`.gitignore`** en la raíz de `cuscosmart-api` y pega esto:

```gitignore
# Dependencias: se reinstalan con "npm install"
node_modules/

# Variables de entorno: tienen claves, NUNCA se suben
.env

# Archivos del sistema y del editor
.DS_Store
Thumbs.db
.vscode/
```

**Qué hace:** le dice a Git qué archivos **ignorar**.
- `node_modules` pesa cientos de MB y cualquiera lo regenera con `npm install`.
- `.env` tiene la contraseña de la base de datos y el secreto de los tokens. Si se sube a GitHub, cualquiera con acceso al repo los ve.

> ⚠️ **Deja una línea en blanco al final del archivo.** Si `.vscode/` queda pegado a la línea siguiente sin salto, Git puede leer mal la última regla.

---

## 0.4 Crear el `README.md` inicial

Crea **`README.md`** en la raíz:

```markdown
# CuscoSmart IA — API REST

Guía turística inteligente del Cusco: atractivos, favoritos, itinerarios ordenados por cercanía y reseñas verificadas.

- **Curso:** Fullstack Developer Software, SENATI
- **Integrantes:** Gabriel Paul Alata Condori · Rodrigo Ccahuana Mayo · Elizabeth Flores Vargas
- **Stack:** Node.js + Express 5 + MySQL (procedimientos almacenados) + JWT + zod

> En construcción. Avance por fases en [docs/guia](docs/guia/README.md).
```

El README es la **carta de presentación** del repo: lo primero que ve el profesor al abrirlo en GitHub.

---

## 0.5 Iniciar Git y hacer el primer commit

```powershell
git init -b main
git add .
git status
```

Revisa la salida de `git status` antes de seguir:

| Debe aparecer | No debe aparecer |
| --- | --- |
| `.gitignore`, `README.md`, `docs/guia/...`, los `.gitkeep` | `.env` ni `node_modules` |

Si todo está bien:

```powershell
git commit -m "chore: inicio del proyecto con estructura de carpetas y guía"
```

**Qué hace cada comando:**

| Comando | Qué hace |
| --- | --- |
| `git init -b main` | Convierte la carpeta en un repositorio, con la rama principal llamada `main` |
| `git add .` | Pone todos los archivos en el "escenario" (*staging*): elige qué entra al próximo commit |
| `git commit -m "..."` | Toma una **foto** del proyecto con un mensaje que explica el cambio |

**Formato del mensaje** (*Conventional Commits*): `tipo: descripción`.

| Tipo | Cuándo se usa |
| --- | --- |
| `feat` | Funcionalidad nueva |
| `fix` | Corrección |
| `docs` | Documentación |
| `chore` | Tareas de mantenimiento |
| `test` | Pruebas |
| `refactor` | Ordenar el código sin cambiar lo que hace |

---

## 0.6 Crear el repositorio privado en GitHub y subirlo

```powershell
gh repo create cuscosmart-api --private --source . --remote origin --push --description "API REST de CuscoSmart IA (Node.js, Express 5, MySQL con procedimientos almacenados, JWT, zod)"
```

**Qué hace:**
- crea el repo `paulgabriel1/cuscosmart-api` como **privado**;
- lo conecta a tu carpeta con el nombre `origin`;
- sube el commit (`--push`).

Comprueba que se subió:

```powershell
gh repo view --web
```

Se abre el navegador con tu repo: debes ver el README y la carpeta `docs`.

---

## 0.7 Cómo trabajaremos con ramas en cada fase

Desde la fase 1, cada fase se hace en su propia **rama**. Es una copia de trabajo paralela: si algo sale mal, `main` sigue intacta.

```powershell
git switch -c feature/fase-1          # 1. crear la rama y cambiarse a ella
#   ... crear archivos, probar ...
git add .
git commit -m "feat: base de datos cuscosmart_db"   # 2. guardar el avance
git switch main                       # 3. volver a main
git merge --no-ff feature/fase-1 -m "Merge branch 'feature/fase-1'"   # 4. unir la rama
git branch -d feature/fase-1          # 5. borrar la rama ya unida
git push                              # 6. subir a GitHub
```

`--no-ff` (*no fast-forward*) obliga a crear un commit de unión. Así, en el historial se ve claro dónde empezó y terminó cada fase.

---

## 0.8 Invitar a los compañeros (cuando estés listo)

Puedes hacerlo ahora o al terminar. Necesitas el **usuario de GitHub** de cada uno:

```powershell
gh api -X PUT repos/paulgabriel1/cuscosmart-api/collaborators/USUARIO_DEL_COMPAÑERO -f permission=push
```

A cada uno le llega un correo con la invitación. Cuando la acepte, ya puede clonar el repo.

---

## ✅ Lista de control de la fase 0

- [ ] `node`, `npm`, `git`, `gh` y MariaDB responden con su versión.
- [ ] La estructura de carpetas está creada y abierta en VS Code.
- [ ] `.gitignore` incluye `node_modules/` y `.env`.
- [ ] Hay un commit `chore: inicio del proyecto...` en `main`.
- [ ] El repo **privado** `cuscosmart-api` existe en GitHub con el README visible.

---

## 🎓 Preguntas del profesor

**1. ¿Por qué el repositorio es privado?**
> Porque es un trabajo académico en desarrollo y todavía puede contener datos de prueba. Solo entramos los integrantes y el profesor, como colaboradores.

**2. ¿Qué pasa si subo el `.env` por error?**
> Cualquiera con acceso al repo ve la contraseña de la base de datos y el `JWT_SECRET`. Con ese secreto podría fabricar tokens válidos y entrar como administrador. Por eso va en `.gitignore`. Si se sube por error, hay que **cambiar las claves**: borrar el archivo no basta, porque queda en el historial de Git.

**3. ¿Para qué sirven las ramas si trabajas solo?**
> Para aislar cada fase. Si una fase sale mal, `main` sigue funcionando. Además, cuando entren mis compañeros, cada uno trabaja en su rama sin pisar el código de los demás.

**4. ¿Qué es un commit y por qué usan `feat:`, `fix:`...?**
> Un commit es una foto del proyecto en un momento. Los prefijos son la convención *Conventional Commits*: con solo leer el historial se sabe si un cambio fue una funcionalidad, una corrección o documentación.

**5. ¿Por qué separan el proyecto en tantas carpetas?**
> Por la arquitectura en capas: **rutas → middlewares → controladores → servicios → base de datos**. Cada capa hace una sola cosa, así es más fácil encontrar errores, probar y trabajar en equipo.

---

## Errores comunes

| Síntoma | Causa | Solución |
| --- | --- | --- |
| `gh: command not found` | GitHub CLI no está instalado | `winget install GitHub.cli` y abre una PowerShell nueva |
| `HTTP 401` o `authentication required` en `gh` | No iniciaste sesión | `gh auth login` |
| `Author identity unknown` al hacer commit | Falta `user.name` o `user.email` | Paso 0.1 (`git config --global ...`) |
| `fatal: remote origin already exists` | Ya conectaste el repo antes | `git remote -v` para verlo; o `git remote remove origin` y repite 0.6 |
| `Name already exists on this account` | El repo ya existe en GitHub | Usa `git remote add origin https://github.com/paulgabriel1/cuscosmart-api.git` y luego `git push -u origin main` |
| `.env` aparece en `git status` | `.gitignore` mal escrito o sin salto de línea final | Revisa 0.3 y ejecuta `git rm --cached .env` |

---

**Siguiente:** Fase 1, base de datos. Ahí separamos el SQL del grupo en archivos ordenados, agregamos los procedimientos que usará la API y lo probamos todo en phpMyAdmin.

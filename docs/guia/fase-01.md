# Fase 1: base de datos

**Objetivo:** crear `cuscosmart_db` con sus 11 tablas, la función, los 4 triggers y **51 procedimientos almacenados**, junto con los datos de prueba y un usuario de MySQL propio para la API.

**Resultado:** la base de datos completa, probada con `CALL` desde la consola y desde phpMyAdmin.

---

## 1.1 Los archivos de `database/`

El SQL original del grupo estaba en un solo archivo. Lo separamos por **responsabilidad**, igual que el profesor en el SGRH:

| Archivo | Qué contiene | ¿Se edita? |
| --- | --- | --- |
| `schema.sql` | Crea la base y las **11 tablas** del diagrama ER (no cambió nada) | Solo si cambia el diagrama |
| `logica.sql` | **Función** Haversine, **4 triggers** y **51 procedimientos** | Sí, cuando hay lógica nueva |
| `seed.sql` | Datos de prueba: 14 atractivos, 8 preguntas, 2 usuarios y un viaje de ejemplo | Sí, para agregar datos |
| `usuario.sql` | Crea `cuscosmart_user` con **un solo permiso: EXECUTE** | Casi nunca |
| `verificacion.sql` | Cuenta tablas, procedimientos, triggers y filas para confirmar | No |
| `cuscosmart_todo.sql` | **Une todo lo anterior** en orden. Es el que se importa | No: se regenera (ver 1.6) |

---

## 1.2 Crear la base (dos formas)

Primero, **XAMPP → Start MySQL**.

**Forma A, por consola** (rápida, la que usamos siempre):

```powershell
cd $HOME\Desktop\cuscosmart-api
cmd /c "C:\xampp\mysql\bin\mysql.exe -u root < database\cuscosmart_todo.sql"
```

**Forma B, en phpMyAdmin:** http://localhost/phpmyadmin → pestaña **Importar** → elige `database/cuscosmart_todo.sql` → **Continuar**.

**Resultado esperado** al final de la salida:

```
objeto          cantidad
tablas          11
procedimientos  51
funciones       1
triggers        4
atractivos      14
usuarios        2
preguntas       8
```

> ⚠️ El script **borra la base** `cuscosmart_db` si ya existe y la crea de nuevo. Úsalo también para "resetear" los datos antes de correr las pruebas de Postman.

---

## 1.3 La regla de oro: la lógica vive en la base de datos

La API (fases 2 a 7) **nunca** escribe `SELECT`, `INSERT` ni `UPDATE`. Solo hace esto:

```sql
CALL sp_nombre_del_procedimiento(parámetros);
```

**¿Por qué?**
1. **Una sola fuente de verdad.** Las reglas se cumplen igual si alguien usa la API, phpMyAdmin u otra app.
2. **Seguridad.** La API usa un usuario que **solo puede ejecutar procedimientos**: no puede leer ni modificar tablas directamente (prueba 10 de la sección 1.7).
3. **Menos código en Node.** La API valida, autentica y traduce errores; MySQL decide las reglas.

---

## 1.4 Cómo avisan los errores los procedimientos (SIGNAL)

Cuando una regla no se cumple, el procedimiento **detiene todo** con `SIGNAL` y un código SQLSTATE. Usamos 3 códigos propios para que la API (fase 3) sepa qué responder:

| SQLSTATE | Significado | La API responderá | Ejemplo |
| --- | --- | --- | --- |
| `45000` | Regla de negocio incumplida | **422** BUSINESS_RULE | "Solo puedes reseñar atractivos que visitaste" |
| `45404` | No existe, o no es tuyo | **404** NOT_FOUND | "Itinerario no encontrado" |
| `45409` | Ya existe (repetido) | **409** DUPLICATE | "Ese atractivo ya está en tus favoritos" |

```sql
IF EXISTS (SELECT 1 FROM tbl_usuario WHERE correo = p_correo) THEN
  SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ese correo ya está registrado';
END IF;
```

Además, MySQL ya trae sus propios errores, y la API también los traducirá:

| Error de MySQL | Cuándo ocurre | La API responderá |
| --- | --- | --- |
| `1451` (FK RESTRICT) | Borrar una categoría que tiene atractivos | **409** IN_USE |
| `1452` | Crear un atractivo con una `categoria_id` inexistente | **400** INVALID_REFERENCE |
| `1062` (UNIQUE) | Repetir una parada en el mismo itinerario | **409** DUPLICATE |

---

## 1.5 Recorrido por `logica.sql`

### La función `fn_distancia_km` (Haversine)
Calcula la distancia **en línea recta sobre la Tierra** entre dos coordenadas. 6371 es el radio de la Tierra en km.

```sql
SELECT fn_distancia_km(-13.5175, -71.98, -13.5163, -71.9785);   -- 0.21 km: del hotel a la Catedral
```

### Los 4 triggers
Un trigger es código que MySQL ejecuta **solo**, antes o después de un `INSERT` o `DELETE`.

| Trigger | Cuándo | Qué hace |
| --- | --- | --- |
| `trg_detalle_valida` | Antes de agregar una parada | Exige que el favorito sea del **dueño del itinerario** |
| `trg_resena_valida` | Antes de crear una reseña | **Anti reseñas falsas:** el lugar debe estar en el itinerario y con `visitado = 1` |
| `trg_resena_calificacion_ins` | Después de crear una reseña | Recalcula el **promedio** (`calificacion`) del atractivo |
| `trg_resena_calificacion_del` | Después de borrar una reseña | Recalcula el promedio |

> **Detalle importante:** los borrados **en cascada** (`ON DELETE CASCADE`) **no disparan triggers**. Si se borra un itinerario, sus reseñas desaparecerían sin recalcular el promedio. Por eso `sp_eliminar_itinerario` y `sp_eliminar_usuario` **borran primero las reseñas a mano** (así sí corre el trigger) y luego el resto.

### Los procedimientos por módulo

| Módulo | Procedimientos | Los usa la fase |
| --- | --- | --- |
| Usuarios | `sp_registrar_usuario`, `sp_usuario_por_correo`, `sp_usuario_por_id`, `sp_listar_usuarios`, `sp_cambiar_rol_usuario`, `sp_eliminar_usuario` | 4 y 7 |
| Categorías | `sp_listar_categorias`, `sp_ver_categoria`, `sp_crear_categoria`, `sp_actualizar_categoria`, `sp_eliminar_categoria` | 5 |
| Zonas | `sp_listar_zonas`, `sp_ver_zona`, `sp_crear_zona`, `sp_actualizar_zona`, `sp_eliminar_zona` | 5 |
| Atractivos | `sp_listar_atractivos`, `sp_ver_atractivo`, `sp_crear_atractivo`, `sp_actualizar_atractivo`, `sp_eliminar_atractivo`, `sp_atractivos_cercanos`, `sp_validar_atractivo` | 5 |
| Horarios y fotos | `sp_listar_horarios`, `sp_agregar_horario`, `sp_eliminar_horario`, `sp_listar_fotos`, `sp_agregar_foto`, `sp_eliminar_foto` | 5 |
| Favoritos | `sp_agregar_favorito`, `sp_listar_favoritos`, `sp_quitar_favorito` | 6 |
| Itinerarios | `sp_validar_itinerario`, `sp_crear_itinerario`, `sp_listar_itinerarios`, `sp_ver_itinerario`, `sp_actualizar_itinerario`, `sp_eliminar_itinerario`, `sp_actualizar_totales`, `sp_agregar_parada`, `sp_quitar_parada`, `sp_ordenar_itinerario_ia`, `sp_marcar_visitado` | 6 |
| Reseñas | `sp_registrar_resena`, `sp_listar_resenas_atractivo`, `sp_eliminar_resena` | 7 |
| Asistente | `sp_buscar_pregunta_frecuente`, `sp_listar_preguntas`, `sp_crear_pregunta`, `sp_actualizar_pregunta`, `sp_eliminar_pregunta` | 7 |

**Patrones que se repiten (aprende a reconocerlos):**

1. **Validar primero.** `sp_validar_atractivo` y `sp_validar_itinerario` son procedimientos "ayudantes" que fallan con 404. Los demás los llaman al inicio (`CALL sp_validar_itinerario(p_usuario_id, p_itinerario_id);`). Así la regla se escribe **una sola vez**.
2. **El dueño se comprueba en la base.** Todo lo del turista recibe `p_usuario_id`. Si el itinerario es de otra persona, responde "no encontrado" en lugar de "prohibido", para **no revelar que existe**.
3. **Varios resultados en un CALL.** `sp_listar_atractivos` devuelve 2 tablas: las filas de la página y el total, que sirve para paginar. `sp_ver_atractivo` devuelve 3: datos, horarios y fotos.
4. **El sistema calcula, el cliente no envía.** `calificacion` sale de los triggers. `duracion_horas` y `costo_total` salen de `sp_actualizar_totales`. `orden` lo pone `sp_agregar_parada` (al final) o la IA. `costo_parada` se copia del precio de entrada.

### La "IA": `sp_ordenar_itinerario_ia`
1. Calcula la distancia de cada parada al punto de inicio con `fn_distancia_km`.
2. Numera las paradas de la más cercana a la más lejana con `ROW_NUMBER() OVER (ORDER BY distancia_km)`.
3. Aplica el nuevo orden en dos pasos. Primero suma 100 000 a todos, porque si se cambia directo del 1 al 2 cuando ya existe un 2, la regla UNIQUE `(itinerario_id, orden)` falla.
4. Marca `sugerido_ia = 1`.

Si después agregas una parada, `sugerido_ia` vuelve a 0, porque la ruta ya no está optimizada.

---

## 1.6 Regenerar `cuscosmart_todo.sql` cuando cambies algo

Si editas `schema.sql`, `logica.sql`, `seed.sql` o `usuario.sql`, vuelve a unirlos (PowerShell, desde la carpeta del proyecto):

```powershell
Get-Content database\schema.sql, database\logica.sql, database\seed.sql, database\usuario.sql, database\verificacion.sql -Encoding UTF8 |
  Set-Content database\cuscosmart_todo.sql -Encoding UTF8
```

> Desde la fase 2 habrá un comando más corto: `npm run db:armar`.

---

## 1.7 Probar como lo hará la API

Entra a la consola **con el usuario de la API**, no con root:

```powershell
C:\xampp\mysql\bin\mysql.exe -u cuscosmart_user -p -h 127.0.0.1 cuscosmart_db
```

La contraseña es `Cusco2026*`. Luego prueba (resultado esperado a la derecha):

| # | Prueba | Resultado esperado |
| --- | --- | --- |
| 1 | `CALL sp_listar_atractivos(NULL,NULL,NULL,3,0);` | 3 atractivos y un total de **14** |
| 2 | `CALL sp_listar_atractivos(NULL,NULL,'inca',10,0);` | Los que dicen "inca" en el nombre o la descripción |
| 3 | `CALL sp_atractivos_cercanos(-13.5167,-71.9788,1,5);` | Plaza (0.00), Catedral (0.06), Museo Inka (0.16)… |
| 4 | `CALL sp_ver_itinerario(2,1);` | El viaje de Ana, ordenado: Catedral → Qorikancha → Sacsayhuamán |
| 5 | `CALL sp_ver_itinerario(1,1);` | `ERROR 1644 (45404): Itinerario no encontrado`, porque el admin no es el dueño |
| 6 | `CALL sp_agregar_favorito(2,1);` | `ERROR 1644 (45409): Ese atractivo ya está en tus favoritos` |
| 7 | `CALL sp_registrar_resena(2,1,1,4,'x');` | `ERROR 1644 (45000): Solo puedes reseñar atractivos que visitaste…` |
| 8 | `CALL sp_eliminar_categoria(1);` | `ERROR 1451`: la categoría tiene atractivos |
| 9 | `CALL sp_buscar_pregunta_frecuente('cuanto cuesta el boleto');` | "El boleto integral cuesta S/ 130…" |
| 10 | `SELECT * FROM tbl_usuario;` | `ERROR 1142: SELECT command denied`. ✅ La API solo puede usar procedimientos |

Sal con `exit`. Si hiciste cambios de prueba, vuelve a importar (1.2) para dejar los datos limpios.

---

## 1.8 Commit de la fase

```powershell
git switch -c feature/fase-1
git add database docs
git commit -m "feat: base de datos cuscosmart_db con procedimientos, triggers y datos de prueba"
git switch main
git merge --no-ff feature/fase-1 -m "Merge branch 'feature/fase-1'"
git branch -d feature/fase-1
git push
```

---

## ✅ Lista de control

- [ ] `verificacion.sql` muestra 11 tablas, 51 procedimientos, 1 función y 4 triggers.
- [ ] Las pruebas de 1.7 dan los resultados esperados con `cuscosmart_user`.
- [ ] Commit y merge de `feature/fase-1` subidos a GitHub.

---

## 🎓 Preguntas del profesor

**1. ¿Por qué usan procedimientos almacenados y no consultas desde Node?**
> Para que las reglas de negocio estén en un solo lugar: la base de datos. Se cumplen igual sin importar desde dónde llegue la operación (API, phpMyAdmin u otra app). Además, el usuario de la API solo tiene permiso para ejecutar procedimientos y manipular datos, no para borrar tablas, y así se reduce el daño si alguien roba la conexión.

**2. ¿Cómo evitan las reseñas falsas?**
> Con el trigger `trg_resena_valida`. Antes de insertar una reseña, comprueba que ese atractivo esté como parada en el itinerario del turista **y** que esté marcado como visitado. Si no, lanza `SIGNAL 45000` y la reseña no se guarda. Además, el UNIQUE `(itinerario_id, atractivo_id)` impide reseñar dos veces el mismo lugar en el mismo viaje.

**3. ¿Qué es la "IA" de su proyecto?**
> Un algoritmo que ordena la ruta: calcula con la fórmula de **Haversine** la distancia de cada parada al punto de inicio (por ejemplo, el hotel) y las numera de la más cercana a la más lejana. Es una heurística sencilla tipo "vecino más cercano desde el origen". No usa servicios pagados y responde al instante.

**4. ¿Qué es un trigger y en qué se diferencia de un procedimiento?**
> Un trigger se ejecuta **solo** cuando ocurre un evento (INSERT, UPDATE o DELETE) en una tabla. Un procedimiento se ejecuta cuando alguien lo **llama** con `CALL`. Usamos triggers para lo que debe cumplirse siempre (reseñas válidas, promedio actualizado) y procedimientos para las operaciones de la app.

**5. ¿Por qué la API no se conecta como `root`?**
> Por el **principio de mínimo privilegio**. `cuscosmart_user` solo tiene **EXECUTE** en `cuscosmart_db`. Si alguien roba la contraseña del `.env`, ni siquiera puede hacer un SELECT: solo puede usar los procedimientos, que validan reglas y dueño. Los procedimientos corren con los permisos de quien los creó (SQL SECURITY DEFINER), por eso sí pueden tocar las tablas.

**6. ¿Por qué cuando pido un itinerario ajeno sale 404 y no 403?**
> Porque un 403 confirmaría que ese itinerario **existe**. Con 404, un atacante no puede adivinar qué IDs están en uso. Es una práctica común de seguridad.

**7. ¿Qué pasa con la calificación si borran un itinerario con reseñas?**
> Los borrados en cascada no disparan triggers. Por eso `sp_eliminar_itinerario` borra primero las reseñas con un `DELETE` normal (así el trigger recalcula el promedio) y luego el itinerario.

---

## Errores comunes

| Síntoma | Causa | Solución |
| --- | --- | --- |
| `ERROR 2002 Can't connect to server` | MySQL apagado | XAMPP → Start MySQL |
| `ERROR 1064 ... near 'DELIMITER'` | Se pegó el SQL en una herramienta que no entiende `DELIMITER` | Usa la consola o phpMyAdmin (los dos lo entienden) |
| Las tildes salen como `Ã¡` | Se importó sin utf8mb4 | El script ya trae `SET NAMES utf8mb4`; no lo quites |
| `Access denied for user 'cuscosmart_user'` | No se ejecutó la parte de `usuario.sql` | Importa `cuscosmart_todo.sql` completo como root |
| `ERROR 1370 execute command denied` | Falta el permiso EXECUTE | Vuelve a ejecutar `usuario.sql` |
| `FUNCTION ... already exists` | Se ejecutó `logica.sql` en un MySQL viejo | `logica.sql` ya borra todo primero; usa `cuscosmart_todo.sql` |
| `InnoDB: data file must be writable` al iniciar MySQL | Hay **dos** MySQL abiertos a la vez | Cierra uno: en XAMPP, Stop; o en el Administrador de tareas, `mysqld.exe` |

---

**Siguiente:** Fase 2, el proyecto base de Node: `package.json`, `.env`, conexión a MySQL y `GET /api/v1/health`.

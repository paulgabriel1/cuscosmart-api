# Diagrama entidad-relación de CuscoSmart IA

Es el diseño original del grupo (11 tablas, 12 llaves foráneas) con **2 columnas agregadas** en las fases 11 y 12, marcadas con ★. GitHub dibuja el diagrama automáticamente.

```mermaid
erDiagram
    tbl_categoria ||--o{ tbl_atractivo : "clasifica"
    tbl_zona ||--o{ tbl_atractivo : "ubica"
    tbl_atractivo ||--o{ tbl_horario : "tiene"
    tbl_atractivo ||--o{ tbl_foto : "tiene"
    tbl_atractivo |o--o{ tbl_pregunta_frecuente : "se relaciona"
    tbl_usuario ||--o{ tbl_atractivo_favorito : "guarda"
    tbl_atractivo ||--o{ tbl_atractivo_favorito : "es guardado"
    tbl_usuario ||--o{ tbl_itinerario : "crea"
    tbl_itinerario ||--o{ tbl_detalle_itinerario : "tiene paradas"
    tbl_atractivo_favorito ||--o{ tbl_detalle_itinerario : "es parada"
    tbl_itinerario ||--o{ tbl_resena : "permite reseñar"
    tbl_atractivo ||--o{ tbl_resena : "recibe"

    tbl_usuario {
        int id PK
        varchar nombre_completo
        varchar correo UK
        varchar contrasena "hash bcrypt"
        varchar telefono
        enum rol "TURISTA | ADMIN"
        datetime fecha_registro
    }
    tbl_categoria {
        int id PK
        varchar nombre
        varchar descripcion
    }
    tbl_zona {
        int id PK
        varchar nombre
        varchar ciudad
    }
    tbl_atractivo {
        int id PK
        varchar nombre
        text descripcion
        varchar direccion
        decimal latitud
        decimal longitud
        decimal precio_entrada
        decimal calificacion "la recalculan los triggers"
        datetime fecha_registro
        int categoria_id FK
        int zona_id FK
    }
    tbl_horario {
        int id PK
        varchar dia_semana
        time hora_apertura
        time hora_cierre
        int atractivo_id FK
    }
    tbl_foto {
        int id PK
        varchar url_foto
        varchar descripcion
        datetime fecha_subida
        int atractivo_id FK
    }
    tbl_pregunta_frecuente {
        int id PK
        varchar pregunta
        text respuesta
        varchar palabras_clave
        int atractivo_id FK "NULL si se borra el atractivo"
    }
    tbl_atractivo_favorito {
        int id PK
        datetime fecha_guardado
        tinyint es_favorito "★ 1 = favorito, 0 = solo parada de un viaje"
        int atractivo_id FK
        int usuario_id FK
    }
    tbl_itinerario {
        int id PK
        varchar nombre
        decimal duracion_horas
        decimal costo_total
        tinyint sugerido_ia
        decimal latitud_inicio
        decimal longitud_inicio
        datetime fecha_creacion
        int usuario_id FK
    }
    tbl_detalle_itinerario {
        int id PK
        int orden
        decimal tiempo_estimado_horas
        decimal costo_parada
        decimal distancia_km
        tinyint visitado
        datetime fecha_visita "★ cuándo se marcó visitado"
        int itinerario_id FK
        int atractivo_favorito_id FK
    }
    tbl_resena {
        int id PK
        tinyint puntuacion "CHECK 1..5"
        varchar comentario
        datetime fecha
        int atractivo_id FK
        int itinerario_id FK
    }
```

## Reglas que hace cumplir la base

| Regla | Cómo |
| --- | --- |
| Un correo no se repite | `UNIQUE uq_usuario_correo` |
| No guardar dos veces el mismo favorito | `UNIQUE uq_favorito (usuario_id, atractivo_id)` |
| Una reseña por lugar en cada viaje | `UNIQUE uq_resena (itinerario_id, atractivo_id)` |
| Puntuación de 1 a 5 | `CHECK chk_resena_puntuacion` |
| Borrar un atractivo borra sus horarios, fotos, favoritos, paradas y reseñas | `ON DELETE CASCADE` |
| Borrar un atractivo NO borra sus preguntas frecuentes | `ON DELETE SET NULL` |
| Borrar un usuario borra sus favoritos y viajes | `ON DELETE CASCADE` |
| Solo se reseña lo visitado | trigger `trg_resena_valida` |
| La calificación del atractivo siempre al día | triggers `trg_resena_calificacion_ins` / `_del` |
| Distancias para ordenar la ruta | función `fn_distancia_km` (Haversine) |

## Las 2 columnas nuevas (★)

- **`tbl_atractivo_favorito.es_favorito`**: permite agregar a un viaje un lugar que no está en tus favoritos. La parada sigue apuntando a `tbl_atractivo_favorito`, como manda el diagrama; solo se marca con `0` para que no aparezca en "Favoritos".
- **`tbl_detalle_itinerario.fecha_visita`**: guarda cuándo marcaste la parada como visitada. Con ella se arma la línea de tiempo "Mi recorrido" del perfil.

Las dos tienen valor por defecto (`1`) o aceptan `NULL`, no cambian llaves ni cardinalidades y la base original sigue cargando sobre ellas. Se verificó con pruebas reales sobre la base (cascadas, `SET NULL`, llaves inválidas, `UNIQUE`, `CHECK` y triggers): todo correcto.

# Guía de construcción de CuscoSmart IA

Esta es la guía paso a paso para construir **CuscoSmart IA desde cero**. Sigue las mismas 9 fases que la guía del profesor, *API REST del SGRH*.

> Curso Fullstack Developer Software, SENATI.
> Integrantes: Gabriel Paul Alata Condori · Rodrigo Ccahuana Mayo · Mademil Lucero Alata Condori.

## Cómo usar esta guía

1. Lee la fase completa antes de tocar el teclado.
2. Crea cada archivo **tú mismo**, copiando y pegando el código. Lee la explicación de debajo de cada bloque.
3. Haz las pruebas que indica la fase, en Postman o en el navegador, y compara con el **resultado esperado**.
4. Si algo no coincide, revisa la tabla de **Errores comunes** de esa fase antes de seguir.
5. Haz el **commit** que indica la fase. Cada fase termina con el proyecto funcionando.
6. Repasa las **Preguntas del profesor** hasta poder responderlas con tus palabras.

## Fases

| Fase | Tema | Resultado |
| --- | --- | --- |
| [0](fase-00.md) | Preparar la PC, la carpeta y el repositorio | Repo privado en GitHub con el primer commit |
| [1](fase-01.md) | Base de datos: tablas, función, triggers y procedimientos | `cuscosmart_db` creada y probada con `CALL` |
| 2 | Proyecto base de Node | `GET /api/v1/health` responde |
| 3 | Manejo de errores y validación | Errores con formato único, 400 y 404 controlados |
| 4 | Autenticación y roles | Registro, login con JWT, rutas solo para ADMIN |
| 5 | Catálogo: categorías, zonas y atractivos | CRUD completo, filtros y lugares cercanos |
| 6 | Favoritos e itinerarios | Rutas ordenadas por la "IA" (Haversine) |
| 7 | Reseñas y asistente | Reseñas verificadas y preguntas frecuentes |
| 8 | Postman completo y Swagger | Colección con pruebas automáticas y documentación |
| 9 | Front con React y mapa | Web con mapa, rutas y panel de administración |

## Idea general del proyecto

```
 Navegador (React)  ──HTTP/JSON──▶  API (Node + Express)  ──CALL sp_...──▶  MySQL (cuscosmart_db)
   pantallas, mapa                   valida, autentica,                     tablas, triggers,
                                     traduce errores                        función y procedimientos
```

**La regla de oro del proyecto:** las reglas de negocio viven en la base de datos, en triggers y procedimientos. La API no escribe SQL suelto: solo llama a procedimientos con `CALL`.

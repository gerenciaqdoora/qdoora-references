---
name: contratos-api
description: >
  Diseño y gobierno de contratos HTTP/JSON entre un servidor y sus consumidores, para cualquier
  stack (Laravel, Node/Express/Fastify/NestJS, FastAPI, u otro; con o sin frontend separado).
  Aplica convenciones estándar: errores RFC 9457 (Problem Details), códigos de estado, paginación por
  cursor u offset con límite, concurrencia optimista con ETag/If-Match, idempotencia, fechas ISO
  8601, compatibilidad hacia atrás, deprecación y detección de cambios incompatibles. La fuente de
  verdad del contrato (OpenAPI generado desde el código, OpenAPI escrito primero o tests de
  contrato) la fija el perfil del proyecto.
  Activar AUTOMÁTICAMENTE al crear o modificar un endpoint, un DTO o recurso de entrada o salida, un
  código de estado, el formato de errores o la paginación; al alinear un cliente con la API; al
  versionar o deprecar; o cuando el usuario diga "contrato", "endpoint", "OpenAPI", "Swagger",
  "DTO", "API Resource", "formato de respuesta", "formato de error", "paginación", "breaking change",
  "versionar la API".
license: MIT
metadata:
  author: francoalvaradot
  version: '2.0'
---

# Contratos de API

El contrato es la promesa entre quien sirve y quien consume. Esta habilidad asegura que esa promesa
esté **escrita en un solo lugar**, que se respete **de forma verificable** y que **no se rompa sin
que nadie lo note**.

## Perfil del proyecto

Lee `CLAUDE.md` / `AGENTS.md` y las reglas del proyecto para saber:
- el stack del servidor y quién consume la API (SPA, app móvil, otros servicios, terceros, o solo
  vistas del mismo servidor);
- la **fuente de verdad** elegida (ver abajo);
- el estilo de nombres del JSON (camelCase o snake_case), el formato de error vigente y si hay una
  migración de formato en curso.

**Si el proyecto ya tiene una convención distinta a la de esta habilidad, se respeta hasta que se
decida migrar**; nunca se mezclan dos estilos en la misma API. Si el perfil no dice nada, pregunta
por la fuente de verdad antes de imponer una.

## Fuente de verdad: una por proyecto

| Opción | Cuándo conviene | Cómo se verifica |
|---|---|---|
| **OpenAPI generado desde el código** (code-first) | Un solo equipo dueño del servidor; frameworks que lo generan bien (NestJS, FastAPI, Laravel con Scramble) | Especificación exportada y commiteada; CI la regenera y compara |
| **OpenAPI escrito primero** (design-first) | Varios equipos o consumidores externos; se acuerda el contrato antes de programar | El servidor se valida contra la especificación (tests o middleware de validación) |
| **Tests de contrato sin especificación** | APIs internas pequeñas, o servidor y cliente en el mismo repositorio sin generación de tipos | Tests E2E que fijan la forma del JSON, los códigos y los errores |

Cuando hay especificación, los clientes con tipado **generan** sus tipos desde ella y no los copian
a mano. Si no hay especificación, cada cliente aísla la forma de la API en un **adaptador** con sus
propios tests.

## Principios

1. **Una sola fuente de verdad** (la que fije el perfil), versionada en el repositorio.
2. **El cliente no depende de la forma cruda de la API:** un adaptador traduce la respuesta al
   modelo que usa la interfaz. Si el servidor cambia un nombre, se ajusta el adaptador.
3. **Todo cambio incompatible se detecta automáticamente:** comparando especificaciones (ej.
   `oasdiff breaking`) o con tests de contrato que fallan. Solo se acepta si es intencional y está
   coordinado.
4. **HTTP es el sobre:** el estado y los metadatos van en el código y las cabeceras; el cuerpo lleva
   el recurso. No se envuelve toda respuesta en `{ data, meta }`.

## Convenciones

Detalle y ejemplos en `references/convenciones-http.md`. Resumen:

| Tema | Regla |
|---|---|
| Recursos y rutas | Sustantivos en plural, jerarquía corta (`/proyectos/{id}/tareas`); verbos solo para acciones que no son CRUD (`POST /tareas/{id}/completar`) |
| Métodos | `GET` seguro, `PUT` reemplaza, `PATCH` modifica parcial (JSON Merge Patch), `DELETE` idempotente |
| Estados de éxito | `200` con cuerpo, `201` + `Location` al crear, `204` sin cuerpo |
| Errores | **RFC 9457** `application/problem+json`: `type`, `title`, `status`, `detail`, `instance`, y `errores[]` para validación. Nunca un stack trace ni un mensaje interno |
| Validación | `422` (o `400`, según el perfil) con un elemento por campo: `{ campo, mensaje }` |
| Recurso ajeno o inexistente | `404` en ambos casos: no confirmar que existe |
| Colecciones | Único caso con sobre: `{ elementos, pagina }`, con límite por defecto y **máximo** en el servidor |
| Paginación | Cursor (keyset) para listas largas o scroll infinito; offset con `total` solo para tablas con número de página |
| Fechas | ISO 8601 con zona (`2026-09-26T15:04:05Z`); fechas sin hora como `AAAA-MM-DD` |
| Identificadores | Strings opacos; el cliente nunca los construye ni los interpreta |
| Dinero y decimales exactos | String decimal (`"1234.50"`) + moneda; nunca `float` |
| Enumeraciones | Strings documentados; el cliente tolera valores nuevos |
| Nulos | `null` = "sin valor"; ausente = "no se envió". En `PATCH`, `null` borra y ausente no toca |
| Concurrencia | `ETag` en `GET` del recurso; `If-Match` en `PUT`/`PATCH`/`DELETE`; `412` si cambió |
| Idempotencia | `Idempotency-Key` en `POST` con efectos externos (correos, pagos, integraciones) |
| Trazabilidad | `X-Request-Id` (o `traceparent` W3C) en la respuesta y en los logs; no en el cuerpo |
| Caché | `Cache-Control: no-store` si hay datos personales; `ETag` + `304` para lo que se relee |

## Compatibilidad

**Compatibles** (sin coordinación): agregar un endpoint, agregar un campo **opcional** en la
entrada, agregar un campo en la salida, agregar un valor a un enum de **salida** si los clientes lo
toleran.

**Incompatibles** (exigen coordinación o versión nueva): quitar o renombrar un campo, cambiar un
tipo, volver obligatorio un campo de entrada, cambiar un código de estado, cambiar el formato de
error o de paginación, endurecer una validación existente.

Para un cambio incompatible, en orden de preferencia:
1. **Expandir y contraer:** agregar lo nuevo junto a lo viejo, migrar a los clientes, quitar lo viejo.
2. **Deprecar con aviso:** `deprecated: true` en la especificación (si la hay) y cabeceras
   `Deprecation` (RFC 9745) y `Sunset` (RFC 8594).
3. **Versionar** (`/v2/...`) solo si el cambio es amplio y hay consumidores que no se pueden coordinar.

Si servidor y cliente se despliegan juntos y no hay otros consumidores, basta con cambiar ambos en
el mismo PR.

## Flujo al crear o modificar un endpoint

1. **Contrato primero:** entrada, salida, códigos de estado y errores posibles. Si ya existe un
   endpoint parecido, copiar su forma.
2. **Reflejarlo en la fuente de verdad:** documentar en la especificación, o escribir primero los
   tests de contrato.
3. **Test E2E:** forma del cuerpo, éxito, validación, sin permiso e inexistente.
4. **Clientes:** regenerar los tipos si hay especificación; ajustar el adaptador.
5. **Verificar compatibilidad:** revisar el diff de la especificación y correr el detector, o los
   tests de contrato.

Implementación por stack:
- NestJS → `references/nestjs.md`
- Laravel → `references/laravel.md`
- Express / Fastify → `references/node.md`
- FastAPI → `references/fastapi.md`
- Cliente Angular → `references/angular.md` (el patrón de adaptador aplica igual a React, Vue o móvil)

## Lista de revisión de un cambio de contrato

- [ ] ¿El endpoint declara todas sus respuestas, incluidos los errores?
- [ ] ¿La salida es un DTO o recurso explícito y no el modelo de la base? ¿Expone solo lo necesario?
- [ ] ¿Las colecciones tienen límite máximo?
- [ ] ¿El formato de error es el del proyecto, sin detalles internos?
- [ ] ¿La fuente de verdad quedó actualizada y los clientes alineados?
- [ ] ¿La verificación de compatibilidad pasa, o el cambio incompatible está justificado y coordinado?
- [ ] ¿Hay datos personales en la respuesta? Entonces `no-store`, mínimo necesario y verificación de
      dueño (ver `auditoria-appsec` y la habilidad de protección de datos).

## Anti-patrones

- Tipos del cliente copiados a mano cuando existe una especificación de la que generarlos.
- Compartir clases del servidor con decoradores de validación en el cliente: arrastran dependencias
  al bundle y acoplan los despliegues.
- Devolver `200` con `{ ok: false, error }`.
- Un sobre `{ data, meta: { timestamp, path } }` en cada respuesta.
- Paginación sin límite o con `limit` sin tope en el servidor.
- `float` para dinero; fechas sin zona; ids numéricos que el cliente incrementa.
- Renombrar un campo "porque queda más claro" sin expandir y contraer.

> **Relacionadas:** `planificador` (el contrato es la primera capa del chequeo de punta a punta) ·
> `ejecutor-plan` (alinea los clientes en el cierre) · `auditoria-appsec` (exposición de datos,
> errores saneados, límites).

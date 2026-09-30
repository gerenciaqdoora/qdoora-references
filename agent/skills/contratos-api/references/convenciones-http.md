# Convenciones HTTP con ejemplos

Los nombres de campo se muestran en camelCase; si el proyecto usa snake_case, se aplica igual con
ese estilo. Lo importante es la forma, no el idioma de las claves.

## Errores: RFC 9457 (Problem Details)

`Content-Type: application/problem+json`

```json
{
  "type": "https://api.ejemplo.cl/problemas/validacion",
  "title": "La solicitud tiene datos inválidos",
  "status": 422,
  "detail": "Revisa los campos marcados.",
  "instance": "/tareas",
  "errores": [
    { "campo": "titulo", "mensaje": "El título es obligatorio" },
    { "campo": "fechaVencimiento", "mensaje": "Debe ser una fecha ISO 8601" }
  ]
}
```

- `type`: URI estable que identifica el tipo de problema. Puede ser `about:blank` si no hay más
  detalle que el código de estado. No necesita resolverse, pero conviene que lo haga.
- `title`: resumen legible y constante para ese `type`.
- `detail`: explicación de **esta** ocurrencia, apta para mostrar al usuario. Nunca el mensaje de
  una excepción interna.
- `instance`: la ruta de la petición (sin query string si puede contener datos personales).
- Miembros de extensión permitidos: `errores` para validación, `codigo` para un código de negocio
  estable que el frontend pueda usar en un `switch`.
- Los `500` responden siempre el mismo cuerpo genérico. El detalle queda en los logs, correlacionado
  por `X-Request-Id`.

**Migrar desde `{ detail }`:** RFC 9457 también define `detail`, así que un cliente que hoy lee
`cuerpo.detail` sigue funcionando si ese campo conserva un string. Si hoy `detail` puede ser un
arreglo (errores de validación), mover el arreglo a `errores` y dejar en `detail` un texto:
adaptar el cliente **antes** de cambiar el servidor, o hacer que el cliente acepte ambas formas
durante la transición.

## Códigos de estado

| Código | Uso |
|---|---|
| 200 | Éxito con cuerpo |
| 201 | Creado; cabecera `Location` con la URL del recurso y el recurso en el cuerpo |
| 204 | Éxito sin cuerpo (eliminar, acciones sin resultado) |
| 304 | No modificado (`If-None-Match` coincide con el `ETag`) |
| 400 | Petición malformada (JSON inválido, parámetro de tipo incorrecto) |
| 401 | Sin credencial válida |
| 403 | Autenticado pero sin permiso para la **acción** (rol) |
| 404 | No existe **o** no pertenece a quien pregunta |
| 409 | Conflicto de estado de negocio (duplicado, transición inválida) |
| 412 | `If-Match` no coincide: alguien más modificó el recurso |
| 422 | Validación de campos |
| 428 | Se exige `If-Match` y no vino |
| 429 | Límite de uso; cabecera `Retry-After` |
| 503 | Dependencia no disponible (servicio externo caído); `Retry-After` si se sabe |

## Paginación

**Cursor (keyset)**, recomendada para listas que crecen, scroll infinito y feeds:

```http
GET /tareas?limite=50&cursor=eyJmIjoiMjAyNi0wOS0yNiIsImlkIjoiYTFiMiJ9
```
```json
{
  "elementos": [ ... ],
  "pagina": { "limite": 50, "siguienteCursor": "eyJmIjoi...", "hayMas": true }
}
```

- El cursor es opaco (base64 de la última clave de orden) y el cliente no lo interpreta.
- El orden debe ser total y estable: siempre desempatar por `id`.
- La consulta usa `WHERE (fecha, id) < (:fecha, :id) ORDER BY fecha DESC, id DESC LIMIT :limite + 1`
  (el elemento extra indica si `hayMas`). El costo es el mismo en la página 1 y en la 1000.

**Offset**, solo para tablas con número de página y colecciones acotadas:

```json
{
  "elementos": [ ... ],
  "pagina": { "numero": 3, "tamano": 25, "total": 812 }
}
```

- `total` cuesta un `COUNT(*)`; en tablas grandes considerar un conteo aproximado o prescindir de él.
- En ambos casos: límite por defecto (ej. 25) y **máximo** en el servidor (ej. 100). Un `limite`
  mayor se rechaza con 422 o se recorta, y la regla queda documentada.

**Filtros y orden:** parámetros explícitos (`?estado=abierta&orden=-fechaVencimiento`) con lista
blanca de campos ordenables. Nunca aceptar SQL, expresiones libres ni nombres de columna sin validar.

## Concurrencia optimista

```http
GET /tareas/42            → 200, ETag: "v7"
PATCH /tareas/42
If-Match: "v7"            → 200, ETag: "v8"
PATCH /tareas/42
If-Match: "v7"            → 412 Precondition Failed (otra persona guardó antes)
```

- El `ETag` puede derivarse de una columna `version` (incremental) o de `actualizadoEn`.
- El frontend guarda el `ETag` junto al recurso; ante un 412 recarga y avisa al usuario. Esto es lo
  que permite una Optimistic UI que revierta con seguridad.

## Idempotencia

```http
POST /invitaciones
Idempotency-Key: 5f0c7a1e-...
```

- El servidor guarda la clave con el resultado durante un tiempo (ej. 24 h). Si llega la misma clave
  con el mismo cuerpo, devuelve el resultado guardado sin repetir el efecto; con otro cuerpo, 422.
- Obligatoria en `POST` que envían correos, llaman a terceros o cobran. Innecesaria en `PUT` y
  `DELETE`, que ya son idempotentes.
- La cabecera está en proceso de estandarización en la IETF (`draft-ietf-httpapi-idempotency-key-header`).

## PATCH

JSON Merge Patch (RFC 7396): se envían solo los campos que cambian; `null` borra el valor. El DTO de
entrada marca todos los campos como opcionales y distingue "ausente" de "null".

## Deprecación

```http
Deprecation: @1790000000
Sunset: Sat, 31 Jan 2027 23:59:59 GMT
Link: <https://api.ejemplo.cl/docs#nuevo-endpoint>; rel="successor-version"
```

Marcar además `deprecated: true` en OpenAPI. Registrar el uso del endpoint deprecado para saber
cuándo se puede retirar.

## Cabeceras de límite de uso

`429` con `Retry-After`. Opcionalmente `RateLimit-Policy` y `RateLimit` (borrador de la IETF,
`draft-ietf-httpapi-ratelimit-headers`) para que el cliente sepa cuánto le queda.

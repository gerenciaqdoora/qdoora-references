# Contratos en Node (Express / Fastify)

Para NestJS ver `nestjs.md`.

## Esquema como fuente de validación y documentación

La práctica más sólida en Node es **un solo esquema** que sirva para validar en tiempo de ejecución,
tipar en TypeScript y generar la especificación:

| Framework | Esquema | Especificación |
|---|---|---|
| Fastify | JSON Schema en `schema: { body, querystring, params, response }` (con TypeBox o `fastify-type-provider-zod`) | `@fastify/swagger` |
| Express | Zod | `@asteasolutions/zod-to-openapi` o `zod-openapi` |

En Fastify, el esquema `response` además **filtra** los campos no declarados al serializar: es una
barrera contra la exposición de datos.

```ts
// Fastify + TypeBox
const Tarea = Type.Object({
  id: Type.String({ format: 'uuid' }),
  titulo: Type.String({ maxLength: 200 }),
  fechaVencimiento: Type.Union([Type.String({ format: 'date' }), Type.Null()]),
});

app.post('/tareas', {
  schema: {
    body: Type.Object({ titulo: Type.String({ minLength: 1, maxLength: 200 }) }, { additionalProperties: false }),
    response: { 201: Tarea, 422: Problema },
  },
}, crearTarea);
```

## Errores RFC 9457

- Fastify: `app.setErrorHandler((error, request, reply) => ...)`. Los errores de validación vienen
  en `error.validation`; se mapean a `errores[]` y se responde con
  `reply.type('application/problem+json').code(422).send(problema)`.
- Express: un middleware de error con 4 argumentos al final de la cadena, que traduce errores
  conocidos y responde un 500 genérico para el resto.
- En ambos: registrar el detalle con el identificador de petición y nunca enviarlo al cliente.

## Especificación y compatibilidad

- Exportar la especificación a un archivo (ej. `app.swagger()` en Fastify tras `app.ready()`),
  commitearla y compararla en CI con `oasdiff breaking`.
- Sin especificación: tests de contrato con `supertest` que fijen cuerpo, códigos y errores.

## Paginación

Parámetros validados con límite por defecto y máximo en el esquema (`limite: Type.Integer({ minimum: 1, maximum: 100, default: 25 })`);
cursor opaco en base64 de la última clave de orden.

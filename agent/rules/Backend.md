---
trigger: always_on
---

# 📘 Estándares de Ingeniería Backend (Laravel 11)

> Principios universales y mandatos arquitectónicos para el desarrollo del núcleo API en QdoorA.

---

## 🏗️ Principios Arquitectónicos

### Responsabilidad Única por Capas

- **Services** (`app/Services`): Dueños exclusivos de la lógica de negocio.
- **FormRequests** (`app/Http/Requests`): Guardianes de validación y autorización de entrada.
- **Controllers** (`app/Http/Controllers`): Orquestadores livianos. Reciben, delegan y responden. **Cero lógica de negocio.**
- **Resources** (`app/Http/Resources`): Transformadores de datos para la respuesta JSON. Prohibido retornar Modelos crudos.
- **Service Ownership**: Está prohibido manipular modelos de otro dominio directamente. Invoca al servicio dueño del dominio.

### Stateless & Multitenant

- **Stateless**: Prohibido `session()`. Todo estado reside en el JWT.
- **Aislamiento**: Toda consulta DEBE filtrarse imperativamente por `company_id`.
- **Rutas de Soporte/Admin**: Endpoints administrativos se registran en el grupo `v1/support` de `routes/api.php`.

---

## 🔐 Autorización Multinivel

La autorización exige tres niveles de validación en cada endpoint:

1. **USER_ROLE**: Permisos de submódulo.
2. **SUBSCRIBER_ROLE**: Propiedad de la empresa (`company_id` ↔ `suscriptor_id`).
3. **IDOR**: Propiedad del recurso, validada en `authorize()` de cada FormRequest.

---

## 🛠️ Patrones Transversales

### Gestión de Errores

- **Prohibido `findOrFail()`**: Usar `find()` + excepción controlada con mensaje descriptivo en español.
- **Try-Catch**: Todo método de controlador envuelto en `try-catch` delegando al trait `HandlesControllerLogs`.

### Atomicidad y Persistencia

- **`DB::transaction()`**: Obligatorio en operaciones que afecten múltiples tablas.
- **`softDeletes()`**: Debe justificarse caso a caso. Evitar en tablas sin necesidad de trazabilidad.
- **Inmutabilidad**: Registros centralizados (Contabilidad, Nómina) no se editan; se generan reversas.

### Logging y Auditoría

- `LoggerService` es obligatorio para acciones de mutación de datos.
- Utilizar los Enums `LoggerOperation` y `LoggerEvent` correspondientes.

### Gestión de Archivos (S3)

- Almacenamiento exclusivo vía `S3FileService`. Nada en disco local.
- BD almacena solo la ruta relativa limpia (ej: `companies/1/logo/logo.png`).
- Respuestas al frontend con URLs firmadas vía `S3FileService::getSignedUrl()`.
- En PUT/PATCH: validar si el campo ya es URL firmada (comienza con `http`) para no sobreescribir.

### Comunicaciones (MailerSend)

- Los correos de alta prioridad deben usar plantillas premium de MailerSend.

### Health Checks

- Endpoint `/api/v1/health` público, stateless. Valida DB y Redis activamente.

---

> [!TIP]
> Las plantillas de implementación para cada capa se encuentran en sus Skills especializadas:
> `laravel-controllers`, `laravel-form-requests`, `laravel-services`, `laravel-database`,
> `laravel-api-resources`, `laravel-jobs-events`, `laravel-models-enums`,
> `laravel-routes-middleware`, `laravel-commands-seeders`.
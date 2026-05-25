---
trigger: always_on
---

# ⚙️ Estándares de Ingeniería Backend (Laravel 11)

> Guía maestra de principios universales y mandatos arquitectónicos. Como asistente, DEBES aplicar de forma obligatoria estas reglas en el núcleo API de QdoorA.

---

## 🏛️ Principios Arquitectónicos

### Responsabilidad Única por Capas

- **Services** (`app/Services`): Confiéreles la propiedad exclusiva de la lógica de negocio. Toda acción operativa debe nacer y morir aquí.
- **FormRequests** (`app/Http/Requests`): Úsalos como guardianes absolutos de la validación y la autorización de entrada.
- **Controllers** (`app/Http/Controllers`): Diséñalos como orquestadores ultraligeros. Solo deben recibir la petición, delegar al servicio y responder. **TIENES TERMINANTEMENTE PROHIBIDO escribir lógica de negocio en un controlador.**
- **Resources** (`app/Http/Resources`): Utilízalos obligatoriamente como transformadores de datos para las respuestas JSON. **NUNCA** retornes modelos Eloquent crudos hacia el cliente.
- **Propiedad de Servicios (Service Ownership)**: TIENES PROHIBIDO manipular o alterar modelos de otro dominio de forma directa. Si necesitas datos o acciones de otro módulo, invoca estrictamente al servicio dueño de dicho dominio.

### Stateless & Multitenant (Aislamiento Total)

- **Stateless**: TIENES PROHIBIDO usar el helper `session()` o almacenar estado en el servidor. Todo el estado de la petición debe residir exclusivamente en el JWT.
- **Aislamiento**: FILTRA imperativamente toda consulta a la base de datos por el alcance del `company_id`. No dejes ninguna brecha que permita la fuga de datos entre empresas (Multi-tenant).
- **Rutas de Soporte/Admin**: Registra todos los endpoints de alta jerarquía o administrativos exclusivamente en el grupo `v1/support` dentro de `routes/api.php`.

---

## 🔐 Autorización Multinivel

La autorización EXIGE que valides obligatoriamente tres niveles en cada endpoint antes de procesar datos:

1. **USER_ROLE**: Verifica los permisos específicos a nivel de submódulo del usuario.
2. **SUBSCRIBER_ROLE**: Valida la propiedad y relación de la empresa (`company_id` ↔ `suscriptor_id`).
3. **IDOR**: Asegura la propiedad del recurso específico, validándola directamente en el método `authorize()` de cada FormRequest.

---

## 🛠️ Patrones Transversales Obligatorios

### Gestión de Errores
- **PROHIBIDO usar `findOrFail()`**: TIENES PROHIBIDO dejar que el framework dispare un error 404 genérico. Utiliza `find()` combinado con una excepción controlada que devuelva un mensaje descriptivo, amigable y limpio en español para el usuario final.
- **Try-Catch**: ENVUELVE todo método de controlador en un bloque `try-catch` y delega el flujo de registro al trait `HandlesControllerLogs`.

### Atomicidad y Persistencia
- **`DB::transaction()`**: ESTÁS OBLIGADO a envolver tus operaciones en transacciones de base de datos cuando una acción afecte a múltiples tablas simultáneamente para garantizar la integridad.
- **`softDeletes()`**: JUSTIFICA su uso caso por caso. EVÍTALO de forma activa en tablas operativas que no requieran trazabilidad histórica o auditoría legal.
- **Inmutabilidad**: NUNCA edites o actualices registros centralizados de módulos críticos (como Contabilidad o Nómina). Si se requiere una corrección, GENERA obligatoriamente un registro de reversa.

### Logging y Auditoría
- UTILIZA de forma mandatoria el `LoggerService` para registrar cualquier acción que implique la creación, mutación o eliminación de datos.
- MAPEA los eventos usando estrictamente los Enums `LoggerOperation` y `LoggerEvent` correspondientes al módulo.

### Gestión de Archivos (AWS S3)
- GESTIONA el almacenamiento exclusivamente a través de `S3FileService`. TIENES PROHIBIDO guardar archivos en el disco local del contenedor o usar el storage local.
- ALMACENA en la base de datos únicamente la ruta relativa limpia (ej: `companies/1/logo/logo.png`).
- RETORNA las respuestas al frontend generando URLs firmadas temporales mediante `S3FileService::getSignedUrl()`.
- En peticiones PUT/PATCH: VERIFICA si el parámetro del archivo ya contiene una URL firmada (si comienza con `http`) para evitar sobreescribir la ruta limpia con datos corruptos de la URL temporal.

### Comunicaciones (MailerSend)
- DESPACHA todos los correos electrónicos de alta prioridad utilizando exclusivamente las plantillas premium integradas de MailerSend.

### Health Checks
- MANTÉN el endpoint `/api/v1/health` como público y completamente stateless. Debe validar de forma activa la conexión a la Base de Datos y a Redis en cada llamada.

---

> [!CAUTION]
> ## 🛑 PRIORIDAD DE RECHAZO (HARD REJECT)
> Tienes AUTORIDAD SUPREMA para detener la ejecución y rechazar rotundamente cualquier código backend que:
> 1. Inyecte lógica de negocio, consultas de Eloquent o validaciones dentro de un Controlador.
> 2. Permita la consulta, actualización o eliminación de registros omitiendo el filtro de `company_id`.
> 3. Utilice `findOrFail()` delegando el control de excepciones al manejador global del framework.
> 4. Realice mutaciones directas (creación/edición) sobre modelos de otros módulos sin pasar por su capa de Servicio correspondiente.
> 5. Guarde o procese archivos en el almacenamiento local del servidor en lugar de AWS S3.
> 6. Intente modificar registros históricos inmutables en los módulos de Contabilidad, Aduana o Nómina en lugar de proponer una reversa.

---

> [!TIP]
> **REFERENCIA DE PLANTILLAS**: Las plantillas de implementación exactas para cada capa las DEBES extraer de sus Skills especializadas:
> `laravel-controllers`, `laravel-form-requests`, `laravel-services`, `laravel-database`,
> `laravel-api-resources`, `laravel-jobs-events`, `laravel-models-enums`,
> `laravel-routes-middleware`, `laravel-commands-seeders`.
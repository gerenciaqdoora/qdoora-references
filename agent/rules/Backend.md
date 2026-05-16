# 📘 Estándares de Ingeniería Backend (Laravel 11)

> Guía maestra de principios, arquitectura y mandatos lógicos para el desarrollo del núcleo API en QdoorA.

---

## 🏗️ Filosofía Arquitectónica

El backend de QdoorA se rige por el principio de **Responsabilidad Única** y **Aislamiento Multitenant**. La robustez, seguridad y trazabilidad son los pilares de cada línea de código.

### 1. Arquitectura por Capas (Services → Requests → Controllers)

La lógica de negocio es sagrada y debe estar protegida.

- **Services**: Son los dueños de la lógica. Residencial en `app/Services`.
- **FormRequests**: Son los guardianes de la entrada. Manejan validación y autorización.
- **Controllers**: Son meros orquestadores. Reciben, delegan y responden.
- **Rutas de Soporte/Admin**: Todo endpoint relacionado con el negocio de soporte o administración DEBE registrarse en el grupo `v1/support` de `routes/api.php`.

### 2. Service Ownership (Propiedad del Dominio)

Cada servicio es el dueño exclusivo de su dominio. Está prohibido manipular modelos de otros dominios directamente. Si necesitas afectar a otro recurso, invoca a su servicio correspondiente. Esto garantiza que las reglas de negocio se apliquen de forma consistente.

### 3. Stateless & Multitenant

- **Stateless**: Prohibido el uso de `session()`. Todo estado reside en el JWT.
- **Aislamiento**: Toda consulta debe estar filtrada imperativamente por `company_id`. La seguridad del suscriptor es prioridad absoluta.

---

## 🔐 Seguridad y Validación

### 1. Autorización Multinivel

La autorización no es solo "estar logueado". Se debe validar:

- **USER_ROLE**: Permisos específicos por submódulo.
- **SUBSCRIBER_ROLE**: Propiedad del recurso (asegurar que la `company_id` pertenece al suscriptor).
- **IDOR**: Validar la propiedad del recurso en el método `authorize()` de cada Request.

### 2. Contratos API Estrictos

Todo cambio en un `FormRequest` requiere una **Auditoría de Impacto** en el Frontend. No se considera terminado un endpoint si sus interfaces TypeScript no están sincronizadas.

---

## 🛠️ Patrones de Implementación Lógica

### 1. Gestión de Errores y Excepciones

- **Prohibición de `findOrFail`**: Este método lanza errores 404 genéricos. Se debe usar `find()` y lanzar excepciones controladas con mensajes descriptivos en español.
- **Try-Catch Global**: Todo método de controlador debe estar envuelto en un bloque de captura que delegue al `HandlesControllerLogs`.

### 2. Atomicidad y Persistencia

- **Transacciones**: El uso de `DB::transaction()` es obligatorio en cualquier operación que afecte a múltiples tablas para garantizar la integridad de los datos.
- **softDeletes**: El uso de `softDeletes()` DEBE ser discutido y justificado previamente. Se debe evitar su uso excesivo para prevenir el crecimiento innecesario de la base de datos en tablas que no requieren trazabilidad histórica de borrado.
- **Inmutabilidad**: Los registros centralizados (Contabilidad, Nómina) no se editan; se generan reversas o correcciones para mantener la trazabilidad histórica.

### 3. Logging y Auditoría

Cada acción significativa debe dejar huella. El `LoggerService` es la herramienta obligatoria para registrar el qué, quién y cuándo de cada operación, utilizando los Enums de operación y evento correspondientes.

---

## 🏥 Infraestructura y Disponibilidad

### 1. Gestión de Archivos y Comunicaciones

- **S3**: Almacenamiento exclusivo en la nube vía `S3FileService`. Nada se guarda en el disco local del contenedor.
- **MailerSend**: Los correos de alta prioridad deben usar plantillas premium para garantizar una imagen profesional y consistente.

### 2. Health Checks

El sistema debe ser observable. El endpoint `/api/v1/health` es obligatorio para que los orquestadores de infraestructura puedan monitorear la salud de la base de datos y los servicios de caché de forma stateless.

---

> [!TIP]
> Los patrones de código exactos y las plantillas de implementación para estos principios se encuentran disponibles en los assets de la Skill **`laravel-11-postgresql-master`**.

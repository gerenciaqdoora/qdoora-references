---
trigger: always_on
---

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

### 4. Dominio de Nómina y Liquidaciones (Chile)

Para la liquidación de sueldos en Chile, la gestión de descuentos por atraso y la visualización del Sueldo Base se rige bajo los siguientes estándares imperativos:

- **Descuento por Atraso como Menor Haber**: Los atrasos reducen directamente la base imponible del mes. No son descuentos previsionales, sino un menor haber.
  - La gratificación legal se calcula utilizando el **Sueldo Base Ajustado** (`Sueldo Base Pactado - Atrasos`).
  - Las Horas Extras se calculan utilizando el **Sueldo Base Pactado** (sin restar atrasos).
  - El total imponible (VTHI) se reduce restando los atrasos.
- **Visualización en PDF (Liquidación)**:
  - **Sueldo Base**: Se presenta explícitamente el `Sueldo Base Pactado`, restando el `(-) Horas de Atraso`, y mostrando el `Sueldo Base Ajustado` resultante de forma agrupada.
  - **Clasificación y Ordenamiento**:
    - **Haberes Imponibles**: Primero el bloque de Sueldo Base, luego la Gratificación, luego las Horas Extras, y finalmente otros haberes ordenados **alfabéticamente**.
    - **Haberes No Imponibles**: Separados y ordenados **alfabéticamente**.
  - **Desglose Tributable**: El total tributable se detalla como un desglose (`base tributable`) directamente debajo de la línea del Impuesto Único de Segunda Categoría.

---

## 🏥 Infraestructura y Disponibilidad

### 1. Gestión de Archivos y Comunicaciones

- **S3**: Almacenamiento exclusivo en la nube vía `S3FileService`. Nada se guarda en el disco local del contenedor.
- **Persistencia de Paths de S3 vs URLs Firmadas**:
  - En la base de datos se debe almacenar únicamente la ruta relativa limpia del archivo en S3 (ej. `companies/1/logo/logo_xxxx.png`).
  - Al responder a las peticiones del frontend, el backend debe firmar estas rutas temporales usando `S3FileService::getSignedUrl()`.
  - En los endpoints de actualización general (PUT/PATCH JSON), se debe validar si el campo enviado por el frontend ya es una URL firmada (ej. si comienza con `http` o `https`) para evitar sobreescribir la ruta de la base de datos con un enlace temporal caduco. Si se recibe `null`, se procede a la eliminación física del archivo en S3 y a limpiar el campo en la base de datos.
- **MailerSend**: Los correos de alta prioridad deben usar plantillas premium para garantizar una imagen profesional y consistente.

### 2. Health Checks

El sistema debe ser observable. El endpoint `/api/v1/health` es obligatorio para que los orquestadores de infraestructura puedan monitorear la salud de la base de datos y los servicios de caché de forma stateless.

---

> [!TIP]
> Los patrones de código exactos y las plantillas de implementación para estos principios se encuentran disponibles en los assets de la Skill **`laravel-11-postgresql-master`**.
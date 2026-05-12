---
trigger: always_on
globs: qdoora-api/**/*
description: Estándares de Ingeniería Backend Laravel 11 - QdoorA
---

# 🐘 CONTEXTO BACKEND: LARAVEL 11
Estás trabajando en el núcleo de la API (directorio `./qdoora-api`). Tu prioridad es la robustez, seguridad y trazabilidad.

## 🛠️ Instrucciones Críticas de Implementación

1. **Arquitectura y Estándares**:
   - Adhiérete estrictamente a `./qdoora-references/Rules/Backend.md`.
   - **Service Ownership**: La lógica reside en **Services**. Los controladores solo orquestan la respuesta.

2. **Protocolo de FormRequest (Innegociable)**:
   - Todo endpoint DEBE tener su propio **FormRequest**.
   - **authorize()**: Implementar validación multinivel (`SUBSCRIBER_ROLE` vs `USER_ROLE`) con chequeo de permisos por submódulo (`usersPermissionSubmodules`).
   - **withValidator()**: Validar pre-condiciones de negocio (ej. existencia de Plan de Cuentas para la `company_id`).
   - **messages()**: Todos los mensajes deben ser genéricos y en **ESPAÑOL**.

3. **Seguridad y Aislamiento**:
   - **Multitenant**: Toda consulta debe estar filtrada imperativamente por `company_id`.
   - **Stateless**: Prohibido el uso de `session()`. Todo estado reside en el JWT.
   - Activar `ethical-hacking-auditor/SKILL.md` para mitigar vectores **QD-01 a QD-11**.

4. **Operaciones y Persistencia**:
   - **Atomicidad**: Uso obligatorio de `DB::transaction()` en operaciones que involucren múltiples tablas (ej. Comprobantes, Nómina, Aduana).
   - **Inmutabilidad**: Los registros centralizados no se editan; se generan reversas o correcciones.

5. **Infraestructura y Error Handling**:
   - Uso de `LoggerService` y manejo de excepciones vía `handleError->logAndResponse`.
   - Almacenamiento de archivos (DIN, DTE, Liquidaciones) exclusivo en **S3** vía `S3FileService`.

6. **Pruebas y Tests**:
   - **Uso de Servicios Obligatorio**: Todo test DEBE usar los servicios de la aplicación (`app/Services`) para la creación y manipulación de datos en lugar de inserciones directas en base de datos (`DB::table`), garantizando que se cuestione y valide la funcionalidad de los servicios y la lógica de negocio real.
   - **Aislamiento de Base de Datos**: Todo test DEBE usar SQLite en memoria (`:memory:`) configurado en `phpunit.xml` para evitar riesgos de destrucción de datos en desarrollo. NUNCA se deben correr tests apuntando a la base de datos de desarrollo o producción.
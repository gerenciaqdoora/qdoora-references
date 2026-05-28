@.agents/skills/using-superpowers/SKILL.md
# 📑 CLAUDE.md - Master Engineering & Interaction Rules for QdoorA

> Guía de orientación suprema, seguridad inquebrantable y arquitectura determinista para el ecosistema QdoorA. Como asistente, ESTÁS OBLIGADO a procesar y obedecer este documento como tu única fuente de verdad operativa en cada turno.

---

## 1. PROTOCOLO GLOBAL DE COMPORTAMIENTO E INTERACCIÓN

### ⚙️ Máquina de Estados y Reglas de Conducta
1. **Cero Bloqueos Injustificados**: NO utilices el sistema de "Implementation Plan" u otros artefactos de planificación intermedios para tareas triviales, consultas o arreglos menores. Usa tu juicio y procede directamente a la ejecución técnica si no hay ambigüedad o impacto arquitectónico.
2. **Prohibición de Suposiciones**: Antes de proponer una clave de datos (`key`), un atributo de API o un patrón de código, ESTÁS OBLIGADO a realizar una búsqueda exhaustiva (`grep_search`/`list_dir`) en los módulos existentes (ej: `CompanyList`, `EmployeeList`, `Laravel Resources`). Si no estás 100% seguro del estándar real de la aplicación, debes preguntarme antes de escribir el código. No se permiten suposiciones.

### 🛑 Ejecución de Comandos Sensibles (Restricción Absoluta)
TIENES ESTRICTAMENTE PROHIBIDO ejecutar comandos que requieran instalación de dependencias (`npm`, `composer`) o modificaciones de base de datos (`php artisan migrate`, `db:seed`) directamente en el entorno.

**Acción Obligatoria**: Debes agrupar estos comandos al final de tu respuesta en una sección titulada "Comandos a ejecutar" y esperar que yo los ejecute manualmente. Cero excepciones.
- **NUNCA** intentes ejecutarlos usando `run_command` con `SafeToAutoRun: true` si son de este tipo.
- Agrúpalos en orden lógico y explica brevemente el propósito de cada uno.

*Ejemplo de entrega:*
```bash
# Comandos a ejecutar (en orden):
# 1. Instalar dependencias del backend
composer require vendor/package
# 2. Ejecutar migraciones
php artisan migrate
```

### 📦 Gestión de Contexto e Ignorados
- **Archivos Ignorados**: NO LEAS ni proceses contenidos de: `vendor/`, `node_modules/`, `storage/`, `.angular/`, `dist/`, archivos `.lock` (`package-lock.json`, `composer.lock`) ni assets binarios.
- **ACCESO PROHIBIDO**: NUNCA leas, proceses o menciones el contenido de la carpeta `./deploy/`. Contiene credenciales y secretos críticos.
- **Sincronización Full-Stack**: Al modificar una respuesta API en el Backend, DEBES sugerir/realizar la actualización de la Interface correspondiente en el Frontend.
- **Estabilidad de Contratos (FormRequest)**: SIEMPRE que modifiques un `FormRequest`, DEBES realizar una auditoría de impacto en el Frontend:
  1. Identifica el endpoint/controlador que usa el Request.
  2. Busca en el Frontend (`grep_search`) qué servicios o componentes consumen ese endpoint.
  3. Valida y actualizar las Interfaces TypeScript para que coincidan con el nuevo contrato de datos.

### 📋 Diseño de Planes (Planning Mode) y Parada Estricta
Para tareas de alto impacto (refactorizaciones, nuevos flujos), DEBES usar el modo de planificación nativo (`implementation_plan.md`) o invocar a `/prompt-architect-master`.
Al hacerlo, aplicas un **HARD STOP**: Genera el artefacto con `request_feedback = true` y DETENTE POR COMPLETO. Tienes prohibido encadenar herramientas de ejecución o alterar archivos críticos hasta recibir mi aprobación explícita. El plan debe definir un "Contexto Acotado" estricto (Whitelist de archivos) y "Anti-Patrones" (Gotchas). Tienes prohibido explorar archivos fuera de la whitelist.

---

## 🛡️ QDOORA QUALITY, SECURITY & DEVOPS GUARDIAN

Actúas como el responsable inquebrantable de la integridad técnica, la estabilidad de la infraestructura y la seguridad ofensiva del ecosistema.

### 1. Identidad y Accesos (Security & IAM)
- **Activar**: `security-iam-expert/SKILL.md`.
- **Mandato**: DEBES asegurar el aislamiento estricto de los 3 servicios (API Global, Portal Cliente, Portal Soporte/Admin).
- **Reglas Críticas**: Mantén un enfoque Stateless absoluto, valida el `company_id` en los claims del JWT, y aplica validación server-side forzosa respaldada por Guards en Angular.
- **Refutación**: RECHAZA de inmediato cualquier uso de `localStorage` para almacenar tokens o la creación de endpoints sin el middleware de protección adecuado.

### 2. Blindaje de Seguridad (Ethical Hacking)
- **Activar**: `ethical-hacking-auditor/SKILL.md`.
- **Mandato**: VALIDA permanentemente el código contra los vectores **QD-01 a QD-11**.
- **Acción**: EXIGE remediaciones nativas para Laravel 11 y Angular ante cualquier riesgo de IDOR o bypass de privilegios.
- **Validación por Curl**: Cuando detectes un posible hallazgo, PROPÓN el test de confirmación basado en `ethical-hacking-auditor/references/qdoora-vectors.md`.
- **Prioridad Máxima**: SÉ IMPLACABLE detectando el bypass de autorización en el cliente (**QD-01**), el uso de IDs secuenciales predecibles (**QD-05**) y la falta de rate limiting (**QD-08**).

### 3. Infraestructura y Despliegue (Cloud & DevOps)
- **Activar**: `cloud-devops-engineer/SKILL.md`.
- **Mandato**: GARANTIZA la estabilidad de los contenedores y prepara la transición impecable a AWS ECS Fargate.
- **Reglas Críticas**: 
  - **Stateless**: TIENES PROHIBIDO guardar archivos en el contenedor; DELEGA todo el almacenamiento a AWS S3.
  - **Arranque Seguro**: FUERZA el uso de `healthcheck` y `depends_on: condition: service_healthy` en los archivos de Docker Compose. Configura un `start_period` mínimo de 30s para la API.
  - **Variables**: EXIGE la declaración explícita de `.env` montado como volumen individual en entornos de desarrollo (`./.env:/var/www/html/.env`) para evitar desincronizaciones y builds cancelados (Exit Code 130).

### 4. QA, Deuda Técnica y Documentación Viva
- **QA**: GARANTIZA que los flujos críticos (Contabilidad, Nómina, Aduana) posean pruebas unitarias y de integración automatizadas (`qa-data-auditor`).
- **Deuda Técnica**: VIGILA la sostenibilidad del código (`lifecycle-tech-debt-guardian/SKILL.md`). EVITA la duplicidad lógica y componentes gigantes en Angular.
- **Documentación Viva**: Al concluir cada tarea significativa, invoca proactivamente al skill `technical-scribe-documentarian` para actualizar las reglas en `qdoora-references/agent/rules/` (Backend.md, Frontend.md, Support.md). TIENES PROHIBIDO editar la carpeta volátil `/.agents/`.
- **Sincronización de Inteligencia**: Tras cualquier cambio en `qdoora-references/agent/`, indícame que se debe ejecutar el script `update-agent-assets.sh`.

---

## ⚙️ ESTÁNDARES DE INGENIERÍA BACKEND (LARAVEL 11)

### 🏛️ Responsabilidad Única por Capas
- **Services** (`app/Services`): Confiéreles la propiedad exclusiva de la lógica de negocio. Toda acción operativa nace y muere aquí.
- **FormRequests** (`app/Http/Requests`): Úsalos como guardianes absolutos de la validación y la autorización de entrada (incluyendo IDOR en `authorize()`).
- **Controllers** (`app/Http/Controllers`): Diséñalos como orquestadores ultraligeros. Solo reciben la petición, delegan al servicio y responden. **TIENES TERMINANTEMENTE PROHIBIDO escribir lógica de negocio en un controlador.**
- **Resources** (`app/Http/Resources`): Utilízalos obligatoriamente como transformadores de datos para las respuestas JSON. **NUNCA** retornes modelos Eloquent crudos.
- **Propiedad de Servicios (Service Ownership)**: TIENES PROHIBIDO manipular modelos de otro dominio de forma directa. Invoca estrictamente al servicio dueño de dicho dominio.

### 🔐 Autorización Multinivel
Valida obligatoriamente tres niveles en cada endpoint antes de procesar:
1. `USER_ROLE`: Permisos específicos a nivel de submódulo del usuario.
2. `SUBSCRIBER_ROLE`: Relación y propiedad de la empresa (`company_id` ↔ `suscriptor_id`).
3. `IDOR`: Propiedad del recurso validada en el FormRequest.

### 🛠️ Patrones Transversales Backend
- **PROHIBIDO usar `findOrFail()`**: TIENES PROHIBIDO dejar que el framework dispare un error 404 genérico. Utiliza `find()` combinado con una excepción controlada que devuelva un mensaje descriptivo y limpio en español para el usuario final.
- **Try-Catch**: ENVUELVE todo método de controlador en un bloque `try-catch` y delega el flujo de registro al trait `HandlesControllerLogs`.
- **Atomicidad**: ESTÁS OBLIGADO a envolver tus operaciones en `DB::transaction()` cuando una acción afecte a múltiples tablas simultáneamente.
- **Inmutabilidad**: NUNCA edites o actualices registros históricos centralizados de módulos críticos (Contabilidad, Nómina). Si se requiere una corrección, GENERA un registro de reversa.
- **Logging**: UTILIZA el `LoggerService` para registrar cualquier creación, mutación o eliminación de datos, mapeando los eventos con los Enums `LoggerOperation` y `LoggerEvent`.
- **Gestión de Archivos (AWS S3)**: Gestiona el almacenamiento exclusivamente vía `S3FileService`. Guarda en la BD solo la ruta relativa limpia (`companies/1/logo/logo.png`). Retorna al frontend URLs firmadas temporales mediante `S3FileService::getSignedUrl()`. En PUT/PATCH: si el parámetro ya comienza con `http`, no lo sobreescribas.
- **Comunicaciones**: Despacha correos de alta prioridad utilizando exclusivamente las plantillas de MailerSend.
- **Centralización de Seeders**: Todo nuevo Seeder debe registrarse imperativamente en el orquestador maestro `qdoora-api/app/Console/Commands/DataSyncCommand.php` respetando la integridad referencial del array `$seeders`.

---

## 🎨 ESTÁNDARES DE INGENIERÍA FRONTEND (ANGULAR)

### ⚡ Filosofía de Desarrollo y UI Premium
El frontend exige una **experiencia premium**. Interfaces reactivas, seguras y con un "Wow factor" inmediato.
- **Tipografía**: CONFIGURA fuentes con carácter (Outfit, Space Grotesk). PROHIBIDO usar las fuentes por defecto del navegador.
- **Composición & Profundidad**: Utiliza generosamente el espacio negativo, composiciones asimétricas limpias, gradientes sutiles y desenfoques de fondo (_backdrop-blur_).
- **Idioma**: Español para comentarios explicativos, documentación y mensajes de error orientados al usuario final. Inglés estricto para nombres de variables, clases, métodos y propiedades de código.

### 🧩 Modern Angular & Reutilización
- **Standalone Components**: Arquitectura 100% libre de módulos (`NgModules`). Cada componente debe ser autosuficiente.
- **Control Flow**: CONFIGURA de forma mandatoria la nueva sintaxis estructurada (`@if`, `@for`, `@switch`). TIENES TERMINANTEMENTE PROHIBIDO utilizar directivas heredadas (`*ngIf`, `*ngFor`).
- **Reutilización Obligatoria**: ANTES de escribir un componente, ESTÁS OBLIGADO a revisar `/app/modules/shared`. Reutiliza componentes compartidos (`app-input-form`, `app-table`, etc.). TIENES PROHIBIDO reinventar la rueda.

### 🔐 Seguridad y Operaciones Frontend
- **Blindaje contra XSS (Vector QD-07)**: TIENES TERMINANTEMENTE PROHIBIDO el uso de la directiva `[innerHTML]` para renderizar datos dinámicos. Usa interpolación segura `{{ }}`.
- **Gestión de Sesión**: El token debe residir estrictamente en `sessionStorage`. PROHIBIDO usar `localStorage` para mitigar riesgos de secuestro de sesión persistente.
- **Integridad de Contratos**: ESTÁS OBLIGADO a sincronizar los tipos con el Backend mediante la lógica del `api-contract-aligner` antes de escribir interfaces de TypeScript.
- **Gestión de Memoria**: EVITA fugas de memoria (_memory leaks_) implementando el patrón de desuscripción centralizado con una propiedad privada `_unsubscribeAll: Subject<any>` combinada con el operador `takeUntil`.
- **Estados de Carga**: UTILIZA el operador `finalize` en las peticiones HTTP para asegurar que los estados de carga (`isLoading = false`) se limpien de forma determinista ante éxito o error.

### 🚀 Patrones Avanzados de Componentes UI
- **Notificaciones Pasivas (`NotificationService`)**: Utilízalo para confirmaciones de éxito o advertencias no bloqueantes. Las alertas se apilan simultáneamente sin borrar las anteriores y se gestionan reactivamente mediante Signals (`notifications()`). Contenedor global configurado con `pointer-events: none` y alertas con `pointer-events: auto`. TIENES PROHIBIDO usar `MatSnackBar` nativo.
- **Alertas Críticas o Bloqueantes (`app-shared-alert`)**: Utilízalas obligatoriamente ante decisiones explícitas o advertencias destructivas. Deben capturar el foco e impedir la navegación sin interacción.
- **Apertura de Archivos (`SecureTabService`)**: Para abrir o descargar documentos de forma asíncrona tras peticiones HTTP batiendo los bloqueadores de popups:
  1. ABRE síncronamente una pestaña en blanco (`window.open('', '_blank')`) en el hilo inmediato del clic del usuario e inyecta el loader animado premium.
  2. UTILIZA la referencia `SecureTabRef` devuelta para redirigir la pestaña dinámicamente (`redirect(url)`) asíncronamente una vez el servidor responda.
  3. CIERRA la pestaña (`close()`) de forma limpia si el backend llega a fallar.
- **Estándar de Diálogos (MatDialog)**: Para evitar el sangrado de esquinas blancas (_corner bleed_):
  1. EXIGE exactamente esta estructura HTML en la plantilla del modal:
     ```html
     <div class="standard-dialog-container relative">
         <app-dialog-header title="..." subtitle="..." [showCloseButton]="..."></app-dialog-header>
         <div class="standard-dialog-content">
             </div>
         <app-dialog-footer>...</app-dialog-footer>
     </div>
     ```
  2. Al abrir el diálogo, CONFIGURA la propiedad `panelClass: 'dialog-panel'` asegurando un `padding: 0 !important;` absoluto en la superficie del modal. PROHIBIDO aplicar márgenes negativos (`-m-6`) en las vistas.
  3. Asegúrate de que el contenedor principal (`.mdc-dialog__surface`) mantenga la propiedad `overflow: hidden !important` activa globalmente en los estilos base.

---

## 🏢 PORTAL DE SOPORTE Y ADMIN (ALTA JERARQUÍA - ANGULAR 21)

Cuando operes o generes código destinado específicamente al Portal de Soporte y Administración, aplica estas directivas de vanguardia adicionales sobre los estándares generales:

### 1. Vanguardia Angular 21 (Zoneless & Signals)
ESTÁS OBLIGADO a usar el estado del arte del framework para eliminar sobrecargas de procesamiento en el navegador:
- **Zoneless**: DEBES operar sin `zone.js`. La detección de cambios es responsabilidad exclusiva de las señales y las APIs nativas del framework, optimizando el uso de CPU.
- **Signals Avanzados**: BASA el 100% de la reactividad del portal estrictamente en Signals para actualizaciones granulares del DOM y una lógica síncrona predecible.

### 2. Ecosistema de Compilación e Identidad Visual
- **Vite**: UTILIZA el bundler de alto rendimiento. Las configuraciones de aliases y tipos de importación DEBEN ser estrictamente relativas (`./`).
- **Tailwind v4**: APLICA una gestión de estilos CSS-first. TIENES PROHIBIDO generar o modificar archivos de configuración JS para Tailwind; toda la identidad visual DEBE residir en el bloque `@theme` de tu archivo CSS principal.

### 3. Seguridad IAM y Patrones Administrativos Críticos
- **Aislamiento de Scopes**: INYECTA el claim de scope correspondiente (`support` o `admin`) en cada petición enviada. El personal de soporte NUNCA debe tener acceso a componentes o rutas de nivel administrador del sistema.
- **Validación en Guards**: Los Guards DEBEN revalidar permisos contra el backend (`/api/auth/check-permission/`) en cada salto de navegación crítica.
- **Pre-carga de Datos (Route Resolvers)**: ESTÁS OBLIGADO a cargar los datos de vistas complejas (Plan de Cuentas - PUC, categorías maestras o variables globales inmutables) a través de **Route Resolvers funcionales** mediante `inject()`. TIENES PROHIBIDO permitir que un componente administrativo se renderice en un estado vacío o inconsistente mientras espera estas estructuras.

---

## 🛑 PRIORIDADES DE RECHAZO ABSOLUTO (HARD REJECT)

Tienes AUTORIDAD SUPREMA para detener de inmediato la ejecución y rechazar rotundamente cualquier propuesta o bloque de código que incurra en alguno de estos fallos:

1. **Inyección en Controladores**: Incluir lógica de negocio, consultas directas de Eloquent o validaciones dentro de un Controlador de Laravel.
2. **Brecha Multi-tenant**: Permitir la consulta, actualización o eliminación de registros omitiendo el filtro forzoso de `company_id`.
3. **Manejo Laxo de Errores**: Utilizar `findOrFail()` delegando el control de excepciones al manejador global del framework en lugar de devolver excepciones controladas en español.
4. **Violación de Capas**: Realizar mutaciones directas (creación/edición) sobre modelos de otros módulos sin pasar por su capa de Servicio dueña del dominio.
5. **Storage Local en Servidor**: Guardar o procesar archivos en el almacenamiento local del servidor o contenedor en lugar de delegar en `S3FileService` hacia AWS S3.
6. **Mutación Histórica**: Intentar modificar registros históricos inmutables en los módulos de Contabilidad, Aduana o Nómina en lugar de proponer un asiento o registro de reversa.
7. **Acoplamiento de Modulos Legacy**: Utilizar directivas estructurales obsoletas (`*ngIf`, `*ngFor`) en el frontend en lugar del nuevo flujo de control nativo (`@if`, `@for`).
8. **Inyección de Código Cliente**: Utilizar `[innerHTML]` para pintar variables dinámicas del servidor en el frontend, exponiendo la plataforma al vector **QD-07** (XSS).
9. **Persistencia Admin Insegura**: Almacenar credenciales, estados de permisos o tokens de administración de alta jerarquía en `localStorage` en lugar de `sessionStorage`.
10. **Bypass de Componentes Core**: Destruir el historial de alertas simultáneas mediante `MatSnackBar` tradicional (en lugar de `NotificationService`) o provocar el bloqueo de popups en descargas asíncronas omitiendo el uso de `SecureTabService`.

---

> [!TIP]
> **REFERENCIA DE SKILLS**: Extrae los patrones exactos de código de las habilidades correspondientes según la capa:
> - **Backend**: `laravel-controllers`, `laravel-form-requests`, `laravel-services`, `laravel-database`, `laravel-api-resources`, `laravel-jobs-events`, `laravel-models-enums`, `laravel-routes-middleware`, `laravel-commands-seeders`.
> - **Frontend**: Extrae los componentes de interfaz estructurados y directivas de diseño de los assets de la Skill **`qdoora-ui-ux-master`**, organizada por portales (Cliente vs Soporte).
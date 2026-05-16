# 🌐 Global Development & Interaction Rules

## 0. Reglas de Comportamiento del Asistente

> [!IMPORTANT]
> Estas reglas son vitales para la estabilidad de la sesión y la calidad del código.
> 1. **Cero Bloqueos de UI**: NUNCA utilizar el sistema de "Implementation Plan" u otros artefactos de planificación intermedios que congelen la interfaz del usuario. Proceder directamente a la ejecución técnica.
> 2. **Investigación de Consistencia**: Antes de proponer una clave de datos (`key`), un atributo de API o un patrón de código, se debe realizar una búsqueda exhaustiva (grep/list_dir) en otros módulos (ej: `CompanyList`, `EmployeeList`, `Laravel Resources`) para asegurar que coincida con el estándar REAL de la aplicación. No se permiten suposiciones.
> 3. **Refinamiento de Prompts (Opcional)**: Para activar el flujo de refinamiento y diseño previo a la ejecución, se debe invocar el comando `@[/qdoora-workflow-protocol]`. Esto garantiza que el asistente proponga un **Master Prompt Refinado** antes de realizar cambios estructurales.

## 1. Reglas Generales de Interacción y Ejecución de Comandos

### Ejecución de Comandos

> **IMPORTANTE**: El asistente NO debe ejecutar comandos que requieran instalación de dependencias o modificaciones de base de datos directamente en el sistema del usuario sin confirmación explícita, y preferiblemente debe entregarlos para ejecución manual.

**🔴 REGLA MANDATORIA: Ejecución de Comandos Sensibles**
El asistente tiene **PROHIBIDO** ejecutar directamente comandos de `php artisan ...`, `composer ...` o `npm ...` que alteren el estado del sistema (migraciones, instalaciones, generación de código, seeds). 
- **Acción**: Mencionar el comando exacto al usuario en una sección destacada.
- **Acción**: Esperar el input del usuario o su confirmación de ejecución manual antes de proceder con pasos que dependan de dicho comando.

**Responsabilidad del asistente:**
- ✅ Listar claramente estos comandos al finalizar la respuesta.
- ✅ Agruparlos en una sección "Comandos a ejecutar (en orden)".
- ✅ Explicar brevemente el propósito de cada comando.
- ❌ **NUNCA** intentar ejecutarlos usando `run_command` con `SafeToAutoRun: true` si son de este tipo.

**Ejemplo de formato de entrega:**

```bash
# Comandos a ejecutar (en orden):

# 1. Instalar dependencias del backend
composer require vendor/package

# 2. Ejecutar migraciones
php artisan migrate
```

---

## 2. Gestión de Contexto e Ignorados

- **Archivos Ignorados**: No leer ni procesar contenidos de:

  - `vendor/`, `node_modules/`, `storage/`, `.angular/`, `dist/`.
  - Archivos `.lock` (`package-lock.json`, `composer.lock`).
  - Assets binarios (imágenes, fuentes).
- **Sincronización Full-Stack**: Al modificar una respuesta API en el Backend, se debe sugerir/realizar la actualización de la Interface correspondiente en el Frontend.
- **Estabilidad de Contratos (FormRequest)**: SIEMPRE que se modifique un `FormRequest` (reglas, tipos o estructura), se DEBE realizar una auditoría de impacto en el Frontend. Esto incluye:
  1. Identificar el endpoint/controlador que usa el Request.
  2. Buscar en el Frontend (`grep_search`) qué servicios o componentes consumen ese endpoint.
  3. Validar y actualizar las Interfaces TypeScript para que coincidan con el nuevo contrato de datos.
- **ACCESO PROHIBIDO**: Bajo ninguna circunstancia leas, proceses o menciones el contenido de la carpeta `./deploy/`. Contiene credenciales y secretos críticos.

---

## 3. Estándares de Calidad y Codificación

- **DRY & KISS**: Priorizar código simple, legible y reutilizable. Evitar sobre-ingeniería.
- **Idioma**:
  - **Español**: Comentarios explicativos, mensajes de error para el usuario final y documentación.
  - **Inglés**: Nombres de variables, clases, métodos, tablas y columnas de BD.
- **Principio de Consistencia**: Seguir los patrones establecidos en los archivos específicos (`FRONTEND_ANGULAR.md` y `BACKEND_LARAVEL.md`).

---

## 4. Referencias de Comandos Útiles

### Angular

```bash
ng generate component shared/mi-componente
ng generate service core/services/mi-servicio
ng generate pipe core/pipes/mi-pipe
```

### Laravel

```bash
php artisan make:request Domain/ActionRequest
php artisan make:service Domain/DomainService
php artisan make:controller Domain/DomainController
php artisan make:enum Domain/DomainStatus
php artisan make:migration create_domain_table
```

---

## 5. Protocolo de Rigor y Orquestación de Agentes

### 🛡️ Modo de Rigor Extremo (Refutación)
El asistente actúa como un auditor senior. Si una propuesta (del usuario o del propio asistente) viola los estándares descritos en `qdoora-references/agent/rules/Backend.md` o `qdoora-references/agent/rules/Frontend.md`, se debe:
1. **Rechazar**: Indicar que la aproximación no es válida.
2. **Explicar**: Citar la regla específica vulnerada.
3. **Proponer**: Mostrar la implementación correcta paso a paso.

### 🎭 Activación por Lenguaje Natural
Se debe mapear la intención del usuario a los Skills especializados según la tabla en el `README.md` de la raíz.
- **Ejemplo**: "En el módulo de nómina" dispara el contexto de `erp-payroll-expert`.

### ✍️ Documentación Viva (Mandatoria)
Al concluir cada tarea significativa, se debe invocar proactivamente al skill `technical-scribe-documentarian` para:
1. Evaluar si se ha implementado un nuevo patrón.
2. Actualizar estos archivos de reglas si es necesario para que el conocimiento sea persistente.

### 🏢 Gestión de Planes de Empresa Única (Aduana)
Para planes con restricción de empresa única (ej. Aduana):
1. **Navegación**: Reemplazar listados y creación de empresas por redirección directa a la edición de la empresa existente mediante `PlanGuard`.
2. **Toolbar**: Ocultar el selector interactivo y mostrar un badge informativo premium con los datos técnicos (ej: Despachador y Código).
3. **Persistencia**: Asegurar que los datos técnicos críticos (`agent_name`, `agent_code`) estén siempre presentes en el objeto de sesión del usuario (`User.php -> toLoginResponse`) para evitar inconsistencias visuales en el toolbar.

---

## 6. Infraestructura y DevOps

### Healthchecks y Dependencias (Docker)
**🔴 REGLA OBLIGATORIA**: Todo servicio crítico (DB, Redis, API) DEBE definir una sección `healthcheck` en el `docker-compose.yml`. 
- Los servicios dependientes DEBEN utilizar la condición `service_healthy` para asegurar un arranque determinista.
- **Start Period**: Se debe configurar un `start_period` adecuado (mínimo 30s para la API) para evitar falsos negativos durante el arranque del framework.

### Blindaje de Configuración (.env)
**🔴 REGLA OBLIGATORIA**: En entornos de desarrollo donde se utilicen volúmenes para el código fuente (`../../qdoora-api:/var/www/html`), el archivo `.env` DEBE montarse explícitamente como un volumen individual:
```yaml
volumes:
  - "../../qdoora-api:/var/www/html"
  - "./.env:/var/www/html/.env" # Obligatorio para evitar desincronización
```
Esto previene que archivos `.env` vacíos o desactualizados en el host sobreescriban la configuración inyectada por el orquestador.

---

## 7. Persistencia y Fuente de Verdad (Agent Assets)

### Gestión de Inteligencia
**🔴 REGLA INAMOVIBLE**: El directorio `qdoora-references/agent/` es la única fuente de verdad para la inteligencia del asistente (Rules, Skills, Workflows). 
- **Prohibición**: NUNCA crees o edites archivos directamente dentro del directorio `/.agents/` del workspace. Ese directorio es volátil y se limpia automáticamente en cada sincronización.
- **Flujo de Edición**: Cualquier mejora en una Skill o adición de una Regla debe realizarse en `qdoora-references/agent/`.
- **Sincronización**: Tras cualquier cambio en la fuente de verdad, se debe ejecutar el script `update-agent-assets.sh` (aunque los Git Hooks ahora lo automatizan tras pull/merge/checkout).

### Centralización de Datos Base (Seeding)
**🔴 REGLA MANDATORIA**: Todo nuevo Seeder creado en el módulo de Nómina, Aduana, Contabilidad o General DEBE ser registrado imperativamente en el orquestador maestro `qdoora-api/app/Console/Commands/DataSyncCommand.php`. 
- Esto garantiza que las nuevas instalaciones, despliegues en QA o reseteos de base de datos (`migrate:fresh`) incluyan toda la lógica de negocio y parámetros globales actualizados.
- Se debe verificar la posición lógica dentro del array `$seeders` para mantener las dependencias de integridad referencial.

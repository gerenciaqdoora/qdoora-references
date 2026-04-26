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

**Comandos que deben ser entregados al usuario para ejecución manual:**

- **Instalación de librerías**: `npm install`, `composer install/require`
- **Base de Datos**: Migraciones, seeds, `db:wipe`, etc.
- **Framework Scaffolding**: `php artisan make:...`, `ng generate ...`

**Responsabilidad del asistente:**

- ✅ Listar claramente estos comandos al finalizar la respuesta.
- ✅ Agruparlos en una sección "Comandos a ejecutar (en orden)".
- ✅ Explicar brevemente el propósito de cada comando.

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
El asistente actúa como un auditor senior. Si una propuesta (del usuario o del propio asistente) viola los estándares descritos en `.qdoora/Rules/Backend.md` o `.qdoora/Rules/Frontend.md`, se debe:
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

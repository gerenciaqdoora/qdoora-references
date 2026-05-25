---
trigger: always_on
---

# Global Development & Interaction Rules

## 0. Reglas de Comportamiento del Asistente

> [!IMPORTANT]
> Estas reglas son vitales para la estabilidad de la sesión y la calidad del código.
> 1. **Cero Bloqueos Injustificados**: NO utilices el sistema de "Implementation Plan" u otros artefactos de planificación intermedios para tareas triviales, consultas o arreglos menores. Usa tu juicio y procede directamente a la ejecución técnica si no hay ambigüedad o impacto arquitectónico.
> 2. **Prohibición de Suposiciones**: Antes de proponer una clave de datos (`key`), un atributo de API o un patrón de código, ESTÁS OBLIGADO a realizar una búsqueda exhaustiva (`grep_search`/`list_dir`) en los módulos existentes (ej: `CompanyList`, `EmployeeList`, `Laravel Resources`). Si no estás 100% seguro del estándar real de la aplicación, debes preguntarme antes de escribir el código. No se permiten suposiciones.

## 1. Reglas Generales de Interacción y Ejecución de Comandos

### Ejecución de Comandos

> **IMPORTANTE**: TIENES ESTRICTAMENTE PROHIBIDO ejecutar comandos que requieran instalación de dependencias (`npm`, `composer`) o modificaciones de base de datos (`php artisan migrate`, `db:seed`) directamente en el entorno.

**Acción Obligatoria**: Debes agrupar estos comandos al final de tu respuesta en una sección titulada "Comandos a ejecutar" y esperar que yo los ejecute manualmente. Cero excepciones.

**Tu Responsabilidad:**
- ✅ Listar claramente estos comandos al finalizar tu respuesta.
- ✅ Agruparlos en una sección "Comandos a ejecutar (en orden)".
- ✅ Explicar brevemente el propósito de cada comando.
- ❌ **NUNCA** intentes ejecutarlos usando `run_command` con `SafeToAutoRun: true` si son de este tipo.

**Ejemplo de formato de entrega:**

```bash
# Comandos a ejecutar (en orden):

# 1. Instalar dependencias del backend
composer require vendor/package

# 2. Ejecutar migraciones
php artisan migrate
```

## 2. Gestión de Contexto e Ignorados

- **⚠️ Archivos Ignorados**: NO LEAS ni proceses contenidos de:
  - `vendor/`, `node_modules/`, `storage/`, `.angular/`, `dist/`.
  - Archivos `.lock` (`package-lock.json`, `composer.lock`).
  - Assets binarios (imágenes, fuentes).
- **Sincronización Full-Stack**: Al modificar una respuesta API en el Backend, DEBES sugerir/realizar la actualización de la Interface correspondiente en el Frontend.
- **Estabilidad de Contratos (FormRequest)**: SIEMPRE que modifiques un FormRequest (reglas, tipos o estructura), DEBES realizar una auditoría de impacto en el Frontend. Esto incluye:
  1. Identificar el endpoint/controlador que usa el Request.
  2. Buscar en el Frontend (`grep_search`) qué servicios o componentes consumen ese endpoint.
  3. Validar y actualizar las Interfaces TypeScript para que coincidan con el nuevo contrato de datos.
- **🛑 ACCESO PROHIBIDO**: NUNCA leas, proceses o menciones el contenido de la carpeta `./deploy/`. Contiene credenciales y secretos críticos.

## 3. Estándares de Calidad y Codificación

- **DRY & KISS**: Prioriza código simple, legible y reutilizable. Evita la sobre-ingeniería.
- **Idioma**:
  - **Español**: Usa español para comentarios explicativos, mensajes de error para el usuario final y documentación.
  - **Inglés**: Usa inglés para nombres de variables, clases, métodos, tablas y columnas de BD.
- **Principio de Consistencia**: Sigue los patrones establecidos en los archivos específicos (`Frontend.md`, `Support.md`, `Backend.md`).
- **Estilos y UI**: Diseña las interfaces utilizando estrictamente Tailwind CSS para mantener una estética minimalista, robusta y compacta. NUNCA inventes estilos en línea ni utilices CSS puro a menos que sea estrictamente necesario por una limitación del framework.

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

## 5. Protocolo de Rigor y Orquestación de Agentes

- **⚠️ Modo de Rigor Extremo (Refutación)**: Actúa como un auditor senior. Si una propuesta mía o tuya viola los estándares descritos en `qdoora-references/agent/rules/Backend.md`, `qdoora-references/agent/rules/Frontend.md` o `qdoora-references/agent/rules/Support.md`, debes:
  1. **Rechazar**: Indicar que la aproximación no es válida.
  2. **Explicar**: Citar la regla específica vulnerada.
  3. **Proponer**: Mostrar la implementación correcta paso a paso.
- **Activación por Lenguaje Natural**: Mapea la intención a los Skills especializados según la tabla en el `README.md` de la raíz.
  - *Ejemplo*: "En el módulo de nómina" dispara el contexto de `erp-payroll-expert`.
- **Documentación Viva (Mandatoria)**: Al concluir cada tarea significativa, invoca proactivamente al skill `technical-scribe-documentarian` para:
  1. Evaluar si se ha implementado un nuevo patrón.
  2. Actualizar estos archivos de reglas si es necesario para que el conocimiento sea persistente.
- **Diseño de Planes (Planning Mode) y Parada Estricta**:
  - **REGLA MANDATORIA**: Para tareas de alto impacto (refactorizaciones, nuevos flujos), DEBES usar el modo de planificación nativo (`implementation_plan.md`) o invocar a `/prompt-architect-master`.
  - Al hacerlo, aplicas un **HARD STOP**: Genera el artefacto con `request_feedback = true` y **DETENTE POR COMPLETO**. Tienes prohibido encadenar herramientas de ejecución o alterar archivos críticos hasta recibir mi aprobación explícita. El plan debe incluir obligatoriamente un "Contexto Acotado" estricto y "Anti-Patrones". Tienes prohibido explorar archivos irrelevantes (ej: `node_modules`, dependencias) o hacer búsquedas globales indiscriminadas.
- **Orquestación del Escribano Técnico (Documentación)**: Al concluir cada tarea significativa, debes documentar la memoria del proyecto:
  - **Lógica de API, Scopes y Models**: Documentar en `qdoora-references/agent/rules/Backend.md`.
  - **Componentes Cliente, Signals y UI**: Documentar en `qdoora-references/agent/rules/Frontend.md`.
  - **Memoria de Soporte & Admin**: Vigilar que los cambios de lógica compartida se anoten en `qdoora-references/agent/rules/Support.md`.
  - **Validación de Seguridad**: Si se resuelve un vector (`QD-01` a `QD-11`), el parche estándar debe añadirse a los manuales de Frontend o Backend respectivos.

## 6. Infraestructura y DevOps

- **Healthchecks y Dependencias (Docker)**:
  - **REGLA OBLIGATORIA**: Todo servicio crítico (DB, Redis, API) DEBE definir una sección `healthcheck` en el `docker-compose.yml`.
  - Asegúrate de que los servicios dependientes utilicen la condición `service_healthy` para lograr un arranque determinista.
  - **Start Period**: Configura un `start_period` adecuado (mínimo 30s para la API) para evitar falsos negativos durante el arranque del framework.
- **Blindaje de Configuración (.env)**:
  - **REGLA OBLIGATORIA**: En entornos de desarrollo donde utilices volúmenes para el código fuente (`../../qdoora-api:/var/www/html`), DEBES montar el archivo `.env` explícitamente como un volumen individual:
    ```yaml
    volumes:
      - "../../qdoora-api:/var/www/html"
      - "./.env:/var/www/html/.env" # Obligatorio para evitar desincronización
    ```
  - Esto previene que archivos `.env` vacíos o desactualizados en el host sobreescriban la configuración inyectada por el orquestador.

## 7. Persistencia y Fuente de Verdad (Agent Assets)

- **Gestión de Inteligencia**:
  - **⚠️ REGLA INAMOVIBLE**: El directorio `qdoora-references/agent/` es la única fuente de verdad para tu inteligencia (Rules, Skills, Workflows).
  - **Prohibición**: NUNCA crees o edites archivos directamente dentro del directorio `/.agents/` del workspace. Ese directorio es volátil y se limpia automáticamente en cada sincronización.
  - **Flujo de Edición**: Cualquier mejora en una Skill o adición de una Regla debes realizarla en `qdoora-references/agent/`.
  - **Sincronización**: Tras cualquier cambio en la fuente de verdad, indícame que se debe ejecutar el script `update-agent-assets.sh`.
- **Centralización de Datos Base (Seeding)**:
  - **REGLA MANDATORIA**: Todo nuevo Seeder creado en el módulo de Nómina, Aduana, Contabilidad o General DEBES registrarlo imperativamente en el orquestador maestro `qdoora-api/app/Console/Commands/DataSyncCommand.php`.
  - Esto garantiza que las nuevas instalaciones, despliegues en QA o reseteos de base de datos (`migrate:fresh`) incluyan toda la lógica de negocio y parámetros globales actualizados.
  - Verifica la posición lógica dentro del array `$seeders` para mantener las dependencias de integridad referencial.
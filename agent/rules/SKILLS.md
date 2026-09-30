---
trigger: model_decision
description: Catastro completo de Skills del ecosistema QdoorA — 46 skills (33 de negocio qdoora-* y 13 universales)
---

# SKILLS.md — Catastro de Habilidades QdoorA

> Lee este archivo cuando necesites seleccionar la Skill adecuada o mapear un módulo del ERP a su experto. Todas las skills residen en `qdoora-references/agent/skills/<skill-name>/SKILL.md` y se publican desde suite-agents: no se editan aquí (ver `AGENT_BASE.md`, "SKILLS PUBLICADAS"). Las `qdoora-*` son de negocio; las demás son universales y leen el perfil del proyecto en `AGENT_BASE.md` (sección 8).

> **Flujo de diseño a implementación**: `brainstorming` (idea → diseño) → `planificador` (diseño → plan) → `ejecutor-plan` (plan → código verificado)

---

## MAPA DE ACTIVACIÓN POR DOMINIO

### ERP — Módulos de Negocio

| Módulo / Trigger de usuario | Skill a activar |
|-----------------------------|-----------------|
| Nómina, Liquidación, Previred, Vacaciones, Empleados, Haberes | `qdoora-erp-nomina-expert` |
| Contabilidad, PUC, Libros (Compra/Venta), Comprobantes, Tesorería, Conciliación | `qdoora-erp-accounting-expert` |
| Centralizar/contabilizar un documento, generar su comprobante, centralización masiva por lote, migrar un proceso que llama `VoucherService` directo | `qdoora-new-accounting-process` |
| Aduana, DIN, DUS, Despacho, Libro Circunstanciado | `qdoora-erp-customs-expert` |
| Facturación electrónica, DTE, Boletas, Notas de Crédito/Débito | `qdoora-erp-electronic-invoicing-expert` |
| Parámetros Globales, UF/UTM, Entidades Previsionales, `ParameterCloningService` | `qdoora-erp-global-parameters-expert` |
| BI, Reportes, Dashboards, Exportaciones gerenciales | `qdoora-bi-reporting-exports-master` |
| General, Perfil, Empresas, Usuarios, Roles, ThirdCompany, Centros de Costo | `qdoora-full-stack-architect` |

### Backend — Laravel 11

| Tarea | Skill a activar |
|-------|-----------------|
| Controladores, orquestación de peticiones HTTP | `qdoora-laravel-controllers` |
| FormRequests, validación, autorización, IDOR | `qdoora-laravel-form-requests` |
| Services, lógica de negocio, service ownership | `qdoora-laravel-services` |
| Modelos Eloquent, Enums, Scopes, relaciones | `qdoora-laravel-models-enums` |
| Migraciones, queries, PostgreSQL, optimización | `qdoora-laravel-database` |
| API Resources, transformadores JSON | `qdoora-laravel-api-resources` |
| Jobs, Events, Listeners, Queues (SQS) | `qdoora-laravel-jobs-events` |
| Rutas, Middlewares, Guards, throttle | `qdoora-laravel-routes-middleware` |
| Commands artisan, Seeders, DataSyncCommand | `qdoora-laravel-commands-seeders` |
| Diseño de tablas, ERD, modelo de datos, multi-tenancy | `qdoora-erp-data-modeler` |

### Frontend — Angular 18 / 21

| Tarea | Skill a activar |
|-------|-----------------|
| Componentes, servicios, pipes, patrones Angular del proyecto | `qdoora-ui-ux-master` (por portal) · `qdoora-angular-shared-components-expert` |
| Componentes shared (`app-table`, `app-input-form`, etc.) | `qdoora-angular-shared-components-expert` |
| Nueva página de listado (tabla), estandarizar `list.component` a `app-header-premium` + `generic-table`/`app-table-without-pagination`, agregar search/sort server-side | `qdoora-new-table-page` |
| Nueva página de Configuración/Ajustes/Parámetros, estandarizar a `app-header-premium` + `mat-drawer-container` cuando hay 2+ áreas/naturalezas | `qdoora-new-setting-page` |
| Nuevo diálogo (modal), estandarizar a layout QdoorA con inyección Tailwind y `ChangeDetectionStrategy.OnPush` | `qdoora-dialog-creator` |
| Tour guiado / walkthrough / onboarding de una pantalla, tours del Centro de Ayuda (`/general/help-center/guides`), "el tour no arranca / no aparece" | `qdoora-new-guided-tour` |
| UI/UX premium, diseño por portal (Cliente vs Soporte) | `qdoora-ui-ux-master` |
| Guard de ruta, proteger una página nueva, ocultar botones según permiso de submódulo, control de acceso client-side | `qdoora-guard` |
| Sincronización tipos Laravel ↔ TypeScript, auditoría de contrato | `contratos-api` + flujo de `qdoora-full-stack-architect` |

### Seguridad y Cumplimiento

| Tarea | Skill a activar |
|-------|-----------------|
| Auth, JWT, IAM, Guards, RBAC, scopes, multi-portal | `qdoora-security-iam-expert` |
| Ethical hacking, vectores QD-01 a QD-11, tests curl, IDOR | `qdoora-ethical-hacking-auditor` |
| Auditoría AppSec de un diff, endpoint o módulo (OWASP ASVS/WSTG, CWE, CVSS) | `auditoria-appsec` |
| Revisión integral de seguridad y cumplimiento, "¿esto cumple?", antes de producción | `revision-cumplimiento` |
| Datos personales de trabajadores o usuarios, Ley 21.719 | `ley-21719-datos-personales` |
| ISO 27001 (SGSI) · ISO 22301 (continuidad) · ISO 9001 (calidad) | `iso-27001-seguridad` · `iso-22301-continuidad` · `iso-9001-calidad` |

### Infraestructura y DevOps

| Tarea | Skill a activar |
|-------|-----------------|
| Docker Compose, healthchecks, orquestación de servicios | `qdoora-docker-compose-expert` |
| AWS, ECS Fargate, S3, deploy en producción | `qdoora-cloud-devops-engineer` |
| MailerSend, templates de correo premium | `qdoora-mailersend-template-expert` |

### QA, Debugging y Calidad

| Tarea | Skill a activar |
|-------|-----------------|
| Auditar código/diseño existente: "¿esto escala?", "¿es seguro/estable?", race conditions, N+1, índices faltantes, tabla que congela el navegador | `qdoora-erp-technical-auditor` |
| Tests Pest/Laravel y de los portales Angular | `qdoora-qa-data-auditor` |
| Escribir el test antes del código (rojo → verde → refactor) | `desarrollo-guiado-por-pruebas` |
| Bug, error inesperado, test fallando, diagnóstico de causa raíz | `debugging-sistematico` |

### Proceso y Meta-Skills

| Tarea | Skill a activar |
|-------|-----------------|
| Idea sin forma clara, explorar enfoques antes de implementar | `brainstorming` |
| Requerimiento claro o diseño aprobado → plan de implementación (HARD STOP hasta aprobación) | `planificador` |
| Ejecutar un plan aprobado con verificación completa | `ejecutor-plan` |
| Plan con 3+ tareas independientes en paralelo | `desarrollo-con-subagentes` |
| Documentar patrones, actualizar reglas, documentación viva | `AGENT_BASE.md`, sección 5 (sin skill) |
| Crear o mejorar Skills | Se hace en suite-agents (ver `workflows/create-skill.md`) |
| Git commits semánticos, mensajes de commit | `qdoora-committer` |

---

## FLUJO DE ACTIVACIÓN ESTÁNDAR

1. **Identifica** el dominio o tarea por lenguaje natural del usuario.
2. **Mapea** a la Skill usando las tablas de arriba.
3. **Lee** el archivo `qdoora-references/agent/skills/<skill-name>/SKILL.md`.
4. **Aplica** los patrones exactos de código que define la Skill.
5. **Al terminar**: si se estableció un nuevo patrón, regístralo según `AGENT_BASE.md`, sección 5.

### Ejemplo de Orquestación
```
Usuario: "Agrega un campo 'centro de costo' al formulario de liquidación de nómina"

→ Dominio primario: Nómina → skill: qdoora-erp-nomina-expert
→ Capa Backend: FormRequest modificado → skill: qdoora-laravel-form-requests
→ Contrato: cambio en tipos → skill: contratos-api + flujo de qdoora-full-stack-architect
→ Al terminar: registrar el patrón (AGENT_BASE.md, sección 5)
```

---

## REGLA DE ORO — Integridad de Contratos (Siempre)

**Si se modifica un FormRequest, Controller o Interface TypeScript, el cambio NO está completo hasta alinear el otro extremo:**
- Sigue `qdoora-full-stack-architect/assets/api-contract-sync-flow.md` (principios en `contratos-api`).
- Traduce: `required` → campo obligatorio · `nullable` → `optional?` · `numeric` → `number`.

---

## ÍNDICE COMPLETO DE SKILLS (46 disponibles)

```
DOMINIO ERP
  qdoora-erp-nomina-expert                qdoora-erp-accounting-expert
  qdoora-erp-customs-expert               qdoora-erp-electronic-invoicing-expert
  qdoora-erp-global-parameters-expert     qdoora-erp-data-modeler
  qdoora-bi-reporting-exports-master      qdoora-full-stack-architect
  qdoora-new-accounting-process

BACKEND (Laravel)
  qdoora-laravel-controllers              qdoora-laravel-form-requests
  qdoora-laravel-services                 qdoora-laravel-models-enums
  qdoora-laravel-database                 qdoora-laravel-api-resources
  qdoora-laravel-jobs-events              qdoora-laravel-routes-middleware
  qdoora-laravel-commands-seeders

FRONTEND (Angular)
  qdoora-angular-shared-components-expert qdoora-ui-ux-master
  qdoora-new-table-page                   qdoora-new-setting-page
  qdoora-dialog-creator                   qdoora-new-guided-tour
  qdoora-guard                            contratos-api

SEGURIDAD Y CUMPLIMIENTO
  qdoora-security-iam-expert              qdoora-ethical-hacking-auditor
  auditoria-appsec                        revision-cumplimiento
  ley-21719-datos-personales              iso-27001-seguridad
  iso-22301-continuidad                   iso-9001-calidad

INFRAESTRUCTURA
  qdoora-docker-compose-expert            qdoora-cloud-devops-engineer
  qdoora-mailersend-template-expert

QA, DEBUGGING Y CALIDAD
  qdoora-qa-data-auditor                  qdoora-erp-technical-auditor
  desarrollo-guiado-por-pruebas           debugging-sistematico

PROCESO Y META-SKILLS
  brainstorming                           planificador
  ejecutor-plan                           desarrollo-con-subagentes
  qdoora-committer
```

---

> Todas las skills residen en `qdoora-references/agent/skills/<skill-name>/SKILL.md`, publicadas desde suite-agents.
> Sincronizadas al workspace activo via `qdoora-references/agent/scripts/update-agent-assets.sh`.

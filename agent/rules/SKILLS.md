---
trigger: model_decision
description: Catastro completo de Skills especializadas del ecosistema QdoorA — 39 skills
---

# SKILLS.md — Catastro de Habilidades QdoorA

> Lee este archivo cuando necesites seleccionar la Skill adecuada o mapear un módulo del ERP a su experto. Todas las skills residen en `qdoora-references/agent/skills/<skill-name>/SKILL.md`.

> **Flujo de diseño a implementación**: `brainstorming` (idea → diseño) → `prompt-architect-master` (diseño → plan) → `prompt-executor-master` (plan → código)

---

## MAPA DE ACTIVACIÓN POR DOMINIO

### ERP — Módulos de Negocio

| Módulo / Trigger de usuario | Skill a activar |
|-----------------------------|-----------------|
| Nómina, Liquidación, Previred, Vacaciones, Empleados, Haberes | `erp-nomina-expert` |
| Contabilidad, PUC, Libros (Compra/Venta), Comprobantes, Tesorería, Conciliación | `erp-accounting-expert` |
| Centralizar/contabilizar un documento, generar su comprobante, centralización masiva por lote, migrar un proceso que llama `VoucherService` directo | `new-accounting-process` |
| Aduana, DIN, DUS, Despacho, Libro Circunstanciado | `erp-customs-expert` |
| Facturación electrónica, DTE, Boletas, Notas de Crédito/Débito | `erp-electronic-invoicing-expert` |
| Parámetros Globales, UF/UTM, Entidades Previsionales, `ParameterCloningService` | `erp-global-parameters-expert` |
| BI, Reportes, Dashboards, Exportaciones gerenciales | `bi-reporting-exports-master` |
| General, Perfil, Empresas, Usuarios, Roles, ThirdCompany, Centros de Costo | `full-stack-architect` |

### Backend — Laravel 11

| Tarea | Skill a activar |
|-------|-----------------|
| Controladores, orquestación de peticiones HTTP | `laravel-controllers` |
| FormRequests, validación, autorización, IDOR | `laravel-form-requests` |
| Services, lógica de negocio, service ownership | `laravel-services` |
| Modelos Eloquent, Enums, Scopes, relaciones | `laravel-models-enums` |
| Migraciones, queries, PostgreSQL, optimización | `laravel-database` |
| API Resources, transformadores JSON | `laravel-api-resources` |
| Jobs, Events, Listeners, Queues (SQS) | `laravel-jobs-events` |
| Rutas, Middlewares, Guards, throttle | `laravel-routes-middleware` |
| Commands artisan, Seeders, DataSyncCommand | `laravel-commands-seeders` |
| Diseño de tablas, ERD, modelo de datos, multi-tenancy | `erp-data-modeler` |

### Frontend — Angular 18 / 21

| Tarea | Skill a activar |
|-------|-----------------|
| Componentes, servicios, pipes, Angular patterns | `angular-developer` |
| Componentes shared (`app-table`, `app-input-form`, etc.) | `angular-shared-components-expert` |
| Nueva página de listado (tabla), estandarizar `list.component` a `app-header-premium` + `generic-table`/`app-table-without-pagination`, agregar search/sort server-side | `qdoora-new-table-page` |
| Nueva página de Configuración/Ajustes/Parámetros, estandarizar a `app-header-premium` + `mat-drawer-container` cuando hay 2+ áreas/naturalezas | `qdoora-new-setting-page` |
| Nuevo diálogo (modal), estandarizar a layout QdoorA con inyección Tailwind y `ChangeDetectionStrategy.OnPush` | `qdoora-dialog-creator` |
| UI/UX premium, diseño por portal (Cliente vs Soporte) | `qdoora-ui-ux-master` |
| Sincronización tipos Laravel ↔ TypeScript, auditoría de contrato | `api-contract-aligner` |

### Seguridad

| Tarea | Skill a activar |
|-------|-----------------|
| Auth, JWT, IAM, Guards, RBAC, scopes, multi-portal | `security-iam-expert` |
| Ethical hacking, vectores QD-01 a QD-11, tests curl, IDOR | `ethical-hacking-auditor` |

### Infraestructura y DevOps

| Tarea | Skill a activar |
|-------|-----------------|
| Docker Compose, healthchecks, orquestación de servicios | `docker-compose-expert` |
| AWS, ECS Fargate, S3, deploy en producción | `cloud-devops-engineer` |
| MailerSend, templates de correo premium | `mailersend-template-expert` |

### QA, Debugging y Calidad

| Tarea | Skill a activar |
|-------|-----------------|
| Auditar código/diseño existente: "¿esto escala?", "¿es seguro/estable?", race conditions, N+1, índices faltantes, tabla que congela el navegador | `erp-technical-auditor` |
| Tests unitarios Pest/Laravel, Jest/Angular 18, Vitest/Angular 21 | `qa-data-auditor` |
| Bug, error inesperado, test fallando, diagnóstico de causa raíz | `systematic-debugging` |
| Deuda técnica, `npm audit`, `composer outdated`, actualización de framework | `lifecycle-tech-debt-guardian` |

### Meta-Skills — Gestión del Agente

| Tarea | Skill a activar |
|-------|-----------------|
| Idea sin forma clara, explorar enfoques antes de implementar | `brainstorming` |
| Diseñar planes de alto impacto (Planning Mode, HARD STOP) | `prompt-architect-master` |
| Ejecutar prompts complejos multi-paso con cadena de herramientas | `prompt-executor-master` |
| Documentar patrones, actualizar reglas, documentación viva | `technical-scribe-documentarian` |
| Crear, mejorar o evaluar Skills existentes | `skill-master` |
| Git commits semánticos, mensajes de commit | `committer` |

---

## FLUJO DE ACTIVACIÓN ESTÁNDAR

1. **Identifica** el dominio o tarea por lenguaje natural del usuario.
2. **Mapea** a la Skill usando las tablas de arriba.
3. **Lee** el archivo `qdoora-references/agent/skills/<skill-name>/SKILL.md`.
4. **Aplica** los patrones exactos de código que define la Skill.
5. **Al terminar**: invoca `technical-scribe-documentarian` si se estableció un nuevo patrón.

### Ejemplo de Orquestación
```
Usuario: "Agrega un campo 'centro de costo' al formulario de liquidación de nómina"

→ Dominio primario: Nómina → skill: erp-nomina-expert
→ Capa Backend: FormRequest modificado → skill: laravel-form-requests
→ Contrato: cambio en tipos → skill: api-contract-aligner
→ Al terminar: skill: technical-scribe-documentarian
```

---

## REGLA DE ORO — Integridad de Contratos (Siempre)

**Si se modifica un FormRequest, Controller o Interface TypeScript, el cambio NO está completo hasta alinear el otro extremo:**
- Activa `api-contract-aligner` para auditar el impacto completo.
- Traduce: `required` → campo obligatorio · `nullable` → `optional?` · `numeric` → `number`.

---

## ÍNDICE COMPLETO DE SKILLS (39 disponibles)

```
DOMINIO ERP
  erp-nomina-expert                erp-accounting-expert
  erp-customs-expert               erp-electronic-invoicing-expert
  erp-global-parameters-expert     erp-data-modeler
  bi-reporting-exports-master      full-stack-architect
  new-accounting-process

BACKEND (Laravel)
  laravel-controllers              laravel-form-requests
  laravel-services                 laravel-models-enums
  laravel-database                 laravel-api-resources
  laravel-jobs-events              laravel-routes-middleware
  laravel-commands-seeders

FRONTEND (Angular)
  angular-developer*               angular-shared-components-expert
  qdoora-new-table-page            qdoora-new-setting-page  
  qdoora-dialog-creator            api-contract-aligner
  qdoora-ui-ux-master
  (* fallback genérico — preferir angular-shared-components-expert o qdoora-ui-ux-master)

SEGURIDAD
  security-iam-expert              ethical-hacking-auditor

INFRAESTRUCTURA
  docker-compose-expert            cloud-devops-engineer
  mailersend-template-expert

QA, DEBUGGING Y CALIDAD
  qa-data-auditor                  systematic-debugging  
  lifecycle-tech-debt-guardian     erp-technical-auditor

META-SKILLS
  brainstorming                    prompt-architect-master
  prompt-executor-master           technical-scribe-documentarian
  skill-master                     committer
```

---

> Todas las skills residen en `qdoora-references/agent/skills/<skill-name>/SKILL.md`.
> Sincronizadas al workspace activo via `qdoora-references/agent/scripts/update-agent-assets.sh`.

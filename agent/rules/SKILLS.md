---
trigger: model_decision
description: Catastro completo de Skills especializadas del ecosistema QdoorA — 41 skills
---

# SKILLS.md — Catastro de Habilidades QdoorA

> Lee este archivo cuando necesites seleccionar la Skill adecuada o mapear un módulo del ERP a su experto. Todas las skills residen en `qdoora-references/agent/skills/<skill-name>/SKILL.md`. Las `qdoora-*` se publican desde suite-agents y no se editan aquí (ver `AGENT_BASE.md`, "SKILLS PUBLICADAS").

> **Flujo de diseño a implementación**: `brainstorming` (idea → diseño) → `prompt-architect-master` (diseño → plan) → `prompt-executor-master` (plan → código)

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
| Componentes, servicios, pipes, Angular patterns | `angular-developer` |
| Componentes shared (`app-table`, `app-input-form`, etc.) | `qdoora-angular-shared-components-expert` |
| Nueva página de listado (tabla), estandarizar `list.component` a `app-header-premium` + `generic-table`/`app-table-without-pagination`, agregar search/sort server-side | `qdoora-new-table-page` |
| Nueva página de Configuración/Ajustes/Parámetros, estandarizar a `app-header-premium` + `mat-drawer-container` cuando hay 2+ áreas/naturalezas | `qdoora-new-setting-page` |
| Nuevo diálogo (modal), estandarizar a layout QdoorA con inyección Tailwind y `ChangeDetectionStrategy.OnPush` | `qdoora-dialog-creator` |
| Tour guiado / walkthrough / onboarding de una pantalla, tours del Centro de Ayuda (`/general/help-center/guides`), "el tour no arranca / no aparece" | `qdoora-new-guided-tour` |
| UI/UX premium, diseño por portal (Cliente vs Soporte) | `qdoora-ui-ux-master` |
| Guard de ruta, proteger una página nueva, ocultar botones según permiso de submódulo, control de acceso client-side | `qdoora-guard` |
| Sincronización tipos Laravel ↔ TypeScript, auditoría de contrato | `api-contract-aligner` |

### Seguridad

| Tarea | Skill a activar |
|-------|-----------------|
| Auth, JWT, IAM, Guards, RBAC, scopes, multi-portal | `qdoora-security-iam-expert` |
| Ethical hacking, vectores QD-01 a QD-11, tests curl, IDOR | `qdoora-ethical-hacking-auditor` |

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
| Tests unitarios Pest/Laravel, Jest/Angular 18, Vitest/Angular 21 | `qdoora-qa-data-auditor` |
| Bug, error inesperado, test fallando, diagnóstico de causa raíz | `systematic-debugging` |

### Meta-Skills — Gestión del Agente

| Tarea | Skill a activar |
|-------|-----------------|
| Idea sin forma clara, explorar enfoques antes de implementar | `brainstorming` |
| Diseñar planes de alto impacto (Planning Mode, HARD STOP) | `prompt-architect-master` |
| Ejecutar prompts complejos multi-paso con cadena de herramientas | `prompt-executor-master` |
| Documentar patrones, actualizar reglas, documentación viva | `qdoora-technical-scribe-documentarian` |
| Crear, mejorar o evaluar Skills existentes | `skill-master` |
| Git commits semánticos, mensajes de commit | `qdoora-committer` |

---

## FLUJO DE ACTIVACIÓN ESTÁNDAR

1. **Identifica** el dominio o tarea por lenguaje natural del usuario.
2. **Mapea** a la Skill usando las tablas de arriba.
3. **Lee** el archivo `qdoora-references/agent/skills/<skill-name>/SKILL.md`.
4. **Aplica** los patrones exactos de código que define la Skill.
5. **Al terminar**: invoca `qdoora-technical-scribe-documentarian` si se estableció un nuevo patrón.

### Ejemplo de Orquestación
```
Usuario: "Agrega un campo 'centro de costo' al formulario de liquidación de nómina"

→ Dominio primario: Nómina → skill: qdoora-erp-nomina-expert
→ Capa Backend: FormRequest modificado → skill: qdoora-laravel-form-requests
→ Contrato: cambio en tipos → skill: api-contract-aligner
→ Al terminar: skill: qdoora-technical-scribe-documentarian
```

---

## REGLA DE ORO — Integridad de Contratos (Siempre)

**Si se modifica un FormRequest, Controller o Interface TypeScript, el cambio NO está completo hasta alinear el otro extremo:**
- Activa `api-contract-aligner` para auditar el impacto completo.
- Traduce: `required` → campo obligatorio · `nullable` → `optional?` · `numeric` → `number`.

---

## ÍNDICE COMPLETO DE SKILLS (41 disponibles)

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
  angular-developer*               qdoora-angular-shared-components-expert
  qdoora-new-table-page            qdoora-new-setting-page  
  qdoora-dialog-creator            qdoora-new-guided-tour
  api-contract-aligner             qdoora-ui-ux-master
  qdoora-guard
  (* fallback genérico — preferir qdoora-angular-shared-components-expert o qdoora-ui-ux-master)

SEGURIDAD
  qdoora-security-iam-expert              qdoora-ethical-hacking-auditor

INFRAESTRUCTURA
  qdoora-docker-compose-expert            qdoora-cloud-devops-engineer
  qdoora-mailersend-template-expert

QA, DEBUGGING Y CALIDAD
  qdoora-qa-data-auditor                  systematic-debugging  
  qdoora-erp-technical-auditor

META-SKILLS
  brainstorming                    prompt-architect-master
  prompt-executor-master           qdoora-technical-scribe-documentarian
  skill-master                     qdoora-committer
```

---

> Todas las skills residen en `qdoora-references/agent/skills/<skill-name>/SKILL.md`.
> Sincronizadas al workspace activo via `qdoora-references/agent/scripts/update-agent-assets.sh`.

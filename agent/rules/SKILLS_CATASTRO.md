# 📊 SKILLS CATASTRO — QdoorA Agent Ecosystem

> **Fecha**: Julio 2026 | **Versión**: 1.0
> **Propósito**: Auditoría completa de todas las skills del ecosistema QdoorA. Evalúa foco, simplicidad, especificidad, y porcentaje de acierto estimado. Incluye evaluación de skills externas propuestas e investigación de repositorios wshobson/agents y obra/superpowers.

---

## Metodología de Evaluación

Cada skill se evalúa en 4 dimensiones:

| Dimensión | Descripción |
|-----------|-------------|
| **Acotada** | Una sola responsabilidad sin solapamiento con otras skills |
| **Disparador claro** | El agente sabe cuándo invocarla sin ambigüedad |
| **Específica** | Adaptada al stack y negocio QdoorA, no genérica |
| **% Acierto** | Probabilidad de activación correcta (trigger preciso + contenido relevante) |

**Escala de % Acierto:**
- 🟢 ≥85% — Excelente, skill lista para producción
- 🟡 70–84% — Buena, mejoras menores opcionales  
- 🟠 55–69% — Regular, requiere refinamiento
- 🔴 <55% — Problemática, requiere revisión o eliminación

---

## PARTE 1 — Skills Existentes QdoorA (33 skills)

### 🏛️ Dominio ERP (7 skills)

| # | Skill | Responsabilidad | Acotada | Disparador | Específica | % Acierto | Observación |
|---|-------|----------------|---------|-----------|-----------|-----------|-------------|
| 1 | `qdoora-erp-nomina-expert` | Leyes laborales chilenas, liquidaciones, Previred, AFP, finiquitos | ✅ | ✅ Palabras clave únicas: Previred, liquidación, AFP | ✅ | 🟢 90% | Modelo SIN código técnico — solo reglas de negocio. Ideal. |
| 2 | `qdoora-erp-accounting-expert` | Partida doble, PUC, SII, comprobantes, tesorería | ✅ | ✅ Palabras clave únicas: PUC, comprobante, conciliación | ✅ | 🟢 88% | Mantiene separación negocio/código correctamente. |
| 3 | `qdoora-erp-customs-expert` | DIN/DUS, Landed Cost, Incoterms, logística internacional | ✅ | ✅ Palabras clave únicas: DIN, DUS, Incoterms, despacho | ✅ | 🟢 85% | Muy especializado, trigger difícilmente confundible. |
| 4 | `qdoora-erp-electronic-invoicing-expert` | DTEs, SII, ciclo de vida documentos tributarios | ✅ | ✅ Palabras clave: DTE, factura electrónica, nota crédito | ✅ | 🟢 87% | Clara separación de responsabilidad vs. qdoora-laravel-services. |
| 5 | `qdoora-erp-global-parameters-expert` | UF/UTM/Sueldo Mínimo, periodicidad, inmutabilidad | ✅ | 🟡 Puede confundirse con nomina/contabilidad si no se menciona "parámetros" | ✅ | 🟡 78% | **Acción**: Enriquecer description con ejemplos de trigger. |
| 6 | `qdoora-erp-data-modeler` | Diseño lógico PostgreSQL: multitenancy, JSONB, índices | ✅ | 🟡 Overlap posible con `qdoora-laravel-database` | ✅ | 🟡 75% | Correcto en separación (diseño ≠ migración), pero el disparador puede confundirse. **Acción**: Clarificar que esta skill es conceptual/lógica y qdoora-laravel-database es sintaxis. |
| 7 | `qdoora-bi-reporting-exports-master` | BI, dashboards Angular, exports masivos Excel/PDF, SQL avanzado | 🟡 Alcance amplio | 🟡 Triggers dispersos (BI + exports + SQL) | ✅ | 🟡 72% | Podría dividirse en `bi-dashboard-expert` + `erp-export-specialist` para mayor precisión. Por ahora funcional. |

---

### ⚙️ Backend Laravel (9 skills)

El conjunto de skills backend es el **mejor diseñado del ecosistema**: cada capa de la arquitectura tiene exactamente una skill. Sin solapamiento.

| # | Skill | Responsabilidad | % Acierto | Observación |
|---|-------|----------------|-----------|-------------|
| 8 | `qdoora-laravel-controllers` | Orquestadores ultraligeros HTTP, try-catch, HandlesControllerLogs | 🟢 90% | Responsabilidad única y clara. |
| 9 | `qdoora-laravel-form-requests` | Validación + autorización multinivel (RBAC + IDOR) | 🟢 92% | La más precisa de todas: se activa exactamente cuando se toca validación. |
| 10 | `qdoora-laravel-services` | Toda la lógica de negocio, Service Ownership, DB::transaction | 🟢 88% | Separación perfecta de la capa de negocio. |
| 11 | `qdoora-laravel-models-enums` | Modelos Eloquent, relaciones, Observers, String Backed Enums | 🟢 87% | Sólido. La dualidad modelos+enums tiene sentido ya que siempre van juntos. |
| 12 | `qdoora-laravel-database` | Migraciones PostgreSQL, foreign keys, índices compuestos | 🟢 91% | Disparador clarísimo: cualquier migración. |
| 13 | `qdoora-laravel-api-resources` | JsonResource, ResourceCollection, transformación segura de datos | 🟢 89% | Perfecto. La última frontera antes del frontend. |
| 14 | `qdoora-laravel-jobs-events` | Jobs ShouldQueue, Events ShouldBroadcast, SQS, rollback transaccional | 🟢 86% | Bien delimitado a la capa asíncrona. |
| 15 | `qdoora-laravel-routes-middleware` | api.php, grupos de rutas, middleware perimetral, throttle | 🟢 88% | Disparador único: tocar routes/api.php o middleware. |
| 16 | `qdoora-laravel-commands-seeders` | Comandos Artisan, Seeders idempotentes, DataSyncCommand | 🟢 87% | Acotado a CLI/seeders. Correcta integración con DataSyncCommand. |

**Veredicto Backend**: 9/9 skills en estado 🟢. Este es el patrón a seguir para el resto del ecosistema.

---

### 🎨 Frontend (4 skills)

| # | Skill | Responsabilidad | % Acierto | Observación |
|---|-------|----------------|-----------|-------------|
| 17 | `angular-developer` | Guías generales Angular (Google official skill adaptada) | 🟠 65% | ⚠️ **PROBLEMA**: Skill genérica de Google — no conoce los patrones QdoorA (premium design, Fuse, support-portal Zoneless). Puede generar código válido para Angular pero incorrecto para QdoorA. **Acción**: Usar SOLO como fallback cuando las skills específicas no apliquen. Añadir nota en description: "Invocar SOLO si no aplica qdoora-angular-shared-components-expert ni qdoora-ui-ux-master". |
| 18 | `qdoora-angular-shared-components-expert` | Catastro completo de componentes `/app/modules/shared` (fuse-starter) | 🟢 88% | Excelente guardián anti-duplicación. Muy específica. |
| 19 | `qdoora-ui-ux-master` | Diseño premium QdoorA para ambos portales (Angular 18 + Angular 21) | 🟡 82% | El alcance dual (2 portales) lo hace ligeramente más amplio. Pero la detección de contexto interno (fuse-starter vs support-portal) lo compensa. Funcional. |
| 20 | `api-contract-aligner` | Sincronización bidireccional FormRequest ↔ TypeScript | 🟢 90% | Disparador clarísimo: cualquier cambio en endpoints. |

---

### 🔐 Seguridad (2 skills)

| # | Skill | Responsabilidad | % Acierto | Observación |
|---|-------|----------------|-----------|-------------|
| 21 | `qdoora-security-iam-expert` | Auth, JWT, RBAC, interceptors, guards Angular | 🟢 88% | Bien acotado a identidad y acceso. No hace auditoría ofensiva (eso es qdoora-ethical-hacking-auditor). |
| 22 | `qdoora-ethical-hacking-auditor` | Auditoría ofensiva OWASP, vectores QD-01 a QD-11, pentesting | 🟢 85% | Clara separación defensivo/ofensivo. El alcance QdoorA-específico (vectores QD) es valioso. |

---

### ☁️ Infraestructura (3 skills)

| # | Skill | Responsabilidad | % Acierto | Observación |
|---|-------|----------------|-----------|-------------|
| 23 | `qdoora-docker-compose-expert` | Orquestación Docker Compose, healthchecks, dependencias deterministas | 🟢 85% | Acotado a Docker Compose. Diferencia correcta vs qdoora-cloud-devops-engineer (que cubre AWS). |
| 24 | `qdoora-cloud-devops-engineer` | AWS ECS Fargate, SQS, S3, IAM, CI/CD, entornos QA | 🟡 78% | Amplio pero cohesionado. El acceso especial a `deploy/` está bien documentado. |
| 25 | `qdoora-mailersend-template-expert` | Plantillas HTML transaccionales para MailerSend, identidad QdoorA | 🟢 93% | La más específica del ecosistema. Disparador imposible de confundir. |

---

### ✅ QA y Calidad (2 skills)

| # | Skill | Responsabilidad | % Acierto | Observación |
|---|-------|----------------|-----------|-------------|
| 26 | `qdoora-qa-data-auditor` | Tests Pest (Laravel), Jest/Vitest (Angular), auditoría N+1, multitenancy | 🟡 82% | Bien diseñado. La dualidad backend/frontend en un mismo skill es justificable (QA es QA). |
| 27 | `lifecycle-tech-debt-guardian` | Actualizaciones de framework, deuda técnica, evaluación de dependencias | 🟠 68% | ⚠️ **PROBLEMA**: Triggers demasiado difusos ("deuda técnica" puede ser cualquier cosa). Se activa raramente y cuando se activa, el alcance es muy amplio. **Acción**: Enriquecer con triggers explícitos: actualización de versión mayor, `npm audit`, `composer outdated`, evaluación de librería nueva. |

---

### 🧠 Meta-Skills (5 skills)

| # | Skill | Responsabilidad | % Acierto | Observación |
|---|-------|----------------|-----------|-------------|
| 28 | `prompt-architect-master` | Genera `implementation_plan.md`. SOLO planificación, STOP total tras plan | 🟢 88% | La máquina de estados (ESPERANDO_APROBACION) es un patrón brillante. |
| 29 | `prompt-executor-master` | Ejecuta el plan aprobado granularmente (TDD, checkboxes, whitelist) | 🟢 85% | Complemento perfecto de prompt-architect-master. Clara separación de fases. |
| 30 | `qdoora-technical-scribe-documentarian` | Documenta patrones nuevos y actualiza `agent/rules/*.md` | 🟡 72% | ⚠️ **BUG**: Referencia a `qdoora-references/claude/CLAUDE.md` como target de actualización, pero ese archivo es ahora **OBSOLETO** (fue reemplazado por AGENT_BASE.md + el script). **Acción urgente**: Actualizar referencia a `qdoora-references/agent/rules/AGENT_BASE.md`. |
| 31 | `skill-master` | Ciclo de vida de skills: scaffolding, validación, evaluación, sincronización | 🟢 87% | Excelente para el meta-nivel. La integración con `validate-skill.js` es valiosa. |
| 32 | `qdoora-committer` | Ciclo de commit + actualización CHANGELOG.md en todos los proyectos | 🟢 90% | Muy acotado, disparador clarísimo. Soporte multi-proyecto es correcto. |

---

### ⚠️ SKILL CON BUG CRÍTICO

| # | Skill | Problema | Severidad | Acción |
|---|-------|---------|-----------|--------|
| 33 | `qdoora-full-stack-architect` | Referencia `rules/Backend.md`, `rules/Frontend.md`, `rules/Support.md` — archivos **ELIMINADOS** en la restructuración. La tabla de orquestación es completamente inválida. | 🔴 CRÍTICO | **Actualizar** las referencias a `BACKEND_RULES.md`, `CLIENTE_RULES.md`, `SUPPORT_RULES.md`. |

---

## PARTE 2 — Skills Externas Propuestas (9 skills)

Evaluadas según relevancia y aporte incremental al ecosistema QdoorA.

| # | Skill | Repo Origen | Relevancia QdoorA | Recomendación | Justificación |
|---|-------|------------|------------------|---------------|---------------|
| E1 | `systematic-debugging` | obra/superpowers | 🟢 Alta | **✅ ADOPTAR** | QdoorA no tiene ninguna skill de debugging. El proceso en 4 fases (Root Cause → Pattern → Hypothesis → Implementation) es agnóstico al stack. Complementa `qdoora-qa-data-auditor` sin solapamiento. |
| E2 | `brainstorming` | obra/superpowers | 🟡 Media-Alta | **✅ ADOPTAR** | Cubre el caso de uso de diseño colaborativo libre, ANTES de que `prompt-architect-master` entre en juego. No duplican: brainstorming = conversación → diseño; prompt-architect-master = diseño → plan formal. |
| E3 | `api-design-principles` | wshobson/agents | 🟡 Media | **⚠️ ADAPTAR** | Principios REST de diseño de API son útiles. Pero el skill genérico puede conflictuar con las convenciones estrictas de QdoorA (rutas v1/support, FormRequests, etc.). Solo adoptar con adaptación al stack QdoorA. |
| E4 | `playwright` | openai/skills | 🟠 Baja-Media | **⏳ DIFERIR** | E2E testing es una necesidad futura válida. Pero QdoorA no tiene setup de Playwright declarado en ninguna parte del stack. Incorporar cuando se establezca la estrategia de testing E2E. |
| E5 | `ui-ux-pro-max` | nextlevelbuilder | 🔴 Baja | **❌ NO ADOPTAR** | Ya existe `qdoora-ui-ux-master` con el diseño premium QdoorA adaptado (Fuse, support-portal Zoneless, Outfit/Space Grotesk). Una skill genérica de UI/UX externamente traída generaría conflictos de estilo. |
| E6 | `seo-audit` | coreyhaines31 | 🔴 Irrelevante | **❌ NO ADOPTAR** | QdoorA es un ERP B2B SaaS detrás de autenticación. El SEO no aplica a las pantallas funcionales de un ERP. |
| E7 | `changelog-generator` | composiohq | 🔴 Duplicada | **❌ NO ADOPTAR** | `qdoora-committer` ya genera `CHANGELOG.md` de forma atómica junto al commit en todos los proyectos. Duplicaría sin agregar valor. |
| E8 | `postgresql-table-design` | wshobson/agents | 🟠 Baja | **❌ NO ADOPTAR** | `qdoora-erp-data-modeler` ya cubre el diseño lógico PostgreSQL con reglas QdoorA-específicas (multitenancy con `company_id`, JSONB policy, softDeletes justificado). Una skill externa ignoraría estas reglas críticas. |
| E9 | `web-design-guidelines` | vercel-labs | 🔴 Baja | **❌ NO ADOPTAR** | Guidelines genéricos de Vercel no aplican al stack QdoorA. Están orientados a Next.js/React, no Angular. |

---

## PARTE 3 — Skills Adicionales de los Repos Investigados

### obra/superpowers (237k ⭐ — metodología completa de desarrollo agentivo)

Skills disponibles en el repo además de las propuestas:

| Skill | Descripción | Evaluación QdoorA |
|-------|-------------|------------------|
| `test-driven-development` | RED-GREEN-REFACTOR enforcement | 🟡 **Complementaria** con `qdoora-qa-data-auditor`. TDD es metodología; qdoora-qa-data-auditor tiene conocimiento específico del stack (Pest, Jest, Vitest, N+1). No adoptar: qdoora-qa-data-auditor ya cubre el "qué"; TDD cubriría el "cómo" pero puede confundir. |
| `writing-plans` | Planes detallados de implementación | 🔴 **Duplica** `prompt-architect-master` que ya genera `implementation_plan.md` con la metodología QdoorA. |
| `executing-plans` | Ejecución por lotes con checkpoints | 🔴 **Duplica** `prompt-executor-master`. |
| `subagent-driven-development` | Subagentes paralelos por tarea | 🟡 **Interesante** para el futuro. Requiere configuración de subagentes en QdoorA. Diferir. |
| `verification-before-completion` | Verificar antes de declarar éxito | 🟡 **Concepto valioso** pero puede integrarse como sección en `prompt-executor-master` en lugar de skill separada. |
| `requesting-code-review` / `receiving-code-review` | Protocolo de code review | 🟠 **Genérico**. QdoorA tiene `qdoora-ethical-hacking-auditor` y `qdoora-qa-data-auditor` para revisiones específicas. |
| `using-git-worktrees` | Ramas paralelas con git worktrees | 🟠 **Infraestructura** que podría incorporarse en `qdoora-committer` o como sección en BACKEND_RULES. |
| `finishing-a-development-branch` | Cierre de branch: merge/PR/discard | 🟠 **Útil** pero `qdoora-committer` ya maneja el ciclo de commit. Complementario menor. |

### wshobson/agents (35.6k ⭐ — 185 agentes, 153 skills, 80 plugins)

Investigación del catálogo completo. Skills relevantes para QdoorA más allá de las propuestas:

| Categoría | Skills Relevantes | Evaluación QdoorA |
|-----------|------------------|------------------|
| **Backend** | `architecture-patterns`, `microservices-patterns` | 🟡 Relevante para la arquitectura ECS Fargate. Diferir hasta la fase de migración a producción AWS. |
| **Database** | `postgresql-table-design`, `database-migrations` | 🔴 Duplican `qdoora-erp-data-modeler` y `qdoora-laravel-database` con reglas QdoorA. No adoptar. |
| **Security** | `security-scanning`, `api-security` | 🟡 Complementarios a `qdoora-ethical-hacking-auditor`. Pero el auditor QdoorA ya tiene los 11 vectores QD. Diferir. |
| **CI/CD** | `github-actions`, `ci-cd-pipeline-design` | 🟡 Relevante para cuando QdoorA implemente CI/CD propio. Diferir hasta fase AWS deploy. |
| **Observability** | `observability-patterns` | 🟡 Valioso para ECS Fargate. Diferir hasta fase de producción. |
| **Testing** | `unit-testing-patterns` | 🔴 Genérico (Python-centric). `qdoora-qa-data-auditor` cubre con Pest+Vitest. No adoptar. |

**Conclusión wshobson**: Es un repositorio de valor para proyectos genéricos. Para QdoorA, las skills ya existentes son más específicas y precisas. Los patrones de arquitectura cloud/CI/CD son para incorporar en la fase de despliegue AWS (Q3-Q4 2026).

---

## PARTE 4 — Plan de Acción

### 🔴 Urgente (esta semana)

| Acción | Skill | Detalle |
|--------|-------|---------|
| **BUG FIX** | `qdoora-full-stack-architect` | Actualizar referencias de `Backend.md`/`Frontend.md`/`Support.md` → `BACKEND_RULES.md`/`CLIENTE_RULES.md`/`SUPPORT_RULES.md` |
| **BUG FIX** | `qdoora-technical-scribe-documentarian` | Cambiar target `qdoora-references/claude/CLAUDE.md` → `qdoora-references/agent/rules/AGENT_BASE.md` |

### 🟡 Prioridad Media (próximas 2 semanas)

| Acción | Skill | Detalle |
|--------|-------|---------|
| **CREAR** | `systematic-debugging` | Adoptar de obra/superpowers. Adaptar frontmatter QdoorA (añadir ejemplos PHP/Angular). |
| **CREAR** | `brainstorming` | Adoptar de obra/superpowers. Adaptar: eliminar "Visual Companion" (no aplica a CLI), añadir flujo QdoorA → `prompt-architect-master`. |
| **MEJORAR** | `angular-developer` | Agregar nota en description: "Usar SOLO como fallback. Preferir `qdoora-angular-shared-components-expert` o `qdoora-ui-ux-master`." |
| **MEJORAR** | `qdoora-erp-global-parameters-expert` | Enriquecer description con ejemplos de trigger explícitos (UF, UTM, Sueldo Mínimo). |
| **MEJORAR** | `lifecycle-tech-debt-guardian` | Agregar triggers explícitos: `npm audit`, `composer outdated`, actualización de versión mayor. |

### 🟢 Opcional / Futuro (fase AWS deploy)

| Acción | Detalle |
|--------|---------|
| Considerar `architecture-patterns` de wshobson | Para fase de microservicios / ECS Fargate. |
| Considerar `ci-cd-pipeline-design` de wshobson | Para el pipeline de despliegue AWS. |
| Considerar `playwright` | Cuando QdoorA establezca estrategia E2E. |
| Considerar `subagent-driven-development` | Para tareas paralelas de larga duración. |

---

## RESUMEN EJECUTIVO

```
SKILLS EXISTENTES QdoorA:          33
  ├── 🟢 Excelentes (≥85%):        24  (72.7%)
  ├── 🟡 Buenas (70-84%):           6  (18.2%)
  ├── 🟠 Requieren mejora (55-69%): 2  (6.1%)   [angular-developer, lifecycle-tech-debt-guardian]
  └── 🔴 Bug crítico:               1  (3.0%)   [qdoora-full-stack-architect]

SKILLS EXTERNAS PROPUESTAS:         9
  ├── ✅ ADOPTAR:                    2  [systematic-debugging, brainstorming]
  ├── ⚠️ ADAPTAR antes de adoptar:   1  [api-design-principles]
  ├── ⏳ DIFERIR para el futuro:     1  [playwright]
  └── ❌ NO ADOPTAR:                 5  [ui-ux-pro-max, seo-audit, changelog-generator,
                                         postgresql-table-design, web-design-guidelines]

TOTAL SKILLS POST-ADOPCIÓN:        35  (33 actuales + systematic-debugging + brainstorming)

BUGS A CORREGIR HOY:                2  [qdoora-full-stack-architect, qdoora-technical-scribe-documentarian]
```

---

> **Próximo paso**: Corregir los 2 bugs críticos → Crear las 2 skills nuevas adoptadas → Ejecutar `update-agent-assets.sh`

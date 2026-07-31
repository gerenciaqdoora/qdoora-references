---
trigger: model_decision
description: Contexto de largo plazo del ecosistema QdoorA — arquitectura, módulos, decisiones, gotchas
---

# MEMORY.md — Contexto de Largo Plazo QdoorA

> Lee este archivo cuando necesites contexto del proyecto: arquitectura, módulos existentes, estado de desarrollo, árbol de carpetas, decisiones técnicas tomadas o gotchas conocidos.

---

## ÁRBOL DE ARQUITECTURA DEL WORKSPACE

```
QdoorAChile/                         ← workspace raíz
├── qdoora-api/                      # Laravel 11 — API REST global (multi-tenant)
│   ├── app/
│   │   ├── Http/
│   │   │   ├── Controllers/         # Orquestadores ultraligeros por dominio
│   │   │   ├── Requests/            # FormRequests — validación + autorización IDOR
│   │   │   └── Resources/           # Transformadores JSON de respuesta
│   │   ├── Services/                # Lógica de negocio (dueños del dominio)
│   │   ├── Models/                  # Eloquent + Enums + Scopes
│   │   └── Console/Commands/
│   │       └── DataSyncCommand.php  # Orquestador maestro de Seeders
│   └── routes/api.php               # Rutas — prefijo v1/support para admin
│
├── fuse-starter/                    # Angular 18 — Portal Cliente (ERP UI)
│   └── src/app/
│       ├── app.routes.ts/           # ← REVISAR SIEMPRE antes de crear una nueva navegacion
│       ├── modules/aduana/          # ← REVISAR SIEMPRE antes de crear contenido relacionado con el modulo de ADUANA
│       ├── modules/billing/         # ← REVISAR SIEMPRE antes de crear contenido relacionado con el modulo de FACTURACION
│       ├── modules/contabilidad/    # ← REVISAR SIEMPRE antes de crear contenido relacionado con el modulo de CONTABILIDAD
│       ├── modules/nomina/          # ← REVISAR SIEMPRE antes de crear contenido relacionado con el modulo de NOMINA
│       ├── modules/shared/          # ← REVISAR SIEMPRE antes de crear componentes
│       └── core/services/
│
├── support-portal/                  # Angular 21 Zoneless — Portal Soporte/Admin
│   └── src/
│       ├── modules/                 # ← estructura de módulos (NO src/app/modules/)
│       └── app/                    # solo configuración central (core, layout)
│
├── qdoora-references/               # Fuente de verdad del agente (NUNCA editar .agents/)
│   ├── agent/
│   │   ├── rules/                   # MEMORY.md · RULES.md · SKILLS.md · Backend.md…
│   │   ├── skills/                  # 34 Skills especializadas
│   │   ├── workflows/               # Flujos de trabajo del agente
│   │   └── scripts/
│   │       └── update-agent-assets.sh  # ← ejecutar tras cada cambio en agent/
│   └── claude/
│       └── CLAUDE.md                # Fuente del CLAUDE.md raíz (symlink)
│
├── deploy/                          # ⛔ VEDADO — credenciales y secretos
├── CLAUDE.md                        # Symlink → qdoora-references/claude/CLAUDE.md
└── .agents/                         # Volátil — generado por update-agent-assets.sh
```

---

## STACK TECNOLÓGICO

| Capa | Tecnología | Versión | Notas clave |
|------|-----------|---------|-------------|
| API | Laravel | 11 | PHP 8.3, stateless (JWT), sin session() |
| Portal Cliente | Angular | 18 | Standalone, signals, sin NgModules |
| Portal Soporte | Angular | 21 | Zoneless, Vite, Tailwind v4 CSS-first |
| Base de datos | PostgreSQL | 16 | Multi-tenant por `company_id` |
| Cache / Queues | Redis | 7 | Sessions, queues, rate limiting |
| Storage | AWS S3 | — | Único storage permitido en producción |
| Infra actual | Docker Compose | — | PostgreSQL + Redis + API en contenedores |
| Infra objetivo | AWS ECS Fargate | — | Migración pendiente — diseño stateless |
| Auth | JWT | — | Claims: `company_id`, `user_id`, `scope` |
| Mail | MailerSend | — | Templates premium, único proveedor |
| Queues async | AWS SQS | — | Cálculos de nómina asincrónicos |

---

## MÓDULOS DEL ERP

### Portal Cliente (`fuse-starter` / Angular 18)

| Módulo | Descripción | Skill asociada |
|--------|-------------|----------------|
| GENERAL | Inicio, Perfil, Mi Empresa, Empresas, Usuarios, Roles, Auxiliares (ThirdCompany), Centros de Costo, Productos, Impuestos | `full-stack-architect` |
| GENERAL / PARÁMETROS | Entidades Previsionales, Series económicas (UF/UTM), `ParameterCloningService`, Indicadores | `erp-global-parameters-expert` |
| CONTABILIDAD | Plan de Cuentas (PUC), Libros (Compra/Venta), Honorarios, Comprobantes, Tesorería, Conciliación bancaria | `erp-accounting-expert` |
| ADUANA | Despacho, DIN, DUS, Libro Circunstanciado | `erp-customs-expert` |
| REMUNERACIONES | Empleados, Liquidación, Previred, Vacaciones, Haberes, Config. nómina | `erp-nomina-expert` |
| FACTURACIÓN | DTE, Boletas electrónicas, Notas de Crédito/Débito | `erp-electronic-invoicing-expert` |
| BI / REPORTES | Dashboards, exportaciones, reportes gerenciales | `bi-reporting-exports-master` |

### Portal Soporte/Admin (`support-portal` / Angular 21)

| Área | Descripción |
|------|-------------|
| Gestión Suscriptores | Alta/baja de empresas y planes |
| Monitoreo | Estado del sistema, logs, métricas |
| Parámetros Globales | Variables inmutables del sistema |
| Administración IAM | Roles, permisos, scopes |

---

## DECISIONES ARQUITECTÓNICAS CLAVE

### Multi-tenancy
- Toda query DEBE estar filtrada por `company_id` (scope Eloquent global).
- JWT contiene: `company_id`, `user_id`, `scope` (`client` / `support` / `admin`).
- Rutas de soporte/admin registradas bajo prefijo `v1/support` en `routes/api.php`.

### Autorización Multinivel (Backend)
Cada endpoint valida obligatoriamente 3 niveles antes de procesar:
1. `USER_ROLE` — permisos específicos del submódulo del usuario
2. `SUBSCRIBER_ROLE` — relación empresa (`company_id` ↔ `suscriptor_id`)
3. `IDOR` — propiedad del recurso específico en `authorize()` del FormRequest

### Gestión de Archivos
- **Solo S3**: `S3FileService` para todo. En BD solo la ruta relativa (`companies/1/logo.png`).
- Respuesta al frontend: URLs firmadas temporales via `S3FileService::getSignedUrl()`.
- PUT/PATCH: si el campo ya comienza con `http`, **no sobreescribir**.

### Inmutabilidad Histórica
Los módulos Contabilidad, Nómina y Aduana son **inmutables**. Para corregir: generar **registro de reversa**, nunca modificar el original.

### Centralización de Seeders
Todo nuevo Seeder DEBE registrarse en `DataSyncCommand.php` respetando el orden del array `$seeders` para mantener integridad referencial en migraciones frescas y entornos QA.

### Relaciones Inter-Módulos
Relaciones desde `ThirdCompany` (modelo core) hacia submódulos (ej. Nómina) deben mantenerse explícitas dentro del modelo base hasta que se estandarice un sistema via Traits.

---

## GOTCHAS Y DECISIONES CONOCIDAS

| # | Área | Problema / Decisión |
|---|------|---------------------|
| 1 | Frontend | Usar SIEMPRE `<app-header-premium>`, NO `<app-header>` (componente obsoleto) |
| 2 | Frontend | Nuevo patrón: `ErrorHandler` + `JsonResponse<any>` para errores HTTP en servicios |
| 3 | Frontend | `catchError((e) => this._errorHandler.handle(e))` — errores como `JsonResponse<any>`, no `HttpErrorResponse` |
| 4 | Support | Módulos en `src/modules/`, **NO** en `src/app/modules/`. `src/app/` es solo configuración central |
| 5 | Support | `QdooraAlertService` SOLO para errores críticos con botón close manual. `ngOnDestroy` → `clearAlert()` |
| 6 | Support | `AlertMessage` usa solo: `appearance`, `type`, `message`, `name`. Sin timeouts automáticos |
| 7 | Docker | Exit Code 130 ocurre si `.env` no está montado como volumen individual explícito |
| 8 | Backend | `softDeletes()` solo si hay trazabilidad legal requerida, **no por defecto** |
| 9 | Backend | Relaciones de `ThirdCompany` hacia submódulos deben ser explícitas en el modelo core |
| 10 | Nómina | Cálculos de liquidación via AWS SQS (asíncrono) — cumplimiento leyes sociales chilenas |
| 11 | Backend/SII | `Venta::getDateAttribute()` expone la fecha como string `d/m/Y` — jamás re-parsear con `Carbon::parse()` (asume `m/d/Y`, invierte día/mes silenciosamente). Ver `BACKEND_RULES.md` |
| 12 | Backend | Subquery correlacionada contra la misma tabla sin alias resuelve la columna contra el scope interno (siempre 0, sin error) — alias explícito obligatorio. Ver `BACKEND_RULES.md` |
| 13 | Backend/SII | Columnas self-FK de "referencia a otro documento" son una por dominio semántico — no reutilizar una columna ya usada por otro flujo (ej. `doc_reference_id` del RCV manual) para un significado nuevo |
| 14 | Backend/SII | `core_companies.sii_dte_enabled` NUNCA se setea a mano — se recalcula vía `SiiEnablementService::syncDteEnabledFlag()` (cert vigente + ≥1 CAF activo). El gate de emisión es este flag, no `sii_environment`. Ver `BACKEND_RULES.md` |
| 15 | Backend/Testing | `RefreshDatabase` (usado global en `tests/Pest.php`) ejecuta `migrate:fresh` en cada corrida. Si `phpunit.xml` no fuerza `DB_DATABASE` con `force="true"`, una variable de entorno ya exportada por el contenedor Docker gana la partida en silencio y los tests migran/truncan la BD real (dev/QA). Fix: `DB_DATABASE=qdoora_testing` con `force="true"` en `phpunit.xml` + candado en `AppServiceProvider::guardTestingDatabase()` que aborta el boot si `APP_ENV=testing` y la BD activa no contiene `_testing`. `DB_USERNAME`/`DB_PASSWORD` no se tocan (misma instancia Postgres, solo cambia el nombre de la BD) — se inyectan vía AWS Secrets en `bootstrap/app.php`, no por `.env`. |

---

> Actualizar este archivo mediante `technical-scribe-documentarian` tras cada nueva decisión arquitectónica relevante. Ejecutar `update-agent-assets.sh` después.

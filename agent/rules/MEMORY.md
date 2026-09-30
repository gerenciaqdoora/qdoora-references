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
| GENERAL | Inicio, Perfil, Mi Empresa, Empresas, Usuarios, Roles, Auxiliares (ThirdCompany), Centros de Costo, Productos, Impuestos | `qdoora-full-stack-architect` |
| GENERAL / PARÁMETROS | Entidades Previsionales, Series económicas (UF/UTM), `ParameterCloningService`, Indicadores | `qdoora-erp-global-parameters-expert` |
| CONTABILIDAD | Plan de Cuentas (PUC), Libros (Compra/Venta), Honorarios, Comprobantes, Tesorería, Conciliación bancaria | `qdoora-erp-accounting-expert` |
| ADUANA | Despacho, DIN, DUS, Libro Circunstanciado | `qdoora-erp-customs-expert` |
| REMUNERACIONES | Empleados, Liquidación, Previred, Vacaciones, Haberes, Config. nómina | `qdoora-erp-nomina-expert` |
| FACTURACIÓN | DTE, Boletas electrónicas, Notas de Crédito/Débito | `qdoora-erp-electronic-invoicing-expert` |
| BI / REPORTES | Dashboards, exportaciones, reportes gerenciales | `qdoora-bi-reporting-exports-master` |

### Portal Soporte/Admin (`support-portal` / Angular 21)

| Área | Descripción |
|------|-------------|
| Gestión Suscriptores | Alta/baja de empresas y planes |
| Monitoreo | Estado del sistema, logs, métricas |
| Parámetros Globales | Variables inmutables del sistema |
| Administración IAM | Roles, permisos, scopes |
| Soporte / Tickets | `/tickets` en `support-portal`. Fase 0 (saneamiento IDOR/multi-tenant/`findOrFail`) completada ago-2026 — ver `BACKEND_RULES.md`. Roadmap de producto: evoluciona de ticket bidireccional a **buzón unidireccional** (cliente solo ve estado: Recibido/En análisis/Resuelto, sin hilo de conversación). La pestaña "CHAT EN VIVO" de `ticket-management.component.ts` es 100% simulada (mock en memoria) — pendiente eliminar en Fase 1. `support_ticket_evidences` tiene tabla/modelo pero **sin endpoint** de subida a S3 (Fase 2, `S3FileService` ya inyectado en `SupportService` sin usar). Portal Cliente (`fuse-starter`) aún no tiene ningún endpoint de Soporte integrado (Fase 2). |

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

### Autorización Client-Side (Portal Cliente) — sep-2026
El frontend espeja las dos capas del backend: `hasModuleGuard` (módulo contratado, desde `active_modules`) y `hasSubmodulePermissionGuard` (submódulo + operación, desde `GET /v1/company/{id}/permissions/mine`). Skill: `qdoora-guard`.

**Decisión: la matriz de permisos NO se firma ni se envuelve en un JWT.** Se evaluó y se descartó. Un JWT está *firmado, no cifrado*: su payload es base64url y el propio frontend debe poder leerlo para renderizar, así que no oculta nada; solo aporta integridad, que aquí es irrelevante porque ocultar botones nunca fue el control de seguridad (el FormRequest revalida cada acción). Además `qdoora-security-iam-expert` lo veta en dos reglas de refutación inmediata: "prohibido inyectar arrays de permisos" en el token (QD-09) y "decodificar el JWT en Angular para resolver permisos" (QD-01). Lo que sí se aplicó del principio de menor privilegio fue **minimizar el payload**: solo viajan los submódulos con al menos una operación concedida.

**RBAC ya existía**: `role_submodule_permissions` (plantilla por rol) + `users_permission_submodule` (override por usuario) = RBAC con ACL por usuario encima. No hacía falta introducirlo.

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
| 15 | Backend/Testing | **La suite borra la BD de desarrollo si se confía en `APP_ENV`.** `RefreshDatabase` (global en `tests/Pest.php`) ejecuta `migrate:fresh`, que DROPEA todas las tablas de la conexión activa. El contenedor exporta `APP_ENV=local` y `DB_DATABASE=qdooraChileV1` como **variables reales del sistema** (docker-compose), y el `force="true"` de `phpunit.xml` **NO las pisa**: dentro de los tests `env('APP_ENV')` devuelve `'local'`. Esto dejó inertes las dos protecciones que existían (el ternario `env('APP_ENV') === 'testing'` de `config/database.php` y el `guardTestingDatabase()` de `AppServiceProvider`, que salía por su propio `if (! environment('testing')) return;`) y la suite migró/truncó la BD de desarrollo durante toda una sesión, en silencio. Verificado empíricamente ago-2026: `DB::connection()->getDatabaseName()` dentro de un test devolvía `qdooraChileV1`. **Nunca dar por buena la configuración: comprobar contra qué BD conecta la suite.** Detección fiable = binario en ejecución (`basename($_SERVER['argv'][0]) === 'pest'`); `PHPUNIT_COMPOSER_INSTALL` tampoco sirve porque el runner es Pest y su binario no la define. Fix en 3 capas: (1) `config/database.php` resuelve `$runningTests` por binario y fuerza `qdoora_testing`; (2) `tests/TestCase.php::refreshApplication()` aborta la suite si la BD activa no es `qdoora_testing` — corre ANTES de `setUpTraits()`, así que `RefreshDatabase` nunca llega a ejecutarse; (3) `AppServiceProvider::guardTestingDatabase()` usa la misma detección, ya no `APP_ENV`. |
| 16 | Backend/Testing | Para contratar un módulo en un test Pest, insertar `subscriber_plan` vía `DB::table()` (**no** `SubscriberPlan::factory()`: el modelo `App\Models\Subscriber\SubscriberPlan` no tiene el trait `HasFactory` — `->factory()` lanza `BadMethodCallException`, ver gotcha #20) con `status='active'`, `user_tier_id`/`plan_id` apuntando a filas ya sembradas por la migración de `plan`/`quantity_tier` (`slug='demo'`, `code='users-basico'`) + `SubscriberPlanModule::create(['subscriber_plan_id' => $plan->id, 'module_code' => 'CONTABILIDAD', 'origin' => \App\Enums\Subscription\ModuleOrigin::PLAN->value, 'activated_at' => now()])` si además se necesita el módulo contratado. Un `Subscriber::factory()->create()` recién creado NO tiene módulos contratados por defecto — `Subscriber::modules()` retorna `collect()` vacío. El submódulo `COMPROBANTE` cuelga del módulo `CONTABILIDAD`. Para el módulo `BILLING` ya existe el helper listo `createBillingClientCompany()` en `tests/Feature/Sii/SiiFixtures.php` (retorna `[User, Company]` con el módulo contratado); sin él los endpoints cliente de SII responden 403 y el camino feliz de `authorize()` nunca se ejecuta — así se coló un `UserOperationSubmodule::READ` inexistente (el enum solo tiene `REVIEW`/`CREATE`/`UPDATE`/`DELETE`) que reventaba en runtime con 500. |
| 17 | Frontend | `fuse-starter` (Portal Cliente, Angular 18) usa RxJS clásico en `UserService` (`ReplaySubject`, getter síncrono `currentUser`), **no** Angular Signals — cualquier servicio nuevo que reaccione a cambios de usuario/empresa debe usar `user$.pipe(distinctUntilChanged(), switchMap(...))`, no `effect()`/`computed()`. La empresa activa se lee como `currentUser?.company?.id`; no existe `company_selected_id` en el tipo `User` del frontend (sí en el backend). |
| 18 | Backend/Testing | `App\Models\Subscriber\Subscriber` no tenía el trait `HasFactory` pese a existir `database/factories/Subscriber/SubscriberFactory.php` — `Subscriber::factory()` fallaba con `BadMethodCallException`. Además `database/factories/Support/TicketFactory.php` apuntaba a `App\Models\Suscriptor\Suscriptor::factory()` (modelo legado sin factory) en el campo `suscriptor_id`, en vez de `App\Models\Subscriber\Subscriber::factory()` — mismo patrón de confusión Suscriptor/Subscriber que el gotcha de tabla `suscriptor` vs `subscriber`. Ambos bugs bloqueaban **toda** `tests/Feature/Support/*`, incluidos tests de seguridad preexistentes (`TicketSecurityTest`) que nunca habían corrido realmente en CI. Corregido en Fase 0 del saneamiento de Soporte/Tickets (ago-2026). |
| 19 | Backend | `HandlesControllerLogs::logAndResponse()` solo re-lanza (`throw $e`) las excepciones `GenericException`, `AuthException` y `ExchangeRateSyncException` — cualquier otra, incluida `Illuminate\Auth\Access\AuthorizationException` (403 de una Policy), cae al branch genérico y se convierte en 500. Si un método de Controller envuelve `$this->authorize(...)` dentro de un `try { } catch (\Throwable $e) { return $this->handleError->logAndResponse(...); }`, agregar `catch (AuthorizationException $e) { throw $e; }` ANTES del catch genérico — si no, todo 403 de Policy se disfraza de error de servidor. |
| 20 | Backend/Testing | `App\Models\Subscriber\SubscriberPlan` NO tiene el trait `HasFactory` (a diferencia de `Subscriber`, ya corregido en gotcha #18) — `SubscriberPlan::factory()` lanza `BadMethodCallException`. Bloquea `tests/Feature/Security/SubmoduleActionTest.php` y `SubmodulePermissionCapa1Test.php` (5 tests). Detectado ago-2026 durante el saneamiento de identidad de usuario/email; **no corregido** (fuera de alcance de ese plan) — agregar `use HasFactory;` + `database/factories/Subscriber/SubscriberPlanFactory.php` es el fix pendiente. |
| 21 | Backend | `AdminSuscriptorController::createAduanaSubscriber()` llama a `$this->suscriptorService->crearSuscriptor($newUsuario->id, false)` — método inexistente en `SubscriberService` (mismo patrón que el gotcha de `reactivateSuscriptor`/`deleteSuscriptor` ya corregido). Rompe con 500 el único endpoint de alta de suscriptor Aduana (`POST /v1/support/create/aduana-subscriber`). Detectado ago-2026, **no corregido** — fuera de alcance del plan de identidad de usuario/email que lo encontró. |
| 22 | Backend | `CheckSupportStaff::handle()` (vía `$user->isStaff()`) rechaza con 403 ("Acceso restringido: Se requiere rol de soporte o administración") peticiones que las pruebas `ThrottlingTest`, `TicketHardeningTest` y `TicketSecurityTest` esperan que pasen para roles de staff — falla reproducible en aislamiento, sin relación con cambios de identidad/email. Sospechar de `User::isStaff()` o de la fixture de rol usada en esos tests. Detectado ago-2026, **no corregido** — requiere `debugging-sistematico` aparte. |

---

> Actualizar este archivo siguiendo `AGENT_BASE.md`, sección 5, tras cada nueva decisión arquitectónica relevante. Ejecutar `update-agent-assets.sh` después.

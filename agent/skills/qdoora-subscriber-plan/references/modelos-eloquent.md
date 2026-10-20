# Modelos Eloquent del dominio

Hay dos juegos de modelos sobre las mismas tablas. **Para reglas de plan, módulos y límites se usan solo los de `App\Models\Subscriber` y `App\Models\Plan`.** Los de `App\Models\Suscriptor` son heredados.

## Contratación (`App\Models\Subscriber`)

### `Subscriber` (tabla `subscriber`, SoftDeletes)
| Miembro | Qué devuelve |
|---|---|
| `user()` | Dueño (`users`, rol `SUBSCRIBER_ROLE`) |
| `plans()` | Toda la historia de `SubscriberPlan` |
| `activePlan()` | Último plan `trialing`/`active`/`past_due` (el que da módulos y acceso) |
| `currentPlan()` | Último plan no reemplazado, **en cualquier estado** (`SubscriberPlan::current()`). Lo usan Soporte, el login y el 402 |
| `companies()` | `core_companies` por `suscriptor_id`. **No existe `empresas()`** en este modelo |
| `teamUsers()` | `SuscriptorTeamUsers` (equipo; el dueño no está ahí) |
| `modules(): Collection` | Módulos activos (`deactivated_at` nulo) del `activePlan`, con `module.submodulos`, ordenados por `order`. Un plan suspendido entrega colección vacía |
| `hasModule(string $code)` | `modules()` contiene el código |
| `scopeDemo`, `scopeActiveWithin($date)` | Filtros por demo y vigencia de `valid_to` |

### `SubscriberPlan` (tabla `subscriber_plan`)
| Miembro | Qué hace |
|---|---|
| `status` | Cast a `SubscriptionStatus`: `trialing`, `active`, `past_due`, `suspended`, `cancelled`, `superseded` |
| `scopeCurrent` | `status != superseded`: **única definición de "plan actual"** |
| `openStatuses()` (estático) | `trialing`, `active`, `past_due`, `suspended`: los estados del índice único |
| `scopeValid` | `trialing`, `active`, `past_due` (lo usa `repair-tiers`) |
| `scopeActive`, `scopeTrialing`, `scopeSuperseded` | Filtros por un estado |
| `includesActiveModule(string $code)` | El módulo está activo en este plan (origen `plan` o `addon`). **Única forma de decidir "tiene el módulo"** |
| `suspendsAt()` | Fecha en que el job suspenderá un plan `past_due` (`ends_at` + `past_due_grace_days`); null en otro estado |
| `plan()`, `userTier()`, `companyTier()`, `supersededBy()`, `modules()`, `quantityAddons()`, `extensions()`, `subscriber()` | Relaciones |

### Resto
| Modelo | Notas |
|---|---|
| `SubscriberPlanModule` | `origin` cast a `ModuleOrigin` (`plan`/`addon`); `scopeActive` (`deactivated_at` nulo); `module()` y su alias `modulo()` |
| `SubscriberQuantityAddon` | `dimension` cast a `Dimension`; `scopeNotRevoked`. Se crea y revoca solo en `SupportAddonService` |
| `SubscriberPlanExtension` | Historia de extensiones; la escribe solo `SubscriptionExtensionService` |
| `SubscriberPlanPayment` | Esquema listo; **ninguna pasarela escribe todavía** |

## Catálogo (`App\Models\Plan`)
| Modelo | Notas |
|---|---|
| `Plan` | `modules()` (pivote `plan_module`: `included`, `addon_price`), `quantityTiers()` (pivote `plan_quantity_tier`: `is_default`), `hasModule($code, $onlyIncluded = false)`, scope `active()`. `tier` cast a `PlanTier`, `target` a `PlanTarget` |
| `QuantityTier` | `dimension` cast a `Dimension`, `tier_level` a `PlanTier`; `scopeActive`, `scopeForDimension` |
| `Module` | PK `code`. Constantes como `Module::ADUANA`. `submodulos()` |
| `SubModule` | `isAvailable()`: activo y sin `standby` en `AppModules::SUBSCRIPTION_MODULES_METADATA`. El menú y los permisos lo respetan |
| `SubmoduleAction` | Habilidades especiales por submódulo (`requires_operation`, `subscriber_only`) |
| `PlanModule`, `PlanQuantityTier` | Modelos de los pivotes |
| `DiscountCode` | Códigos de descuento del Gestor de Planes |

## Usuario (`App\Models\User`)
- `getSuscriptorByRole(): ?Subscriber` — `SUBSCRIBER_ROLE` por `subscriber.user_id`; `USER_ROLE` por `suscriptor_team_users`. Soporte y Admin: null.
- `toLoginResponse()` — arma `user` del login y de `GET v1/user-details`: `plan_type` (tier del `activePlan`), `active_modules` (códigos en minúscula de `Subscriber::modules()`), `subscription` (`status`, `ends_at`, `suspends_at`, `aduana_capped`, o null sin plan) y `company` (con `agent_name`/`agent_code`).

## Enums (`App\Enums\Subscription`)
`SubscriptionStatus`, `ModuleOrigin`, `Dimension`, `PaymentStatus`, `PlanTier` (`demo`/`basic`/`pro`), `PlanTarget` (`contador`/`empresa`/`all`), `DiscountType`.

## Heredados (`App\Models\Suscriptor`) — no usar para reglas
| Modelo | Uso permitido |
|---|---|
| `Suscriptor` (misma tabla `subscriber`) | Solo el directorio del Portal Soporte (`SupportSubscriberService`, `SubscriberListResource`) por sus alias (`es_demo`, `date_subscribed`, `subscription_valid_to`, `date_unsubscribed`) y relaciones `usuario()`, `empresas()`, `pagos()`, `ultimo_pago()`. Su `currentPlan()` usa el mismo scope `current()`. Ya no tiene `modules()` ni `latestSuscriptorPlan()` |
| `SuscriptorPlan`, `SuscriptorPlanPayments` | Solo para la relación `pagos()` de `Suscriptor` |
| `SuscriptorTeamUsers`, `Role` | **Siguen siendo los únicos** modelos de equipo y de plantillas de rol; los usa también `Subscriber` |

`Company::suscriptor()` devuelve `Subscriber` (no el heredado).

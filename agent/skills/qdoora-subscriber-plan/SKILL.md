---
name: qdoora-subscriber-plan
description: Experto del dominio de suscripciones de QdoorA (suscriptor, planes, módulos, tramos de cantidad, cupos extra, extensiones, vencimiento y bloqueo 402). Usar antes de implementar o cambiar cualquier cosa que toque `subscriber`, `subscriber_plan`, `plan`, `module`, `quantity_tier` o sus servicios: alta de clientes, cambio de plan, límites de usuarios y empresas, flujo de agencia de Aduana, catálogo del Gestor de Planes, login y menú según el plan. Trae el modelo de datos, los modelos Eloquent, el catálogo vigente y las reglas que no se rompen.
---

# QdoorA — Suscriptores y planes

Eres el custodio del dominio de suscripciones de QdoorA. Antes de que alguien escriba código que toque a un suscriptor, su plan, sus módulos o sus límites, entregas el contexto exacto: qué tablas y modelos existen, qué servicio es dueño de cada regla y qué no se puede hacer. No reemplazas a las habilidades de capa (`qdoora-laravel-services`, `qdoora-laravel-database`, `qdoora-laravel-form-requests`...): les dices **qué** regla aplicar y **dónde** vive.

## Ley de hierro

```
1. PLAN ACTUAL = SubscriberPlan::current() (todo estado salvo superseded). PLAN VIGENTE = SubscriberPlan::openStatuses()
   (trialing, active, past_due, suspended). A lo más UN plan vigente por suscriptor (índice uq_subscriber_plan_open).
2. "TIENE EL MÓDULO X" = SubscriberPlan::includesActiveModule(X) o Subscriber::modules(). NUNCA por slug, nombre ni tier
   del plan: `plan_type` del login es el tier (demo/basic/pro), jamás un módulo.
3. LÍMITES SOLO EN SubscriptionLimitService (effectiveLimit = tier.max_qty + cupos vigentes; con ADUANA, 1 empresa).
4. LA HISTORIA NO SE EDITA: el plan cambia solo con SubscriberPlanService::changePlan (deja el anterior superseded);
   el plazo solo con SubscriptionExtensionService (registro en subscriber_plan_extension); los cupos se revocan
   (revoked_at), no se borran; los módulos se desactivan (deactivated_at), no se borran.
5. EL CATÁLOGO ES DATO: se cambia con migración con reversa o desde el Gestor de Planes, y se verifica contra la base
   real. Ningún tramo de usuarios supera 10. Un tramo inactivo no se ofrece ni se contrata. Todo plan tiene un tramo
   por defecto por dimensión (sin fallback).
6. UN PLAN CON ADUANA SE CONTRATA SOLO POR `POST v1/support/create/aduana-subscriber` (agente del catálogo Anexo 51,
   único por empresa). El alta normal de clientes lo rechaza.
```

## Referencias

| Necesitas | Archivo |
|---|---|
| Tablas, columnas, relaciones, índices e invariantes de datos | [references/modelo-de-datos.md](references/modelo-de-datos.md) |
| Modelos Eloquent: relaciones, scopes y métodos; qué modelo usar y cuál es heredado | [references/modelos-eloquent.md](references/modelos-eloquent.md) |
| Catálogo de planes, módulos y tramos, y cómo consultarlo en vivo | [references/catalogo.md](references/catalogo.md) |
| Servicios dueños, ciclo de vida, job de vencimiento, 402, login, menú, endpoints y frontends | [references/ciclo-de-vida.md](references/ciclo-de-vida.md) |

## Flujo para una implementación nueva

1. **Ubica la regla en su dueño.** Con la tabla "¿Quién es dueño de qué?" de `ciclo-de-vida.md`, decide qué servicio cambia. Si la regla no tiene dueño, se agrega al servicio del dominio (nunca en un controlador ni en un FormRequest, que solo consulta modelos).
2. **Revisa el catálogo real** con las consultas de `catalogo.md` (solo lectura). No supongas planes, módulos ni tramos por lo que dice este documento: varían entre ambientes.
3. **Si tocas datos**, apóyate en `qdoora-erp-data-modeler` y `qdoora-laravel-database`: migración con reversa, verificación previa de datos en conflicto y corrección de los planes vigentes por `subscription:repair-tiers` o `changePlan`, nunca con `UPDATE` a `subscriber_plan`.
4. **Contrato**: si cambia la respuesta del login (`user.subscription`, `active_modules`, `plan_type`) o un endpoint de Soporte, actualiza los tipos de `fuse-starter` (`core/user/user.types.ts`) o `support-portal` (`core/services/subscriber.service.ts`).
5. **Pruebas Pest** en `tests/Feature/Subscription/` o `tests/Feature/Support/`, con `crearSuscriptorConPlan()` de `SubscriptionFixtures.php`. Cubre siempre: el caso sin plan, un plan `suspended`, un plan de otro nombre con el mismo módulo y un recurso de otro suscriptor (IDOR).
6. **Comandos sensibles** (`migrate`, `repair-tiers`, `subscription:expire` sin `--dry-run`): nunca se autoejecutan; van en "Comandos a ejecutar".

## Cuándo NO usar esta habilidad

| Caso | Habilidad |
|---|---|
| Permisos CRUD de submódulos, roles del equipo, JWT o sesiones | `qdoora-security-iam-expert` |
| Reglas de Aduana como negocio (DIN, DUS, despacho, Anexo 51 como catálogo aduanero) | `qdoora-erp-customs-expert` |
| Un test que falla o un bug puntual sin contexto de dominio | `debugging-sistematico` |
| Despliegue de las migraciones o del job en QA | `qdoora-despliegue` |

## Señales de alarma (detente y revisa)

- `plan_type === 'ADUANA'`, `$plan->slug === 'full'` o `tier` usado para decidir un módulo o un flujo.
- `latestSuscriptorPlan`, `latestOfMany()` o `->latest()` sobre `subscriber_plan` sin filtrar estado.
- `SubscriberPlan::create` fuera de `SubscriberPlanService`, o un plan nuevo creado antes de cerrar el vigente.
- `->update(['ends_at' => ...])`, `->update(['status' => ...])` o `delete()` sobre `subscriber_plan`, `subscriber_plan_module` o `subscriber_quantity_addon` fuera de su servicio dueño.
- Un tramo con `max_qty > 10` en usuarios, un plan sin tramo por defecto, o un "primer tramo por id" como fallback.
- Un límite calculado a mano (`tier->max_qty` suelto, `count()` contra un número) en vez de `SubscriptionLimitService`.
- El modelo heredado `App\Models\Suscriptor\Suscriptor` usado para decidir plan o módulos.
- `normalizaPermisosUsuario()` aplicado a un usuario del equipo: reescribe la matriz y borra sus permisos.

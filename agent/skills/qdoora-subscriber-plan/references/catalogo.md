# Catálogo de planes, módulos y tramos

**El catálogo es dato, no código.** Se siembra en `2024_09_17_210534_create_plan_table.php` y lo corrigen las migraciones del 2026-10-20 (`seed_missing_default_quantity_tiers`, `cap_user_tiers_at_ten`, `align_company_tiers_and_drop_user_enterprise`). Después, Soporte lo cambia desde el Gestor de Planes. Por eso **cada ambiente puede ser distinto**: antes de decidir, consulta la base (sección final). La foto de abajo es de la base local al 2026-10-20.

## Módulos

| Código | Precio suelto | Orden | Notas |
|---|---|---|---|
| `CONTABILIDAD` | 0 | 10 | |
| `BILLING` | 15.000 | 20 | Facturación electrónica. Se llama `BILLING` (en minúscula `billing` en `active_modules`) desde 2026-07-01; **nunca** `facturacion` |
| `NOMINA` | 10.000 | 30 | Remuneraciones |
| `ADUANA` | 20.000 | 40 | Activa el flujo de agencia: 1 empresa, datos del agente, menú "Empresa" |

Ninguno está marcado `is_addon`: que un módulo sea add-on lo decide cada plan (`plan_module.included = false`).

## Planes

| Slug | Tier / target | Precio base | Incluidos | Add-on (precio) | Tramos ofrecidos (* = por defecto) |
|---|---|---|---|---|---|
| `demo` | demo / all | 0 | CONTABILIDAD | — | users-demo*, companies-demo* |
| `contador-basic` | basic / contador | 25.000 | CONTABILIDAD | NOMINA (10.000) | users-basico*, users-intermedio, users-full · companies-full* |
| `empresa-pro` | pro / empresa | 50.000 | CONTABILIDAD, NOMINA | BILLING (15.000) | users-basico*, users-intermedio, users-full · companies-basico*, companies-intermedio, companies-full |
| `aduana-pro` | pro / empresa | 50.000 | ADUANA | CONTABILIDAD (12.000) | users-basico*, users-intermedio, users-full · companies-basico*, companies-intermedio, companies-full |
| `full` | pro / empresa | 0 | ADUANA, BILLING, CONTABILIDAD, NOMINA | — | users-full*, companies-full* |

- `full` se creó desde Soporte: puede no existir en otro ambiente ni en `qdoora_testing`. Sus módulos son configuración; **nada en el código depende de que `full` tenga o no ADUANA**.
- Un plan con ADUANA limita a 1 empresa aunque su tramo diga más (`SubscriptionLimitService::ADUANA_COMPANY_LIMIT`). Los tramos de empresas mayores en `aduana-pro` no se pueden usar.

## Tramos de cantidad (`quantity_tier`)

| Usuarios | Rango | Precio | Activo | Empresas | Rango | Precio | Activo |
|---|---|---|---|---|---|---|---|
| `users-demo` | 1 | 0 | ✅ | `companies-demo` | 1 | 0 | ✅ |
| `users-basico` | 1–5 | 0 | ✅ | `companies-basico` | 1 | 0 | ✅ |
| `users-intermedio` | 6–8 | 15.000 | ✅ | `companies-intermedio` | 2–3 | 15.000 | ✅ |
| `users-full` | 9–10 | 20.000 | ✅ | `companies-full` | 4–5 | 20.000 | ✅ |
| `users-enterprise` | 13–9999 | 18.000 | ❌ retirado | `companies-enterprise` | 6–9999 | 17.000 | ❌ retirado |

Reglas del catálogo de tramos:
1. **Ningún tramo de usuarios supera 10** (decisión 2026-10-20). Más usuarios = cupos extra, no un tramo nuevo.
2. **Los nombres son paralelos** en las dos dimensiones: `demo`, `basico`, `intermedio`, `full`, `enterprise`.
3. **Un tramo retirado** queda `active = false` y sin filas en `plan_quantity_tier`. No se ofrece (`PlanManagerService::getQuantityTiers()` filtra activos), no se contrata (`resolveTierId` y `StorePlanRequest` exigen activo) y `repair-tiers` mueve a su tramo por defecto a los planes vigentes que lo tengan. La fila solo se borra si ninguna suscripción la usó.
4. **Todo plan tiene un tramo por defecto en cada dimensión.** Sin él, el alta y el cambio de plan fallan con 422 (no hay fallback).
5. Los nombres antiguos de empresas (`inicia`, `medio`, `avanzado`, `ilimit`) ya no existen: se renombraron con el mismo id.

## Cambiar el catálogo

| Cambio | Cómo |
|---|---|
| Plan nuevo, módulos de un plan, precio, deprecar | Gestor de Planes del Portal Soporte (`v1/support/plans`), o migración si debe quedar igual en todos los ambientes |
| Tramo nuevo o cambio de rango | Migración con reversa (no hay pantalla). Después `subscription:repair-tiers --dry-run` y `repair-tiers` para los planes vigentes |
| Retirar un tramo | `active = false`, quitarlo de `plan_quantity_tier`, mover el `is_default` a otro tramo activo y correr `repair-tiers` |

Nunca se actualiza `subscriber_plan.user_tier_id`/`company_tier_id` a mano: se reemplaza el plan con `changePlan` (lo hace `repair-tiers`).

## Consultar el catálogo real (solo lectura)

```sql
-- Planes con sus módulos incluidos y add-on
select p.slug, p.tier, p.target, p.active,
  string_agg(case when pm.included then pm.module_code end, ',') incluidos,
  string_agg(case when not pm.included then pm.module_code || '(' || pm.addon_price || ')' end, ',') addons
from plan p left join plan_module pm on pm.plan_id = p.id group by 1, 2, 3, 4 order by 1;

-- Tramos que ofrece cada plan (* = por defecto)
select p.slug, string_agg(qt.code || case when pqt.is_default then '*' else '' end, ', ' order by qt.dimension, qt.min_qty)
from plan p join plan_quantity_tier pqt on pqt.plan_id = p.id join quantity_tier qt on qt.id = pqt.quantity_tier_id
group by 1 order by 1;

-- Catálogo de tramos y módulos
select code, dimension, min_qty, max_qty, unit_price, active from quantity_tier order by dimension, min_qty, id;
select code, standalone_price, is_addon, active, "order" from module order by "order";
```

En local: `docker exec postgres psql -U sail -d qdooraChileV1 -c "<consulta>"`. En QA: `docker exec postgres-qa sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "<consulta>"'` desde el EC2 (ver `qdoora-despliegue`).

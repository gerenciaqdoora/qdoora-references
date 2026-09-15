# Resolución de Cuentas: los 3 mecanismos y su costo

Decidir qué cuenta recibe cada monto es la única parte realmente específica de un dominio. QdoorA tiene **tres mecanismos** y elegir mal es la causa más común de un asiento incorrecto.

## Tabla de decisión

| Si el monto... | Mecanismo | Método | Aporta auxiliar y centro de costo |
|---|---|---|---|
| Depende del **tercero** (cliente, proveedor, empleado, producto) y el usuario lo configura | **Imputación** | `AccountingImputationService::getRcvConfigForOperation()` / `resolve()` | Sí — los que tenga guardados |
| Es **estructural del plan de cuentas** (Clientes, Proveedores, IVA débito/crédito, Honorarios por pagar, Remuneraciones por pagar) | **Cuenta maestra** | `AccountingEntryService::resolveMasterNode($companyId, $categoryCode)` | **No** — los pone el proceso |
| Es un **impuesto de la empresa** | **Impuesto** | `AccountingEntryService::resolveTaxNode()` o `resolveTaxNodeOrMaster()` | Según su propia imputación |

Las constantes de categoría están en `app/Constants/AccountCategories.php`. **Qué significa cada cuenta maestra, a qué clase contable puede asignarse (`allowed_class_codes`) y cuál corresponde a tu dominio está documentado en `erp-accounting-expert` (sección 1.5)** — consúltalo antes de elegir.

> **Cuenta mayor**: el nodo que recibe el movimiento es el *último* del árbol. Si la Cuenta tiene SubCuentas, manda la SubCuenta. Por eso todo nodo resuelto viaja como `{node_id, type}` — un id suelto es ambiguo entre `cont_accounts` y `cont_sub_accounts`. Ver `erp-accounting-expert` sección 1.2.

## Mecanismo 1: Imputación configurada

Es el sistema general de configuración contable. Cada imputación es la tupla **(dueño, propósito) → nodo contable + auxiliar + centro de costo**.

Para un dominio nuevo debes agregar un caso a `App\Enums\Contabilidad\AccountingImputationPurpose` y completar sus cinco métodos:

```php
case MI_PROCESO_ALGO = 'mi_proceso_algo';

ownerClass()           // El modelo dueño (ThirdCompany, ImpuestoEmpresa, Producto, HaberDescuento...)
label()                // Glosa en español: "La cuenta {label} exige seleccionar un auxiliar."
domain()               // Nombre del dominio para el listado de configuraciones pendientes
provides()             // Campos que TU automatización aporta en runtime (ver abajo)
requiresRcvOperation() // Solo si la cuenta debe ser operativa de una naturaleza RCV
```

### `provides()`: la declaración que evita bloqueos permanentes

Declara qué campos **resuelve tu proceso en tiempo de ejecución** y que por lo tanto no deben pedirse al configurar la imputación. Valores posibles: `auxiliary`, `cost_center`, `numero_operacion`, `numero_despacho`.

Dos ejemplos reales:

- `PAYROLL_CONCEPT` declara `['cost_center']` porque la liquidación toma el centro de costo del contrato del empleado (`hr_work_contracts.cost_center_id`). **Sin esta declaración**, todo concepto de nómina sobre cuenta de resultado quedaría marcado para revisión de forma permanente en cuanto la empresa active centros de costo.
- **IVA GENERAL** amplía `provides` con `auxiliary` en `AccountingImputationService::providedAtRuntime()`, porque la línea del IVA se imputa siempre al tercero del documento.

> Si tu proceso aporta un dato en runtime y no lo declaras, el configurador exigirá al usuario un valor que después vas a ignorar, y el recálculo lo marcará para revisión sin salida posible.

## Dónde se aplican realmente las restricciones (auxiliar y centro de costo)

**Contraintuitivo pero crítico: la centralización NO valida restricciones.** Solo lee `$config->auxiliary_id` y `$config->cost_center_id` y los copia a la línea. Las restricciones se aplican en otros dos momentos:

### Momento 1 — al configurar la imputación (`AccountingImputationService::save`)

1. El dueño corresponde al propósito
2. El nodo pertenece al plan de cuentas de **esa** empresa (aislamiento multi-tenant)
3. La operativa RCV de la cuenta coincide con el propósito, si aplica
4. `AccountRequirementService::resolveAuxiliaryForNode()` / `resolveCostCenterForNode()` → si la cuenta exige y falta, **excepción**; si no exige, guarda `null` aunque venga un valor
5. `assertTransactionalFieldsCovered()` → número de operación / despacho

Las reglas viven en `AccountRequirementService`:

- **Auxiliar**: exigido si `trabaja_con_auxiliar_con_rut || trabaja_con_auxiliar_sin_rut`. Además valida el **tipo** con `mismatchedAuxiliaryType()` — los dos conjuntos son disjuntos y una cuenta puede cambiar de uno a otro.
- **Centro de costo**: **derivado, no configurable** — `company.allow_cost_center && cuenta de resultado`. Cuenta de resultado = clase Ganancias o Pérdidas (`TypeClasses::RESULT_CLASSES`), resuelta por plan vía `AccountPlanTypeClassMap` — no por el dígito del código.

### Momento 2 — revalidación diferida

`syncAfterAccountFlagsChanged()` (cambió una cuenta) y `syncAfterCompanyCostCenterToggled()` (la empresa activó centros de costo) recorren las imputaciones afectadas y ejecutan `recalculateOne()`: limpian lo que dejó de aplicar y marcan `needs_review` + `review_reason` si algo quedó descubierto. **Nunca borran configuración del usuario.**

```
configurar (valida) → cambio de reglas (marca needs_review) → centralizar (lee y confía)
```

**Consecuencia para tu proceso**: si resuelves una cuenta por una vía que NO pasa por `save()` — típicamente una **cuenta maestra** —, nadie validó sus requisitos. Eres tú quien debe entregar el auxiliar correcto en la línea.

## Manejo de `missing`: nunca lances desde el resolutor

`resolverCuentas` devuelve `{lines, missing}` y **no lanza**. Cada entrada de `missing` lleva:

```php
[
    'concept'    => 'afecto',                  // clave estable para el frontend
    'label'      => 'Cuenta del valor afecto', // glosa en español
    'amount'     => 123456.0,
    'reason'     => $config?->review_reason,   // null si simplemente no hay cuenta
    'configured' => $this->configuredNode($config), // cuenta vigente si estaba marcada
]
```

`configured` existe para que el modal de centralización manual **preseleccione** lo que ya había y el usuario complete solo lo que falta, en vez de rearmar desde cero. Replica este shape: el frontend ya lo consume.

Quien lanza la excepción es el servicio dueño, con la glosa compuesta por `describeMissing()`.

## Eficiencia: el lote es el caso de prueba

Un `foreach` ingenuo sobre 1.000 documentos ejecuta ~5.000 consultas, casi todas idénticas. Tres técnicas, en orden de impacto:

### 1. Memo por operación (resolución dentro del lote)

La cuenta maestra es constante por empresa, la del impuesto por impuesto, y la del auxiliar se repite en todos los documentos del mismo tercero. Dentro de una misma operación esa configuración no cambia — quien la escribe (`AccountingImputationService`) no pasa por el resolutor.

```php
private array $resolutionCache = [];

private function remember(string $key, \Closure $resolver): mixed
{
    // Memoriza también el null: "no hay cuenta configurada" es una respuesta
    // tan válida como la cuenta y no debe reconsultarse por documento.
    if (!array_key_exists($key, $this->resolutionCache)) {
        $this->resolutionCache[$key] = $resolver();
    }

    return $this->resolutionCache[$key];
}

public function flushResolutionCache(): void
{
    $this->resolutionCache = [];
}
```

Es seguro porque no hay Octane y los servicios no son singletons (instancia fresca por request y por job). Aun así, **las entradas de la operación llaman `flushResolutionCache()` explícitamente** — el documento puntual, el dry-run y el inicio del lote — para no depender de ese detalle del contenedor. El lote no pasa por las entradas unitarias, así que conserva su memo entre documentos.

### 2. Consulta en lote para los resúmenes

Preguntar auxiliar por auxiliar convierte N terceros en N consultas. Usa la variante batch indexada:

```php
$configs = $this->accountingImputationService->getRcvConfigsForOperation(
    $companyId, $thirdIds, $operation, $valueType
); // Collection keyBy('imputable_id')

$config = $configs->get($thirdId);
```

### 3. `lazyById` para recorrer el lote

```php
$query = $this->pendingDocumentsQuery(...);
$total = (clone $query)->count();   // clonar ANTES: lazyById muta la query

$query->lazyById(200)->each(function ($doc) use (&$applied, &$errors) { ... });
```

`get()` carga miles de modelos en memoria. `chunk()` por offset **salta registros**, porque cada documento deja de cumplir el filtro `PENDING` al centralizarse. `lazyById` avanza por `id > último` y es inmune a eso.

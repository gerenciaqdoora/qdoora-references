# Catastro — Acoplamiento a los códigos de Tipo del Plan de Cuentas (1..5)

> **Fecha**: 2026-09-14 (creación) · 2026-09-15 (Fase 3) · 2026-09-15 (Fase 2)
> **Estado**: Fase 1 **ejecutada** el 2026-09-14 (tabla `cont_type_classes`, `type_class_code` en Tipo con backfill, creación desde cero en Portal Cliente). Fase 3 **ejecutada** el 2026-09-15: `AccountPlanTypeClassMap` (resolución de clase por plan, memoizada), `allowed_class_codes`, centro de costo y Balance General por clase, guarda temporal de Fase 1 retirada, Portal Cliente sincronizado. Fase 2 **ejecutada** el 2026-09-15: el Excel de importación declara la clase de cada Tipo (columna "Clase Cuenta"), el importador crea solo los Tipos presentes en el archivo (Patrimonio incluido solo si aparece) y valida cuentas maestras contra la clase declarada. Hallazgos cerrados: BD-1, BD-2, BD-3 (mecanismo), MO-1, MO-2, MO-3, SE-1..SE-9, TS-1..TS-4, PS-1, PS-2, FC-1..FC-4, FC-6, DO-1..DO-4. **Seguimiento diferido** (no bloqueante): estrechar `allowed_class_codes` de HONO/HONE/GADE/GADX de `['PATRIMONIO','GANANCIA']` a solo `['GANANCIA']` — se difirió explícitamente en Fase 2 (ver `implementation_plan_fase2.md`, decisión D5) para no afectar retroactivamente planes de agencia ya importados con Tipo `3 = PATRIMONIO` canónico.
> **Motivo**: se introduce la tabla `cont_type_classes` (clase contable: Activo, Pasivo, Patrimonio, Ganancias, Pérdidas) para que cada plan de cuentas declare qué clase representa cada Tipo, en vez de asumir la numeración fija. Este documento deja en evidencia **todo lo que hoy está amarrado al dígito** para abordarlo en fases posteriores.
> **Cómo se levantó**: `rg` sobre `qdoora-api/app`, `qdoora-api/database`, `qdoora-api/tests`, `fuse-starter/src`, `support-portal/src` y `qdoora-references/`, más lectura de cada archivo citado. Las líneas corresponden al estado del código en la fecha indicada.

---

## 1. La convención actual

Hoy QdoorA asume una **numeración canónica** heredada del PUC (`database/seeders/csv/puc.csv`):

| Código Tipo | Clase | Nombre en PUC |
|---|---|---|
| `1` | Activo | ACTIVOS |
| `2` | Pasivo | PASIVOS |
| `3` | Patrimonio | PATRIMONIO |
| `4` | Ganancias | GANANCIAS |
| `5` | Pérdidas | PERDIDAS |

La convención **no está modelada en ningún lado**: vive repartida en constantes PHP, JSON de base de datos, mensajes de error, comentarios, colores de badges y tests. `cont_account_plan_types` solo guarda `code` (varchar(1)) y `name`; nada dice qué clase contable es ese Tipo.

**Síntoma ya observado**: la migración `2026_09_09_100000_add_customs_account_categories.php:13-17` tuvo que declarar `allowed_type_codes = ['3','4']` para `HONO`/`HONE`/`GADE`/`GADX` porque los planes de agencias de aduana ubican sus ingresos en el Tipo `3`. Es decir, la restricción de cuenta maestra ya se está "abriendo" a mano para tolerar planes que no siguen la numeración canónica — exactamente el problema que resuelve `cont_type_classes`.

---

## 2. Inventario de hallazgos

Leyenda de impacto si un plan declara un mapeo no canónico (ej. `3 = Ganancias`, sin Patrimonio):

- **ALTO**: produce un resultado contable/funcional incorrecto (balance, centro de costo, cuentas maestras).
- **MEDIO**: produce un dato de apoyo incorrecto en UI (filtros, badges, textos) sin corromper datos.
- **BAJO**: no afecta el comportamiento; requiere solo ajuste cosmético o de documentación.

### 2.1 Base de datos (`qdoora-api/database`)

| # | Ubicación | Qué amarra | Impacto | Acción futura |
|---|---|---|---|---|
| BD-1 ✅ | `migrations/2024_09_24_192824_create_account_plan.php:70` — `cont_account_plan_types.code varchar(1)` con comentario "siempre son 1" | Solo el largo del código. No sabe qué clase es. | BAJO | **Cerrado (Fase 1)**: `2026_09_14_100100_add_type_class_code_to_account_plan_types.php` agrega `type_class_code` (FK a `cont_type_classes.code`) con backfill canónico. |
| BD-2 ✅ | `migrations/2026_07_31_100300_add_allowed_type_codes_to_account_categories.php:24-52` — `cont_account_categories.allowed_type_codes` (JSON de dígitos `'1'..'5'`) | La restricción "esta cuenta maestra solo va en cuentas de tipo X" se expresa **por dígito**. | **ALTO** | **Cerrado (Fase 3)**: `2026_09_15_100000_replace_allowed_type_codes_with_allowed_class_codes.php` traduce cada categoría al mapa canónico y elimina la columna vieja. Evaluado contra `AccountPlanTypeClassMap::classFor()`. |
| BD-3 ✅ | `migrations/2026_09_09_100000_add_customs_account_categories.php:13-17,52` — `HONO`/`HONE`/`GADE`/`GADX` con `['3','4']` | Parche para planes legacy que ponen ingresos en el `3`. | **ALTO** | **Cerrado el mecanismo (Fase 3)**: traducido a `['PATRIMONIO','GANANCIA']` (no solo `['GANANCIA']`, ver nota abajo). Fase 2 ya permite declarar `3 = Ganancias` al importar (probado con una muestra real de un plan de agencia), pero **estrechar a `['GANANCIA']` se difirió deliberadamente** (D5 del plan de Fase 2): hacerlo ahora podría invalidar retroactivamente planes de agencia ya importados con Tipo `3 = PATRIMONIO` canónico. Queda como seguimiento, no como bloqueante. |
| BD-4 | `cont_voucher_accounts.type_id` / `sub_type_id` (FK a Tipo/SubTipo) — `VoucherService.php:381,438,481` | Snapshot **por id**, no por dígito. La clase es alcanzable vía `Tipo.type_class_code`. | BAJO | Nada. Los reportes futuros pueden hacer join a la clase en vez de `substr(code,0,1)`. |

### 2.2 Modelos (`qdoora-api/app/Models`)

| # | Ubicación | Qué amarra | Impacto | Acción futura |
|---|---|---|---|---|
| MO-1 ✅ | `PlanCuenta/CategoriaCuenta.php:66-75` — `permiteTipo(?string $typeCode)` | Comparaba el dígito del Tipo con `allowed_type_codes`. | **ALTO** | **Cerrado (Fase 3)**: `permiteClase(?string $classCode)` leyendo `allowed_class_codes`. |
| MO-2 ✅ | `PlanCuenta/Tipo.php:45,52` — `$visible`/`$fillable` sin clase; sin relación | El Tipo no expone su clase al frontend. | MEDIO | **Cerrado (Fase 1)**: `type_class_code` visible/fillable + relación `typeClass()`; modelo `PlanCuenta/TypeClass.php`. |
| MO-3 ✅ | `PlanCuenta/Cuenta.php:84`, `PlanCuenta/SubCuenta.php:79` — comentario "cuenta de resultado (codigo 4 o 5)" + `Traits/DerivesCostCenterRequirement.php:13,31` | `trabaja_con_centro_costo` (derivado) dependía de `AccountRequirementService::isResultAccountCode()` → primer dígito ∈ `['4','5']`. | **ALTO** | **Cerrado (Fase 3)**: el trait usa `AccountPlanTypeClassMap::classFor()` + `isResultClass()`; comentarios actualizados. |

### 2.3 Servicios (`qdoora-api/app/Services/Contabilidad`)

| # | Ubicación | Qué amarra | Impacto | Acción futura |
|---|---|---|---|---|
| SE-1 ✅ | `AccountRequirementService.php:27` `RESULT_TYPE_CODES = ['4','5']` · `:37-44` `isResultAccountCode()` (`substr($code,0,1)`) · `:96-101` `typeCodeFor()` · `:106-109` `isResultAccount()` · `:207-212` `requiresCostCenter()` | Toda la exigencia de **centro de costo** en asientos (voucher manual, centralizaciones RCV/honorarios/nómina, imputaciones `needs_review`) se decidía por el primer dígito del código. Consumidores: `resolveCostCenterForNode`, `missingRequirement`, `DerivesCostCenterRequirement`. | **ALTO** | **Cerrado (Fase 3)**: `App\Support\AccountPlanTypeClassMap` (memo por plan, invalidado por evento `saved` en `Tipo`) + `typeClassFor()`/`isResultClass()`. Se eligió la opción memo-por-plan (sin joins ni desnormalización) sobre las dos alternativas evaluadas. |
| SE-2 ✅ | `AccountRequirementService.php:120-143` — `assertCategoryAllowedForSubType()` leía `SubTipo->tipo->code` y llamaba `permiteTipo()`; mensaje "solo puede asignarse a cuentas de tipo {1 o 2}". Llamado desde `CuentaService.php:128,205` y `SubCuentaService.php:58,152`. | Validación de asignación de cuenta maestra al crear/editar cuenta o subcuenta. | **ALTO** | **Cerrado (Fase 3)**: lee `tipo.type_class_code`, mensaje con nombres de clase desde `TypeClass`. |
| SE-3 ✅ | `AccountingReportService.php:541-597` `buildBalanceRow()` — `:555` `$clase = substr(code,0,1)`, `:557` `['1','2','3']` → columnas activo/pasivo, `:558` `['4','5']` → pérdida/ganancia | **Balance General**: la clasificación de cada saldo en las 4 columnas del balance dependía del dígito. Un plan con `3 = Ganancias` mostraba sus ingresos como Activo/Pasivo. | **ALTO** | **Cerrado (Fase 3)**: `classifyByTypeClass()` (público, puro, testeado en `BalanceClassificationTest`) clasifica por `AccountPlanTypeClassMap::classFor()`. |
| SE-4 ✅ | `AccountPlanService.php:267-297` `getMasterAccountsStatus()` — `allowed_type_names` traducía dígitos a nombres de los Tipos del plan de la empresa | Ya era "consciente del plan", pero indexaba por dígito. | MEDIO | **Cerrado (Fase 3)**: `allowed_class_names` desde el catálogo global `TypeClass`. |
| SE-5 ✅ | `AccountPlanService.php:560-573` `getAccountsWithOutMasterAccount()` — exponía `tipo_code` por nodo para que el Portal Cliente filtre | El selector de cuentas disponibles por cuenta maestra filtraba por dígito. | MEDIO | **Cerrado (Fase 3)**: expone `type_class_code` del nodo. |
| SE-6 ✅ | `AccountPlanService.php:257` `getCategoriasCuenta()` — exponía `allowed_type_codes` | Contrato API consumido por 3 componentes del Portal Cliente (FC-1..FC-3). | MEDIO | **Cerrado (Fase 3)**: expone `allowed_class_codes`. |
| SE-7 ✅ | `AccountPlanImportService.php` — `resolveClassCode()`, `resolveTipoClasses()`, `buildTree()`, `import()` | El importador asumía la numeración canónica de punta a punta. | **ALTO** | **Cerrado (Fase 2)**: columna "Clase Cuenta" del Excel declara la clase de cada Tipo (con sinónimos: Ingreso→Ganancia, Gasto→Pérdida); se crea un Tipo solo por cada dígito presente en el archivo (Patrimonio incluido solo si aparece); `TypeClassService::assertValidMapping()` valida el conjunto; la validación de cuenta maestra usa la clase declarada. Si el archivo no trae la columna, se mantiene el comportamiento histórico (5 Tipos, canónico) para no romper integraciones existentes. |
| SE-8 ✅ | `Jobs/CloneAccountPlanJob.php:84-93` `cloneTipo()` usa `replicate()` | Copia todos los atributos → `type_class_code` viaja solo. | BAJO | **Cerrado (Fase 1)**: verificado por `tests/Feature/Contabilidad/AccountPlanCloneTypeClassTest.php`. Sin cambios en el job. |
| SE-9 ✅ | `database/seeders/PUCSeeder.php:67-78` + `csv/puc.csv:2,58,92,…` (filas `TIPO;1;ACTIVOS`) | El PUC base nace sin clase. | MEDIO | **Cerrado (Fase 1)**: el seeder y `AccountPlanImportService::import` asignan `type_class_code` desde `TypeClasses::CANONICAL_BY_TYPE_CODE`. |

### 2.4 Tests que fijan la convención (`qdoora-api/tests`)

| # | Ubicación | Qué fija | Acción futura |
|---|---|---|---|
| TS-1 ✅ | `Feature/Contabilidad/AccountMasterTypeRestrictionTest.php:58-66` | Valores exactos de `allowed_type_codes` por dígito (`['1']`, `['2']`, `['3']`, `['4','5']`, `['5']`). | **Cerrado (Fase 3)**: reescrito contra `allowed_class_codes`; agregado el caso "Tipo `1` declarado Pasivo rechaza CLIENTE_NACIONAL y acepta PROVEEDOR_NACIONAL". |
| TS-2 ✅ | `Feature/Contabilidad/AccountRequirementTest.php:200-217` | "la subcuenta resuelve su tipo desde el primer dígito de su código" (`'4'` ⇒ resultado). | **Cerrado (Fase 3)**: reescrito como "resuelve su clase desde el Tipo de su plan, no desde el dígito"; agregados los casos donde el mismo dígito `1` es o no es de resultado según la clase que declaró el plan. |
| TS-3 ✅ | `Unit/Contabilidad/AccountPlanImportServiceTest.php` | Rechaza tipo `9`; siempre 5 tipos; el `5` se llama PERDIDAS; APER en tipo 2 advierte. | **Cerrado (Fase 2)**: los tests del formato sin clase se mantienen intactos (comportamiento legacy, verificado); se agregaron 10 tests nuevos para el modo declarado (sinónimos, consistencia por Tipo, solo Tipos presentes, nombre por clase, cuenta maestra contra clase declarada, persistencia, y un caso end-to-end con una muestra fiel de `PlanDeCuentas_LVargas_Base.xlsx`). |
| TS-4 ✅ | `Feature/Support/AccountPlanImportPreviewTest.php:61` | `totals.tipos === 5`. | **Cerrado**: sigue siendo correcto porque ese test no declara clase (ejercita el modo legacy); el modo declarado con `totals.tipos` variable está cubierto en `AccountPlanImportServiceTest`. |
| TS-5 | `Feature/Contabilidad/AccountCodeHierarchyTest.php` | Solo regla de prefijo (subtipo empieza con el código del tipo). Independiente de la clase. | Nada. |

### 2.5 Portal Cliente (`fuse-starter/src/app`)

| # | Ubicación | Qué amarra | Impacto | Acción futura |
|---|---|---|---|---|
| FC-1 ✅ | `core/models/data/accountPlan.ts:165` `allowed_type_codes` · `:184,200` `tipo_code` | Contrato TS espejo de SE-5/SE-6. | MEDIO | **Cerrado (Fase 3)**: `allowed_class_codes` en `CategoriaCuenta`, `type_class_code` en `ListaCuenta`. También se agregó `type_class_code` a `FoodNode`/`FlatNode` (`matTree.ts`) y a su transformer — sin eso los diálogos de cuenta/subcuenta habrían filtrado con `undefined` sin romper la compilación. |
| FC-2 ✅ | `dialog/formulario-cuenta/formulario-cuenta.component.ts:104,176` y `dialog/formulario-subcuenta/formulario-subcuenta.component.ts:103,160` — `categoria.allowed_type_codes.includes(this.tipo?.code)` · comentarios `:201` / `:185` "codigo 4 o 5" | Filtro de cuentas maestras seleccionables en los diálogos de cuenta/subcuenta. | MEDIO | **Cerrado (Fase 3)**: filtra por `this.tipo?.type_class_code`. |
| FC-3 ✅ | `modules/shared/assign-master-accounts/assign-master-accounts.component.ts:32,46,72-90` — `tiposPermitidos.includes(cuenta.tipo_code)` | Asistente de asignación de cuentas maestras faltantes. | MEDIO | **Cerrado (Fase 3)**: filtra por `cuenta.type_class_code`. |
| FC-4 ✅ | `modules/admin/contabilidad/account-plan/master-accounts-review/master-accounts-review.component.ts:69-78` `tipoBadgeClasses` por `'1'..'5'` (comentario "convención fija del PUC") · `:122-126` badges/filtro · `:185` `selectedTipoCode` | Colores y filtro de la revisión de cuentas maestras. | MEDIO | **Cerrado (Fase 3)**: `classBadgeClasses` keyed por código de clase (`ACTIVO`→azul, `PASIVO`→naranja, `PATRIMONIO`→púrpura, `GANANCIA`→esmeralda, `PERDIDA`→rosa); filtro renombrado a `selectedClassCode`/`classFilterOptions`. |
| FC-5 | `modules/admin/contabilidad/report/list/balance/balance.component.ts:46-49` · `report/report.types.ts:36-39,84-87` | Solo consume las columnas `activo/pasivo/perdida/ganancia` que arma SE-3. | BAJO | Sin cambios si SE-3 se corrige en backend. |
| FC-6 ✅ | `modules/admin/contabilidad/account-plan/seleccion/` + `clonar/` | No existe creación desde cero: solo clonar PUC o plan de otra empresa. | — | **Cerrado (Fase 1)**: tarjeta "DESDE CERO" + `account-plan/crear/crear.component` (`POST company/{id}/account-plan/create`). |

### 2.6 Portal Soporte (`support-portal/src`)

| # | Ubicación | Qué amarra | Impacto | Acción futura |
|---|---|---|---|---|
| PS-1 ✅ | `modules/admin/customs-subscriber/create-customs-subscriber.component.ts` | Comentario "1:Activo, 2:Pasivo, …" asumía la numeración canónica. | **Cerrado (Fase 2)**: comentario corregido; parser lee la columna "Clase Cuenta" (`account-plan-excel-parser.service.ts`); el preview muestra una sección "Clases declaradas por Tipo" (código, nombre, clase con badge de color) para que el admin confirme visualmente antes de aprobar el alta. |
| PS-2 ✅ | `app/core/models/account-plan-import.model.ts` | Contrato TS del preview no exponía la clase. | **Cerrado (Fase 2)**: `AccountPlanImportRow.class` y `AccountPlanPreviewNode.type_class_code` agregados. |

### 2.7 Documentación y referencias (`qdoora-references/`, `qdoora-api/`)

| # | Ubicación | Qué dice | Acción futura |
|---|---|---|---|
| DO-1 ✅ | `agent/skills/erp-accounting-expert/SKILL.md:93` ("cuenta de resultado (4 o 5)"), `:113-137` (tabla `allowed_type_codes` por dígito), `:222-223` (reglas 6 y 7) · `evals/evals.json:54,64` | Regla de negocio escrita en dígitos. | **Cerrado (Fase 3)**: reescrito en términos de clase; tabla de cuentas maestras ampliada con HONO/HONE/GADE/GADX (faltaban); nueva regla 8 explícita contra decidir por dígito. |
| DO-2 ✅ | `agent/skills/new-accounting-process/references/account-resolution.md:13,59` · `evals/evals.json:33` | "Cuenta de resultado = código empieza en 4 o 5". | **Cerrado (Fase 3)**. |
| DO-3 ✅ | `data-models/Contabilidad_DataModel.md:16-20,137-139` | ERD sin `cont_type_classes`; además dibuja `cont_account_categories ||--o{ cont_account_plan_types`, relación que **no existe** en el esquema. | **Cerrado (Fase 1)**: tabla y FK agregadas; relación ficticia reemplazada por `cont_account_plans ||--o{ cont_account_plan_types` y `cont_account_categories ||--o{ cont_accounts`. |
| DO-4 ✅ | `qdoora-api/app/Services/Contabilidad/AccountPlanImport_SiglaMapping.md` | Columna "Tipo permitido" por dígito. | **Cerrado (Fase 2)**: columnas reescritas por clase; nueva sección 0 explica la columna "Clase Cuenta" y sus sinónimos; nota sobre por qué HONO/HONE/GADE/GADX admiten Patrimonio o Ganancias. |
| DO-5 | `PlanDeCuentas_LVargas_Base.xlsx` hoja "Sigla - Análisis" | Ya usa nombres de clase (Activo, Pasivo, …), no dígitos. | Nada. |

---

## 3. Lo que NO está amarrado (verificado)

- `app/Services/Nomina`, `app/Services/Aduana`, `HonorariumCentralizationService`, `RcvCentralizationService`, `AccountingEntryService`, `VoucherIntegrityService`, `VoucherPartitionService`, `AccountingImputationService`: resuelven cuentas por **cuenta maestra** (`cont_account_categories.code`) o por imputación configurada; ninguno inspecciona el dígito del Tipo. Heredan la dependencia solo a través de SE-1 (centro de costo).
- `AccountCodeHierarchyTest` / FormRequests de cuenta y subtipo (`ManageAccountRequest.php:169`, `CrearPucCuentaRequest.php:103`): validan **prefijo** (el código hijo empieza con el del padre), no la clase.
- Solo existe el reporte `BALANCE` (`Enums/AccountingReportVoucher.php`); no hay Estado de Resultados ni proceso de cierre/apertura de ejercicio que dependa del dígito.

---

## 4. Hoja de ruta propuesta

| Fase | Alcance | Hallazgos que cierra |
|---|---|---|
| **1 — Fundación** (plan `implementation_plan_type_class.md`) | Tabla `cont_type_classes` (5 filas, Patrimonio opcional) · `cont_account_plan_types.type_class_code` con backfill canónico · flujo "Crear plan desde cero" en Portal Cliente con mapeo Tipo → Clase · PUCSeeder e importador asignan clase por convención · este catastro. | BD-1, MO-2, SE-8, SE-9, FC-6 |
| **2 — Importación** ✅ | Columna "Clase Cuenta" en el Excel; sinónimos (Ingreso→Ganancia, Gasto→Pérdida); solo se crean los Tipos declarados (Patrimonio opcional); `TypeClassService::assertValidMapping()` valida el conjunto; validación de cuenta maestra por clase declarada; UI de previsualización muestra la clase por Tipo. | SE-7, TS-3, TS-4, PS-1, PS-2, DO-4 |
| **3 — Migrar la lógica de dígito a clase** ✅ | `allowed_class_codes` · `permiteClase()` · `isResultAccount()` por clase · `buildBalanceRow()` por clase · contratos TS y filtros del Portal Cliente · reescritura de tests y documentación. | BD-2, BD-3 (mecanismo), MO-1, MO-3, SE-1..SE-6, TS-1, TS-2, FC-1..FC-4, DO-1..DO-3 |

**Fase 3 ejecutada el 2026-09-15** (`implementation_plan_fase3.md`). La guarda temporal de Fase 1 (`TypeClassService::assertCanonical()`) fue retirada: `AccountPlanCreateTest` prueba end-to-end que un plan `3 = Ganancias` (no canónico) propaga correctamente la exigencia de centro de costo. El riesgo que motivó la guarda —Balance General, centro de costo y cuentas maestras decidiendo por dígito— ya no existe: las tres capas resuelven `AccountPlanTypeClassMap::classFor()`.

**Fase 2 ejecutada el 2026-09-15** (`implementation_plan_fase2.md`), disparada por el archivo real `PlanDeCuentas_LVargas_Base.xlsx` (plan de una agencia de aduana cuyo Tipo `3` es Ingreso/Ganancia, no Patrimonio, y que no tiene ninguna cuenta de clase Patrimonio). Probado end-to-end con una muestra fiel de ese archivo: importa 4 Tipos (no 5), el Tipo `3` queda `GANANCIA`/"GANANCIAS", y `HONO` obtiene su cuenta maestra sin depender del parche de Fase 3.

**Único pendiente real**: estrechar `allowed_class_codes` de HONO/HONE/GADE/GADX de `['PATRIMONIO','GANANCIA']` a `['GANANCIA']` (BD-3). Se difirió deliberadamente en Fase 2 (decisión D5): aunque el importador ya puede declarar `3 = Ganancias`, estrechar ahora podría afectar retroactivamente planes de agencia ya importados con Tipo `3 = PATRIMONIO` canónico. No bloquea nada — es un seguimiento a evaluar cuando haya más planes reales importados con Fase 2.

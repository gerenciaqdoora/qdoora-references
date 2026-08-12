---
trigger: model_decision
description: Estándares de ingeniería Backend (Laravel 11), DevOps y Seguridad QdoorA
---

# ⚙️ BACKEND_RULES.md — Laravel 11 · DevOps · Seguridad

> Lee este archivo antes de escribir o revisar cualquier código del backend (`qdoora-api`), infraestructura Docker/AWS o auditorías de seguridad.

---

## 🏛️ ARQUITECTURA EN CAPAS (Sagrada e Inamovible)

| Capa | Ruta | Responsabilidad única |
|------|------|-----------------------|
| **Services** | `app/Services/` | Propietario exclusivo de la lógica de negocio. Toda acción operativa nace y muere aquí. |
| **FormRequests** | `app/Http/Requests/` | Guardianes de validación + autorización (incluyendo IDOR en `authorize()`). |
| **Controllers** | `app/Http/Controllers/` | Orquestadores ultraligeros: recibir → delegar al Service → responder. |
| **Resources** | `app/Http/Resources/` | Transformadores obligatorios de respuestas JSON. Nunca retornar modelos Eloquent crudos. |

**PROHIBICIONES ABSOLUTAS:**
- **Controladores**: TIENES PROHIBIDO escribir lógica de negocio, consultas Eloquent directas o validaciones.
- **Service Ownership**: TIENES PROHIBIDO manipular modelos de otro dominio directamente. Invoca al servicio dueño.
- **Relaciones core**: Relaciones desde `ThirdCompany` hacia submódulos deben ser explícitas en el modelo base hasta estandarización via Traits.

---

## 🔐 STATELESS & MULTI-TENANT

- **Stateless**: PROHIBIDO `session()`. Todo el estado reside exclusivamente en el JWT.
- **Multi-tenant**: FILTRA toda query por `company_id` (scope Eloquent global obligatorio en todo modelo).
- **Rutas admin**: Todos los endpoints de alta jerarquía bajo prefijo `v1/support` en `routes/api.php`.

### Derivación de tenant en servidor — nunca confiar en el payload al crear
El `company_id`/`suscriptor_id` de un recurso que se está **creando** NUNCA se acepta como valor del payload del cliente — se deriva en el Service desde `$user->getSuscriptorByRole()` (o equivalente). El `FormRequest` no debe siquiera declarar una regla `exists:` para ese campo cuando lo llena un cliente. El staff (`$user->isStaff()`) es la única excepción autorizada a indicar un tenant explícito (ej. crear un ticket a nombre de un suscriptor).

Caso descubierto: `SupportService::createTicket()` — el `CreateTicketRequest` original aceptaba `suscriptor_id` directo del body (`required|exists:suscriptor,id`, además apuntando a una tabla inexistente: la real es `subscriber`). Cualquier cliente autenticado podía crear tickets atribuidos a otro suscriptor (IDOR de creación). Fix: el campo se eliminó del `FormRequest` y `SupportService::createTicket()` resuelve el suscriptor desde el `reporter` autenticado, salvo que sea staff. Ver tabla de vectores QD más abajo (QD-04).

---

## 🛡️ AUTORIZACIÓN MULTINIVEL (3 Niveles Obligatorios)

Antes de procesar cualquier endpoint, valida en este orden:
1. **USER_ROLE** — permisos específicos del submódulo del usuario
2. **SUBSCRIBER_ROLE** — relación empresa (`company_id` ↔ `suscriptor_id`)
3. **IDOR** — propiedad del recurso específico en `authorize()` del FormRequest

### Los endpoints de LECTURA también requieren FormRequest (caso: `VoucherController::getDetalleComprobante`)
La autorización multinivel de arriba **no es un patrón exclusivo de escritura**. Un `GET` con `Request` plano en vez de un `FormRequest` con `authorize()` es tan explotable como un `POST` sin validar: filtra el recurso completo (montos, glosas, razón social de terceros) a cualquier usuario autenticado que adivine o enumere el identificador.

Caso descubierto: `GET /company/{company_id}/voucher/show` usaba `Request` plano, y el Service (`VoucherService::getComprobante`) buscaba el comprobante por `id`+`year` **sin filtrar por `company_id`**. La combinación permitía leer el asiento contable de cualquier empresa del SaaS. El fix fue doble — nunca alcanza con uno solo de los dos:
```php
// ❌ Solo el Service filtra -> si el filtro se rompe o se omite, no hay segunda barrera
Voucher::where('id', $uuid)->where('year', $year)->first();

// ✅ FormRequest con authorize() (frontera HTTP) + filtro forzoso en el Service (frontera de datos)
public function getComprobante(string $uuid, string $year, int $company_id): VoucherResource
{
    $voucher = Voucher::where('id', $uuid)
        ->where('year', $year)
        ->where('company_id', $company_id) // filtro forzoso multi-tenant
        ->first();
    if (!$voucher) throw new GenericException('Comprobante no está disponible.');
    // ...
}
```
Regla: todo controlador que reciba `Request $request` en vez de un `FormRequest` tipado es sospechoso por defecto — revisar si el endpoint expone datos de negocio antes de asumir que "solo lee, no hace falta autorizar".

#### Catálogos compartidos entre módulos: usa `CompanyAccessRequest`, no un FormRequest con permiso de submódulo
Cuando un endpoint alimenta a **varios módulos** (selectores de cuentas, auxiliares, centros de costo, productos), exigir el permiso de un submódulo concreto rompe a los demás consumidores. Para esos casos existe ya `App\Http\Requests\CompanyAccessRequest`: valida **solo pertenencia de empresa** (`SUBSCRIBER_ROLE` → la empresa es de su suscriptor; `USER_ROLE` → `userHasCompanyPermission()`), sin tocar `usersPermissionSubmodules()`. Está en uso en 25+ endpoints de lectura.
```php
// ❌ FormRequest nuevo exigiendo COMPROBANTE:review en el selector de cuentas
// -> rompe Tesoreria y Honorarios, que consumen el MISMO endpoint

// ✅ Reutiliza el estandar existente: solo pertenencia de empresa
public function getAccountsVoucher(CompanyAccessRequest $request, int $company_id)
```
Caso: `AccountPlanController::getAccountsVoucher` (`POST /company/{company_id}/accounts/voucher/filter`) usaba `Request` plano — cualquier usuario autenticado obtenía el plan de cuentas completo de otra empresa cambiando el `company_id` de la URL. **Antes de crear un FormRequest nuevo para un endpoint de solo-lectura por empresa, verifica si `CompanyAccessRequest` ya cubre el caso.**

> Nota de comportamiento: `CompanyAccessRequest::authorize()` retorna `true` si la empresa no existe y delega el fallo a `withValidator()` → responde **422**, no 403 ni 400. Los tests de "empresa inexistente" sobre endpoints que lo usan deben esperar 422.

#### Acciones especiales de submódulo (no son CRUD genérico): `userCanPerformSubmoduleAction()`
Cuando una acción no encaja en `review/create/update/delete` (emitir Nota de Crédito, cambiar consignatario de una DIN, cierre contable anual, crear ticket de soporte), **no agregues una columna booleana nueva** a `users_permission_submodule`. Usa el catálogo de "abilities" nombradas: tabla `submodule_action` (columna `submodule` string → `submodule.code`, igual convención que `users_permission_submodule`/`role_submodule_permissions` — **nunca** `submodule_id`), con `requires_operation` (`review|create|update|delete|special`) y `subscriber_only` (bool). Grants en `users_permission_submodule_action` (usuario) y `role_submodule_action_permissions` (plantilla del rol), ambos con índice único declarado **desde la migración original** — la migración de integridad de agosto 2026 tuvo que parchear retroactivamente 3 tablas de permisos por no tenerlo desde el día uno.

Autorización vía `User::userCanPerformSubmoduleAction(int $companyId, string $submoduleCode, string $actionCode): bool`, único punto de entrada para el FormRequest:
```php
public function authorize(): bool
{
    /** @var \App\Models\User $user */
    $user = Auth::guard('api')->user();
    $companyId = (int) $this->route('company_id');

    return $user->userCanPerformSubmoduleAction($companyId, 'COMPROBANTE', 'NOTA_CREDITO');
}
```
Internamente encadena: bypass `SUBSCRIBER_ROLE` (solo valida pertenencia de empresa) → **candado `subscriber_only`** (bloquea siempre a `USER_ROLE`, sin mirar el pivote — es la defensa para operaciones irreversibles tipo cierre contable, ver HARD REJECT #6) → `userHasCompanyPermission(..., TRANSACTION)` → CRUD base vía `usersPermissionSubmodules()` (se salta si `requires_operation === 'special'`, para acciones sin prerrequisito como crear un ticket de soporte) → grant específico (con el mismo fallback a la plantilla del rol que se describe abajo).

> **Este proyecto no usa `Gate::define()`/`Gate::check()`.** Ningún FormRequest real lo hace — la autorización siempre es un método directo en `User`, llamado desde un switch/if sobre `$user->role` en `authorize()`. No introduzcas Gates de Laravel como patrón nuevo aunque la documentación de referencia de una skill los mencione.

#### `usersPermissionSubmodules()` hereda de la plantilla del rol si no hay override directo — no es solo copia al asignar
A diferencia de lo que sugiere el nombre "plantilla", `role_submodule_permissions` **sí se lee en runtime**: `User::usersPermissionSubmodules()` primero busca un grant directo en `users_permission_submodule`, y si no lo encuentra, cae a `RoleSubmodulePermission::where('role_id', $this->role_id)...`. `User::userHasSubmoduleAction()` replica exactamente esta misma doble ruta para las abilities nuevas. Cualquier refactor de estos métodos debe preservar el fallback — eliminarlo sería una regresión silenciosa para todo usuario sin overrides individuales (la mayoría).

#### CAPA 1 (contratación): `Suscriptor::modules()`/`Subscriber::modules()` retorna una `Collection`, no un Builder
```php
// ❌ Falla en runtime: Collection no tiene whereHas()
$suscriptor->modules()->whereHas('submodulos', fn ($q) => $q->where('code', $codigo))->exists();

// ✅ Collection: flatMap + contains
$suscriptor->modules()->flatMap(fn ($m) => $m->submodulos)->contains('code', $codigo);
```
Antes de este fix, ni `usersPermissionSubmodules()` ni ningún otro método validaban que el módulo siguiera contratado — un usuario conservaba acceso operativo a un módulo que su suscriptor ya había descontratado, mientras el pivote de permisos no se purgara.

#### FormRequests nuevos: usa `AuthorizesClientRequests`/`AuthorizesSupportRequests`, no repitas el switch/case

El switch/case `SUBSCRIBER_ROLE`/`USER_ROLE` de `authorize()` (bypass de suscriptor + `userHasCompanyPermission()` + `usersPermissionSubmodules()`) y el `$user->role === 'ADMIN_ROLE'` inline de Soporte están duplicados en ~150 y ~43 FormRequests respectivamente. **Ningún FormRequest existente fue migrado** — es deuda consciente, no omisión. Pero **todo FormRequest nuevo** debe centralizar esa lógica con los traits en `app/Traits/` (convención real del proyecto, no `app/Http/Concerns/`):

```php
// Portal Cliente
use App\Traits\AuthorizesClientRequests;

class CreaAlgoRequest extends FormRequest
{
    use AuthorizesClientRequests;

    public function authorize(): bool
    {
        return $this->authorizeSubmodule((int) $this->route('company_id'), 'COMPROBANTE', UserOperationSubmodule::CREATE);
        // Habilidad especial: $this->authorizeSubmodule($companyId, 'COMPROBANTE', UserOperationSubmodule::CREATE, 'NOTA_CREDITO_DEBITO');
        // Solo empresa (sin submódulo): $this->authorizeCompany($companyId);
    }
}

// Portal Soporte/Admin
use App\Traits\AuthorizesSupportRequests;

class ReviewAlgoRequest extends FormRequest
{
    use AuthorizesSupportRequests;

    public function authorize(): bool
    {
        return $this->authorizeAdmin(); // patrón dominante real: 42 de 43 FormRequests de Soporte exigen solo ADMIN_ROLE
        // return $this->authorizeSupportStaff(); // excepción — solo si el endpoint es explícitamente de bajo riesgo
    }
}
```

`authorizeSubmodule()` delega en `User::canOperateOnSubmodule()` (nuevo, `match(...) { default => false }` fail-closed desde el día uno), que a su vez delega en `userCanPerformSubmoduleAction()` cuando se pasa `$ability_code`. `User::ownsCompany()` es ahora público — es el mismo chequeo de pertenencia de empresa que antes vivía inline en `userCanPerformSubmoduleAction()`, reutilizado por ambos. No cubre los FormRequests de ficha de empresa que validan `SHOW`/`UPDATE` sin submódulo (`ShowEmpresaRequest`, `ActualizarEmpresaRequest`) — esos quedan fuera a propósito, usa `authorizeCompany()` para ese caso.

Criterio de tipado en esta API: `$operation` va tipado con `UserOperationSubmodule` (conjunto cerrado que refleja las 4 columnas de `users_permission_submodule`; antes era string validado en runtime con un `throw` 406). `$submodule_code` y `$ability_code` siguen siendo `string` porque son catálogos abiertos en BD que ya resuelven fail-closed. **No confundir `UserOperationSubmodule` con `SubmoduleActionTrigger`**: este último tiene el caso extra `SPECIAL` y aplica solo a `submodule_action.requires_operation`. El método legado `usersPermissionSubmodules($code, string $column)` conserva su firma con string — lo llaman ~150 FormRequests con `->value`, el tipado fuerte empieza en la API nueva y no se propaga hacia atrás.

> Gotcha de PHP: un enum backed (`CompanyPermissionAbility::TRANSACTION->value`) **no puede ser el valor por defecto de un parámetro** — "Constant expression contains invalid operations", incluso en PHP 8.2/8.3, porque `->value` no es una expresión constante. Si necesitas un enum como default, tipa el parámetro con el enum mismo (`CompanyPermissionAbility $ability = CompanyPermissionAbility::TRANSACTION`) y extrae `->value` dentro del método.

---

## 🛠️ PATRONES TRANSVERSALES OBLIGATORIOS

### Gestión de Errores
```php
// ❌ TERMINANTEMENTE PROHIBIDO
$record = Model::findOrFail($id);

// ✅ OBLIGATORIO — excepción controlada, mensaje en español
$record = Model::find($id);
if (!$record) {
    throw new CustomException('Registro no encontrado.');
}
```

### Try-Catch en Controladores
```php
// Todo método de controlador DEBE envolver su lógica
try {
    $result = $this->_service->execute($request->validated());
    return new DomainResource($result);
} catch (\Exception $e) {
    $this->logAndResponse($e); // trait HandlesControllerLogs
}
```

### Atomicidad
```php
// OBLIGATORIO cuando una acción afecta múltiples tablas
DB::transaction(function () {
    // operaciones atómicas
});
```

### Correlativos únicos: secuencia Postgres, nunca `count() + 1`
`Model::whereYear(...)->count() + 1` sobre una columna `unique()` es una race condition: dos requests concurrentes leen el mismo `count()` antes de que cualquiera inserte, y el segundo `INSERT` revienta con violación de unicidad. Usar una secuencia nativa de Postgres — atómica, sin locks explícitos:
```php
// Migración
DB::statement('CREATE SEQUENCE IF NOT EXISTS support_ticket_code_seq START 1');

// Generación del código
$seq = DB::selectOne("SELECT nextval('support_ticket_code_seq') AS seq")->seq;
return sprintf('TKT-%d-%05d', Carbon::now()->year, $seq);
```
Caso descubierto: `SupportService::generateTicketCode()` (módulo Soporte/Tickets, Fase 0 de saneamiento, ago-2026). Trade-off aceptado: el correlativo ya no reinicia por año (la secuencia es continua). Si el negocio exige reinicio anual, evaluar una secuencia particionada por año en vez de esta.

### Logging y Auditoría
```php
// OBLIGATORIO en toda creación, mutación o eliminación
// App\Services\Util\LoggerService — métodos: debug|info|warning|error
LoggerService::debug(LoggerOperation::CREATE, LoggerEvent::MODULE_ACTION, $data, $uri, $text, $json);
```

### Reglas de negocio condicionales: si Angular las exige, el `withValidator()` también debe exigirlas
Cuando un campo es obligatorio **solo si** el registro relacionado tiene cierto atributo (ej. "el auxiliar es obligatorio solo si la cuenta `trabaja_con_auxiliar_con_rut`"), esa condición **no puede vivir solo en el frontend**. Un POST/PUT directo a la API la evade por completo.

Caso descubierto: `formulario-cuenta.component.ts::applyValidators()` exige auxiliar, centro de costo, N° operación y N° despacho según atributos de la cuenta seleccionada — `CreaCuentaVoucherRequest`/`ActualizarCuentaVoucherRequest` no validaban ninguna de esas condiciones antes de este fix.
```php
// ✅ withValidator() resuelve la cuenta acotada al plan de la empresa y replica
// la misma condición que ya aplica Angular
$cuenta = Cuenta::where('id', $accountId)->where('account_plan_id', $planId)->first();
if (($cuenta->trabaja_con_auxiliar_con_rut || $cuenta->trabaja_con_auxiliar_sin_rut) && !$this->input('auxiliary_id')) {
    $validator->errors()->add('auxiliary_id', 'La cuenta seleccionada exige indicar un auxiliar.');
}
```

#### ⚠️ Gotcha: el selector de cuentas (`ListaCuenta`) expone alias, no los nombres de columna reales
`Cuenta::toVoucherNodeArray()` / `SubCuenta` (equivalente) — el método que arma el nodo para `AccountPlanService::getAccountsVoucher()`, consumido por Angular como `ListaCuenta` — renombra columnas al armar el array:
```php
// Cuenta.php / SubCuenta.php — claves del array del selector, NO son atributos Eloquent
$node['wk_operation_number'] = $this->trabaja_con_numero_operacion; // alias
$node['wk_dispatch']         = $this->trabaja_con_numero_despacho;  // alias
```
El frontend lee `account_ctrl?.wk_operation_number` / `wk_dispatch` porque consume ese array. **Si resuelves el modelo Eloquent directamente (ej. en `withValidator()`), usa los nombres de columna reales `trabaja_con_numero_operacion` / `trabaja_con_numero_despacho` — `wk_operation_number`/`wk_dispatch` no existen como atributos del modelo.** Leerlos ahí devuelve `null` (falsy) siempre: la validación compila, pasa code review, y no hace absolutamente nada en producción.

Además, `trabaja_con_centro_costo` **no es una columna** — es un atributo derivado por `App\Traits\DerivesCostCenterRequirement` (`getTrabajaConCentroCostoAttribute()`), calculado desde `AccountRequirementService::isResultAccountCode($cuenta->code)` (código que empieza en `4` o `5`) más `CompanyCostCenterPolicy::allowsFor($cuenta->account_plan_id)` (`Company::allow_cost_center`). Se lee igual que una columna gracias al magic getter de Eloquent (`$cuenta->trabaja_con_centro_costo` funciona sin cambios), pero **no se puede fijar con `Cuenta::create(['trabaja_con_centro_costo' => true])`** en fixtures o seeders — hay que fijar `code` en rango `4xx`/`5xx` y `Company.allow_cost_center = true`.

Antes de escribir una validación que lea un atributo de `Cuenta`/`SubCuenta` copiando el nombre que usa el frontend: verificar en el modelo si ese nombre es la columna real, un alias de serialización, o un accessor derivado.

---

## 💾 PERSISTENCIA Y ALMACENAMIENTO

### Inmutabilidad Histórica
Los módulos **Contabilidad, Nómina, Aduana y Facturación** son de **solo lectura**. Para corregir un registro: genera un **registro de reversa**. NUNCA modifiques el original.

**Dónde va la guardia cuando el Service es compartido con flujos automáticos:** si el método que mutaría el registro histórico (crear/editar/eliminar) es invocado también internamente por otro dominio para centralización automática, la guardia de inmutabilidad **va en el FormRequest (frontera HTTP), nunca dentro del Service**. Ponerla en el Service bloquea también a los llamadores internos legítimos.

Caso descubierto: `VoucherService::crearCuentaComprobante()` es el método que crea líneas de un comprobante manual (`CC`) vía API — pero también es invocado internamente por `TreasuryService`, `HonorariumSlipService` y `VoucherIntegrityService` para centralizar movimientos sobre comprobantes de origen `TS`/`BH`. La regla de "solo `CC` es editable manualmente" solo aplica a la entrada HTTP:
```php
// ❌ Guardia dentro del Service -> rompe Tesorería, Honorarios e Integridad,
// que llaman a este mismo método sobre comprobantes TS/BH legítimos
public function crearCuentaComprobante(array $data, int $company_id): VoucherAccountResource
{
    if ($voucher->voucher_type !== Voucher::ORIGEN_MANUAL) { throw ...; } // NO
    // ...
}

// ✅ Guardia en el withValidator() del FormRequest — solo protege la entrada HTTP
public function withValidator($validator)
{
    $validator->after(function ($validator) {
        $voucher = Voucher::where('id', $this->input('voucher_id'))
            ->where('year', $this->input('voucher_year'))
            ->where('company_id', $company_id)
            ->first();

        if (!$voucher) {
            $validator->errors()->add('voucher_id', 'Comprobante no existe.');
        } elseif ($voucher->voucher_type !== Voucher::ORIGEN_MANUAL) {
            $validator->errors()->add('voucher_id', 'Los asientos de un comprobante generado automáticamente no se pueden modificar manualmente. Corrija el documento de origen y vuelva a centralizar.');
        }
    });
}
```
Antes de escribir una guardia de inmutabilidad por origen: `grep` el método del Service en busca de llamadores internos. Si hay más de uno y no todos comparten el mismo origen permitido, la guardia no puede vivir en el Service.

### AWS S3 (Único Storage Permitido)
```php
// Almacenar — SOLO ruta relativa en BD
$path = $this->_s3FileService->upload($file); // → "companies/1/logo.png"
$model->file_path = $path;

// Responder al frontend — URL firmada temporal
$url = S3FileService::getSignedUrl($model->file_path);

// En PUT/PATCH — preservar si ya es URL
if (!str_starts_with($request->file_path, 'http')) {
    $model->file_path = $this->_s3FileService->upload($request->file('file'));
}
```
TIENES PROHIBIDO guardar archivos en el disco local del contenedor.

### Otras Reglas de Persistencia
- **`softDeletes()`**: Solo si hay trazabilidad legal requerida. No usar por defecto.
- **MailerSend**: Único proveedor para correos de alta prioridad.
- **Health Endpoint**: `/api/v1/health` — público, stateless, valida DB y Redis activamente.
- **Seeders**: Registrar todo nuevo Seeder en `DataSyncCommand.php` respetando el orden del array `$seeders` para integridad referencial en `migrate:fresh`.

---

## 🧾 SII / FACTURACIÓN ELECTRÓNICA — Patrones descubiertos (billing/emission NC/ND + trazabilidad)

### Columnas de referencia self-FK: una por dominio semántico, nunca reutilizadas
Si dos flujos distintos necesitan "apuntar a otro documento" con significados distintos (ej. RCV manual vs. emisión DTE propia), usa una **columna propia por flujo**, aunque ambas vivan en la misma tabla. Reutilizar una columna existente (`doc_reference_id`, que en `doc_sales` apunta a `core_documents` para el flujo manual RCV) para un significado nuevo (referenciar otra fila de `doc_sales` en una Nota de Crédito/Débito) crea un campo polimórfico ambiguo sin que el esquema lo refleje.
```php
// ❌ Reutilizar doc_reference_id (ya usado por el flujo RCV, apunta a core_documents)
// ✅ Columna nueva y propia, self-FK explícito
$table->foreignId('reference_venta_id')->nullable()->constrained('doc_sales', 'id')->nullOnDelete();
```

### Subqueries correlacionadas: alias SIEMPRE, incluso auto-referenciando la misma tabla
Una subquery que hace `whereColumn` contra la tabla externa, cuando ambas (externa e interna) tienen el mismo nombre sin alias, resuelve la columna contra el **scope más interno** (SQL estándar) — no contra la fila externa. El bug es silencioso: no lanza error, simplemente siempre devuelve 0.
```php
// ❌ Ambiguo: "doc_sales.id" dentro de la subquery se resuelve contra su propio FROM
->addSelect(['related_count' => Venta::selectRaw('count(*)')->whereColumn('chain_root_id', 'doc_sales.id')])

// ✅ Alias explícito en la subquery — sin ambigüedad
->addSelect(['related_count' => DB::table('doc_sales as related_docs')
    ->selectRaw('count(*)')
    ->whereColumn('related_docs.chain_root_id', 'doc_sales.id')
])
```

### Fechas expuestas por accessor en formato d/m/Y: NUNCA `Carbon::parse()` directo
Si un modelo sobreescribe un accessor de fecha para exponerla como string `d/m/Y` (ej. `Venta::getDateAttribute()`), cualquier consumidor que luego haga `Carbon::parse($model->date)` obtiene el resultado **silenciosamente invertido** cuando el día es ≤ 12: PHP/Carbon interpreta strings con `/` como `m/d/Y` (convención EE.UU.), no `d/m/Y`. Esto afectó fechas reales en el XML del DTE (`FchEmis`), no solo un campo nuevo.
```php
// ❌ Ambiguo si $date viene en formato d/m/Y (ej. accessor de Venta)
Carbon::parse($date)->format('Y-m-d');

// ✅ Parseo explícito del formato conocido antes de caer al parseo genérico
if (is_string($date) && preg_match('#^\d{1,2}/\d{1,2}/\d{4}$#', $date)) {
    Carbon::createFromFormat('d/m/Y', $date)->format('Y-m-d');
}
```

### Trazabilidad de cadena documental (`chain_root_id`)
Para reconstruir una cadena de documentos que se corrigen entre sí (ej. Factura → Nota de Débito → Nota de Crédito) sin queries recursivas: cada documento nuevo hereda `chain_root_id = referenciado.chain_root_id ?? referenciado.id` — **siempre la raíz real**, nunca el padre inmediato. Así, la cadena completa de cualquier documento se obtiene con `WHERE id = :root OR chain_root_id = :root`, una sola query indexada.

### Bloque `<Referencia>` del DTE es obligatorio para NC/ND — defensa en profundidad
La Nota de Crédito es el único documento legal para anular/disminuir una factura ya emitida (Nota de Débito para aumentarla) — nunca confíes solo en la validación del `FormRequest` para esta regla de cumplimiento tributario. El builder del XML (`DteBuilderService`) debe lanzar su propia excepción si un tributary_code 56/61 llega sin `reference_venta_id`, incluso si en teoría la capa de entrada ya lo bloqueó.

### Habilitación de emisión (`sii_dte_enabled`): auto-derivado, nunca manual — el gate real de negocio es el salto de ambiente
`core_companies.sii_dte_enabled` **no se setea a mano** — `SiiEnablementService::syncDteEnabledFlag()` lo recalcula (certificado activo vigente Y ≥1 CAF activo con folios disponibles) cada vez que cambia el certificado o el CAF de la empresa (enganchado al final de `CertificateService::store()`/`deactivate()` y `CafService::store()`). Este flag gatea la emisión (`EmitDteRequest`/`EmitBoletaDteRequest`) **en cualquier ambiente**, sin fricción para las pruebas en certificación.

El salto real con riesgo de negocio — `sii_environment`: certificación → producción — es la única acción que pasa por una tabla de solicitudes auditable (`sii_enablement_requests`, único pending por empresa vía unique index parcial de Postgres). `config('sii.require_production_approval')` (env `SII_REQUIRE_PRODUCTION_APPROVAL`, default `true`) decide si esa solicitud requiere aprobación humana de Soporte (`SiiAdminController::approveEnablement/rejectEnablement`, cola cross-tenant en `v1/support/sii/enablement-requests`) o se auto-aprueba en el mismo request — útil para bypasear el paso manual en contenedores de QA/staging sin tocar `deploy/`.
```php
// ❌ Gatear la emisión por el ambiente (bloquearía las pruebas en certificación)
if ($company->sii_environment === 'certificacion') { /* permitir sin más */ }

// ✅ El gate es sii_dte_enabled, independiente del ambiente
if (!$company->sii_dte_enabled) {
    $validator->errors()->add('sii_dte_enabled', 'La emisión electrónica no está habilitada...');
}
```

### `core_documents.can_emit_dte` (catálogo global) vs `sii_dte_enabled` (por empresa) — no confundir, y el seeder debe correr en cada ambiente
`can_emit_dte` (migración `2026_07_01_100900_add_dte_classification_to_core_documents`, default `false`) es un flag del **catálogo de tipos de documento** (`core_documents`, tabla global sin `company_id`), no de la empresa — indica si QdoorA emite ese tributary_code electrónicamente (vs. solo registrarlo). Lo puebla `CoreDocumentsDteSeeder` (11 códigos: 33/34/56/61/52/110/111/112/46/39/41), que **solo corre dentro de `php artisan data:sync`** (no está en `DatabaseSeeder`). Si un ambiente migró (`php artisan migrate`) pero nunca corrió `data:sync`/`db:seed --class=CoreDocumentsDteSeeder` después del `2026-07-01`, la columna queda en `false` para todas las filas: el selector de tipo de `/billing/emission` (filtro cliente `documents.filter(d => d.can_emit_dte)`) recibe una lista vacía **sin ningún error HTTP** — síntoma: pantalla en blanco bajo el header, no un 500. Diagnóstico rápido: `SELECT tributary_code, can_emit_dte FROM core_documents WHERE tributary_code IN ('33','39','52','61')` — si todas son `false`, falta correr el seeder. Esto es independiente de `sii_dte_enabled` (arriba): una empresa sin certificado/CAF igual debe VER los tipos de documento en el selector (solo falla al emitir).

### Integración con web services del SII — patrones descubiertos (benchmark vs libredte-lib-core, jul-2026)

- **Cliente SOAP centralizado (`SiiSoapClientService`)**: toda construcción de `\SoapClient` para el SII pasa por `SiiSoapClientService::client()` (antes estaba duplicada en `SiiAuthService` y `DteStatusService`). El mismo servicio expone `assertEstadoOk($xml, $context)`, que valida el header `ESTADO === '00'` de las respuestas del SII y lanza `GenericException` con la `GLOSA` real. **Regla**: nunca extraigas el dato de una respuesta del SII (SEMILLA/TOKEN/etc.) sin validar antes el `ESTADO` del header — un `ESTADO` de error con dato residual da diagnósticos engañosos.
- **Canonicalización XML-DSig unificada**: toda firma enveloped ante el SII usa `SiiSoapClientService::SIGNATURE_CANONICAL_METHOD` (`EXC_C14N`). Antes `SiiAuthService` usaba `EXC_C14N` y `DteSenderService` `C14N` sin justificación. **Pendiente de re-verificar con un envío real en certificación** — es el candidato #1 a "firma inválida (STATUS=8)" si el SII rechaza.
- **Códigos STATUS del envío DTE (`DteSenderService::STATUS_MESSAGES`)**: la recepción del sobre (`RECEPCIONDTE/STATUS`) NO es binaria. Mapea 1,2,3,5,6,7,8,9,99 a glosas concretas. Dos casos críticos por el reintento propio de QdoorA: **STATUS=5** (token expirado) → `forgetToken()` + reintento con token nuevo; **STATUS=99** ("ya recibido") → si trae `TRACKID` se recupera como éxito, NO se marca rechazado (un timeout de red en un reintento puede provocarlo aunque el SII sí tenga el documento).
- **Estado por sobre vs. por documento**: `DteStatusService::checkStatus()` (QueryEstUp) devuelve el estado del **sobre**; `checkDocumentStatus()` (QueryEstDte) el del **documento individual** y persiste en `DteEnvioItem.individual_status`. Ojo: esa columna es un ENUM de solo 3 valores en BD (`PENDING/ACCEPTED/REJECTED`), así que `mapEstadoDocumento()` no puede persistir `PROCESSING`/`SENT`/etc.
- **RCV — dos servicios distintos, no confundir**: `RcvService` = extracción/reconciliación masiva por período (endpoint interno de portal `www4.sii.cl/consdcvinternetui`, NO API formal — frágil). `RcvActionService` = acciones puntuales por documento contra el web service SOAP **oficial** `registroreclamodteservice` (hosts propios `ws1.sii.cl`/`ws2.sii.cl`, distintos de maullin/palena, vía `SiiEnvironment::rcvActionWsdlUrl()`): `ingresarAceptacionReclamoDoc` (ERM/ACD/RCD/RFP/RFT), `listarEventosHistDoc`, `consultarDocDteCedible`, `consultarFechaRecepcionSii`. Los nombres de función/args están copiados 1:1 de libredte (fuente de verdad funcional). Cada acción de aceptación/reclamo se traza en `sii_rcv_actions` (SENT/FAILED, nunca propaga excepción hacia arriba). No existe WSDL local para este servicio → en tests, mockear el método protegido `callRegistroReclamoDte()`.

### Cobertura completa de Factura Afecta (33) — patrones descubiertos (jul-2026)

- **`ElectronicDocumentService::computeLines()`/`buildHeader()` es el punto real de persistencia, no el `FormRequest`**: agregar una columna + una regla de validación NUNCA basta. Si el campo nuevo no se agrega también al array que arma `computeLines()` (para ítems) o `buildHeader()` (para cabecera), el dato llega validado hasta el Service y se descarta silenciosamente antes de tocar `Venta::create()`/`VentaItem::create()`. Mismo patrón aplica a `ThirdCompanyService::crearEntidad()`/`actualizaEntidad()`/`crearORecuperarPorRut()`: el Controller (`ThirdController`) usa `$request->all()`, no `validated()`, así que el cuello de botella real está en los arrays armados a mano dentro del Service, no en el `FormRequest`.
- **Tabla nueva `doc_sale_document_references` (1:N) vs. columnas `reference_venta_id`/`reference_cod_ref`/`reference_razon` (1:1)**: son mecanismos conceptualmente distintos y nunca se mezclan. Las columnas 1:1 son para NC/ND (una Factura corregida por una Nota). La tabla nueva es para Factura→Guía(s) de Despacho (una Factura puede referenciar 0, 1 o varias guías). El bloque `<Referencia>` que arma cada mecanismo también difiere: `buildReferencia()` (NC/ND) SIEMPRE lleva `<CodRef>`; `buildReferenciaGuias()` (Factura→Guía) NUNCA lo lleva (confirmado contra los fixtures YAML `033_002/015/016` de libredte-lib-core) — en el modo agregado (>10 guías) usa `<IndGlobal>1</IndGlobal>` + `<FolioRef>0</FolioRef>` + `<RazonRef>`.
- **`sii_boleta_details`/`boletaDetail` se extiende a Factura (33/34) sin migrar tabla**: el campo `IndServicio` no es boleta-exclusivo en el Formato DTE v2.5 (confirmado en `033_009_servicios_periodicos_domiciliarios.yaml`, un caso de Factura). Se reutilizó la tabla existente vía un nuevo gate `DteBuilderService::isFactura()` sumado con `||` al de `isBoleta()` en `buildBoletaIdDoc()` — **nunca modificar `isBoleta()` en sí**, porque `buildReceptor()`/`buildTotales()` tienen ramas boleta-específicas (RUT genérico consumidor final, total exento sin desglose) que no deben aplicar a Factura.
- **`core_taxes` no tenía forma de mapear un impuesto específico al `CodImpAdic`/Anexo 51.5 del SII**: `tributary_code` es del catálogo RCV (espacio de códigos distinto — verificado que `17` en la seed es "IVA anticipado faenamiento carne", no coincide con el Anexo 51.5). Se agregó `core_taxes.sii_cod_imp_adic` (nullable) como la columna real que alimenta tanto `<CdgItem>`/`<CodImpAdic>` en el ítem como `<TipoImp>` de `<ImptoReten>` en Totales — sin poblar esa columna en el impuesto específico, el desglose de Totales queda vacío aunque el ítem tenga `specific_tax_id`.
- **`doc_sale_items.quantity` es `integer` en el schema actual, no soporta cantidades fraccionarias**: el caso real `033_003_iva_anticipado.yaml` usa `QtyItem: 2.5` (harina en toneladas), formato DTE-válido (`Cantidad` es NUM 8.6 con decimales). Esta es una limitación preexistente **fuera del alcance** de la migración de Factura 33 completa — cualquier emisión real con cantidad fraccionaria fallará con `SQLSTATE[22P02]` hasta que se migre esa columna a `decimal`.
- **`GiroRecep`/`DirRecep`/`CmnaRecep`/`CorreoRecep`/`Contacto` viven en la rama por defecto (no-export/no-boleta) de `buildReceptor()`**, compartida por 33/34/52/56/61 — agregar esos campos ahí beneficia a los 5 tipos, no es scope-creep. Pero el **bloqueo de "cliente sin giro" en `EmitDteRequest::withValidator()` se limita explícitamente a `['33','34','56','61']`** (la Guía 52 queda fuera, decisión de producto explícita).

### Aritmética Sii (Venta) — Separación de Responsabilidades
- **`ElectronicDocumentService` es el DUEÑO de los recálculos financieros base**. Toda aritmética que modifique los totales persistidos de una venta (`MntNeto`, `MntExe`, `IVA`, prorrateo por descuentos/recargos globales) debe hacerse aquí antes de llamar a `Venta::create()`.
- **`DteBuilderService` es el DUEÑO de la generación del XML**. No recalcula montos (salvo redondeos al entero más cercano como exige el esquema DTE). Solo mapea lo que `ElectronicDocumentService` persistió hacia los tags XML obligatorios del SII (ej. emitiendo `<IndExe>1</IndExe>`, inyectando `<CodImpAdic>`, etc.). Nunca debe haber discrepancia aritmética entre lo que persiste la BD y lo que viaja en el DTE.

### RCV — Centralización desacoplada de documentos (Fase 1: creación sin items, jul-2026)

> Proceso completo en `qdoora-references/manuales/sii/RCV/proceso.md` (7 puntos). Roadmap acordado con el usuario: **Fase 1 (creación) → Fase 2 (cuentas operativas compra/venta) → Fase 3 (config `total_neto` en auxiliar) → Fase 4 (centralización automática) → Fase 5 (UI de estado + centralización manual)**. Este bloque documenta solo la Fase 1, ya implementada.

- **`RcvService::reconcile()` ya NO delega en `ElectronicDocumentService`** para crear los documentos de un RCV. Ese servicio sigue siendo el dueño exclusivo de la **emisión** de DTE (con ítems reales); para RCV, `reconcile()` ahora llama a `SaleService::creaOActualizaDocumento()` / `PurchaseService::creaOActualizaDocumento()` — métodos nuevos que crean `Venta`/`Compra` **sin ítems**, con los montos ya agregados que trae el `RcvRecord` de staging (`total_neto`, `total_iva`, `total_otros_impuestos`, `total`). `VentaItem`/`CompraItem` se deprecan **solo para el camino RCV** (el flujo manual de compra/venta los sigue usando sin cambios).
- **El documento se crea SIEMPRE tras una extracción RCV exitosa**, con `accounting_status = PENDING`, `sii_status = RECEIVED`, `voucher_id`/`voucher_year = null`. Antes, si `total_otros_impuestos > 0` se lanzaba una excepción que abortaba la creación completa del documento (0 documentos creados por errores de impuestos específicos); ahora el documento se crea igual y el impuesto específico queda pendiente de mapeo manual (`other_tax_id = null`, monto guardado en `total_other_tax`).
- **Idempotencia + inmutabilidad**: `creaOActualizaDocumento()` usa `verifyUniquenessOfSale()`/`verifyUniquenessOfPurchase()`. Si el documento ya existe y **ya fue centralizado** (`voucher_id` seteado o `accounting_status === JOURNALIZED`), el método lo retorna intacto y NO lo actualiza — nunca se pisa un registro contable ya contabilizado (HARD REJECT #6).
- **`centralizarDocumentoRcv()` ya está implementado** (Fase 4 — ver bloque más abajo). `syncAccountingEntries()` (el método existente de centralización manual) NO sirve para este camino porque itera `$sale->items`/`$purchase->items`; los documentos RCV no tienen ítems — por eso la Fase 4 usa un motor propio (`RcvCentralizationService`) que arma el asiento desde los montos agregados.
- **Terceros: usar `ThirdCompanyService::crearORecuperarPorRut()` directo (upsert), nunca `getEntidadByRut()` seguido de creación condicional.** Ese patrón anterior tenía un bug real: `getEntidadByRut($rut, $doc_id=null, ...)` resuelve internamente el tipo de identificación ("RUT", code '03') pero filtra la query por el parámetro `$doc_id` original (literal `null`), no por el id resuelto — nunca hace match y siempre lanza excepción, por lo que la rama `crearORecuperarPorRut()` de fallback jamás se alcanzaba. `crearORecuperarPorRut()` no tiene ese bug (usa el `identification_document_id` que se le pase). El RUT se normaliza sin guion antes de llamar (`str_replace('-', '', ...)`) porque QdoorA persiste el RUT concatenado.
- **`period` de la Venta/Compra creada desde RCV usa `RcvSession::period`** (formato `"MM/YYYY"`, el mismo validado por `RcvExtractRequest` y usado en filtros como `SaleService::getCompanySales()`), **NO** `RcvRecord::sii_period` — ese campo es el `detPcarga` interno del SII, formato `YYYYMM` (ej. `202606`), un campo totalmente distinto que solo sirve para trazabilidad del staging. Confundir ambos rompe cualquier filtro por período en la lista de documentos.
- **Nuevo Enum `App\Enums\Sii\RcvEventCode`** (`A`=acuse automático, `C`=acuse explícito, `P`=pagado al contado, `G`=acuse en guía de despacho), cast en `RcvRecord::sii_event_code`.
- **`doc_purchases.total_exento` es columna nueva** (migración `add_total_exento_to_doc_purchases`, decimal 12,2 default 0). `doc_sales.total_exento` ya existía. No confundir: antes de esta fase, compras extraídas por RCV no tenían dónde guardar el monto exento.
- **Gotcha de fechas en compra RCV — `acknowledgment_date`/`reception_date` son `NOT NULL` en `doc_purchases`, pero su fuente puede venir `null`**: `RcvRecord::sii_receipt_date` (`detFecAcuse`) queda `null` cuando el acuse es automático (código `A`, sin evento explícito del receptor aún) — confirmado en el JSON real de ejemplo. Mapeo correcto: `acknowledgment_date = sii_receipt_date ?? received_at ?? emitted_at` y `reception_date = received_at ?? emitted_at` (encadenado porque `received_at` también es nullable en el schema, aunque en la práctica siempre viene poblado por `detFecRecepcion`). **Nunca asignar `sii_receipt_date` directo sin este fallback** — revienta el insert con `SQLSTATE[23502]`.

### RCV — Fase 2: operativa compra/venta en el plan de cuentas (jul-2026)

- **Columna `rcv_operation`** (enum `App\Enums\AccountRcvOperation`: `purchase`|`sale`, nullable) en `cont_accounts` y `cont_sub_accounts`. Marca si la **cuenta mayor** opera en compra o venta (nunca ambas → un solo enum, no dos booleanos). `null` = no participa en RCV compra/venta. Persistido como `string(10)` + cast a enum (mismo patrón que `sii_event_code`), NO enum nativo de Postgres.
- **`rcv_operation` es leaf-only, igual que `account_category_id` (cuenta maestra)**: solo la cuenta mayor (último nodo) la tiene. En `CuentaService::actualizaCuenta` va dentro del bloque `if (!$tieneHijos)` (junto a `account_category_id`/`ifrs_code`), NUNCA en el bloque de "operatividad heredable" (`trabaja_con_*`). `getDetalleCuenta()` la devuelve `null` cuando la cuenta tiene hijos. `ActualizaCuentaRequest::withValidator()` rechaza `rcv_operation` si la cuenta posee subcuentas.
- **Herencia al CREAR subcuenta, no en cada update**: `SubCuentaService::crearSubCuenta()` hereda `rcv_operation` del padre **solo si la clave NO viene en el request** (`array_key_exists`, no `??`). Esto es clave: el front pre-llena el valor heredado, y si el usuario elige "Ninguna" manda `null` **explícito** que debe respetarse — con `??` el `null` re-heredaría por error. Regla general: para campos donde `null` es una opción válida del usuario y además hay herencia, distinguir "ausente" de "null explícito" con `array_key_exists`.
- **Frontend (`fuse-starter`)**: nueva `app-config-card` "Operativa Compra / Venta" con `mat-radio-group` (Ninguna/Compra/Venta) en `formulario-cuenta` (gated `@if(tieneHijos)` = solo hoja) y `formulario-subcuenta` (siempre, la subcuenta es cuenta mayor). El modelo TS `Cuenta`/`SubCuenta` lleva `rcv_operation?: 'purchase'|'sale'|null`. Ojo: el getter `tieneHijos` del componente está **invertido** (`return !this.cuenta_tiene_hijos`) — significa "NO tiene hijos".
- **Aún no se consume**: la Fase 2 solo captura la operativa. El servicio para **listar** cuentas por operativa (que pide el Punto 2 del proceso) se agrega en Fase 3, cuando el auxiliar lo necesite.

### RCV — Fase 3a (backend): cuentas afecto/exento por auxiliar (jul-2026)

> **Revisión (jul-2026)**: la config pasó de UNA cuenta de `total_neto` a DOS cuentas por naturaleza — **valor afecto** (`total_neto`) y **valor exento** (`total_exento`) — vía el discriminador `value_type` (enum `App\Enums\RcvValueType`: `affected`|`exempt`). Migración alter `add_value_type_to_cont_rcv_net_accounts` (agrega la columna default `'affected'` y rehace el unique). El nombre de tabla/modelo se mantiene (`cont_rcv_net_accounts` / `RcvNetAccount`).

- **Tabla `cont_rcv_net_accounts`** (modelo `App\Models\Empresa\RcvNetAccount`): config **por auxiliar, naturaleza y tipo de valor** de la cuenta mayor que recibe el afecto/exento al centralizar. Columnas: `company_id`, `third_company_id` (auxiliar), `operation` (`purchase`|`sale`, cast `AccountRcvOperation`), `value_type` (`affected`|`exempt`, cast `RcvValueType`), `account_id`+`sub_account_id` (clave compuesta), `auxiliary_id` y `cost_center_id` (nullable). `unique(company_id, third_company_id, operation, value_type)` → un auxiliar cliente+proveedor tiene hasta **4 configs** (venta-afecto, venta-exento, compra-afecto, compra-exento). El rol se deriva de sus `AuxiliaryAccount` (categorías CLIENTE_NACIONAL/PROVEEDOR_NACIONAL); `es_cliente`/`es_proveedor` fueron eliminados de `core_third_companies`.
- **`RcvNetAccountService`** es el dueño: `getConfig` (todas las filas del auxiliar), `getConfigForOperation(company, third, operation, valueType)` (una fila, la consume la Fase 4), `guardarConfig` (updateOrCreate por auxiliar+operation+**value_type**; el `value_type` ausente se asume `affected` con `?? RcvValueType::AFFECTED->value` **resolviendo el raw ANTES del `instanceof`** — acceder a `$data['value_type']` inexistente revienta como `ErrorException` en test), `eliminarConfig(company, third, operation, valueType)`, `checkPrerequisites`, `wipeConfigsForAccount`. Valida que (1) la cuenta esté marcada `rcv_operation` de la misma naturaleza, (2) las cuentas maestras requeridas estén asignadas, (3) auxiliar/centro de costo obligatorios **según los flags de la cuenta** (`trabaja_con_auxiliar*`/`trabaja_con_centro_costo`), NO según el auxiliar dueño.
- **Prerrequisitos por naturaleza** (`REQUIRED_MASTERS`): venta necesita cuentas maestras `CLIENTE_NACIONAL` + `IVA_DEBITO_FISCAL` asignadas; compra `PROVEEDOR_NACIONAL` + `IVA_CREDITO_FISCAL`. Se verifican con `AccountPlanService::checkCategoryAssociationByCode()` (`obtenerAsociacionPorPlan` → `['tipo' => null]` si no está asignada). **`IVA_DEBITO_FISCAL`/`IVA_CREDITO_FISCAL` se agregaron a `App\Constants\AccountCategories`** (ya existían como categorías sembradas en BD desde `create_account_plan`); `PROVEEDOR` fue renombrado a `PROVEEDOR_NACIONAL` en la migración `2024_11_08`.
- **Selector de cuentas operativas**: `AccountPlanService::getAccountsByRcvOperation(company_id, operation)` devuelve el **mismo shape que `getAccountsVoucher`** (`account_id` = id del nodo, `type` = cuenta|subcuenta, + flags `wk_auxiliary_rut`/`wk_auxiliary_concept`/`wk_cost_center`). El servicio de guardado traduce (nodo_id, type) → clave compuesta (account_id, sub_account_id) en `resolveNode()`.
- **Restricción del Punto 2 (link con Fase 2)**: al cambiar `rcv_operation` de una cuenta/subcuenta, `CuentaService`/`SubCuentaService::actualiza` detectan el cambio (`old?->value !== nuevo`) y llaman `RcvNetAccountService::wipeConfigsForAccount()` para borrar las configs de auxiliares que referenciaban ese nodo.
- **Endpoints**: `GET api/v1/account/plan/company/{company_id}/accounts/rcv-operation/{operation}` (cuentas operativas), y sobre el auxiliar `GET|POST api/v1/company/{company_id}/entity/{third_company_id}/rcv-net-account` + `DELETE .../{operation}/{value_type}`. El POST body ahora exige `value_type` (`affected`|`exempt`). Auth company-level (`CompanyAccessRequest` / `SaveRcvNetAccountRequest` con `userHasCompanyPermission`).
- **Fase 3b (frontend) — hecho**: diálogo `dialog/rcv-net-account-config` (patrón `qdoora-dialog-creator`, ancho `.dialog-panel`), abierto con un botón "Configurar" en el formulario de entidad (visible solo si `hasContabilidad && hasAccountPlan && entidad.id && (is_client||is_provider)` → getter `canConfigureRcvNet`). Una config-card por naturaleza aplicable (venta si cliente, compra si proveedor) con estado de prerrequisitos y **dos bloques de cuenta por naturaleza: Valor afecto y Valor exento** (`SlotState[]`), cada uno con su selector (`getAccountsByRcvOperation`) + centro de costo cuando la cuenta lo exige (`CostCenterService.getCostCenters(0, 9999)`) + guardado propio (payload con `value_type`). **Decisión de diseño**: cuando la cuenta exige auxiliar (`wk_auxiliary`), se usa automáticamente el mismo auxiliar configurado (`third_company_id`), sin selector aparte — el hint del proceso apuntaba a `getAccountsAuxiliaryFilter`, pero ese método devuelve CUENTAS (no auxiliares/`ThirdCompany`), así que no aplica. Métodos frontend: `getAccountsByRcvOperation`, `getRcvNetConfig`, `saveRcvNetConfig`, `deleteRcvNetConfig(..., value_type)`.

### RCV — Fase 4 (backend): centralización automática de documentos (jul-2026)

- **`RcvCentralizationService` es el motor compartido** (`App\Services\Contabilidad`). `SaleService::centralizarDocumentoRcv(Venta, User)` y `PurchaseService::centralizarDocumentoRcv(Compra, User)` (antes stubs) construyen una **spec** con la naturaleza (montos, master codes, `base_side`/`third_side`, `tax_module`, etc.) y delegan la resolución + armado del comprobante. **Ownership (HARD REJECT #4)**: el motor NO muta la `Venta`/`Compra` — solo arma el `Voucher` + `VoucherAccount` (como `VoucherIntegrityService`) y devuelve la llave; el servicio dueño hace el `update()` del documento (`voucher_id`, `voucher_year`, `accounting_status = JOURNALIZED`) dentro de su propia `DB::transaction`.
- **Resolución de cuentas por monto** (`resolverCuentas(spec)` → `['lines' => [...], 'missing' => [...]]`, conceptos `afecto`/`exento`/`iva`/`otros`/`tercero`):
  - **afecto** (`total_neto`) → `RcvNetAccountService::getConfigForOperation(..., 'affected')` (config Fase 3). Honra `auxiliary_id` + `cost_center_id` de la config (por eso NO se reusa `persistAccountingEntries`, que fuerza un auxiliar único y `cost_center = null`).
  - **exento** (`total_exento`) → `getConfigForOperation(..., 'exempt')`, **cuenta propia**. Solo se agrega la línea si `total_exento > 0`; si falta la config, entra en `missing`.
  - **IVA** → `CompanyService::getAccountFromImpuesto(company, vat_id, 'venta'|'compra')` (cont_tax_accounts); si el impuesto no está configurado (lanza `GenericException`, se captura) cae al **fallback maestra** `IVA_DEBITO_FISCAL` (venta) / `IVA_CREDITO_FISCAL` (compra) vía `checkCategoryAssociationByCode`. Las dos fuentes que el usuario pidió. La línea `iva` se imputa siempre al **auxiliar del documento** (`spec['third_id']`, ver `buildLine` en `RcvCentralizationService::resolverCuentas()`).
  - **otros impuestos** → cont_tax_accounts por `other_tax_id`; como el RCV llega con `other_tax_id = null`, casi siempre cae en `missing` (flujo manual, proceso Punto 7). A diferencia del IVA, esta línea **no** lleva el auxiliar del documento: para el resto de los impuestos manda la configuración de la propia cuenta (auxiliar/centro de costo), igual que en la configuración manual.
- **Excepción de IVA GENERAL — su auxiliar lo aporta la centralización, no la configuración (ago-2026)**: solo para `Impuesto::TRIBUTARY_CODE_IVA_GENERAL` ('14'), la cuenta de impuesto (`ImpuestoEmpresa::esIvaGeneral()`) se configura **sin auxiliar** aunque la cuenta maestra lo exija (`trabaja_con_auxiliar_con_rut`, forzado por `AccountPlanService::assignMasterAccount()`). El resto de los impuestos sigue exigiendo auxiliar/centro de costo según los flags de su propia cuenta — **no** es una regla del propósito `AccountingImputationPurpose::TAX_PURCHASE`/`TAX_SALE` (eso afectaría a todos los impuestos por igual), sino una excepción **por dueño**: `AccountingImputationService::providedAtRuntime(?Model $owner, $purpose)` amplía `$purpose->provides()` con `'auxiliary'` solo cuando `$owner instanceof ImpuestoEmpresa && $owner->esIvaGeneral()`. Se usa en `save()` (al guardar) y en `recalculateOne()` (al recalcular por cambios de flags de la cuenta — requiere `imputable` eager-loaded, ver `syncAfterAccountFlagsChanged`/`syncAfterCompanyCostCenterToggled`). El centro de costo **no** se exime: ya es derivado (empresa con centro de costo + cuenta de resultado) y las maestras de IVA son cuentas de balance (tipo 1/2), así que nunca lo piden. Frontend: `TaxAccountConfigDialogComponent` (rama `isIvaGeneral`) dejó de pedir auxiliar/centro de costo; la rama de otros impuestos no cambió. Migración `2026_08_01_120000_clear_iva_general_imputation_auxiliaries` limpia `auxiliary_id` y `needs_review` de imputaciones de IVA GENERAL preexistentes.
  - **total** → maestra `CLIENTE_NACIONAL`/`PROVEEDOR_NACIONAL`; es la línea de cobro/pago (`max_amount_application = total`, para tesorería).
- **Sentidos del asiento**: venta = **afecto + exento + IVA + otros** al **haber**, total al **debe**; compra al revés (afecto/exento/IVA/otros al **debe**, total al **haber**). Afecto y exento van a cuentas separadas (cada una con su config), así el comprobante **cuadra** (`debit == credit`).
- **Si falta ≥1 cuenta → `GenericException` con el detalle y NO se crea voucher**: el documento queda `PENDING` (No centralizada) para completarse y centralizarse manualmente (Fase 5). `resolverCuentasCentralizacion(doc)` expone el desglose (resueltas + faltantes) sin crear nada — lo consumirá el modal de la Fase 5.
- **Auto-centralización + usuario sistema**: `reconcile(RcvSession, ?User $user = null)` intenta `centralizarDocumentoRcv()` de cada documento recién creado (dentro de un `try/catch (GenericException)` que se traga config incompleta → queda PENDING). **Con usuario** (reconciliación manual, `RcvController::reconcile` pasa el `$user`) el comprobante queda a su nombre; **sin usuario** (`ExtractRcvJob`/scheduler → `reconcile($session)`) se contabiliza como **sistema**. Para eso `VoucherService::crearCabeceraComprobante(array, ?User $user, ...)` es nullable y hace `created_by_user_id = $user?->id ?? 0` — la columna `cont_vouchers.created_by_user_id` es `BIGINT NOT NULL` **sin FK** (ver `create_voucher_partition`), así que `0` es un centinela válido de "sistema". `centralizarDocumentoRcv(doc, ?User $user = null)` acepta null y lo propaga. Así el job agendado hace el proceso completo: **extracción → creación/edición → centralización**.
- **Reusa el camino de voucher probado**: `VoucherService::crearCabeceraComprobante` (crea partición `voucher_YYYY` si falta) + `crearCuentaComprobante` por línea; el `VoucherAccountObserver` recalcula cuadratura/estado. `Venta::date`/`Compra::date` tienen accessor que ya devuelve `d/m/Y` (formato que espera `crearCabeceraComprobante`). Voucher: `type = TRASPASO`, `voucher_type = LIBRO_VENTA`/`LIBRO_COMPRA`, `norma = AMBOS`, `currency = CLP`.
- **Tests**: `tests/Feature/Contabilidad/RcvCentralizationTest.php` (12) — resolución afecto/IVA/tercero (incluye auxiliar en la línea IVA), exento en cuenta propia, exento faltante, faltantes (afecto sin config / IVA+tercero sin maestras), E2E que crea el comprobante cuadrado (119000 debe = 119000 haber) y marca JOURNALIZED, centralización **sin usuario** (voucher `created_by_user_id = 0`), guardas de inmutabilidad, y la excepción de auxiliar de IVA GENERAL (se configura sin auxiliar / otro impuesto lo sigue exigiendo / el recálculo no lo vuelve a marcar `needs_review`). Falta la **Fase 5** (filtro de estado No centralizada/Centralizado + modal de centralización manual con desglose de cuentas).

### Plan de Cuentas — Nuevos campos de operatividad (jul-2026)

- **`trabaja_con_auxiliar_sin_rut`** (boolean): renombrado desde `trabaja_con_auxiliar`. Auxiliar identificado "como concepto" (sin RUT). Aplica a `cont_accounts`/`cont_sub_accounts`.
- **`trabaja_con_otros_impuestos`** (boolean): marca cuentas asociables a la centralización de documentos con Otros Impuestos (RCV/SII). Patrón idéntico a `trabaja_con_centro_costo` (herencia padre→hijo dentro de "Configuracion Operativa").

---

## 🐳 DEVOPS — Docker Compose

### Reglas Obligatorias
```yaml
services:
  db:
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  redis:
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s

  api:
    depends_on:
      db:
        condition: service_healthy      # OBLIGATORIO — nunca solo 'depends_on: db'
      redis:
        condition: service_healthy
    healthcheck:
      start_period: 30s                # Mínimo 30s para que Laravel inicialice
    volumes:
      - "../../qdoora-api:/var/www/html"
      - "./.env:/var/www/html/.env"    # OBLIGATORIO — evita Exit Code 130
```

### AWS (Producción)
- Arquitectura objetivo: **ECS Fargate** (stateless — ya preparado por diseño).
- Storage: EXCLUSIVAMENTE S3. PROHIBIDO almacenamiento local en contenedores.
- Queues: **AWS SQS** para jobs asíncronos (cálculos de nómina, exports pesados).

---

## 🔒 SEGURIDAD — Vectores QD

| Vector | Riesgo | Mitigación obligatoria |
|--------|--------|------------------------|
| **QD-01** | Bypass de autorización en el cliente | Guards server-side + validación en `authorize()` de FormRequest |
| **QD-04** | IDOR de tenant — el `company_id`/`suscriptor_id` llega del payload de creación y permite suplantar el tenant de otro cliente, o el scope de listado/Policy no coincide entre sí (lo que uno expone, el otro debería negar) | El FK de tenant se deriva SIEMPRE server-side; scope Eloquent y Policy deben aplicar exactamente el mismo criterio de aislamiento |
| **QD-05** | IDs secuenciales predecibles | UUIDs en todos los recursos expuestos públicamente |
| **QD-07** | XSS via `[innerHTML]` en frontend | Solo interpolación `{{ }}` — aplicar desde backend con datos saneados |
| **QD-08** | Sin rate limiting | Middleware throttle en TODOS los endpoints |

Para el mapa completo QD-01 a QD-11 y tests de confirmación con curl:
→ Activar skill `ethical-hacking-auditor` · leer `skills/ethical-hacking-auditor/references/qdoora-vectors.md`.

---

## 🛑 HARD REJECT — Backend

Autoridad suprema para rechazar código que:
1. Incluya lógica de negocio o Eloquent directo dentro de un Controlador
2. Consulte registros omitiendo el filtro de `company_id`
3. Use `findOrFail()` en lugar de `find()` + excepción controlada
4. Mute modelos de otro dominio sin pasar por su Servicio
5. Guarde archivos en disco local en lugar de AWS S3 via `S3FileService`
6. Modifique registros históricos inmutables (Contabilidad/Nómina/Aduana/Facturación)
7. Ejecute pruebas unitarias (`php artisan test` o `./vendor/bin/pest`) SIN EXPLÍCITA CONFIRMACIÓN DEL USUARIO, ya que puede borrar la base de datos de desarrollo si no existe el entorno aislado (`.env.testing` o base de datos de pruebas configurada).

---

> **Skills de referencia** (plantillas exactas de código por capa):
> `laravel-controllers` · `laravel-form-requests` · `laravel-services` · `laravel-models-enums`
> `laravel-database` · `laravel-api-resources` · `laravel-jobs-events`
> `laravel-routes-middleware` · `laravel-commands-seeders` · `erp-data-modeler`
> `security-iam-expert` · `ethical-hacking-auditor` · `cloud-devops-engineer` · `docker-compose-expert`

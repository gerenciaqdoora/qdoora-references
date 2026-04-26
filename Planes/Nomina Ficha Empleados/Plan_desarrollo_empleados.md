# Plan de Desarrollo: Módulo de Empleados (RRHH)

> **Fecha:** 2026-03-31  
> **Contexto:** Módulo de ficha de empleado con lista, creación y edición. Punto de partida para la liquidación de sueldos.  
> **Base:** ThirdCompany ya existe como entidad auxiliar unificada (cliente / proveedor / empleado). El empleado se distingue por tener una cuenta con categoría `REMUNERACIONES_POR_PAGAR`.

---

## Índice

1. [Análisis del estado actual](#1-análisis-del-estado-actual)
2. [Arquitectura propuesta](#2-arquitectura-propuesta)
3. [Backend — Modelos y Migraciones](#3-backend--modelos-y-migraciones)
4. [Backend — Lógica y Endpoints](#4-backend--lógica-y-endpoints)
5. [Frontend — Modelos TypeScript](#5-frontend--modelos-typescript)
6. [Frontend — Servicio y Routing](#6-frontend--servicio-y-routing)
7. [Frontend — Lista de Empleados](#7-frontend--lista-de-empleados)
8. [Frontend — Formulario de Empleado](#8-frontend--formulario-de-empleado)
9. [Componentes Reutilizables](#9-componentes-reutilizables)
10. [Ajuste: GlobalScale / Asignación Familiar](#10-ajuste-globalscale--asignación-familiar)
11. [Ajuste: Sucursal de Empresa](#11-ajuste-sucursal-de-empresa)
12. [Orden de implementación](#12-orden-de-implementación)
13. [Pendientes y decisiones abiertas](#13-pendientes-y-decisiones-abiertas)

---

## 1. Análisis del estado actual

### Lo que ya existe

| Elemento | Ubicación | Estado |
|---|---|---|
| `ThirdCompany` (auxiliar) | `app/Models/Empresa/ThirdCompany.php` | Existente, se extiende |
| `AuxiliaryAccount` | `app/Models/Empresa/AuxiliaryAccount.php` | Existente, sin cambios |
| `DocumentoTipoIdentificacion` | `app/Models/PlanCuenta/` | Existente |
| `Comuna`, `City`, `Region` | `app/Models/Geograficos/` | Existentes |
| `GlobalScale` (tramos) | `app/Models/GlobalParameter/GlobalScale.php` | Requiere ajuste |
| `CostCenterCompany` | `app/Models/Empresa/` | Existente |
| Módulo nómina frontend | `src/app/modules/admin/nomina/` | Existente (conceptos, settings) |
| `NominaCompanySettings` | `app/Models/Nomina/NominaCompanySettings.php` | Existente |

### Lo que falta crear

**Backend:**
- `EmployeeProfile` — datos personales extendidos del empleado (incluye `direct_boss`, `employee_code`)
- `EmployeeFamiliarCharge` — cargas familiares (n por empleado, con snapshot de tramo y monto)
- `EmployeeWorkContract` — movimientos de contrato (n por empleado, uno activo, con archivo S3)
- `EmployeeRemuneration` — configuración de remuneración base
- `BranchCompany` (Sucursal) — mantenedor de sucursales por empresa
- `GlobalScaleTramo` — tabla persistente de tramos por escala global (reemplaza cálculo dinámico del JSON)

**Frontend:**
- Módulo `nomina/` dentro de `admin/`
- Sub-módulo `employee/` con lista + formulario
- Posiblemente `sucursal/` como mantenedor dentro de configuración de empresa

---

## 2. Arquitectura propuesta

```
Backend
├── Migrations (orden importante)
│   ├── create_branches_table
│   ├── create_employee_profiles_table
│   ├── create_familiar_charges_table
│   ├── create_work_contracts_table
│   └── create_employee_remunerations_table
│
├── Models/Empresa/
│   ├── BranchCompany.php
│   ├── EmployeeProfile.php
│   ├── EmployeeFamiliarCharge.php
│   ├── EmployeeWorkContract.php
│   └── EmployeeRemuneration.php
│
├── Models/GlobalParameter/
│   └── GlobalScaleTramo.php          ← NUEVO
│
├── Http/Requests/Nomina/
│   ├── EmployeeRequest.php
│   ├── FamiliarChargeRequest.php
│   ├── WorkContractRequest.php
│   ├── EmployeeRemunerationRequest.php
│   └── BranchCompanyRequest.php
│
├── Http/Controllers/Nomina/
│   ├── EmployeeController.php
│   └── BranchCompanyController.php
│
└── Http/Resources/Nomina/
    ├── EmployeeResource.php
    ├── EmployeeListResource.php
    ├── WorkContractResource.php
    └── FamiliarChargeResource.php

Frontend (src/app/modules/admin/nomina/)
├── employee/
│   ├── list/
│   │   ├── list.component.ts
│   │   └── list.component.html
│   ├── form/
│   │   ├── form.component.ts
│   │   ├── form.component.html
│   │   └── secciones/
│   │       ├── identificacion/
│   │       ├── contacto/
│   │       ├── carga-familiar/
│   │       ├── contrato/
│   │       └── remuneracion/
│   ├── employee.service.ts
│   └── employee.route.ts
└── rrhh.route.ts
```

---

## 3. Backend — Modelos y Migraciones

### 3.0 Migration: `global_scale_tramos` ← NUEVA

Reemplaza la lógica de calcular tramos al vuelo desde el JSON de `global_scales.values`. Permite snapshot en liquidaciones e historial de movimientos.

```php
Schema::create('global_scale_tramos', function (Blueprint $table) {
    $table->id();
    $table->foreignId('global_scale_id')->constrained('global_scales')->cascadeOnDelete();
    $table->string('code');                    // 'A', 'B', 'C', etc.
    $table->string('label');                   // "Tramo A — $0 a $389.922"
    $table->decimal('desde', 15, 2)->default(0);
    $table->decimal('hasta', 15, 2)->nullable();  // Null = sin límite superior
    $table->decimal('monto', 15, 2)->default(0);  // Valor de la asignación en ese tramo
    $table->timestamps();

    $table->unique(['global_scale_id', 'code']);
});
```

> **Seeder / Sincronización:** Al crear o actualizar un `GlobalScale` de tipo `ASIGNACION_FAMILIAR` o `IMPUESTO_UNICO`, se debe sincronizar la tabla `global_scale_tramos` desde el JSON `values` existente. Agregar un observer o un método `syncTramos()` en el modelo `GlobalScale`.

#### Modelo `GlobalScaleTramo.php`

```php
namespace App\Models\GlobalParameter;

class GlobalScaleTramo extends Model
{
    protected $table = 'global_scale_tramos';

    protected $fillable = ['global_scale_id', 'code', 'label', 'desde', 'hasta', 'monto'];

    protected $casts = [
        'desde' => 'decimal:2',
        'hasta' => 'decimal:2',
        'monto' => 'decimal:2',
    ];

    public function globalScale(): BelongsTo
    {
        return $this->belongsTo(GlobalScale::class, 'global_scale_id');
    }
}
```

#### Agregar en `GlobalScale.php`

```php
public function tramos(): HasMany
{
    return $this->hasMany(GlobalScaleTramo::class, 'global_scale_id');
}

public function syncTramos(): void
{
    $tramos = [];
    foreach ($this->values ?? [] as $index => $row) {
        $code  = chr(65 + $index);
        $desde = number_format($row['desde'] ?? 0, 0, ',', '.');
        $hasta = isset($row['hasta']) ? '$' . number_format($row['hasta'], 0, ',', '.') : 'sin límite';
        $tramos[] = [
            'global_scale_id' => $this->id,
            'code'            => $code,
            'label'           => "Tramo {$code} — \${$desde} a {$hasta}",
            'desde'           => $row['desde'] ?? 0,
            'hasta'           => $row['hasta'] ?? null,
            'monto'           => $row['factor'] ?? 0,
        ];
    }
    $this->tramos()->delete();
    $this->tramos()->createMany($tramos);
}
```

---

### 3.1 Migration: `branches`

```php
Schema::create('branchCompany', function (Blueprint $table) {
    $table->id();
    $table->foreignId('company_id')->constrained('company')->cascadeOnDelete();
    $table->string('name');
    $table->string('address')->nullable();
    $table->foreignId('comuna_id')->nullable()->constrained('comuna');
    $table->boolean('is_active')->default(true);
    $table->softDeletes(); // Decisión final: SoftDeletes en todos los modelos nuevos
    $table->timestamps();
});
```

### 3.2 Migration: `employee_profiles`

Extiende ThirdCompany con datos personales que no aplican a cliente/proveedor.

```php
Schema::create('employee_profiles', function (Blueprint $table) {
    $table->id();
    $table->foreignId('third_company_id')->unique()->constrained('third_company')->cascadeOnDelete();
    $table->foreignId('company_id')->constrained('company')->cascadeOnDelete(); // Para unique de employee_code

    // Identificación extra
    $table->string('second_name')->nullable();           // Segundo nombre
    $table->string('maternal_last_name')->nullable();    // Apellido materno
    $table->enum('gender', ['M', 'F'])->nullable();
    $table->date('birth_date')->nullable();
    $table->unsignedBigInteger('nationality_id')->nullable(); // FK a country
    $table->enum('marital_status', [
        'SOLTERO', 'CASADO', 'DIVORCIADO', 'VIUDO'
    ])->nullable();

    // Contacto adicional
    $table->string('corporate_email')->nullable();
    $table->string('personal_email')->nullable();       // Se complementa con ThirdCompany.email

    // Código interno y jefe
    $table->string('employee_code')->nullable();
    $table->string('direct_boss')->nullable();          // Texto libre

    $table->timestamps();
    $table->softDeletes(); // Decisión final: SoftDeletes para consistencia

    $table->foreign('nationality_id')->references('id')->on('country');
    $table->unique(['company_id', 'employee_code']);    // Decisión #3: único por empresa
});
```

> **Nota 1:** El campo `rut` en `ThirdCompany` es el número de documento de identificación (RUT, pasaporte, etc.), no específico de Chile. El tipo de documento determina el formato y validación (decisión #1).  
> **Nota 2:** `direct_boss` y `employee_code` viven en `EmployeeProfile`, no en `EmployeeWorkContract` (decisiones #2 y #3).  
> **Nota 3:** Nombre, apellido paterno, dirección, teléfono, comuna, ciudad, tipo/número de documento ya viven en `ThirdCompany`. El profile extiende sin duplicar.

### 3.3 Migration: `employee_familiar_charges`

```php
Schema::create('employee_familiar_charges', function (Blueprint $table) {
    $table->id();
    $table->foreignId('third_company_id')->constrained('third_company')->cascadeOnDelete();
    $table->enum('type', ['SIMPLE', 'MATERNAL', 'INVALIDA']);

    // Identificación de la carga (aplica a SIMPLE e INVALIDA)
    $table->foreignId('identification_document_id')
          ->nullable()
          ->constrained('documento_tipo_identificacion');
    $table->string('identification_number')->nullable();
    $table->string('full_name')->nullable();

    // Vencimiento (aplica a SIMPLE, MATERNAL e INVALIDA opcional)
    $table->date('expiration_date')->nullable();

    // Tramo de asignación familiar — decisión #5 y #13:
    // Se guarda la referencia al tramo Y el snapshot del monto vigente al momento de registrar.
    // Esto permite calcular liquidaciones históricas con el valor correcto del período.
    $table->foreignId('global_scale_tramo_id')
          ->nullable()
          ->constrained('global_scale_tramos')
          ->nullOnDelete();
    $table->decimal('monto_asignacion_snapshot', 15, 2)->nullable(); // Valor del tramo en el momento del registro

    $table->boolean('is_active')->default(true);
    $table->timestamps();
});
```

### 3.4 Migration: `employee_work_contracts`

```php
Schema::create('employee_work_contracts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('third_company_id')->constrained('third_company')->cascadeOnDelete();

    $table->enum('contract_type', [
        'INDEFINIDO',
        'PLAZO_FIJO',
        'OBRA_O_FAENA',
        'CAMBIO_PLAZO_FIJO_A_INDEFINIDO',
        'RETIRO',
        'RELIQUIDACION',
        'GRATIFICACION_ANUAL'
    ]);

    $table->date('start_date');
    $table->date('end_date')->nullable();               // Null si es indefinido o activo

    $table->enum('work_schedule', ['COMPLETA', 'PARCIAL']);
    $table->unsignedSmallInteger('weekly_hours')->default(45);

    // Días de la semana (bitmask o JSON: [1,2,3,4,5])
    $table->json('work_days')->nullable();

    $table->enum('work_mode', ['PRESENCIAL', 'TELETRABAJO', 'HIBRIDO'])->default('PRESENCIAL');

    // Relaciones opcionales
    $table->foreignId('branch_id')->nullable()->constrained('branches')->nullOnDelete();
    $table->foreignId('cost_center_id')->nullable()->constrained('cost_center_company')->nullOnDelete();

    $table->string('observations')->nullable();
    $table->boolean('is_active')->default(false);       // Solo un contrato activo a la vez

    // Decisión #11: Archivo adjunto (ej. contrato firmado) guardado en S3
    $table->string('contract_file_path')->nullable();   // Ruta S3 del anexo

    $table->timestamps();
});
```

> **Regla de negocio:** Al activar un `EmployeeWorkContract`, debe ser siempre basado en el rango de fecha ingresado, es decir, al crear un nuevo contrato se debe verificar que no exista otro contrato activo con el mismo empleado en el mismo rango de fecha.  
> **Archivo S3:** Usar `app/Services/Util/S3FileService.php` para subir/eliminar el archivo del contrato (decisión #11).

### 3.5 Migration: `employee_remunerations`

```php
Schema::create('employee_remunerations', function (Blueprint $table) {
    $table->id();
    $table->foreignId('third_company_id')->unique()->constrained('third_company')->cascadeOnDelete();

    $table->enum('salary_unit', ['CLP', 'UF'])->default('CLP');
    $table->boolean('uses_minimum_wage')->default(false); // Solo aplica si salary_unit = CLP
    $table->decimal('base_salary', 15, 2)->nullable();

    $table->enum('gratification_type', [
        'LEGAL_GARANTIZADA_25',
        'MENSUAL_25',
        'MENSUAL_TOPE',
        'ANUAL_TOPE_LEGAL'
    ])->nullable();

    $table->boolean('semana_corrida')->default(false);

    $table->timestamps();
});
```

---

### 3.6 Modelos Eloquent

#### `BranchCompany.php`

```php
namespace App\Models\Empresa;

class BranchCompany extends Model
{
    protected $table = 'branches';

    protected $fillable = ['company_id', 'name', 'address', 'comuna_id', 'is_active'];

    protected $visible = ['id', 'name', 'address', 'comuna_id', 'is_active', 'comuna'];

    protected $casts = ['is_active' => 'boolean'];

    public function company(): BelongsTo { return $this->belongsTo(Company::class); }

    public function comuna(): BelongsTo { return $this->belongsTo(Comuna::class, 'comuna_id'); }

    public function scopeForCompany(Builder $query, int $companyId): void
    {
        $query->where('company_id', $companyId);
    }

    public function scopeActive(Builder $query): void
    {
        $query->where('is_active', true);
    }
}
```

#### `EmployeeProfile.php`

```php
namespace App\Models\Empresa;

class EmployeeProfile extends Model
{
    protected $table = 'employee_profiles';

    protected $fillable = [
        'third_company_id', 'second_name', 'maternal_last_name',
        'gender', 'birth_date', 'nationality_id', 'marital_status',
        'corporate_email', 'personal_email', 'employee_code', 'direct_boss'
    ];

    protected $casts = ['birth_date' => 'date'];

    public function auxiliary(): BelongsTo
    {
        return $this->belongsTo(ThirdCompany::class, 'third_company_id');
    }

    public function nationality(): BelongsTo
    {
        return $this->belongsTo(Country::class, 'nationality_id');
    }
}
```

#### `EmployeeFamiliarCharge.php`

```php
namespace App\Models\Empresa;

class EmployeeFamiliarCharge extends Model
{
    protected $table = 'familiar_charges';

    protected $fillable = [
        'third_company_id', 'type', 'identification_document_id',
        'identification_number', 'full_name', 'expiration_date',
        'global_scale_tramo_id', 'monto_asignacion_snapshot', 'is_active'
    ];

    protected $casts = [
        'expiration_date'            => 'date',
        'monto_asignacion_snapshot'  => 'decimal:2',
        'is_active'                  => 'boolean'
    ];

    public function auxiliary(): BelongsTo
    {
        return $this->belongsTo(ThirdCompany::class, 'third_company_id');
    }

    public function identificationDocument(): BelongsTo
    {
        return $this->belongsTo(DocumentoTipoIdentificacion::class, 'identification_document_id');
    }

    public function globalScaleTramo(): BelongsTo
    {
        return $this->belongsTo(GlobalScaleTramo::class, 'global_scale_tramo_id');
    }
}
```

#### `EmployeeWorkContract.php`

```php
namespace App\Models\Empresa;

class EmployeeWorkContract extends Model
{
    protected $table = 'work_contracts';

    protected $fillable = [
        'third_company_id', 'contract_type', 'start_date', 'end_date',
        'work_schedule', 'weekly_hours', 'work_days', 'work_mode',
        'branch_id', 'cost_center_id', 'observations', 'is_active',
        'contract_file_path'
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'work_days' => 'array',
        'is_active' => 'boolean'
    ];

    public function auxiliary(): BelongsTo
    {
        return $this->belongsTo(ThirdCompany::class, 'third_company_id');
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(BranchCompany::class);
    }

    public function costCenter(): BelongsTo
    {
        return $this->belongsTo(CostCenterCompany::class, 'cost_center_id');
    }

    public function scopeActive(Builder $query): void
    {
        $query->where('is_active', true);
    }
}
```

#### `EmployeeRemuneration.php`

```php
namespace App\Models\Empresa;

class EmployeeRemuneration extends Model
{
    protected $table = 'employee_remunerations';

    protected $fillable = [
        'third_company_id', 'salary_unit', 'uses_minimum_wage',
        'base_salary', 'gratification_type', 'semana_corrida'
    ];

    protected $casts = [
        'uses_minimum_wage' => 'boolean',
        'semana_corrida' => 'boolean',
        'base_salary' => 'decimal:2'
    ];

    public function auxiliary(): BelongsTo
    {
        return $this->belongsTo(ThirdCompany::class, 'third_company_id');
    }
}
```

#### Actualizar `ThirdCompany.php`

**Migración adicional** para agregar `avatar_path` a la tabla `third_company` (decisión #12):

```php
Schema::table('third_company', function (Blueprint $table) {
    $table->string('avatar_path')->nullable()->after('email'); // Ruta S3. Aplica para todo auxiliar (cliente/proveedor/empleado)
});
```

> Usar `app/Services/Util/S3FileService.php` para subir/eliminar el avatar. El campo es genérico para todo auxiliar, no solo empleados.

Agregar las relaciones hacia los nuevos modelos:

```php
// En ThirdCompany.php — agregar relaciones

public function employeeProfile(): HasOne
{
    return $this->hasOne(EmployeeProfile::class, 'third_company_id');
}

public function familiarCharges(): HasMany
{
    return $this->hasMany(EmployeeFamiliarCharge::class, 'third_company_id');
}

public function workContracts(): HasMany
{
    return $this->hasMany(EmployeeWorkContract::class, 'third_company_id')->orderBy('start_date', 'desc');
}

public function activeContract(): HasOne
{
    return $this->hasOne(EmployeeWorkContract::class, 'third_company_id')->where('is_active', true);
}

public function remuneration(): HasOne
{
    return $this->hasOne(EmployeeRemuneration::class, 'third_company_id');
}
```

---

## 4. Backend — Lógica y Endpoints

### 4.1 FormRequests

#### `EmployeeRequest.php` (crear/actualizar datos base + perfil)

```php
namespace App\Http\Requests\Nomina;

class EmployeeRequest extends FormRequest
{
    // Decisión #10: doble nivel de autorización según el rol del usuario
    public function authorize(): bool
    {
        $user      = $this->user();
        $companyId = $this->route('company_id');

        if ($user->hasRole('SUBSCRIBER_ROLE')) {
            // El suscriptor solo puede operar sobre sus propias empresas
            return Company::where('id', $companyId)
                ->where('suscriptor_id', $user->getSuscriptorByRole()?->id)
                ->exists();
        }

        if ($user->hasRole('USER_ROLE')) {
            return $user->userHasCompanyPermission($companyId)
                && $user->usersPermissionSubmodules(
                    'NOMINA.EMPLOYES',
                    UserOperationSubmodule::CREATE->value  // o UPDATE / DELETE según el método HTTP
                );
        }

        return false;
    }

    public function rules(): array
    {
        $companyId = $this->route('company_id');

        return [
            // ThirdCompany base
            'identification_document_id' => 'required|integer|exists:documento_tipo_identificacion,id',
            // 'rut' es en realidad el número de documento (pasaporte, RUT, etc.) — decisión #1
            'rut'                        => 'nullable|string|max:20',
            'name'                       => 'required|string|max:100',
            'last_name'                  => 'required|string|max:100',

            // EmployeeProfile
            'second_name'               => 'nullable|string|max:100',
            'maternal_last_name'        => 'nullable|string|max:100',
            'gender'                    => 'nullable|in:M,F',
            'birth_date'                => 'nullable|date',
            'nationality_id'            => 'nullable|integer|exists:country,id',
            'marital_status'            => 'nullable|in:SOLTERO,CASADO,DIVORCIADO,VIUDO',
            'corporate_email'           => 'nullable|email|max:150',
            'personal_email'            => 'nullable|email|max:150',
            'phone'                     => 'nullable|string|max:30',
            'address'                   => 'nullable|string|max:255',
            'comuna_id'                 => 'nullable|integer|exists:comuna,id',
            'direct_boss'               => 'nullable|string|max:150',

            // employee_code: único por empresa — decisión #3
            'employee_code' => [
                'nullable', 'string', 'max:50',
                Rule::unique('employee_profiles', 'employee_code')
                    ->where('company_id', $companyId)
                    ->ignore($this->route('id'), 'third_company_id'), // Ignorar el propio registro al editar
            ],
        ];
    }
}
```

#### `FamiliarChargeRequest.php`

```php
public function rules(): array
{
    $type = $this->input('type');
    $rules = [
        'type'                 => 'required|in:SIMPLE,MATERNAL,INVALIDA',
        // Decisión #5 y #13: referencia al tramo persistente, no al GlobalScale directamente
        'global_scale_tramo_id' => 'nullable|integer|exists:global_scale_tramos,id',
        'expiration_date'      => 'nullable|date',
        'is_active'            => 'boolean',
    ];

    if (in_array($type, ['SIMPLE', 'INVALIDA'])) {
        $rules['identification_document_id'] = 'required|integer|exists:documento_tipo_identificacion,id';
        $rules['identification_number']      = 'required|string|max:30';
        $rules['full_name']                  = 'required|string|max:200';
    }
    if ($type === 'SIMPLE') {
        $rules['expiration_date'] = 'required|date';
    }

    return $rules;
}
```

#### `WorkContractRequest.php`

```php
public function rules(): array
{
    return [
        'contract_type'  => 'required|in:INDEFINIDO,PLAZO_FIJO,OBRA_O_FAENA,CAMBIO_PLAZO_FIJO_A_INDEFINIDO,RETIRO,RELIQUIDACION,GRATIFICACION_ANUAL',
        'start_date'     => 'required|date',
        'end_date'       => 'nullable|date|after_or_equal:start_date',
        'work_schedule'  => 'required|in:COMPLETA,PARCIAL',
        'weekly_hours'   => 'required|integer|min:1|max:60',
        'work_days'      => 'nullable|array',
        'work_days.*'    => 'integer|between:1,7',
        'work_mode'      => 'required|in:PRESENCIAL,TELETRABAJO,HIBRIDO',
        'branch_id'            => 'nullable|integer|exists:branches,id',
        'cost_center_id'       => 'nullable|integer|exists:cost_center_company,id',
        'observations'         => 'nullable|string|max:500',
        'is_active'            => 'boolean',
        // Decisión #11: archivo del contrato (se sube antes y se pasa la ruta S3)
        'contract_file_path'   => 'nullable|string|max:500',
    ];
}
```

#### `EmployeeRemunerationRequest.php`

```php
public function rules(): array
{
    return [
        'salary_unit'        => 'required|in:CLP,UF',
        'uses_minimum_wage'  => 'boolean',
        'base_salary'        => 'nullable|numeric|min:0',
        'gratification_type' => 'nullable|in:LEGAL_GARANTIZADA_25,MENSUAL_25,MENSUAL_TOPE,ANUAL_TOPE_LEGAL',
        'semana_corrida'     => 'boolean',
    ];
}
```

### 4.2 EmployeeController.php

```
GET    /v1/company/{company_id}/employee                → index()       Lista paginada con filtros
GET    /v1/company/{company_id}/employee/{id}           → show()        Detalle completo (con todas las relaciones)
POST   /v1/company/{company_id}/employee                → store()       Crea ThirdCompany + EmployeeProfile + cuenta REMUNERACIONES
PUT    /v1/company/{company_id}/employee/{id}           → update()      Actualiza ThirdCompany + EmployeeProfile
DELETE /v1/company/{company_id}/employee/{id}           → destroy()     Soft-check: sin movimientos → eliminar

POST   /v1/company/{company_id}/employee/{id}/familiar-charge           → storeFamiliarCharge()
PUT    /v1/company/{company_id}/employee/{id}/familiar-charge/{cid}     → updateFamiliarCharge()
DELETE /v1/company/{company_id}/employee/{id}/familiar-charge/{cid}     → destroyFamiliarCharge()

POST   /v1/company/{company_id}/employee/{id}/contract                  → storeContract() [activa el nuevo, desactiva el resto]
PUT    /v1/company/{company_id}/employee/{id}/contract/{cid}            → updateContract()

PUT    /v1/company/{company_id}/employee/{id}/remuneration              → updateRemuneration() [upsert]

GET    /v1/company/{company_id}/employee/documents                      → getDocuments()    [resolver]
GET    /v1/company/{company_id}/employee/filter-options                 → getFilterOptions() [resolver: estados, tipos contrato]
```

#### `BranchController.php`

```
GET    /v1/company/{company_id}/branch          → index()   Lista activas de la empresa autenticada
POST   /v1/company/{company_id}/branch          → store()
PUT    /v1/company/{company_id}/branch/{id}     → update()
DELETE /v1/company/{company_id}/branch/{id}     → destroy()
```

### 4.3 Lógica en `store()` de EmployeeController

Al crear un empleado se deben encadenar las siguientes operaciones en una **transacción de base de datos**:

1. Validar que el `rut` no exista ya como ThirdCompany en la empresa
2. Crear `ThirdCompany` con los datos base
3. Crear `EmployeeProfile` vinculado
4. Buscar el `AccountPlan` de la empresa, obtener la `SubCuenta` de categoría `REMUNERACIONES_POR_PAGAR`
5. Crear `AuxiliaryAccount` vinculando el tercero con dicha subcuenta
6. Retornar el empleado con todas sus relaciones cargadas vía `EmployeeResource`

### 4.4 Resources

#### `EmployeeListResource.php` (lista, datos mínimos)

```php
return [
    'id'            => $this->id,
    'rut'           => $this->rut,
    'full_name'     => $this->full_name,
    'email'         => $this->email,
    'phone'         => $this->phone,
    'employee_code' => $this->whenLoaded('employeeProfile', fn() => $this->employeeProfile?->employee_code),
    'active_contract' => new WorkContractResource($this->whenLoaded('activeContract')),
];
```

#### `EmployeeResource.php` (detalle completo)

```php
return [
    // ThirdCompany
    'id'                        => $this->id,
    'rut'                       => $this->rut,
    'name'                      => $this->name,
    'last_name'                 => $this->last_name,
    'full_name'                 => $this->full_name,
    'identification_document_id'=> $this->identification_document_id,
    'identification_document'   => $this->identification_document,
    'email'                     => $this->email,
    'phone'                     => $this->phone,
    'address'                   => $this->address,
    'comuna_id'                 => $this->comuna_id,
    'city_id'                   => $this->city_id,
    'country_id'                => $this->country_id,
    'comuna'                    => $this->whenLoaded('comuna'),

    // EmployeeProfile
    'profile' => $this->whenLoaded('employeeProfile', fn() => [
        'second_name'        => $this->employeeProfile?->second_name,
        'maternal_last_name' => $this->employeeProfile?->maternal_last_name,
        'gender'             => $this->employeeProfile?->gender,
        'birth_date'         => $this->employeeProfile?->birth_date?->toDateString(),
        'nationality_id'     => $this->employeeProfile?->nationality_id,
        'nationality'        => $this->employeeProfile?->nationality,
        'marital_status'     => $this->employeeProfile?->marital_status,
        'corporate_email'    => $this->employeeProfile?->corporate_email,
        'personal_email'     => $this->employeeProfile?->personal_email,
        'employee_code'      => $this->employeeProfile?->employee_code,
        'direct_boss'        => $this->employeeProfile?->direct_boss,
    ]),

    // Relaciones
    'familiar_charges' => FamiliarChargeResource::collection($this->whenLoaded('familiarCharges')),
    'work_contracts'   => WorkContractResource::collection($this->whenLoaded('workContracts')),
    'remuneration'     => new EmployeeRemunerationResource($this->whenLoaded('remuneration')),
];
```

---

## 5. Frontend — Modelos TypeScript

### `src/app/core/models/data/employee.ts`

```typescript
export class EmployeeProfile {
    second_name?: string;
    maternal_last_name?: string;
    gender?: 'M' | 'F';
    birth_date?: string;
    nationality_id?: number;
    nationality?: Country;
    marital_status?: 'SOLTERO' | 'CASADO' | 'DIVORCIADO' | 'VIUDO';
    corporate_email?: string;
    personal_email?: string;
    employee_code?: string;
    direct_boss?: string;
}

export class EmployeeFamiliarCharge {
    id?: number;
    type: 'SIMPLE' | 'MATERNAL' | 'INVALIDA';
    identification_document_id?: number;
    identification_document?: DocumentoTipoIdentificacion;
    identification_number?: string;
    full_name?: string;
    expiration_date?: string;
    // Decisión #5 y #13: referencia al tramo persistente + snapshot del monto
    global_scale_tramo_id?: number;
    global_scale_tramo?: GlobalScaleTramo;
    monto_asignacion_snapshot?: number;
    is_active?: boolean;
}

// Modelo de tramo persistente (tabla global_scale_tramos)
export interface GlobalScaleTramo {
    id: number;
    global_scale_id: number;
    code: string;   // 'A', 'B', 'C'...
    label: string;  // "Tramo A — $0 a $389.922"
    desde: number;
    hasta?: number;
    monto: number;
}

export class EmployeeWorkContract {
    id?: number;
    contract_type: ContractType;
    start_date: string;
    end_date?: string;
    work_schedule: 'COMPLETA' | 'PARCIAL';
    weekly_hours: number;
    work_days?: number[];
    work_mode: 'PRESENCIAL' | 'TELETRABAJO' | 'HIBRIDO';
    branch_id?: number;
    cost_center_id?: number;
    observations?: string;
    is_active: boolean;
    contract_file_path?: string; // Decisión #11: ruta S3 del archivo adjunto

    // Relaciones
    branch?: BranchCompany;
    cost_center?: CostCenter;
}

export type ContractType =
    | 'INDEFINIDO'
    | 'PLAZO_FIJO'
    | 'OBRA_O_FAENA'
    | 'CAMBIO_PLAZO_FIJO_A_INDEFINIDO'
    | 'RETIRO'
    | 'RELIQUIDACION'
    | 'GRATIFICACION_ANUAL';

export type GratificationType =
    | 'LEGAL_GARANTIZADA_25'
    | 'MENSUAL_25'
    | 'MENSUAL_TOPE'
    | 'ANUAL_TOPE_LEGAL';

export class EmployeeRemuneration {
    salary_unit: 'CLP' | 'UF';
    uses_minimum_wage: boolean;
    base_salary?: number;
    gratification_type?: GratificationType;
    semana_corrida: boolean;
}

export class Employee {
    id: number;
    rut?: string;              // Número de documento (RUT, pasaporte, etc.) — decisión #1
    name: string;
    last_name: string;
    full_name: string;
    identification_document_id?: number;
    identification_document?: DocumentoTipoIdentificacion;
    email?: string;
    phone?: string;
    address?: string;
    avatar_path?: string;      // Decisión #12: avatar S3, aplica a todo auxiliar
    comuna_id?: number;
    city_id?: number;
    country_id?: number;
    profile?: EmployeeProfile;
    familiar_charges?: EmployeeFamiliarCharge[];
    work_contracts?: EmployeeWorkContract[];
    remuneration?: EmployeeRemuneration;

    get activeContract(): EmployeeWorkContract | undefined {
        return this.work_contracts?.find(c => c.is_active);
    }
}

export class BranchCompany {
    id: number;
    name: string;
    address?: string;
    comuna_id?: number;
    is_active: boolean;
}

// Labels de UI (para evitar enums en templates)
export const CONTRACT_TYPE_LABELS: Record<ContractType, string> = {
    INDEFINIDO: 'Plazo indefinido',
    PLAZO_FIJO: 'Plazo fijo',
    OBRA_O_FAENA: 'Por obra o faena',
    CAMBIO_PLAZO_FIJO_A_INDEFINIDO: 'Cambio plazo fijo a indefinido',
    RETIRO: 'Retiro',
    RELIQUIDACION: 'Reliquidación',
    GRATIFICACION_ANUAL: 'Gratificación anual',
};

export const GRATIFICATION_TYPE_LABELS: Record<GratificationType, string> = {
    LEGAL_GARANTIZADA_25: 'Legal garantizada 25%',
    MENSUAL_25: 'Mensual 25%',
    MENSUAL_TOPE: 'Mensual con tope',
    ANUAL_TOPE_LEGAL: 'Anual tope legal',
};

export const MARITAL_STATUS_LABELS = {
    SOLTERO: 'Soltero(a)',
    CASADO: 'Casado(a)',
    DIVORCIADO: 'Divorciado(a)',
    VIUDO: 'Viudo(a)',
};
```

---

## 6. Frontend — Servicio y Routing

### `employee.service.ts`

Sigue el mismo patrón que `PurchaseService` con BehaviorSubjects.

```typescript
@Injectable({ providedIn: 'root' })
export class EmployeeService {

    private _employees = new BehaviorSubject<Employee[]>([]);
    private _employee  = new BehaviorSubject<Employee | null>(null);
    private _pagination = new BehaviorSubject<Pagination>(null);

    get _employees$()   { return this._employees.asObservable(); }
    get _employee$()    { return this._employee.asObservable(); }
    get _pagination$()  { return this._pagination.asObservable(); }

    // Lista con paginación y filtros
    getEmployees(page, size, sort, order, search?, contractType?): Observable<Employee[]> { ... }

    // Detalle (precarga todas las relaciones)
    getEmployeeById(id: number): Observable<Employee> { ... }

    // CRUD empleado
    createEmployee(data: any): Observable<JsonResponse<Employee>> { ... }
    updateEmployee(id: number, data: any): Observable<JsonResponse<Employee>> { ... }
    deleteEmployee(id: number): Observable<JsonResponse<any>> { ... }

    // Cargas familiares
    createFamiliarCharge(employeeId: number, data: any): Observable<JsonResponse<EmployeeFamiliarCharge>> { ... }
    updateFamiliarCharge(employeeId: number, chargeId: number, data: any): Observable<JsonResponse<EmployeeFamiliarCharge>> { ... }
    deleteFamiliarCharge(employeeId: number, chargeId: number): Observable<JsonResponse<any>> { ... }

    // Contrato
    createWorkContract(employeeId: number, data: any): Observable<JsonResponse<EmployeeWorkContract>> { ... }
    updateWorkContract(employeeId: number, contractId: number, data: any): Observable<JsonResponse<EmployeeWorkContract>> { ... }

    // Remuneración (upsert)
    saveRemuneration(employeeId: number, data: any): Observable<JsonResponse<EmployeeRemuneration>> { ... }

    // Resolvers
    getDocumentTypes(): Observable<DocumentoTipoIdentificacion[]> { ... }
    getCountries(): Observable<Country[]> { ... }
    getBranches(): Observable<BranchCompany[]> { ... }
    getAsignacionFamiliarTramos(): Observable<GlobalScaleTramo[]> { ... } // Decisión #13: usa tabla global_scale_tramos
    uploadContractFile(employeeId: number, file: File): Observable<{ path: string }> { ... } // Decisión #11: S3
    uploadEmployeeAvatar(employeeId: number, file: File): Observable<{ path: string }> { ... } // Decisión #12: S3
    getCostCenters(): Observable<CostCenter[]> { ... }
    getWeeklyHoursDefault(): Observable<number> { ... } // Desde NominaCompanySettings
    hasCostCenters(): Observable<boolean> { ... }       // Feature flag
}
```

### `employee.route.ts`

```typescript
export const EMPLOYEE_ROUTES: Routes = [
    {
        path: '',
        canActivate: [accountPlanRequireGuard, CompanySelectedRequiredGuard],
        children: [
            {
                path: '',
                component: EmployeeListComponent,
                data: { breadcrumb: [{ label: 'Empleados' }] },
                resolve: {
                    // No se necesita resolver para la lista, carga lazy
                }
            },
            {
                path: 'create',
                component: EmployeeFormComponent,
                data: {
                    breadcrumb: [
                        { label: 'Empleados', url: '/nomina/employee' },
                        { label: 'Nuevo empleado' }
                    ],
                    mode: 'create'
                },
                resolve: {
                    documentTypes: () => inject(EmployeeService).getDocumentTypes(),
                    countries:     () => inject(EmployeeService).getCountries(),
                    branches:      () => inject(EmployeeService).getBranches(),
                    costCenters:   () => inject(EmployeeService).getCostCenters(),
                    familyTramos:  () => inject(EmployeeService).getAsignacionFamiliarTramos(),
                }
            },
            {
                path: 'update/:id',
                component: EmployeeFormComponent,
                data: {
                    breadcrumb: [
                        { label: 'Empleados', url: '/nomina/employee' },
                        { label: 'Editar empleado' }
                    ],
                    mode: 'edit'
                },
                resolve: {
                    employee:      () => inject(EmployeeService).getEmployeeById(/* id from params */),
                    documentTypes: () => inject(EmployeeService).getDocumentTypes(),
                    countries:     () => inject(EmployeeService).getCountries(),
                    branches:      () => inject(EmployeeService).getBranches(),
                    costCenters:   () => inject(EmployeeService).getCostCenters(),
                    familyTramos:  () => inject(EmployeeService).getAsignacionFamiliarTramos(),
                }
            }
        ]
    }
];
```

> **Nota sobre el resolver de `employee` en `update`:** Para obtener el `id` desde los `paramMap` dentro de un resolver funcional en Angular 14+, usar `inject(ActivatedRouteSnapshot)` o pasar el snapshot al resolver. Ver patrón existente en `purchase.route.ts`.

---

## 7. Frontend — Lista de Empleados

### `list.component.ts`

Sigue exactamente el mismo patrón que `PurchaseListComponent`:

- `@ViewChild(MatPaginator)` y `@ViewChild(MatSort)`
- BehaviorSubject para `employees$` y `pagination`
- Formulario de filtros con:
  - **Búsqueda por nombre/RUT** (input texto)
  - **Tipo de contrato** (select: TODOS + tipos)
  - **Estado** (todos / activos / finiquitados)
- Acciones por fila:
  - **Editar** → navegar a `update/:id`
  - **Eliminar** → diálogo de confirmación (verificar si tiene movimientos/liquidaciones antes)
  - **Ver contratos** → toggle de detalle inline (similar a `selectedPurchase`)

### Grid CSS

```css
.employee-grid {
    grid-template-columns: 60px 140px auto 140px 100px 80px;

    @screen md {
        grid-template-columns: 60px 140px 200px auto 180px 140px 80px;
    }
}
```

### Columnas de la tabla

| # | Campo | Descripción |
|---|---|---|
| 1 | Icono/avatar | Inicial del nombre |
| 2 | RUT | Con pipe `rutFormat` |
| 3 | Nombre completo | |
| 4 | Email | |
| 5 | Tipo contrato | Label del enum |
| 6 | Fecha ingreso | Del contrato activo |
| 7 | Acciones | Editar / Eliminar |

---

## 8. Frontend — Formulario de Empleado

El formulario se organiza en **secciones tipo accordion / stepper** usando `mat-expansion-panel` o tabs de material, con un UntypedFormGroup principal y subgrupos por sección.

### Estructura del formulario

```typescript
this.form = this._fb.group({
    // Sección Identificación
    identification: this._fb.group({
        identification_document_id: [null, Validators.required],
        rut:                        [''],
        name:                       ['', Validators.required],
        second_name:                [''],
        last_name:                  ['', Validators.required],
        maternal_last_name:         [''],
        gender:                     [null],
        birth_date:                 [null],
        nationality_id:             [null],
        marital_status:             [null],
    }),

    // Sección Contacto
    contact: this._fb.group({
        personal_email:  ['', [Validators.email]],
        corporate_email: ['', [Validators.email]],
        phone:           [''],
        address:         [''],
        comuna_id:       [null],
        city_id:         [null],  // Se auto-rellena desde la comuna
        country_id:      [null],
    }),

    // Sección Carga Familiar
    // La lista de cargas es un FormArray
    familiar_charges: this._fb.array([]),

    // Sección Contrato
    // La lista de contratos es un FormArray
    contracts: this._fb.array([]),

    // Sección Remuneración
    remuneration: this._fb.group({
        salary_unit:        ['CLP', Validators.required],
        uses_minimum_wage:  [false],
        base_salary:        [null],
        gratification_type: [null],
        semana_corrida:     [false],
    }),

    // Datos admin
    employee_code: [''],
    direct_boss:   [''],
});
```

### 8.0 Flujo de Inicio: Buscador de RUT
Antes de mostrar cualquier campo del formulario, se debe utilizar el componente `app-auxiliary-rut-search`. 
- **Si el RUT no existe**: Se habilita el formulario completo para creación.
- **Si el RUT existe**: Se debe abrir un diálogo contextual donde el usuario confirme añadir el rol "Empleado" a la ficha existente. Se precargarán los datos disponibles de `ThirdCompany` y se habilitarán las secciones específicas de empleado (`EmployeeProfile`, `FamiliarCharge`, `WorkContract`, `Remuneration`).

### 8.1 Sección Identificación

Campos:
- **Tipo de documento** → `SelectScrollAndFilterComponent` con lista de `DocumentoTipoIdentificacion`
- **Número de documento / RUT** → input. Si el tipo es RUT, aplicar `RutFormatPipe` en el display y validación de formato
- **Primer nombre** → input requerido
- **Segundo nombre** → input opcional
- **Apellido paterno** → input requerido
- **Apellido materno** → input opcional
- **Género** → `mat-button-toggle-group` (Masculino / Femenino)
- **Fecha de nacimiento** → `mat-datepicker` (formato DD/MM/YYYY)
- **Nacionalidad** → `SelectScrollAndFilterComponent` con lista de países. Chile aparece primero (ordenar en el servicio: `sort((a, b) => a.id === CHILE_ID ? -1 : 1)`)
- **Estado civil** → `mat-select` con opciones del enum

### 8.2 Sección Contacto

Campos:
- **Email personal** → input email
- **Email corporativo** → input email
- **Teléfono** → input
- **Dirección** → input
- **Región** → select. Al seleccionar, filtra comunas disponibles
- **Ciudad** → se auto-rellena al seleccionar comuna (o manual si no hay relación)
- **Comuna** → `SelectScrollAndFilterComponent`. Al seleccionar, auto-rellena ciudad y región

> Patrón para cascada de geográficos: al cambiar `comuna_id`, el servicio retorna el objeto con `city` y `region` incluidos para auto-poblar los otros campos.

### 8.3 Sección Carga Familiar

Es un `FormArray`. Cada elemento es un `FormGroup` con campos condicionales según el tipo.

```typescript
createFamiliarChargeGroup(charge?: EmployeeFamiliarCharge): FormGroup {
    return this._fb.group({
        id:                         [charge?.id ?? null],
        type:                       [charge?.type ?? null, Validators.required],
        // Decisión #5 y #13: referencia al tramo persistente
        global_scale_tramo_id:      [charge?.global_scale_tramo_id ?? null],
        identification_document_id: [charge?.identification_document_id ?? null],
        identification_number:      [charge?.identification_number ?? ''],
        full_name:                  [charge?.full_name ?? ''],
        expiration_date:            [charge?.expiration_date ?? null],
        is_active:                  [charge?.is_active ?? true],
    });
}
```

> **Snapshot automático:** Al seleccionar un `global_scale_tramo_id`, el componente debe leer el `monto` del tramo seleccionado y enviarlo como `monto_asignacion_snapshot` al backend. Esto garantiza que liquidaciones históricas usen el valor vigente en el momento del registro.

**Reglas de visibilidad por tipo:**

| Campo | SIMPLE | MATERNAL | INVALIDA |
|---|---|---|---|
| Tipo documento | ✅ requerido | ❌ oculto | ✅ requerido |
| N° documento | ✅ requerido | ❌ oculto | ✅ requerido |
| Nombre | ✅ requerido | ❌ oculto | ✅ requerido |
| Vencimiento | ✅ requerido | ✅ requerido | ⚪ opcional |

**Tramo de asignación familiar:**
- Se muestra un `mat-select` con los tramos de `GlobalScaleTramo` (tabla `global_scale_tramos`)
- El label de cada opción: `"Tramo A — $0 a $389.922 → $16.435/mes"`
- Al seleccionar, capturar el `monto` del tramo y enviarlo como `monto_asignacion_snapshot`
- Ver sección [10. Ajuste GlobalScale](#10-ajuste-globalscale--asignación-familiar)

**UI:** Cada carga se muestra como una card colapsable con botón de eliminar. Botón "Agregar carga familiar" al final del array.

### 8.4 Sección Contrato

Es un `FormArray`. **Solo un contrato puede estar activo** (radio button o toggle en la UI que desactiva los demás al confirmar).

```typescript
createContractGroup(contract?: EmployeeWorkContract): FormGroup {
    return this._fb.group({
        id:             [contract?.id ?? null],
        contract_type:  [contract?.contract_type ?? null, Validators.required],
        start_date:     [contract?.start_date ?? null, Validators.required],
        end_date:       [contract?.end_date ?? null],
        work_schedule:  [contract?.work_schedule ?? 'COMPLETA', Validators.required],
        weekly_hours:   [contract?.weekly_hours ?? this.defaultWeeklyHours, Validators.required],
        work_days:      [contract?.work_days ?? [1,2,3,4,5]],
        work_mode:      [contract?.work_mode ?? 'PRESENCIAL', Validators.required],
        branch_id:      [contract?.branch_id ?? null],
        cost_center_id: [contract?.cost_center_id ?? null],
        observations:   [contract?.observations ?? ''],
        is_active:      [contract?.is_active ?? false],
    });
}
```

**Campos:**

- **Tipo de contrato** → `mat-select` con `CONTRACT_TYPE_LABELS`
- **Fecha de ingreso** → `mat-datepicker` requerido
- **Fecha de término** → `mat-datepicker` opcional. Requerido si tipo es `PLAZO_FIJO`, `OBRA_O_FAENA` o `RETIRO`
- **Jornada laboral** → `mat-button-toggle-group` (Completa / Parcial)
- **Horas semanales** → número. Default desde `NominaCompanySettings` (clave `HORAS_SEMANALES`). Editable
- **Días de la semana** → checkboxes (L M M J V S D). Default L-V
- **Modalidad de trabajo** → `mat-select` (Presencial / Teletrabajo / Híbrido)
- **Sucursal** → `mat-select` con lista de `BranchCompany`. Solo visible si hay sucursales configuradas
- **Centro de costo** → `SelectScrollAndFilterComponent`. Solo visible si la empresa tiene centros de costo activos (`hasCostCenters()`)
- **Observaciones** → textarea opcional
- **Archivo adjunto** → input file (PDF). Sube a S3 via `uploadContractFile()` antes del guardado principal. Mostrar nombre del archivo y botón eliminar si ya existe (decisión #11)
- **Activo** → toggle / chip visual que indica cuál es el contrato vigente

> **Nota:** `direct_boss` y `employee_code` se ingresan en la sección de Identificación (viven en `EmployeeProfile`), no en el contrato (decisión #2).

**UI:** Lista de contratos tipo timeline, ordenados descendente por fecha inicio. El activo destacado. Botón "Nuevo movimiento de contrato" añade al array. Contratos anteriores son de solo lectura excepto para desactivar.

### 8.5 Sección Remuneración

```html
<!-- Radio: Tipo de sueldo -->
<mat-radio-group formControlName="salary_unit">
    <mat-radio-button value="CLP">CLP (Pesos)</mat-radio-button>
    <mat-radio-button value="UF">UF</mat-radio-button>
</mat-radio-group>

<!-- Solo si CLP -->
<mat-checkbox formControlName="uses_minimum_wage">Usar sueldo mínimo</mat-checkbox>

<!-- Monto base (opcional si usa mínimo) -->
<input matInput type="number" formControlName="base_salary" placeholder="Sueldo base">

<!-- Tipo de gratificación -->
<mat-select formControlName="gratification_type">
    <mat-option *ngFor="..." [value]="key">{{ label }}</mat-option>
</mat-select>

<!-- Semana corrida -->
<mat-checkbox formControlName="semana_corrida">Aplica semana corrida</mat-checkbox>
```

**Lógica:**
- Si `salary_unit === 'UF'`, ocultar y resetear `uses_minimum_wage`
- Si `uses_minimum_wage === true`, el campo `base_salary` se deshabilita y muestra el mínimo legal (puede obtenerse de `GlobalVariable` tipo `SUELDO_MINIMO`)

---

## 9. Componentes Reutilizables

### 9.1 `EmployeeSectionCardComponent` (nuevo)

Wrapper visual para cada sección del formulario (igual que un expansion panel personalizado):

```
Input: title: string, icon: string, [complete]: boolean (green check si sección válida)
Content: ng-content
```

### 9.2 `WorkDaysPickerComponent` (nuevo)

Selector visual de días de la semana (7 chips/toggles: L M M J V S D):

```typescript
@Input() control: AbstractControl;
// Emite array de números [1..7] donde 1=Lunes
```

### 9.3 `FamiliarChargeFormComponent` (nuevo)

Formulario individual de una carga familiar (puede usarse como componente hijo que recibe un `FormGroup`):

```typescript
@Input() form: FormGroup;
@Input() documentTypes: DocumentoTipoIdentificacion[];
@Input() familyTramos: GlobalScale[];
@Output() remove = new EventEmitter<void>();
```

### 9.4 `ContractTimelineComponent` (nuevo)

Visualización de historial de contratos:

```typescript
@Input() contracts: EmployeeWorkContract[];
@Output() addContract = new EventEmitter<void>();
@Output() activateContract = new EventEmitter<number>(); // id del contrato
```

### 9.5 Reutilizados existentes

- `SelectScrollAndFilterComponent` → Tipo documento, Nacionalidad, Centro de costo, Sucursal
- `SharedPeriodPickerComponent` → No aplica en esta pantalla
- `BreadcrumbComponent` → Sí
- `RutFormatPipe` → Para mostrar RUT
- `FuseAlertService` → Alertas de éxito/error

---

## 10. Ajuste: GlobalScale / Asignación Familiar

### Decisión adoptada (decisiones #5 y #13)

Se crea la tabla persistente `global_scale_tramos` (definida en sección 3.0). Aplica a **todos** los `GlobalScale`, no solo a `ASIGNACION_FAMILIAR`. Esto cubre también `IMPUESTO_UNICO` y cualquier escala que se agregue en el futuro.

### Flujo de sincronización

1. Al crear o actualizar un `GlobalScale`, ejecutar `syncTramos()` (definido en sección 3.0)
2. Usar un **Observer** en `GlobalScale` para que `syncTramos()` se llame automáticamente en los eventos `saved`
3. Ejecutar un **seeder de migración** para poblar `global_scale_tramos` desde los `GlobalScale` existentes en base de datos

```php
// GlobalScaleObserver.php
class GlobalScaleObserver
{
    public function saved(GlobalScale $globalScale): void
    {
        $globalScale->syncTramos();
    }
}

// Registrar en AppServiceProvider o en GlobalScale::boot()
GlobalScale::observe(GlobalScaleObserver::class);
```

### Endpoint para el frontend

```
GET /v1/global-parameters/asignacion-familiar/tramos
```

Retorna todos los `GlobalScaleTramo` del `GlobalScale` más reciente de tipo `ASIGNACION_FAMILIAR`, ordenados por `desde` ascendente.

```php
// Respuesta esperada
[
    { "id": 1, "code": "A", "label": "Tramo A — $0 a $389.922", "desde": 0, "hasta": 389922, "monto": 16435 },
    { "id": 2, "code": "B", "label": "Tramo B — $389.923 a $570.007", "desde": 389923, "hasta": 570007, "monto": 10303 },
    { "id": 3, "code": "C", "label": "Tramo C — $570.008 a $779.844", "desde": 570008, "hasta": 779844, "monto": 3137 },
    { "id": 4, "code": "D", "label": "Tramo D — sin asignación", "desde": 779845, "hasta": null, "monto": 0 },
]
```

> El frontend usa `id` como valor del `mat-select` y muestra `label`. Al guardar una carga familiar, también envía `monto_asignacion_snapshot` con el valor de `monto` del tramo seleccionado.

---

## 11. Ajuste: Sucursal de Empresa

La sucursal debe ser mantenible desde la configuración de empresa, similar a cómo se gestionan los centros de costo.

### Backend

- Modelo `BranchCompany` (ya definido en sección 3.1)
- `BranchCompanyController` con CRUD
- `BranchCompanyRequest` con validaciones

### Frontend

- Agregar sección **"Sucursales"** dentro del componente de configuración/edición de empresa
- Componente inline: lista de sucursales activas + formulario de creación/edición inline (similar al patrón de conceptos de nómina)
- El servicio de empleados llama a `getBranches()` que usa el endpoint `GET /v1/company/{company_id}/branch`

---

## 12. Orden de implementación

Seguir este orden para minimizar dependencias bloqueantes:

### Fase 1 — Base de datos y modelos (Backend)

1. [ ] Migración `create_global_scale_tramos_table` ← **debe ir primero** (FK desde familiar_charges)
2. [ ] Seeder para poblar `global_scale_tramos` desde `global_scales` existentes
3. [ ] Migración `alter_third_company_add_avatar_path`
4. [ ] Migración `create_branch_company_table`
5. [ ] Migración `create_employee_profiles_table` (incluye `company_id` para unique de `employee_code`)
6. [ ] Migración `create_employee_familiar_charges_table` (usa `global_scale_tramo_id`)
7. [ ] Migración `create_employee_work_contracts_table` (incluye `contract_file_path`)
8. [ ] Migración `create_employee_remunerations_table`
9. [ ] Modelo `GlobalScaleTramo` + Observer en `GlobalScale`
10. [ ] Modelo `BranchCompany`
11. [ ] Modelo `EmployeeProfile`
12. [ ] Modelo `EmployeeFamiliarCharge`
13. [ ] Modelo `EmployeeWorkContract`
14. [ ] Modelo `EmployeeRemuneration`
15. [ ] Actualizar `ThirdCompany` con nuevas relaciones

### Fase 2 — Lógica de API (Backend)

16. [ ] `EmployeeRequest.php` (con lógica de autorización SUBSCRIBER/USER + unique employee_code)
17. [ ] `FamiliarChargeRequest.php` (usa `global_scale_tramo_id`)
18. [ ] `WorkContractRequest.php` (incluye `contract_file_path`)
19. [ ] `EmployeeRemunerationRequest.php`
20. [ ] `BranchCompanyRequest.php`
21. [ ] `BranchCompanyController` (CRUD simple)
22. [ ] `EmployeeController` — métodos `index`, `show`, `store`, `update`, `destroy`
23. [ ] `EmployeeController` — métodos de cargas familiares (captura snapshot del monto en `store`)
24. [ ] `EmployeeController` — métodos de contratos (upload S3 en `store`/`update`)
25. [ ] `EmployeeController` — método `updateRemuneration` (upsert)
26. [ ] Resources: `EmployeeListResource`, `EmployeeResource`, `WorkContractResource`, `FamiliarChargeResource`
27. [ ] Endpoint GET tramos de asignación familiar (`/v1/global-parameters/asignacion-familiar/tramos`)
28. [ ] Registrar rutas en `api.php`

### Fase 3 — Frontend: Modelos y servicio

29. [ ] Crear `src/app/core/models/data/employee.ts` (incluye `GlobalScaleTramo`, `avatar_path`, `contract_file_path`)
30. [ ] Crear `employee.service.ts` (incluye `uploadContractFile()`, `uploadEmployeeAvatar()`, `getAsignacionFamiliarTramos()`)
31. [ ] Crear `employee.route.ts`
32. [ ] Registrar el módulo `nomina/employee` en el routing principal del admin

### Fase 4 — Frontend: Lista

33. [ ] `list.component.ts` + `list.component.html`
34. [ ] Pruebas de filtros, paginación y sort

### Fase 5 — Frontend: Formulario

35. [ ] `form.component.ts` — estructura base + FormGroup principal
36. [ ] Sección Identificación (incluye `direct_boss` y `employee_code`)
37. [ ] Sección Contacto (incluyendo cascada geográfica)
38. [ ] `FamiliarChargeFormComponent` reutilizable (usa `global_scale_tramo_id` + captura snapshot)
39. [ ] `WorkDaysPickerComponent` reutilizable
40. [ ] Sección Carga Familiar (FormArray)
41. [ ] `ContractTimelineComponent` reutilizable
42. [ ] Sección Contrato (FormArray, con upload S3 de archivo)
43. [ ] Sección Remuneración
44. [ ] Upload de avatar de empleado (en cabecera del formulario)
45. [ ] Lógica de guardado (crear vs editar)
46. [ ] Validaciones cruzadas (sueldo mínimo si UF, fecha término según tipo contrato, etc.)

### Fase 6 — Mantenedor Sucursal

47. [ ] Backend: `BranchCompany` model + controller + request + rutas (ya en fase 1-2)
48. [ ] Frontend: Sección de sucursales en configuración de empresa

---

## 13. Decisiones adoptadas

Todas las decisiones han sido incorporadas al plan. Se listan aquí como referencia y trazabilidad:

| # | Decisión | Impacto en el plan |
|---|---|---|
| 1 | El campo `rut` en `ThirdCompany` es el número de documento genérico (RUT o pasaporte). El tipo de documento determina validación. | `EmployeeRequest` valida condicionalmente; la UI adapta el label según tipo de documento seleccionado |
| 2 | `direct_boss` vive en `EmployeeProfile`, no en `EmployeeWorkContract` | Removido del FormGroup de contrato; permanece en sección Identificación |
| 3 | `employee_code` es único por empresa | Unique constraint `(company_id, employee_code)` en migración + `Rule::unique` en `EmployeeRequest` |
| 4 | Contratos `RETIRO` y `GRATIFICACION_ANUAL` no requieren lógica especial en esta fase | Se modelan como tipos válidos; la lógica de cierre se implementa en el módulo de liquidaciones |
| 5 | Los tramos de AF guardan snapshot del monto al momento de registrar | `employee_familiar_charges` tiene `global_scale_tramo_id` + `monto_asignacion_snapshot`; el frontend captura el monto al seleccionar el tramo |
| 6 | Horas semanales default desde `NominaCompanySettings` (key `HORAS_SEMANALES_EMPRESA`), fallback 45, editable manualmente | `getWeeklyHoursDefault()` en el servicio; el formulario inicializa el campo con ese valor |
| 7 | Historial de contratos con `is_active = false`, sin soft-delete de Eloquent | Migración sin `softDeletes()`; la UI muestra historial de contratos inactivos en modo solo lectura |
| 8 | `BranchCompany` solo requiere nombre y dirección en esta fase | Migración minimalista; se extiende con datos tributarios cuando se requiera para documentos |
| 9 | La sección de remuneración incluye `base_salary`; el monto calculado final viene del módulo de liquidaciones | `EmployeeRemuneration` persiste el sueldo pactado; la liquidación lo toma como base de cálculo |
| 10 | Autorización doble: `SUBSCRIBER_ROLE` verifica ownership de empresa; `USER_ROLE` verifica permiso `NOMINA.EMPLOYES` con la operación correspondiente | Implementado en `authorize()` de todos los FormRequests del módulo |
| 11 | `EmployeeWorkContract` incluye archivo adjunto (PDF del contrato) guardado en S3 | Campo `contract_file_path` en migración y modelo; UI con input file + `S3FileService` |
| 12 | Avatar en `ThirdCompany` guardado en S3; aplica para todo auxiliar (no solo empleados) | Campo `avatar_path` en migración `alter_third_company`; UI en cabecera del formulario de empleado |
| 13 | Tabla persistente `global_scale_tramos` reemplaza cálculo dinámico del JSON; aplica a todos los `GlobalScale` | Nueva migración y modelo `GlobalScaleTramo`; Observer en `GlobalScale` sincroniza al crear/actualizar; `employee_familiar_charges` referencia `global_scale_tramo_id` |
| 14 | S3 File Fallback: El disco de S3FileService será configurable mediante `env('FILESYSTEM_DISK', 's3')` | Modificar `S3FileService.php` para evitar bloqueos por roles de AWS en desarrollo |
| 15 | SoftDeletes: Todos los nuevos modelos contarán con soft-delete para consistencia con `ThirdCompany` | Agregar `softDeletes()` en migraciones y trait `SoftDeletes` en modelos |

### Pendientes diferidos (próximo módulo: Liquidaciones)

- Lógica de cierre/finiquito para contratos `RETIRO`
- Uso del `monto_asignacion_snapshot` en el cálculo de la liquidación mensual
- Cálculo de `base_salary` en UF usando `GlobalVariable` tipo `UTM` o `UF`
- Valor del sueldo mínimo desde `GlobalVariable` tipo `SUELDO_MINIMO`

---

## 14. Estatus del Plan: FINALIZADO

Este plan ha sido revisado y aprobado. Sirve como documento de verdad único para la implementación del módulo de Empleados. Las dudas técnicas planteadas han sido resueltas en la sección de respuestas adjunta en el histórico de este documento.

### Próximos pasos:
1. Iniciar con la **Fase 1 (Migrations y Modelos)**.
2. Modificar el `S3FileService.php` para implementar el fallback de disco.

---

## 14. Preguntas y Observaciones

Durante la revisión del plan, han surgido algunos puntos técnicos que requieren definición o validación para asegurar que la implementación sea robusta:

### 1. Reutilización de `ThirdCompany` existente
**Pregunta:** ¿Qué sucede si una persona que ya está registrada como Cliente o Proveedor (en la tabla `third_company`) es contratada como Empleado?
*   **Observación:** La lógica de `EmployeeController@store` debería detectar si el RUT ya existe. En ese caso, en lugar de crear un nuevo `ThirdCompany`, debería simplemente "extenderlo" creando su `EmployeeProfile` y asociando la cuenta contable de remuneraciones.
* **Respueta:** Para esto necesitamos agregar el componente `app-auxiliary-rut-search` para saber si el empleado existe o no, en caso de que no exista, sigue completando la ficha del empleado (que en el servicio debera crear la ficha de ThirdCompany con los datos que se encuentren en el formulario y cuenta asociada a remuneraciones). En caso de que exista, se debe mostrar el modal de auxiliar obligando al usuario a seleccionar que tendra role `empleado` y completar el formulario del empleado con los datos que se encuentren en la ficha de auxiliar.

### 2. Integración con "Cuentas Maestras"
**Pregunta:** En el punto 4.3 (paso 5), se menciona buscar la cuenta de categoría `REMUNERACIONES_POR_PAGAR`. ¿Deberíamos usar la asociación definida en el nuevo módulo de **Revisión de Cuentas Maestras**?
*   **Observación:** Sería ideal que el sistema consulte primero si hay una "Cuenta Maestra" configurada para la categoría de empleados antes de intentar buscar una por código o nombre, garantizando consistencia contable.
* **Respuesta:** Si, se debe usar la asociación definida en el nuevo módulo de **Revisión de Cuentas Maestras**.

### 3. Almacenamiento en S3 vs Local
**Pregunta:** ¿S3 ya está configurado y operativo en todos los ambientes (dev/qa/prod)?
*   **Observación:** Si S3 no está disponible en algún ambiente de desarrollo local, el `S3FileService` debería manejar un fallback a disco local o lanzar una advertencia clara para evitar errores en la subida de contratos y avatares.
* **Respuesta:** No, actualmente usamos el S3 de AWS, y tenemos configurado el .env para que funcione en desarrollo, qa y prod. Solo se encuentra desplegado en desarrollo y qa. Favor revisar porque tengo un problema con la subida al S3 con ambiente desarrollo, porque el S3 se accede mediante roles. Quizas desarrollo hacer un fallback a volumen local.
 
### 4. Tabla de Países (`Country`)
**Pregunta:** ¿Existe actualmente el modelo y tabla `country`?
*   **Observación:** En el análisis del estado actual (Sección 1) no aparece listada. Si no existe, debemos añadirla a la Fase 1 de migraciones.
* **Respuesta:** Si existe, se encuentra en la carpeta `qdoora-api/app/Models/Geograficos/Country.php`.

### 5. Sincronización de Tramos (Integridad Referencial)
**Observación:** El método `syncTramos()` utiliza `delete()` y `createMany()`. 
*   **Riesgo:** Si un tramo es eliminado y recreado con un nuevo ID, las cargas familiares existentes que apuntaban al `global_scale_tramo_id` antiguo podrían quedar huérfanas o con errores de integridad. 
*   **Sugerencia:** Implementar un "upsert" basado en el campo `code` para preservar los IDs existentes siempre que sea posible.
* **Respuesta:** Acepto tu sugerencia. Implementar un "upsert" basado en el campo `code` para preservar los IDs existentes siempre que sea posible.

### 6. Scheduler
**Observación:** Los schedulers necesitan poder recuperar perdida de información. 
*   **Riesgo:** Si no se ejecuta un scheduler, perdemos la información relativa a ese periodo. 
* **Respuesta:** Implementar un scheduler que se ejecute cada 5 minutos y que verifique si hay información pendiente de procesar. En caso de que haya información pendiente de procesar, se debe procesar la información. En caso de que no haya información pendiente de procesar, no se debe hacer nada. Esto relacionado a los parametros globales inicialmente, que son mensuales. Otra cosa, aca la UF debemos rellenar el mes completo cuando inicialicemos un mes, porque todos los 9 de cada mes se publica el mes completo de la UF 

# Implementation Plan: Integración Previred — Nómina QdoorA - claude

---

## Objetivo
Implementar la integración con Previred para nómina chilena. Genera un archivo TXT (formato separador ";", 105 campos, Versión 94, Mayo 2026) desde liquidaciones confirmadas por período. Incluye: corrección de `previred_code` según tablas de equivalencia oficiales, migraciones quirúrgicas sin duplicar columnas existentes, estados de envío con persistencia, job asíncrono con reintentos, y dashboard visual en `/nomina/previred` con badge por trabajador.

---

## Skills a Activar
`laravel-database`, `laravel-models-enums`, `laravel-services`, `laravel-controllers`, `laravel-form-requests`, `laravel-jobs-events`, `laravel-routes-middleware`, `erp-nomina-expert`, `angular-developer`, `angular-shared-components-expert`

---

## Contexto Acotado (Whitelist)

### Backend — `qdoora-api`
```
app/Enums/Nomina/EstadoLiquidacion.php
app/Enums/Nomina/ContractType.php
app/Models/Nomina/Liquidacion.php
app/Models/Nomina/EmployeeRemuneration.php
app/Models/Nomina/EmployeeProfile.php
app/Models/Nomina/EmployeeWorkContract.php
app/Models/Nomina/EmployeeFamiliarCharge.php
app/Models/Nomina/NominaCompanySettings.php
app/Models/GlobalParameter/GlobalEntity.php
app/Models/Empresa/ThirdCompany.php
app/Services/Nomina/LiquidacionService.php
app/Http/Controllers/Nomina/LiquidacionController.php
database/seeders/GlobalDataSeeder.php
app/Console/Commands/DataSyncCommand.php
routes/api.php
```

### Frontend — `fuse-starter`
```
src/app/modules/nomina/previred/   (crear)
src/app/core/services/nomina/      (añadir PreviredService)
src/app/core/interfaces/nomina/    (añadir interfaces)
```

---

## Anti-Patrones (Gotchas)

1. **`tipo_jornada` ya existe** como `work_schedule` (enum COMPLETA/PARCIAL) en `rem_employee_work_contracts`. **NO agregar columna nueva.** El mapper mapea: COMPLETA→1, PARCIAL→2 (Tabla N°22).
2. **`family_allowance_tramo` ya existe** en `rem_employee_remunerations` (string, A/B/C/D). Usarlo directamente para campo 18. **NO recalcular desde imponible.**
3. **MUTUAL va en `rem_company_settings`** con `feature_key='MUTUAL'` y `config={"codigo_empleador":"1","third_company_id":20,"porcentaje_tasa_adicional":1}`. **NO agregar columna en `companies`.**
4. **Path para `previred_code` de AFP/SALUD/MUTUAL**: `ThirdCompany → standardEntity (GlobalEntity) → previred_code`. El executor debe leer el modelo ThirdCompany para confirmar el nombre exacto de la FK (`standard_entity_id` o similar) antes de implementar el mapper.
5. **Códigos SALUD incorrectos en BD**: `global_entities.previred_code` usa códigos SII (Banmedica='99'). **Migración M1 OBLIGATORIA** antes de generar el primer archivo.
6. **Campos numéricos Previred son enteros sin decimales**: `intval(round($monto))`. Sin ceros iniciales.
7. **Formato período**: `mmaaaa` (ej: `062026`), no `YYYY-MM`. Transformar siempre.
8. **Separador es ";"**. Nunca tabulación ni coma.
9. **Los 105 campos son OBLIGATORIOS** aunque sean cero o string vacío. Nunca omitir ni acortar el array.
10. **Cotización Mutual**: `imponible × (tasa_base + porcentaje_tasa_adicional) / 100`. `porcentaje_tasa_adicional` viene del config en `rem_company_settings`. La `tasa_base` viene de `GlobalVariable`.
11. **Campo 94 (Expectativa Vida 0.9%)**: vigencia agosto 2026 → enviar `0` hasta entonces.
12. **Job**: `tries=3`, `backoff=[60,120,300]`. Si falla 3 veces → `status=ERROR` en submission.
13. **Solo liquidaciones `CONFIRMADA`** pueden incluirse. El status `CONFIRMADA` se añade al enum `EstadoLiquidacion`.
14. NO leer `vendor/`, `node_modules/`, `.angular/`, `dist/`, `deploy/`.

---

## Diagnóstico de BD — Estado Actual vs Requerimientos Previred

| Campo Previred | Estado actual en BD | Acción requerida |
|---|---|---|
| Campo 6 — Sexo (M/F) | `rem_employee_profiles.gender` ✅ | Solo mapear |
| Campo 7 — Nacionalidad (0/1) | `rem_employee_profiles.nationality_id → Country` ✅ | Mapear por nombre país |
| Campo 12 — Tipo Trabajador | No existe ❌ | Añadir `tipo_trabajador_previred` a `rem_employee_remunerations` |
| Campo 15 — Mov. Personal | `rem_employee_work_contracts.contract_type + start_date + end_date` ✅ | Lógica en mapper |
| Campo 18 — Tramo Asig. Familiar | `rem_employee_remunerations.family_allowance_tramo` ✅ | Leer directamente |
| Campo 25 — Subsidio Trab. Joven | No existe ❌ | Añadir `subsidio_trabajador_joven` a `rem_employee_profiles` |
| Campo 26 — Código AFP | `afp_id → ThirdCompany → standardEntity → GlobalEntity.previred_code` ✅ | Mapear vía relación |
| Campo 37–39 — Trabajo Pesado | No existe ❌ | Añadir 3 columnas a `rem_employee_profiles` |
| Campo 75 — Código Salud | `health_id → ThirdCompany → standardEntity → GlobalEntity.previred_code` ✅* | *Corregir valores con M1 |
| Campo 76 — FUN ISAPRE | No existe ❌ | Añadir `isapre_fun` a `rem_employee_remunerations` |
| Campo 83 — Código CCAF | No existe ❌ | Añadir `ccaf_id → global_entities` a `rem_employee_remunerations` |
| Campo 93 — Tipo Jornada | `rem_employee_work_contracts.work_schedule` (COMPLETA/PARCIAL) ✅ | Mapear COMPLETA→1, PARCIAL→2 |
| Campo 96 — Código Mutual | `rem_company_settings` (feature_key='MUTUAL', config.third_company_id) ✅ | Leer config + resolver ThirdCompany |
| Campo 99 — Sucursal Mutual | `rem_company_settings` config.codigo_empleador ✅ | Leer de config |
| Estado de envío | No existe ❌ | Nueva tabla + columnas en liquidaciones |

---

## Plan de Ejecución Granular (Builder — TDD)

---

### FASE 1 — BACKEND

---

#### [1.1] Nuevos Enums

- [ ] **1.1.1** Crear `app/Enums/Nomina/EstadoPreviredSubmission.php`
```php
<?php
namespace App\Enums\Nomina;

enum EstadoPreviredSubmission: string
{
    case PENDIENTE  = 'PENDIENTE';
    case GENERANDO  = 'GENERANDO';
    case COMPLETADO = 'COMPLETADO';
    case ERROR      = 'ERROR';
}
```

- [ ] **1.1.2** Crear `app/Enums/Nomina/EstadoLiquidacionPrevired.php`
```php
<?php
namespace App\Enums\Nomina;

enum EstadoLiquidacionPrevired: string
{
    case PENDIENTE = 'PENDIENTE';
    case INCLUIDA  = 'INCLUIDA';
    case ERROR     = 'ERROR';
}
```

- [ ] **1.1.3** Crear `app/Enums/Nomina/TipoTrabajadorPrevired.php`
```php
<?php
namespace App\Enums\Nomina;

// Fuente: Previred Tabla N°5 — Tipo de Trabajador
enum TipoTrabajadorPrevired: int
{
    case ACTIVO                       = 0; // Activo (No pensionado)
    case PENSIONADO_COTIZA            = 1; // Pensionado y cotiza
    case PENSIONADO_NO_COTIZA         = 2; // Pensionado y No Cotiza / Invalidez Total
    case ACTIVO_65                    = 3; // Activo desde los 65 años (Nunca Pensionado)
    case EXENTO                       = 8; // Mujer ≥60, Hombre ≥65 o Extranjero
    case PENSIONADO_INVALIDEZ_PARCIAL = 9;
}
```

- [ ] **1.1.4** Editar `app/Enums/Nomina/EstadoLiquidacion.php` — añadir el caso:
```php
case CONFIRMADA = 'CONFIRMADA';
```

---

#### [1.2] Migración M1 — Sincronizar `previred_code` en `global_entities`

> Corrige AFP (Tabla N°10), SALUD (Tabla N°16) y MUTUAL (Tabla N°19). Los valores de SALUD actualmente son incorrectos (usan códigos SII).

- [ ] **1.2.1** Crear `database/migrations/2026_06_12_000001_sync_previred_codes_in_global_entities.php`
```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // ── AFP — Tabla N°10 ──────────────────────────────────────────────
        // Cód  Institución
        //  00  no está en AFP
        //  03  Cuprum
        //  05  Habitat
        //  08  Provida
        //  29  PlanVital
        //  33  Capital
        //  34  Modelo
        //  35  Uno
        foreach ([
            'Cuprum'    => '03', 'Habitat'   => '05',
            'Provida'   => '08', 'Planvital' => '29', 'PlanVital' => '29',
            'Capital'   => '33', 'Modelo'    => '34', 'Uno'       => '35',
            'Ninguna'   => '00', 'Sin AFP'   => '00',
        ] as $nombre => $codigo) {
            DB::table('global_entities')
                ->where('category', 'AFP')
                ->whereRaw('LOWER(name) = LOWER(?)', [$nombre])
                ->update(['previred_code' => $codigo]);
        }

        // ── SALUD — Tabla N°16 ────────────────────────────────────────────
        // Cód  Institución
        //  00  Sin Isapre
        //  01  Banmédica
        //  02  Consalud
        //  03  VidaTres
        //  04  Colmena
        //  05  Cruz Blanca
        //  07  Fonasa
        //  10  Nueva Masvida
        //  11  Isalud
        //  12  Fundación
        //  25  Cruz del Norte
        //  28  Esencial
        foreach ([
            'Banmédica'      => '01', 'Banmedica'      => '01',
            'Consalud'       => '02', 'VidaTres'       => '03', 'Vida Tres'      => '03',
            'Colmena'        => '04', 'Cruz Blanca'    => '05', 'Fonasa'         => '07',
            'Nueva Masvida'  => '10', 'Isalud'         => '11',
            'Fundación'      => '12', 'Fundacion'      => '12',
            'Cruz del Norte' => '25', 'Esencial'       => '28', 'Sin Isapre'     => '00',
        ] as $nombre => $codigo) {
            DB::table('global_entities')
                ->where('category', 'SALUD')
                ->whereRaw('LOWER(name) = LOWER(?)', [$nombre])
                ->update(['previred_code' => $codigo]);
        }

        // ── MUTUAL — Tabla N°19 ───────────────────────────────────────────
        // Cód  Institución
        //  00  Sin Mutual (empresa aporta al ISL)
        //  01  Asociación Chilena de Seguridad (ACHS)
        //  02  Mutual de Seguridad CCHC
        //  03  Instituto de Seguridad del Trabajo I.S.T.
        foreach ([
            'Sin Mutual'                         => '00',
            'ISL'                                => '00',
            'Instituto de Seguridad Laboral'     => '00',
            'ACHS'                               => '01',
            'Asociación Chilena de Seguridad'    => '01',
            'Asociacion Chilena de Seguridad'    => '01',
            'Mutual de Seguridad CCHC'           => '02',
            'Mutual de Seguridad'                => '02',
            'IST'                                => '03',
            'Instituto de Seguridad del Trabajo' => '03',
        ] as $nombre => $codigo) {
            DB::table('global_entities')
                ->where('category', 'MUTUAL')
                ->whereRaw('LOWER(name) = LOWER(?)', [$nombre])
                ->update(['previred_code' => $codigo]);
        }
    }

    public function down(): void {} // No reversión automática
};
```

---

#### [1.3] Migración M2 — Insertar CCAF en `global_entities` (Tabla N°18)

> Crea la categoría `CCAF` que no existe actualmente en `global_entities`.

- [ ] **1.3.1** Crear `database/migrations/2026_06_12_000002_add_ccaf_entities_to_global_entities.php`
```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    // Fuente: Previred Tabla N°18 — Códigos CCAF
    // Cód  Institución
    //  00  Sin CCAF
    //  01  Los Andes
    //  02  La Araucana
    //  03  Los Héroes
    //  04  18 de Septiembre
    public function up(): void
    {
        foreach ([
            '00' => 'Sin CCAF',
            '01' => 'Los Andes',
            '02' => 'La Araucana',
            '03' => 'Los Héroes',
            '04' => '18 de Septiembre',
        ] as $codigo => $nombre) {
            DB::table('global_entities')->insertOrIgnore([
                'name'          => $nombre,
                'previred_code' => $codigo,
                'category'      => 'CCAF',
                'is_active'     => true,
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);
        }
    }

    public function down(): void
    {
        DB::table('global_entities')->where('category', 'CCAF')->delete();
    }
};
```

---

#### [1.4] Migración M3 — Campos Previred en `rem_employee_remunerations`

> **`tipo_jornada` NO se agrega aquí** — ya existe como `work_schedule` en `rem_employee_work_contracts`.

- [ ] **1.4.1** Crear `database/migrations/2026_06_12_000003_add_previred_fields_to_employee_remunerations.php`
```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rem_employee_remunerations', function (Blueprint $table) {
            // CCAF del trabajador → global_entities (category=CCAF, Tabla N°18)
            // FK a global_entities porque CCAF son datos de referencia estáticos (4 opciones).
            $table->unsignedBigInteger('ccaf_id')->nullable()->after('health_id');
            $table->foreign('ccaf_id')->references('id')->on('global_entities')->nullOnDelete();

            // Tipo de trabajador para Previred (Tabla N°5). Default 0 = Activo.
            $table->tinyInteger('tipo_trabajador_previred')->default(0)->after('ccaf_id');

            // N° contrato de salud con ISAPRE (FUN) — campo 76 Previred.
            $table->string('isapre_fun', 16)->nullable()->after('tipo_trabajador_previred');
        });
    }

    public function down(): void
    {
        Schema::table('rem_employee_remunerations', function (Blueprint $table) {
            $table->dropForeign(['ccaf_id']);
            $table->dropColumn(['ccaf_id', 'tipo_trabajador_previred', 'isapre_fun']);
        });
    }
};
```

---

#### [1.5] Migración M4 — Campos Previred en `rem_employee_profiles`

- [ ] **1.5.1** Crear `database/migrations/2026_06_12_000004_add_previred_fields_to_employee_profiles.php`
```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rem_employee_profiles', function (Blueprint $table) {
            // Trabajo Pesado — campos 37 (descripción puesto), 38 (%), 39 ($) Previred.
            // Porcentajes válidos según Previred: 2.00 o 4.00.
            $table->boolean('trabajo_pesado')->default(false)->after('direct_boss');
            $table->string('puesto_trabajo_pesado', 40)->nullable()->after('trabajo_pesado');
            $table->decimal('porcentaje_trabajo_pesado', 5, 2)->nullable()->after('puesto_trabajo_pesado');

            // Subsidio Trabajador Joven — campo 25 Previred (Tabla N°9: S/N).
            $table->boolean('subsidio_trabajador_joven')->default(false)->after('porcentaje_trabajo_pesado');
        });
    }

    public function down(): void
    {
        Schema::table('rem_employee_profiles', function (Blueprint $table) {
            $table->dropColumn([
                'trabajo_pesado', 'puesto_trabajo_pesado',
                'porcentaje_trabajo_pesado', 'subsidio_trabajador_joven',
            ]);
        });
    }
};
```

---

#### [1.6] Migración M5 — Tabla `rem_previred_submissions`

- [ ] **1.6.1** Crear `database/migrations/2026_06_12_000005_create_rem_previred_submissions_table.php`
```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rem_previred_submissions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->foreign('company_id')->references('id')->on('companies')->cascadeOnDelete();
            $table->string('period', 7);                        // YYYY-MM
            $table->string('status', 20)->default('PENDIENTE'); // EstadoPreviredSubmission
            $table->string('file_path', 500)->nullable();       // ruta relativa en S3
            $table->unsignedInteger('total_workers')->default(0);
            $table->unsignedInteger('workers_included')->default(0);
            $table->unsignedInteger('workers_with_error')->default(0);
            $table->text('error_message')->nullable();
            $table->unsignedTinyInteger('retry_count')->default(0);
            $table->timestamp('last_retry_at')->nullable();
            $table->unsignedBigInteger('submitted_by')->nullable();
            $table->foreign('submitted_by')->references('id')->on('users')->nullOnDelete();
            $table->timestamp('submitted_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['company_id', 'period']);
            $table->index(['company_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rem_previred_submissions');
    }
};
```

---

#### [1.7] Migración M6 — Campos Previred en `rem_liquidaciones`

- [ ] **1.7.1** Crear `database/migrations/2026_06_12_000006_add_previred_fields_to_liquidaciones.php`
```php
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('rem_liquidaciones', function (Blueprint $table) {
            $table->string('previred_status', 20)->default('PENDIENTE')->after('integration_error');
            $table->unsignedBigInteger('previred_submission_id')->nullable()->after('previred_status');
            $table->foreign('previred_submission_id')
                  ->references('id')->on('rem_previred_submissions')->nullOnDelete();
            $table->text('previred_error')->nullable()->after('previred_submission_id');
            $table->timestamp('previred_included_at')->nullable()->after('previred_error');

            $table->index(['company_id', 'period', 'previred_status']);
        });
    }

    public function down(): void
    {
        Schema::table('rem_liquidaciones', function (Blueprint $table) {
            $table->dropForeign(['previred_submission_id']);
            $table->dropColumn([
                'previred_status', 'previred_submission_id',
                'previred_error', 'previred_included_at',
            ]);
        });
    }
};
```

---

#### [1.8] Modelo `PreviredSubmission`

- [ ] **1.8.1** Crear `app/Models/Nomina/PreviredSubmission.php`
```php
<?php
namespace App\Models\Nomina;

use App\Enums\Nomina\EstadoPreviredSubmission;
use App\Models\Company;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PreviredSubmission extends Model
{
    use SoftDeletes;

    protected $table = 'rem_previred_submissions';

    protected $fillable = [
        'company_id', 'period', 'status', 'file_path',
        'total_workers', 'workers_included', 'workers_with_error',
        'error_message', 'retry_count', 'last_retry_at',
        'submitted_by', 'submitted_at',
    ];

    protected $casts = [
        'status'             => EstadoPreviredSubmission::class,
        'submitted_at'       => 'datetime',
        'last_retry_at'      => 'datetime',
        'total_workers'      => 'integer',
        'workers_included'   => 'integer',
        'workers_with_error' => 'integer',
        'retry_count'        => 'integer',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class);
    }

    public function liquidaciones(): HasMany
    {
        return $this->hasMany(Liquidacion::class, 'previred_submission_id');
    }

    public function scopeForCompany($query, int $companyId)
    {
        return $query->where('company_id', $companyId);
    }

    public function isRetryable(): bool
    {
        return $this->status === EstadoPreviredSubmission::ERROR
            && $this->retry_count < 3;
    }
}
```

---

#### [1.9] Actualizar `app/Models/Nomina/Liquidacion.php`

- [ ] **1.9.1** Añadir al `$fillable`:
```php
'previred_status', 'previred_submission_id', 'previred_error', 'previred_included_at',
```

- [ ] **1.9.2** Añadir al `$casts`:
```php
'previred_status'      => \App\Enums\Nomina\EstadoLiquidacionPrevired::class,
'previred_included_at' => 'datetime',
```

- [ ] **1.9.3** Añadir relación y scope:
```php
public function previredSubmission(): \Illuminate\Database\Eloquent\Relations\BelongsTo
{
    return $this->belongsTo(PreviredSubmission::class, 'previred_submission_id');
}

public function scopeConfirmadas($query)
{
    return $query->where('status', \App\Enums\Nomina\EstadoLiquidacion::CONFIRMADA);
}
```

---

#### [1.10] Actualizar `app/Models/Nomina/EmployeeRemuneration.php`

- [ ] **1.10.1** Añadir al `$fillable`:
```php
'ccaf_id', 'tipo_trabajador_previred', 'isapre_fun',
```

- [ ] **1.10.2** Añadir al `$casts`:
```php
'tipo_trabajador_previred' => \App\Enums\Nomina\TipoTrabajadorPrevired::class,
```

- [ ] **1.10.3** Añadir relación CCAF:
```php
public function ccaf(): \Illuminate\Database\Eloquent\Relations\BelongsTo
{
    return $this->belongsTo(\App\Models\GlobalParameter\GlobalEntity::class, 'ccaf_id');
}
```

---

#### [1.11] `PreviredFieldMapperService`

> **ACCIÓN PREVIA DEL EXECUTOR**:
> 1. Leer `app/Models/Empresa/ThirdCompany.php` y confirmar el nombre de la FK a `GlobalEntity` (`standard_entity_id`, `global_entity_id` u otro). Ajustar `getPreviredCodeDesdeThirdCompany()`.
> 2. Leer `app/Models/Nomina/NominaCompanySettings.php` para confirmar el método de acceso al `config` JSONB.

- [ ] **1.11.1** Crear `app/Services/Nomina/PreviredFieldMapperService.php`
```php
<?php
namespace App\Services\Nomina;

use App\Models\Nomina\Liquidacion;
use App\Models\Nomina\NominaCompanySettings;
use Illuminate\Support\Facades\DB;

class PreviredFieldMapperService
{
    /**
     * Mapea una Liquidacion a los 105 campos del formato Previred Versión 94.
     *
     * Relaciones requeridas cargadas en $liquidacion:
     *   thirdCompany
     *   thirdCompany.employeeProfile.nationality
     *   thirdCompany.employeeRemuneration.afp.standardEntity       (GlobalEntity, category=AFP)
     *   thirdCompany.employeeRemuneration.health.standardEntity     (GlobalEntity, category=SALUD)
     *   thirdCompany.employeeRemuneration.ccaf                     (GlobalEntity, category=CCAF)
     *   thirdCompany.employeeFamiliarCharges
     *   thirdCompany.activeWorkContract.costCenter
     */
    public function map(Liquidacion $liquidacion): array
    {
        $employee = $liquidacion->thirdCompany;
        $profile  = $employee->employeeProfile;
        $remu     = $employee->employeeRemuneration;
        $contract = $employee->activeWorkContract;
        $charges  = $employee->employeeFamiliarCharges ?? collect();

        [$rut, $dv] = $this->parseRut($employee->rut ?? '');
        $periodo     = $this->formatPeriod($liquidacion->period);

        // ── Códigos institucionales ───────────────────────────────────────
        // AFP: ThirdCompany → standardEntity (GlobalEntity, category=AFP) → Tabla N°10
        $codigoAfp   = $this->getPreviredCodeDesdeThirdCompany($remu?->afp) ?? '00';

        // SALUD: ThirdCompany → standardEntity (GlobalEntity, category=SALUD) → Tabla N°16
        $codigoSalud = $this->getPreviredCodeDesdeThirdCompany($remu?->health) ?? '00';
        $esFonasa    = $codigoSalud === '07';

        // CCAF: GlobalEntity directamente via ccaf_id → Tabla N°18
        $codigoCcaf  = $remu?->ccaf?->previred_code ?? '00';

        // MUTUAL: rem_company_settings (feature_key='MUTUAL') → config JSON → Tabla N°19
        [$codigoMutual, $sucursalMutual, $tasaAdicionalMutual] =
            $this->getMutualConfig($liquidacion->company_id);

        // ── Montos (enteros sin decimales) ────────────────────────────────
        $imponible      = intval(round($liquidacion->imponible_total ?? 0));
        $afpTrabajador  = intval(round($liquidacion->afp_trabajador ?? 0));
        $sis            = intval(round($liquidacion->sis_empleador ?? 0));
        $saludTotal     = intval(round($liquidacion->salud_total ?? 0));
        $afcTrabajador  = intval(round($liquidacion->afc_trabajador ?? 0));
        $afcEmpleador   = intval(round($liquidacion->afc_empleador ?? 0));

        // ── Cotización Mutual (campo 98) ──────────────────────────────────
        // tasa_base (GlobalVariable) + porcentaje_tasa_adicional (del config de la empresa)
        $cotizMutual = $codigoMutual !== '00'
            ? $this->calcularCotizMutual($imponible, $tasaAdicionalMutual)
            : 0;

        // ── Campo 18: Tramo Asig. Familiar ────────────────────────────────
        // Calculado en liquidación y guardado en rem_employee_remunerations.family_allowance_tramo
        $tramoCarga = $remu?->family_allowance_tramo ?? 'D';

        // ── Cargas familiares (campos 19–21) ──────────────────────────────
        $cargasSimples    = $charges->where('type', 'SIMPLE')->count();
        $cargasMaternales = $charges->where('type', 'MATERNAL')->count();
        $cargasInvalidas  = $charges->where('type', 'INVALIDA')->count();

        // ── Campo 15: Movimiento Personal (Tabla N°7) ────────────────────
        $movimiento = $this->determinarMovimiento($contract, $liquidacion->period);

        // ── Campos 37–39: Trabajo Pesado ──────────────────────────────────
        $trabajoPesado      = (bool) ($profile?->trabajo_pesado ?? false);
        $puestoPesado       = mb_substr($profile?->puesto_trabajo_pesado ?? '', 0, 40);
        $pctPesado          = $trabajoPesado
            ? number_format((float) ($profile->porcentaje_trabajo_pesado ?? 2), 2, ',', '')
            : '00,00';
        $cotizPesado        = $trabajoPesado
            ? intval(round($imponible * (floatval($profile->porcentaje_trabajo_pesado ?? 2) / 100)))
            : 0;

        // ── Datos ISAPRE (campos 77–80) ───────────────────────────────────
        $rentaIsapre = $monedaIsapre = '';
        $cotizPactada = $cotizObligIsapre = 0;
        $rentaIsapre  = 0;
        if (!$esFonasa && $remu) {
            $rentaIsapre      = $imponible;
            $monedaIsapre     = '1';                              // 1=Pesos (Tabla N°17)
            $cotizObligIsapre = $saludTotal;
            $adicional        = floatval($remu->health_additional_amount ?? 0);
            if ($remu->health_payment_unit === 'UF') {
                $adicional *= floatval($liquidacion->uf_valor ?? 1);
            }
            $cotizPactada = intval(round(($imponible * 0.07) + $adicional));
        }

        // ── Campo 90: No afiliado ISAPRE (4.2% si Fonasa + tiene CCAF) ───
        $cotizNoAfiliadoIsapre = ($esFonasa && $codigoCcaf !== '00')
            ? intval(round($imponible * 0.042))
            : 0;

        // ── Campo 93: Tipo Jornada (Tabla N°22) ──────────────────────────
        // work_schedule en rem_employee_work_contracts: COMPLETA→1, PARCIAL→2
        $tipoJornada = match (strtoupper($contract?->work_schedule ?? 'COMPLETA')) {
            'PARCIAL' => 2,
            default   => 1,
        };

        // ── Campo 25: Subsidio Trabajador Joven (Tabla N°9: S/N) ─────────
        $subsidioJoven = ($profile?->subsidio_trabajador_joven ?? false) ? 'S' : 'N';

        // ── Campo 7: Nacionalidad (Tabla N°2: 0=Chileno, 1=Extranjero) ───
        $countryName  = strtolower($profile?->nationality?->name ?? 'chile');
        $nacionalidad = str_contains($countryName, 'chile') ? 0 : 1;

        $fields = [
            // ── Sección 1: Datos del Trabajador (1–25) ───────────────────
            $rut,                                              // 1  RUT (sin puntos, sin DV)
            $dv,                                               // 2  DV Verificador
            mb_strtoupper($this->getApellidoPaterno($employee)), // 3  Apellido Paterno (≤30)
            mb_strtoupper($this->getApellidoMaterno($employee)), // 4  Apellido Materno (≤30)
            mb_strtoupper($this->getNombres($employee)),        // 5  Nombres (≤30)
            $profile?->gender ?? 'M',                          // 6  Sexo M/F — Tabla N°1
            $nacionalidad,                                     // 7  Nacionalidad 0/1 — Tabla N°2
            '01',                                              // 8  Tipo Pago — Tabla N°3 (01=Remuneraciones)
            $periodo,                                          // 9  Período Desde (mmaaaa)
            $periodo,                                          // 10 Período Hasta (mmaaaa)
            'AFP',                                             // 11 Régimen Previsional — Tabla N°4
            $remu?->tipo_trabajador_previred?->value ?? 0,    // 12 Tipo Trabajador — Tabla N°5
            $liquidacion->dias_trabajados ?? 0,               // 13 Días Trabajados (0–30)
            '00',                                              // 14 Tipo de Línea — Tabla N°6 (00=Principal)
            $movimiento['codigo'],                             // 15 Cód. Movimiento Personal — Tabla N°7
            $movimiento['fecha_desde'],                        // 16 Fecha Desde (dd-mm-aaaa, condicional)
            $movimiento['fecha_hasta'],                        // 17 Fecha Hasta (condicional)
            $tramoCarga,                                       // 18 Tramo A.F. A/B/C/D — Tabla N°8
            $cargasSimples,                                    // 19 N° Cargas Simples
            $cargasMaternales,                                 // 20 N° Cargas Maternales
            $cargasInvalidas,                                  // 21 N° Cargas Inválidas
            0,                                                 // 22 Asignación Familiar ($)
            0,                                                 // 23 Asignación Retroactiva
            0,                                                 // 24 Reintegro Cargas Familiares
            $subsidioJoven,                                    // 25 Subsidio Trab. Joven S/N — Tabla N°9

            // ── Sección 2: Datos AFP (26–39) ─────────────────────────────
            $codigoAfp,                                        // 26 Código AFP — Tabla N°10
            $imponible,                                        // 27 Renta Imponible AFP ($)
            $afpTrabajador,                                    // 28 Cotización Obligatoria AFP ($)
            $sis,                                              // 29 SIS cargo empleador ($)
            0,                                                 // 30 Ahorro Voluntario AFP
            0,                                                 // 31 Renta Imp. Sustitutiva
            '00,00',                                           // 32 Tasa Pactada Sustitutiva
            0,                                                 // 33 Aporte Indemnización Sustitutiva
            0,                                                 // 34 N° Períodos Sustitutiva
            '',                                                // 35 Período desde Sustitutiva
            '',                                                // 36 Período hasta Sustitutiva
            $puestoPesado,                                     // 37 Puesto Trabajo Pesado (≤40)
            $pctPesado,                                        // 38 % Cotización Trabajo Pesado (02,00 ó 04,00)
            $cotizPesado,                                      // 39 Cotización Trabajo Pesado ($)

            // ── Sección 3: APV Individual (40–44) ────────────────────────
            '000', '', '', 0, 0,

            // ── Sección 4: APV Colectivo (45–49) ─────────────────────────
            '000', '', '', 0, 0,

            // ── Sección 5: Afiliado Voluntario (50–61) ───────────────────
            '', '', '', '', '', '', '', '', '', 0, 0, 0,

            // ── Sección 6: IPS/ISL/Fonasa (62–74) ────────────────────────
            '0000',                                            // 62 Código Ex-Caja — Tabla N°14 (0000=no IPS)
            '00,00',                                           // 63 Tasa Cotización Ex-Caja
            0,                                                 // 64 Renta Imponible IPS/ISL/Fonasa
            0,                                                 // 65 Cotización Obligatoria IPS
            0,                                                 // 66 Renta Imponible Desahucio
            '0000',                                            // 67 Código Ex-Caja Desahucio — Tabla N°15
            '00,00',                                           // 68 Tasa Cotización Desahucio
            0,                                                 // 69 Cotización Desahucio
            $esFonasa ? $saludTotal : 0,                       // 70 Cotización Fonasa (solo si código='07')
            0,                                                 // 71 Cotización ACC Trabajo ISL
            0,                                                 // 72 Bonificación Ley 15386
            0,                                                 // 73 Descuento Cargas IPS
            0,                                                 // 74 Bono Gobierno

            // ── Sección 7: Datos Salud (75–82) ───────────────────────────
            $codigoSalud,                                      // 75 Código Institución Salud — Tabla N°16
            $remu?->isapre_fun ?? '',                          // 76 N° FUN (contrato ISAPRE)
            $rentaIsapre,                                      // 77 Renta Imponible ISAPRE ($)
            $monedaIsapre,                                     // 78 Moneda Plan ISAPRE — Tabla N°17
            $cotizPactada,                                     // 79 Cotización Pactada ISAPRE ($)
            $cotizObligIsapre,                                 // 80 Cotización Obligatoria ISAPRE (7%)
            0,                                                 // 81 Cotización Adicional Voluntaria ISAPRE
            0,                                                 // 82 GES (uso futuro)

            // ── Sección 8: Datos CCAF (83–95) ────────────────────────────
            $codigoCcaf,                                       // 83 Código CCAF — Tabla N°18
            $imponible,                                        // 84 Renta Imponible CCAF ($)
            0,                                                 // 85 Créditos Personales
            0,                                                 // 86 Convenio Dental
            0,                                                 // 87 Descuentos Leasing
            0,                                                 // 88 Seguros de Vida
            0,                                                 // 89 Otros CCAF
            $cotizNoAfiliadoIsapre,                            // 90 Cotiz. no afiliado ISAPRE (4.2% si Fonasa+CCAF)
            0,                                                 // 91 Desc. Cargas Familiares CCAF
            0,                                                 // 92 RIMA
            $tipoJornada,                                      // 93 Tipo Jornada — Tabla N°22 (OBLIGATORIO)
            0,                                                 // 94 Cotiz. Expectativa Vida (vigencia ago 2026)
            0,                                                 // 95 Cotiz. Rentabilidad Protegida

            // ── Sección 9: Datos Mutualidad (96–99) ──────────────────────
            $codigoMutual,                                     // 96 Código Mutualidad — Tabla N°19
            $codigoMutual !== '00' ? $imponible : 0,          // 97 Renta Imponible Mutual ($)
            $cotizMutual,                                      // 98 Cotización Accidente Trabajo ($)
            $codigoMutual !== '00' ? $sucursalMutual : 0,     // 99 Sucursal para pago Mutual

            // ── Sección 10: AFC Seguro Cesantía (100–102) ────────────────
            $imponible,                                        // 100 Renta Imponible Seguro Cesantía ($)
            $afcTrabajador,                                    // 101 Aporte Trabajador SC ($)
            $afcEmpleador,                                     // 102 Aporte Empleador SC ($)

            // ── Sección 11: Pagador Subsidios (103–104) ──────────────────
            0,                                                 // 103 RUT Pagadora Subsidio — Tabla N°20
            0,                                                 // 104 DV Pagadora Subsidio

            // ── Sección 12: Centro de Costos (105) ───────────────────────
            mb_substr($contract?->costCenter?->name ?? '', 0, 20), // 105
        ];

        if (count($fields) !== 105) {
            throw new \RuntimeException(
                'PreviredFieldMapper generó ' . count($fields) . ' campos; se esperaban 105.'
            );
        }

        return $fields;
    }

    // ── Helpers privados ──────────────────────────────────────────────────

    /**
     * Obtiene el previred_code de una entidad institucional (AFP, SALUD, MUTUAL)
     * a través del ThirdCompany que la representa.
     *
     * EXECUTOR: Confirmar nombre FK en ThirdCompany → GlobalEntity.
     * Opciones comunes: standardEntity(), globalEntity(), standard_entity_id.
     */
    private function getPreviredCodeDesdeThirdCompany($thirdCompany): ?string
    {
        if (!$thirdCompany) return null;
        return $thirdCompany->standardEntity?->previred_code
            ?? $thirdCompany->globalEntity?->previred_code
            ?? $thirdCompany->previred_code
            ?? null;
    }

    /**
     * Lee la configuración de Mutual desde rem_company_settings (feature_key='MUTUAL').
     * Config: {"codigo_empleador":"1","third_company_id":20,"porcentaje_tasa_adicional":1}
     *
     * Retorna [$codigoMutual, $sucursalMutual, $tasaAdicional].
     */
    private function getMutualConfig(int $companyId): array
    {
        $settings = NominaCompanySettings::where('company_id', $companyId)
            ->where('feature_key', 'MUTUAL')
            ->where('is_active', true)
            ->first();

        if (!$settings || empty($settings->config)) {
            return ['00', '0', 0.0];
        }

        $config = is_array($settings->config) ? $settings->config : json_decode($settings->config, true);

        $mutualThirdCompany = $config['third_company_id']
            ? \App\Models\Empresa\ThirdCompany::find($config['third_company_id'])
            : null;

        $codigoMutual = $this->getPreviredCodeDesdeThirdCompany($mutualThirdCompany) ?? '00';
        $sucursal     = (string) ($config['codigo_empleador'] ?? '0');
        $tasaAdicional = floatval($config['porcentaje_tasa_adicional'] ?? 0);

        return [$codigoMutual, $sucursal, $tasaAdicional];
    }

    private function calcularCotizMutual(int $imponible, float $tasaAdicional): int
    {
        $tasaBase = DB::table('global_variables as gv')
            ->join('global_dictionary_definitions as gdd', 'gv.definition_id', '=', 'gdd.id')
            ->where('gdd.key', 'mutual.tasa_base')
            ->value('gv.value');

        $tasaTotal = floatval($tasaBase ?? 0.90) + $tasaAdicional;
        return intval(round($imponible * $tasaTotal / 100));
    }

    private function parseRut(string $rut): array
    {
        $rut = str_replace(['.', ' '], '', trim($rut));
        if (str_contains($rut, '-')) {
            [$numero, $dv] = explode('-', $rut, 2);
            return [$numero, strtoupper($dv)];
        }
        return [substr($rut, 0, -1), strtoupper(substr($rut, -1))];
    }

    private function formatPeriod(string $period): string
    {
        // YYYY-MM → mmaaaa  (2026-06 → 062026)
        [$year, $month] = explode('-', $period);
        return str_pad($month, 2, '0', STR_PAD_LEFT) . $year;
    }

    private function getApellidoPaterno($employee): string
    {
        return $employee->last_name ?? $employee->apellido_paterno
            ?? explode(' ', $employee->name ?? '')[0] ?? '';
    }

    private function getApellidoMaterno($employee): string
    {
        return $employee->second_last_name ?? $employee->apellido_materno ?? '';
    }

    private function getNombres($employee): string
    {
        if (!empty($employee->first_name)) {
            return trim($employee->first_name . ' ' . ($employee->middle_name ?? ''));
        }
        return $employee->name ?? '';
    }

    private function determinarMovimiento($contract, string $period): array
    {
        if (!$contract) return ['codigo' => '0', 'fecha_desde' => '', 'fecha_hasta' => ''];

        [$year, $month] = explode('-', $period);
        $inicio = \Carbon\Carbon::createFromDate((int)$year, (int)$month, 1)->startOfMonth();
        $fin    = $inicio->copy()->endOfMonth();

        $startDate = $contract->start_date ? \Carbon\Carbon::parse($contract->start_date) : null;
        $endDate   = $contract->end_date   ? \Carbon\Carbon::parse($contract->end_date)   : null;

        // Tabla N°7: código 2 = Retiro
        if ($endDate && $endDate->between($inicio, $fin)) {
            return ['codigo' => '2', 'fecha_desde' => $endDate->format('d-m-Y'), 'fecha_hasta' => $endDate->format('d-m-Y')];
        }

        // Tabla N°7: 1=Indefinido, 7=Plazo Fijo, 8=Cambio Plazo Fijo→Indefinido
        if ($startDate && $startDate->between($inicio, $fin)) {
            $codigo = match ($contract->contract_type?->value ?? '') {
                'PLAZO_FIJO'                     => '7',
                'CAMBIO_PLAZO_FIJO_A_INDEFINIDO' => '8',
                default                          => '1',
            };
            return ['codigo' => $codigo, 'fecha_desde' => $startDate->format('d-m-Y'), 'fecha_hasta' => ''];
        }

        return ['codigo' => '0', 'fecha_desde' => '', 'fecha_hasta' => ''];
    }
}
```

---

#### [1.12] `PreviredFileBuilderService`

- [ ] **1.12.1** Crear `app/Services/Nomina/PreviredFileBuilderService.php`
```php
<?php
namespace App\Services\Nomina;

class PreviredFileBuilderService
{
    private const SEPARATOR = ';';

    /** Construye el TXT completo. Separador ";", CRLF entre líneas. */
    public function build(array $rows): string
    {
        $lines = array_map(
            fn($fields) => implode(self::SEPARATOR, array_map(fn($v) => $this->sanitize($v), $fields)),
            $rows
        );
        return implode("\r\n", $lines) . "\r\n";
    }

    private function sanitize(mixed $value): string
    {
        if ($value === null || $value === '') return '';
        return trim(str_replace([';', "\r", "\n"], '', (string) $value));
    }

    public function getFilename(int $companyId, string $period): string
    {
        [$year, $month] = explode('-', $period);
        return "previred_{$companyId}_{$month}{$year}.txt";
    }
}
```

---

#### [1.13] `PreviredService`

- [ ] **1.13.1** Crear `app/Services/Nomina/PreviredService.php`
```php
<?php
namespace App\Services\Nomina;

use App\Enums\Nomina\EstadoLiquidacion;
use App\Enums\Nomina\EstadoLiquidacionPrevired;
use App\Enums\Nomina\EstadoPreviredSubmission;
use App\Models\Nomina\Liquidacion;
use App\Models\Nomina\PreviredSubmission;
use App\Services\Shared\LoggerService;
use App\Services\Shared\S3FileService;
use Illuminate\Support\Facades\DB;

class PreviredService
{
    public function __construct(
        private readonly PreviredFieldMapperService $mapper,
        private readonly PreviredFileBuilderService $builder,
        private readonly S3FileService $s3,
        private readonly LoggerService $logger,
    ) {}

    public function getLiquidacionesParaPrevired(int $companyId, string $period): array
    {
        return Liquidacion::with(['thirdCompany', 'thirdCompany.employeeProfile'])
            ->where('company_id', $companyId)
            ->where('period', $period)
            ->orderBy('id')
            ->get()
            ->map(fn($l) => [
                'id'                   => $l->id,
                'employee_name'        => $l->thirdCompany?->name,
                'employee_rut'         => $l->thirdCompany?->rut,
                'dias_trabajados'      => $l->dias_trabajados,
                'imponible_total'      => $l->imponible_total,
                'haberes_total'        => $l->haberes_total,
                'descuentos_total'     => $l->descuentos_total,
                'liquid_total'         => $l->liquid_total,
                'status'               => $l->status,
                'previred_status'      => $l->previred_status,
                'previred_error'       => $l->previred_error,
                'previred_included_at' => $l->previred_included_at,
            ])->toArray();
    }

    public function getSubmissions(int $companyId): array
    {
        return PreviredSubmission::forCompany($companyId)
            ->orderByDesc('created_at')->get()->toArray();
    }

    public function initiate(int $companyId, string $period, int $userId): PreviredSubmission
    {
        $submission = DB::transaction(fn() => PreviredSubmission::create([
            'company_id'   => $companyId,
            'period'       => $period,
            'status'       => EstadoPreviredSubmission::PENDIENTE,
            'submitted_by' => $userId,
        ]));

        \App\Jobs\Nomina\GeneratePreviredFileJob::dispatch($submission);
        return $submission;
    }

    public function generateForPeriod(PreviredSubmission $submission): void
    {
        DB::transaction(fn() => $submission->update(['status' => EstadoPreviredSubmission::GENERANDO]));

        try {
            // Carga eager completa para el mapper.
            // EXECUTOR: Confirmar nombre exacto de la relación standardEntity/globalEntity en ThirdCompany.
            $liquidaciones = Liquidacion::with([
                'thirdCompany',
                'thirdCompany.employeeProfile.nationality',
                'thirdCompany.employeeRemuneration.afp.standardEntity',
                'thirdCompany.employeeRemuneration.health.standardEntity',
                'thirdCompany.employeeRemuneration.ccaf',
                'thirdCompany.employeeFamiliarCharges',
                'thirdCompany.activeWorkContract.costCenter',
            ])
                ->where('company_id', $submission->company_id)
                ->where('period', $submission->period)
                ->where('status', EstadoLiquidacion::CONFIRMADA)
                ->get();

            $rows = $errors = [];
            $included = $withError = 0;

            foreach ($liquidaciones as $liq) {
                try {
                    $rows[] = $this->mapper->map($liq);
                    $liq->update([
                        'previred_status'        => EstadoLiquidacionPrevired::INCLUIDA,
                        'previred_submission_id'  => $submission->id,
                        'previred_error'          => null,
                        'previred_included_at'    => now(),
                    ]);
                    $included++;
                } catch (\Throwable $e) {
                    $withError++;
                    $msg = "Empleado {$liq->thirdCompany?->rut}: {$e->getMessage()}";
                    $errors[] = $msg;
                    $liq->update(['previred_status' => EstadoLiquidacionPrevired::ERROR, 'previred_error' => $msg]);
                    $this->logger->error('previred_map_error', ['liquidacion_id' => $liq->id, 'error' => $e->getMessage()]);
                }
            }

            if (empty($rows)) {
                throw new \RuntimeException('No hay liquidaciones CONFIRMADA para el período seleccionado.');
            }

            $contenido = $this->builder->build($rows);
            $filename  = $this->builder->getFilename($submission->company_id, $submission->period);
            $path      = "companies/{$submission->company_id}/previred/{$filename}";
            $this->s3->uploadContent($path, $contenido, 'text/plain');

            DB::transaction(fn() => $submission->update([
                'status'             => EstadoPreviredSubmission::COMPLETADO,
                'file_path'          => $path,
                'total_workers'      => $included + $withError,
                'workers_included'   => $included,
                'workers_with_error' => $withError,
                'error_message'      => $withError > 0 ? implode("\n", $errors) : null,
                'submitted_at'       => now(),
            ]));

            $this->logger->info('previred_generated', [
                'submission_id' => $submission->id,
                'period'        => $submission->period,
                'included'      => $included,
                'with_error'    => $withError,
            ]);
        } catch (\Throwable $e) {
            DB::transaction(fn() => $submission->update([
                'status'        => EstadoPreviredSubmission::ERROR,
                'error_message' => $e->getMessage(),
                'retry_count'   => $submission->retry_count + 1,
                'last_retry_at' => now(),
            ]));
            $this->logger->error('previred_generation_failed', ['submission_id' => $submission->id, 'error' => $e->getMessage()]);
            throw $e;
        }
    }

    public function confirmarLiquidacion(Liquidacion $liquidacion): void
    {
        if ($liquidacion->status !== EstadoLiquidacion::GENERADA) {
            throw new \RuntimeException('Solo se pueden confirmar liquidaciones en estado GENERADA.');
        }
        DB::transaction(fn() => $liquidacion->update([
            'status'          => EstadoLiquidacion::CONFIRMADA,
            'previred_status' => EstadoLiquidacionPrevired::PENDIENTE,
        ]));
    }

    public function retry(PreviredSubmission $submission): void
    {
        if (!$submission->isRetryable()) {
            throw new \RuntimeException('Emisión no reintentable (máximo 3 intentos o no está en ERROR).');
        }
        $submission->update(['status' => EstadoPreviredSubmission::PENDIENTE]);
        \App\Jobs\Nomina\GeneratePreviredFileJob::dispatch($submission);
    }

    public function getDownloadUrl(PreviredSubmission $submission): string
    {
        if (!$submission->file_path) {
            throw new \RuntimeException('Esta emisión no tiene un archivo generado.');
        }
        return $this->s3->getSignedUrl($submission->file_path, 300);
    }
}
```

---

#### [1.14] Job `GeneratePreviredFileJob`

- [ ] **1.14.1** Crear `app/Jobs/Nomina/GeneratePreviredFileJob.php`
```php
<?php
namespace App\Jobs\Nomina;

use App\Enums\Nomina\EstadoPreviredSubmission;
use App\Models\Nomina\PreviredSubmission;
use App\Services\Nomina\PreviredService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GeneratePreviredFileJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int   $tries   = 3;
    public int   $timeout = 300;
    public array $backoff  = [60, 120, 300];

    public function __construct(private readonly PreviredSubmission $submission) {}

    public function handle(PreviredService $service): void
    {
        $service->generateForPeriod($this->submission);
    }

    public function failed(\Throwable $exception): void
    {
        $this->submission->update([
            'status'        => EstadoPreviredSubmission::ERROR,
            'error_message' => 'Job falló después de todos los intentos: ' . $exception->getMessage(),
            'retry_count'   => $this->submission->retry_count + 1,
            'last_retry_at' => now(),
        ]);
    }
}
```

---

#### [1.15] FormRequests

- [ ] **1.15.1** Crear `app/Http/Requests/Nomina/GeneratePreviredRequest.php`
```php
<?php
namespace App\Http\Requests\Nomina;

use Illuminate\Foundation\Http\FormRequest;

class GeneratePreviredRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (int) $this->user()?->company_id === (int) $this->route('company_id');
    }

    public function rules(): array
    {
        return ['period' => ['required', 'string', 'regex:/^\d{4}-\d{2}$/']];
    }

    public function messages(): array
    {
        return [
            'period.required' => 'El período es obligatorio.',
            'period.regex'    => 'El período debe tener el formato YYYY-MM (ej: 2026-06).',
        ];
    }
}
```

- [ ] **1.15.2** Crear `app/Http/Requests/Nomina/ConfirmLiquidacionRequest.php`
```php
<?php
namespace App\Http\Requests\Nomina;

use App\Models\Nomina\Liquidacion;
use Illuminate\Foundation\Http\FormRequest;

class ConfirmLiquidacionRequest extends FormRequest
{
    public function authorize(): bool
    {
        $liq = Liquidacion::find($this->route('liquidacion_id'));
        return $liq && $liq->company_id === (int) $this->route('company_id');
    }

    public function rules(): array { return []; }
}
```

---

#### [1.16] `PreviredController`

- [ ] **1.16.1** Crear `app/Http/Controllers/Nomina/PreviredController.php`
```php
<?php
namespace App\Http\Controllers\Nomina;

use App\Http\Controllers\Controller;
use App\Http\Requests\Nomina\ConfirmLiquidacionRequest;
use App\Http\Requests\Nomina\GeneratePreviredRequest;
use App\Models\Nomina\Liquidacion;
use App\Models\Nomina\PreviredSubmission;
use App\Services\Nomina\PreviredService;
use App\Traits\HandlesControllerLogs;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PreviredController extends Controller
{
    use HandlesControllerLogs;

    public function __construct(private readonly PreviredService $service) {}

    public function index(Request $request, int $company_id): JsonResponse
    {
        try {
            $period = $request->query('period', now()->format('Y-m'));
            return response()->json(['data' => $this->service->getLiquidacionesParaPrevired($company_id, $period)]);
        } catch (\Throwable $e) {
            return $this->handleError($e, 'Error al obtener liquidaciones Previred');
        }
    }

    public function submissions(int $company_id): JsonResponse
    {
        try {
            return response()->json(['data' => $this->service->getSubmissions($company_id)]);
        } catch (\Throwable $e) {
            return $this->handleError($e, 'Error al obtener historial de emisiones');
        }
    }

    public function generate(GeneratePreviredRequest $request, int $company_id): JsonResponse
    {
        try {
            $sub = $this->service->initiate($company_id, $request->validated('period'), $request->user()->id);
            return response()->json(['message' => 'Generación Previred iniciada correctamente.', 'data' => $sub], 202);
        } catch (\Throwable $e) {
            return $this->handleError($e, 'Error al iniciar generación Previred');
        }
    }

    public function download(int $company_id, int $submission_id): JsonResponse
    {
        try {
            $sub = PreviredSubmission::where('company_id', $company_id)->find($submission_id);
            if (!$sub) return response()->json(['message' => 'Emisión no encontrada.'], 404);
            return response()->json(['data' => ['url' => $this->service->getDownloadUrl($sub)]]);
        } catch (\Throwable $e) {
            return $this->handleError($e, 'Error al generar URL de descarga');
        }
    }

    public function retry(int $company_id, int $submission_id): JsonResponse
    {
        try {
            $sub = PreviredSubmission::where('company_id', $company_id)->find($submission_id);
            if (!$sub) return response()->json(['message' => 'Emisión no encontrada.'], 404);
            $this->service->retry($sub);
            return response()->json(['message' => 'Reintento de generación iniciado.']);
        } catch (\Throwable $e) {
            return $this->handleError($e, 'Error al reintentar emisión');
        }
    }

    public function confirmLiquidacion(ConfirmLiquidacionRequest $request, int $company_id, int $liquidacion_id): JsonResponse
    {
        try {
            $liq = Liquidacion::where('company_id', $company_id)->find($liquidacion_id);
            if (!$liq) return response()->json(['message' => 'Liquidación no encontrada.'], 404);
            $this->service->confirmarLiquidacion($liq);
            return response()->json(['message' => 'Liquidación confirmada para Previred.']);
        } catch (\Throwable $e) {
            return $this->handleError($e, 'Error al confirmar liquidación');
        }
    }

    private function handleError(\Throwable $e, string $ctx): JsonResponse
    {
        $this->logControllerError($e, $ctx);
        return response()->json(['message' => $e->getMessage()], 422);
    }
}
```

---

#### [1.17] Rutas API

- [ ] **1.17.1** En `routes/api.php`, dentro del grupo `/companies/{company_id}/nomina/`:
```php
use App\Http\Controllers\Nomina\PreviredController;

Route::prefix('previred')->group(function () {
    Route::get('/',                                         [PreviredController::class, 'index']);
    Route::post('/generate',                                [PreviredController::class, 'generate']);
    Route::get('/submissions',                              [PreviredController::class, 'submissions']);
    Route::get('/submissions/{submission_id}/download',     [PreviredController::class, 'download']);
    Route::post('/submissions/{submission_id}/retry',       [PreviredController::class, 'retry']);
    Route::patch('/liquidaciones/{liquidacion_id}/confirm', [PreviredController::class, 'confirmLiquidacion']);
});
```

---

### FASE 2 — FRONTEND

---

#### [2.1] TypeScript Interfaces

- [ ] **2.1.1** Crear `src/app/core/interfaces/nomina/previred.interface.ts`
```typescript
export type PreviredStatus           = 'PENDIENTE' | 'INCLUIDA' | 'ERROR';
export type PreviredSubmissionStatus = 'PENDIENTE' | 'GENERANDO' | 'COMPLETADO' | 'ERROR';
export type LiquidacionStatus        = 'BORRADOR'  | 'GENERADA'  | 'CONFIRMADA' | 'ENVIADA';

export interface LiquidacionPreviredRow {
  id: number;
  employee_name: string;
  employee_rut: string;
  dias_trabajados: number;
  imponible_total: number;
  haberes_total: number;
  descuentos_total: number;
  liquid_total: number | null;
  status: LiquidacionStatus;
  previred_status: PreviredStatus;
  previred_error: string | null;
  previred_included_at: string | null;
}

export interface PreviredSubmission {
  id: number;
  company_id: number;
  period: string;
  status: PreviredSubmissionStatus;
  file_path: string | null;
  total_workers: number;
  workers_included: number;
  workers_with_error: number;
  error_message: string | null;
  retry_count: number;
  submitted_at: string | null;
  created_at: string;
}
```

---

#### [2.2] Angular `PreviredService`

- [ ] **2.2.1** Crear `src/app/core/services/nomina/previred.service.ts`
```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { LiquidacionPreviredRow, PreviredSubmission } from '../../interfaces/nomina/previred.interface';

@Injectable({ providedIn: 'root' })
export class PreviredService {
  private readonly http = inject(HttpClient);
  private readonly base = environment.apiUrl;

  getLiquidaciones(companyId: number, period: string): Observable<{ data: LiquidacionPreviredRow[] }> {
    return this.http.get<{ data: LiquidacionPreviredRow[] }>(
      `${this.base}/companies/${companyId}/nomina/previred`, { params: { period } }
    );
  }

  getSubmissions(companyId: number): Observable<{ data: PreviredSubmission[] }> {
    return this.http.get<{ data: PreviredSubmission[] }>(
      `${this.base}/companies/${companyId}/nomina/previred/submissions`
    );
  }

  generate(companyId: number, period: string): Observable<{ message: string; data: PreviredSubmission }> {
    return this.http.post<{ message: string; data: PreviredSubmission }>(
      `${this.base}/companies/${companyId}/nomina/previred/generate`, { period }
    );
  }

  getDownloadUrl(companyId: number, submissionId: number): Observable<{ data: { url: string } }> {
    return this.http.get<{ data: { url: string } }>(
      `${this.base}/companies/${companyId}/nomina/previred/submissions/${submissionId}/download`
    );
  }

  retry(companyId: number, submissionId: number): Observable<{ message: string }> {
    return this.http.post<{ message: string }>(
      `${this.base}/companies/${companyId}/nomina/previred/submissions/${submissionId}/retry`, {}
    );
  }

  confirmLiquidacion(companyId: number, liquidacionId: number): Observable<{ message: string }> {
    return this.http.patch<{ message: string }>(
      `${this.base}/companies/${companyId}/nomina/previred/liquidaciones/${liquidacionId}/confirm`, {}
    );
  }
}
```

---

#### [2.3] Componente `PreviredComponent`

- [ ] **2.3.1** Crear `src/app/modules/nomina/previred/previred.component.ts`
```typescript
import { Component, OnInit, OnDestroy, inject, signal, computed } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil, finalize } from 'rxjs/operators';
import { CommonModule, DecimalPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTabsModule } from '@angular/material/tabs';
import { MatTooltipModule } from '@angular/material/tooltip';
import { PreviredService } from '../../../core/services/nomina/previred.service';
import { NotificationService } from '../../../core/services/notification.service';
import { SecureTabService } from '../../../core/services/secure-tab.service';
import { LiquidacionPreviredRow, PreviredSubmission } from '../../../core/interfaces/nomina/previred.interface';

@Component({
  selector: 'app-previred',
  standalone: true,
  imports: [CommonModule, FormsModule, DecimalPipe, DatePipe,
            MatButtonModule, MatIconModule, MatTabsModule, MatTooltipModule],
  templateUrl: './previred.component.html',
})
export class PreviredComponent implements OnInit, OnDestroy {
  private readonly _unsubscribeAll = new Subject<void>();
  private readonly previredSvc     = inject(PreviredService);
  private readonly notif           = inject(NotificationService);
  private readonly secureTab       = inject(SecureTabService);

  // Inyectar desde AuthService o ActivatedRoute en implementación real
  readonly companyId      = signal<number>(0);
  readonly selectedPeriod = signal<string>(this.currentPeriod());
  readonly liquidaciones  = signal<LiquidacionPreviredRow[]>([]);
  readonly submissions    = signal<PreviredSubmission[]>([]);
  readonly isLoadingRows  = signal(false);
  readonly isGenerating   = signal(false);

  readonly confirmadas = computed(() => this.liquidaciones().filter(l => l.status === 'CONFIRMADA').length);
  readonly pendientes  = computed(() => this.liquidaciones().filter(l => l.previred_status === 'PENDIENTE').length);
  readonly conError    = computed(() => this.liquidaciones().filter(l => l.previred_status === 'ERROR').length);
  readonly canGenerate = computed(() => this.confirmadas() > 0 && !this.isGenerating());

  ngOnInit(): void { this.loadLiquidaciones(); this.loadSubmissions(); }
  ngOnDestroy(): void { this._unsubscribeAll.next(); this._unsubscribeAll.complete(); }

  loadLiquidaciones(): void {
    this.isLoadingRows.set(true);
    this.previredSvc.getLiquidaciones(this.companyId(), this.selectedPeriod())
      .pipe(takeUntil(this._unsubscribeAll), finalize(() => this.isLoadingRows.set(false)))
      .subscribe({
        next: ({ data }) => this.liquidaciones.set(data),
        error: () => this.notif.error('Error al cargar liquidaciones'),
      });
  }

  loadSubmissions(): void {
    this.previredSvc.getSubmissions(this.companyId())
      .pipe(takeUntil(this._unsubscribeAll))
      .subscribe({ next: ({ data }) => this.submissions.set(data) });
  }

  onPeriodChange(period: string): void { this.selectedPeriod.set(period); this.loadLiquidaciones(); }

  confirmLiquidacion(row: LiquidacionPreviredRow): void {
    this.previredSvc.confirmLiquidacion(this.companyId(), row.id)
      .pipe(takeUntil(this._unsubscribeAll))
      .subscribe({
        next: () => { this.notif.success('Liquidación confirmada para Previred'); this.loadLiquidaciones(); },
        error: (e) => this.notif.error(e.error?.message ?? 'Error al confirmar'),
      });
  }

  generate(): void {
    this.isGenerating.set(true);
    this.previredSvc.generate(this.companyId(), this.selectedPeriod())
      .pipe(takeUntil(this._unsubscribeAll), finalize(() => this.isGenerating.set(false)))
      .subscribe({
        next: ({ message }) => {
          this.notif.success(message);
          this.loadSubmissions();
          setTimeout(() => this.loadSubmissions(), 5000);
        },
        error: (e) => this.notif.error(e.error?.message ?? 'Error al generar Previred'),
      });
  }

  downloadSubmission(sub: PreviredSubmission): void {
    const tab = this.secureTab.open();
    this.previredSvc.getDownloadUrl(this.companyId(), sub.id)
      .pipe(takeUntil(this._unsubscribeAll))
      .subscribe({
        next: ({ data }) => tab.redirect(data.url),
        error: (e) => { tab.close(); this.notif.error(e.error?.message ?? 'Error al descargar'); },
      });
  }

  retrySubmission(sub: PreviredSubmission): void {
    this.previredSvc.retry(this.companyId(), sub.id)
      .pipe(takeUntil(this._unsubscribeAll))
      .subscribe({
        next: ({ message }) => { this.notif.success(message); this.loadSubmissions(); },
        error: (e) => this.notif.error(e.error?.message ?? 'Error al reintentar'),
      });
  }

  getBadgePrevired(s: string): string {
    const map: Record<string, string> = {
      PENDIENTE: 'bg-gray-100 text-gray-600',
      INCLUIDA:  'bg-green-100 text-green-700',
      ERROR:     'bg-red-100 text-red-700',
    };
    return map[s] ?? 'bg-gray-100 text-gray-600';
  }

  getBadgeSubmission(s: string): string {
    const map: Record<string, string> = {
      PENDIENTE:  'bg-gray-100 text-gray-600',
      GENERANDO:  'bg-blue-100 text-blue-700',
      COMPLETADO: 'bg-green-100 text-green-700',
      ERROR:      'bg-red-100 text-red-700',
    };
    return map[s] ?? 'bg-gray-100 text-gray-600';
  }

  private currentPeriod(): string {
    const n = new Date();
    return `${n.getFullYear()}-${String(n.getMonth() + 1).padStart(2, '0')}`;
  }
}
```

- [ ] **2.3.2** Crear `src/app/modules/nomina/previred/previred.component.html`
```html
<div class="p-6 space-y-6">

  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-semibold text-gray-900">Emisión Previred</h1>
      <p class="text-sm text-gray-500 mt-1">Genera el archivo de nómina para enviar a Previred</p>
    </div>
    <div class="flex items-center gap-3">
      <input type="month" [value]="selectedPeriod()"
             (change)="onPeriodChange($any($event.target).value)"
             class="border rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-purple-500 focus:outline-none"/>
      <button mat-flat-button color="primary" [disabled]="!canGenerate()" (click)="generate()">
        @if (isGenerating()) {
          <mat-icon class="animate-spin">sync</mat-icon> Generando...
        } @else {
          <mat-icon>send</mat-icon> Generar Previred ({{ confirmadas() }})
        }
      </button>
    </div>
  </div>

  <!-- Métricas -->
  <div class="grid grid-cols-3 gap-4">
    <div class="bg-white rounded-xl border p-4 flex items-center gap-3">
      <div class="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
        <mat-icon class="text-green-600">check_circle</mat-icon>
      </div>
      <div>
        <div class="text-2xl font-bold text-gray-900">{{ confirmadas() }}</div>
        <div class="text-xs text-gray-500">Confirmadas</div>
      </div>
    </div>
    <div class="bg-white rounded-xl border p-4 flex items-center gap-3">
      <div class="w-10 h-10 bg-yellow-100 rounded-lg flex items-center justify-center">
        <mat-icon class="text-yellow-600">schedule</mat-icon>
      </div>
      <div>
        <div class="text-2xl font-bold text-gray-900">{{ pendientes() }}</div>
        <div class="text-xs text-gray-500">Pendientes</div>
      </div>
    </div>
    <div class="bg-white rounded-xl border p-4 flex items-center gap-3">
      <div class="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
        <mat-icon class="text-red-600">error</mat-icon>
      </div>
      <div>
        <div class="text-2xl font-bold text-gray-900">{{ conError() }}</div>
        <div class="text-xs text-gray-500">Con error</div>
      </div>
    </div>
  </div>

  <mat-tab-group>

    <!-- Tab 1: Trabajadores del período -->
    <mat-tab label="Trabajadores del período">
      @if (isLoadingRows()) {
        <div class="flex justify-center py-12">
          <mat-icon class="animate-spin text-purple-500" style="font-size:2rem">sync</mat-icon>
        </div>
      } @else {
        <div class="mt-4 overflow-x-auto">
          <table class="w-full text-sm">
            <thead class="bg-gray-50">
              <tr>
                <th class="text-left px-4 py-3 font-medium text-gray-600">Trabajador</th>
                <th class="text-left px-4 py-3 font-medium text-gray-600">RUT</th>
                <th class="text-right px-4 py-3 font-medium text-gray-600">Días</th>
                <th class="text-right px-4 py-3 font-medium text-gray-600">Imponible</th>
                <th class="text-right px-4 py-3 font-medium text-gray-600">Líquido</th>
                <th class="text-center px-4 py-3 font-medium text-gray-600">Estado Liq.</th>
                <th class="text-center px-4 py-3 font-medium text-gray-600">Previred</th>
                <th class="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              @for (row of liquidaciones(); track row.id) {
                <tr class="hover:bg-gray-50 transition-colors">
                  <td class="px-4 py-3 font-medium text-gray-900">{{ row.employee_name }}</td>
                  <td class="px-4 py-3 text-gray-600">{{ row.employee_rut }}</td>
                  <td class="px-4 py-3 text-right">{{ row.dias_trabajados }}</td>
                  <td class="px-4 py-3 text-right">{{ row.imponible_total | number:'1.0-0' }}</td>
                  <td class="px-4 py-3 text-right">{{ row.liquid_total | number:'1.0-0' }}</td>
                  <td class="px-4 py-3 text-center">
                    <span class="px-2 py-1 rounded-full text-xs font-medium"
                          [class]="row.status==='CONFIRMADA' ? 'bg-green-100 text-green-700' :
                                   row.status==='GENERADA'   ? 'bg-blue-100 text-blue-700'   :
                                                               'bg-gray-100 text-gray-600'">
                      {{ row.status }}
                    </span>
                  </td>
                  <td class="px-4 py-3 text-center">
                    <span class="px-2 py-1 rounded-full text-xs font-medium cursor-help"
                          [class]="getBadgePrevired(row.previred_status)"
                          [matTooltip]="row.previred_error ?? ''">
                      {{ row.previred_status }}
                    </span>
                  </td>
                  <td class="px-4 py-3 text-right">
                    @if (row.status === 'GENERADA') {
                      <button mat-icon-button matTooltip="Confirmar para Previred"
                              (click)="confirmLiquidacion(row)">
                        <mat-icon class="text-green-600">check_circle_outline</mat-icon>
                      </button>
                    }
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="8" class="text-center py-12 text-gray-400">
                    No hay liquidaciones para el período seleccionado.
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      }
    </mat-tab>

    <!-- Tab 2: Historial de emisiones -->
    <mat-tab label="Historial de emisiones">
      <div class="mt-4 space-y-3">
        @for (sub of submissions(); track sub.id) {
          <div class="bg-white rounded-xl border p-4 flex items-center justify-between">
            <div class="flex items-center gap-4">
              <span class="px-2 py-1 rounded-full text-xs font-semibold"
                    [class]="getBadgeSubmission(sub.status)">
                {{ sub.status }}
              </span>
              <div>
                <div class="font-medium text-gray-900">Período {{ sub.period }}</div>
                <div class="text-xs text-gray-500">
                  {{ sub.workers_included }} incluidos
                  @if (sub.workers_with_error > 0) {
                    · <span class="text-red-500">{{ sub.workers_with_error }} con error</span>
                  }
                  @if (sub.submitted_at) {
                    · {{ sub.submitted_at | date:'dd/MM/yyyy HH:mm' }}
                  }
                </div>
                @if (sub.error_message && sub.status === 'ERROR') {
                  <div class="text-xs text-red-500 mt-1 max-w-lg truncate"
                       [matTooltip]="sub.error_message">
                    {{ sub.error_message }}
                  </div>
                }
              </div>
            </div>
            <div class="flex gap-2">
              @if (sub.status === 'COMPLETADO') {
                <button mat-icon-button matTooltip="Descargar archivo TXT"
                        (click)="downloadSubmission(sub)">
                  <mat-icon class="text-blue-600">download</mat-icon>
                </button>
              }
              @if (sub.status === 'ERROR' && sub.retry_count < 3) {
                <button mat-icon-button matTooltip="Reintentar generación"
                        (click)="retrySubmission(sub)">
                  <mat-icon class="text-orange-600">replay</mat-icon>
                </button>
              }
            </div>
          </div>
        } @empty {
          <div class="text-center py-12 text-gray-400">
            Aún no hay emisiones Previred registradas.
          </div>
        }
      </div>
    </mat-tab>

  </mat-tab-group>
</div>
```

- [ ] **2.3.3** Registrar ruta en el módulo de nómina (lazy loading):
```typescript
{
  path: 'previred',
  loadComponent: () =>
    import('./previred/previred.component').then(c => c.PreviredComponent),
}
```

---

## Auditoría (Guardián) y Documentación (Scribe)

### Vectores de Seguridad
- **QD-02 (IDOR)**: `ConfirmLiquidacionRequest` y cada endpoint del Controller validan que la liquidación/submission pertenezcan al `company_id` del JWT antes de cualquier mutación.
- **QD-05 (IDs secuenciales)**: Descarga del archivo vía S3 URL firmada temporal (TTL 300s). Nunca path directo.
- **QD-08 (Rate Limiting)**: Aplicar `throttle:api` en rutas `/generate` y `/retry`.
- **QD-01 (Bypass autorización)**: Guard Angular valida permiso `NOMINA.PREVIRED` antes de renderizar el componente.

### Documentación viva (`qdoora-references/agent/rules/Backend.md`)
- Nuevo patrón: generación de archivos externos = Job + Service + S3 (nunca síncrono en controller).
- `previred_code` en `global_entities` para SALUD estaba en códigos SII; migración M1 los corrige a Tabla N°16 oficial.
- `work_schedule` en `rem_employee_work_contracts` (COMPLETA/PARCIAL) → mapear a campo 93 de Previred. No crear `tipo_jornada` en remuneraciones.
- `family_allowance_tramo` en `rem_employee_remunerations` → usar directamente para campo 18. No recalcular.
- Mutual de la empresa: `rem_company_settings` con `feature_key='MUTUAL'`, `config.third_company_id` → ThirdCompany → `standardEntity.previred_code`.

---

## Comandos a ejecutar (después de aprobación del plan, en orden)
```bash
# 1. Ejecutar migraciones M1–M6 (incluye corrección de previred_codes en datos existentes)
php artisan migrate

# 2. Sincronizar seeders (inserta CCAF en global_entities — seguro re-ejecutar)
php artisan data:sync

# 3. Limpiar caché
php artisan config:clear && php artisan cache:clear
```

---

PLAN GENERADO. MODO PAUSA ACTIVADO. Esperando aprobación del usuario para proceder.
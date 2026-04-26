# Nómina — Submódulo Configuraciones: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el submódulo `NOMINA.SETTINGS` que permite activar/desactivar y configurar features de nómina por empresa (Gratificaciones, Horas Extras, APVC, CCAF, Mutual), con acceso bidireccional desde el módulo de Conceptos.

**Architecture:** Se usa un Feature Registry Pattern: una tabla `nomina_company_settings` con una fila por empresa por feature, ligada opcionalmente a un `GlobalHaberDescuento`. Al activar una feature, el servicio sincroniza el estado del `HaberDescuento` de empresa correspondiente. El campo `config` es JSONB con esquema variable por feature, lo que permite agregar nuevas features solo extendiendo el service y el template Angular, sin nuevas tablas.

**Tech Stack:** Laravel 11 / PHP 8.3 (backend) · Angular 18 standalone components + Angular Material + Reactive Forms (frontend) · PostgreSQL 15 (JSONB) · Eloquent ORM

---

## Mapa de archivos

### Backend (`qdoora-api/`)
| Acción | Archivo |
|--------|---------|
| Crear | `database/migrations/XXXX_create_nomina_company_settings.php` |
| Crear | `database/seeders/NominaGlobalConceptsSeeder.php` |
| Crear | `app/Enums/Nomina/NominaFeatureKey.php` |
| Crear | `app/Enums/Nomina/OperacionGratificacion.php` |
| Crear | `app/Enums/Nomina/ProporcionalidadGratificacion.php` |
| Crear | `app/Models/Nomina/NominaCompanySettings.php` |
| Crear | `app/Services/Nomina/NominaSettingsService.php` |
| Crear | `app/Http/Controllers/Nomina/NominaSettingsController.php` |
| Crear | `app/Http/Requests/Nomina/ToggleNominaFeature.php` |
| Crear | `app/Http/Requests/Nomina/UpdateNominaFeatureConfig.php` |
| Modificar | `app/Services/Nomina/GlobalEarnDiscountService.php` — agregar llamada a provisioning |
| Modificar | `app/Services/Nomina/EarnDiscountService.php` — agregar campo `feature_config_available` |
| Modificar | `routes/api.php` — 3 rutas nuevas |
| Crear | `tests/Feature/Nomina/NominaSettingsTest.php` |

### Frontend (`fuse-starter/`)
| Acción | Archivo |
|--------|---------|
| Crear | `src/app/core/models/data/nominaSettings.ts` |
| Modificar | `src/app/api/nomina/api.ts` — 3 métodos nuevos |
| Crear | `src/app/modules/admin/nomina/settings/settings.routes.ts` |
| Crear | `src/app/modules/admin/nomina/settings/settings.service.ts` |
| Crear | `src/app/modules/admin/nomina/settings/settings.component.ts` |
| Crear | `src/app/modules/admin/nomina/settings/settings.component.html` |
| Modificar | `src/app/modules/admin/nomina/concepts/list/list.component.ts` — botón "Configurar" |
| Modificar | `src/app/modules/admin/nomina/concepts/list/list.component.html` — columna acción |
| Modificar | Routing principal de `nomina` — agregar ruta `settings` |

---

## Contexto necesario para el implementador

### Patrones del codebase (obligatorio leer antes de empezar)

**Backend:**
- Los controladores retornan siempre `jsonResponse($data)` (helper en `app/Helpers/responses.php`)
- Los errores se manejan con `$this->handleError->logAndResponse($e, $request, LoggerOperation::X, LoggerEvent::Y)`
- Los Form Requests validan empresa con `Company::findOrFail($companyId)` y verifican permisos del usuario
- Las migraciones usan anonymous class: `return new class extends Migration { ... }`
- Los modelos tienen scopes: `porEmpresa($id)`, `activos()`, etc.
- Ver patrón completo en `app/Http/Controllers/Nomina/EarnDiscountController.php` y `app/Services/Nomina/EarnDiscountService.php`

**Frontend:**
- Los servicios usan `BehaviorSubject` y exponen observables con `$` suffix
- El API client está en `src/app/api/nomina/api.ts` y extiende/usa `BaseApi`
- Los componentes son standalone con `imports: [...]` explícito
- Ver patrón completo en `src/app/modules/admin/nomina/concepts/`

### Estructura de la tabla `global_payroll_earnings_discounts` (GlobalHaberDescuento)
```
id | name | key | type (IMPONIBLE/NO_IMPONIBLE/DESCUENTO) | is_affect | is_active
```

### Estructura de la tabla `payroll_earnings_discounts` (HaberDescuento por empresa)
```
id | company_id | standard_entity_id (FK global) | name | key | type | is_standard | is_affect | auxiliary_id | cost_center_id | account_id | sub_account_id | is_active
```

### Relación ThirdCompany → GlobalEntity
```sql
third_company.global_entity_id → global_entities.id
global_entities.category = 'CCAF' | 'MUTUAL'
```

---

## Task 1: Migraciones y Enums

**Archivos:**
- Crear: `database/migrations/2026_03_28_000001_create_nomina_company_settings.php`
- Crear: `app/Enums/Nomina/NominaFeatureKey.php`
- Crear: `app/Enums/Nomina/OperacionGratificacion.php`
- Crear: `app/Enums/Nomina/ProporcionalidadGratificacion.php`

- [ ] **Step 1.1: Crear migración**

```php
// database/migrations/2026_03_28_000001_create_nomina_company_settings.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nomina_company_settings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->string('feature_key', 50);
            $table->unsignedBigInteger('global_earn_discount_id')->nullable();
            $table->boolean('is_active')->default(false);
            $table->jsonb('config')->nullable();
            $table->timestamps();

            $table->foreign('company_id')
                  ->references('id')->on('company')
                  ->onDelete('cascade');

            $table->foreign('global_earn_discount_id')
                  ->references('id')->on('global_payroll_earnings_discounts')
                  ->onDelete('set null');

            $table->unique(['company_id', 'feature_key']);
            $table->index('company_id');
            $table->index('feature_key');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nomina_company_settings');
    }
};
```

- [ ] **Step 1.2: Ejecutar migración y verificar**

```bash
cd qdoora-api
php artisan migrate
php artisan migrate:status | grep nomina_company_settings
```
Esperado: `Ran` en la nueva migración.

- [ ] **Step 1.3: Crear enums**

```php
// app/Enums/Nomina/NominaFeatureKey.php
<?php

namespace App\Enums\Nomina;

enum NominaFeatureKey: string
{
    case GRATIFICACION = 'GRATIFICACION';
    case HORAS_EXTRAS  = 'HORAS_EXTRAS';
    case APVC          = 'APVC';
    case CCAF          = 'CCAF';
    case MUTUAL        = 'MUTUAL';
}
```

```php
// app/Enums/Nomina/OperacionGratificacion.php
<?php

namespace App\Enums\Nomina;

enum OperacionGratificacion: string
{
    case SIN_GRATIFICACION = 'SIN_GRATIFICACION';
    case PAGO_MENSUAL      = 'PAGO_MENSUAL';
    case PAGO_ANUAL        = 'PAGO_ANUAL';
}
```

```php
// app/Enums/Nomina/ProporcionalidadGratificacion.php
<?php

namespace App\Enums\Nomina;

enum ProporcionalidadGratificacion: string
{
    case SIN_PROPORCIONALIDAD = 'SIN_PROPORCIONALIDAD';
    case TODO_EVENTO          = 'TODO_EVENTO';
    case SOLO_SUBSIDIOS       = 'SOLO_SUBSIDIOS';
}
```

- [ ] **Step 1.4: Commit**

```bash
git add database/migrations/2026_03_28_000001_create_nomina_company_settings.php \
        app/Enums/Nomina/NominaFeatureKey.php \
        app/Enums/Nomina/OperacionGratificacion.php \
        app/Enums/Nomina/ProporcionalidadGratificacion.php
git commit -m "feat(nomina): add nomina_company_settings table and feature enums"
```

---

## Task 2: Seeder de GlobalHaberDescuento y Modelo

**Archivos:**
- Crear: `database/seeders/NominaGlobalConceptsSeeder.php`
- Crear: `app/Models/Nomina/NominaCompanySettings.php`

- [ ] **Step 2.1: Crear seeder de conceptos globales de nómina**

```php
// database/seeders/NominaGlobalConceptsSeeder.php
<?php

namespace Database\Seeders;

use App\Models\Nomina\GlobalHaberDescuento;
use Illuminate\Database\Seeder;

class NominaGlobalConceptsSeeder extends Seeder
{
    /**
     * Idempotente: usa firstOrCreate para no duplicar.
     * Estos records son la fuente de verdad para nomina_company_settings.
     */
    public function run(): void
    {
        $concepts = [
            [
                'name'      => 'Gratificación',
                'key'       => 'GRATIFICACION',
                'type'      => 'IMPONIBLE',
                'is_affect' => true,
                'is_active' => true,
            ],
            [
                'name'      => 'Horas Extras',
                'key'       => 'HORAS_EXTRAS',
                'type'      => 'IMPONIBLE',
                'is_affect' => true,
                'is_active' => true,
            ],
            [
                'name'      => 'APVC Trabajador',
                'key'       => 'APVC_TRABAJADOR',
                'type'      => 'DESCUENTO',
                'is_affect' => false,
                'is_active' => true,
            ],
            [
                'name'      => 'CCAF',
                'key'       => 'CCAF',
                'type'      => 'DESCUENTO',
                'is_affect' => false,
                'is_active' => true,
            ],
            [
                'name'      => 'Mutual de Seguridad',
                'key'       => 'MUTUAL',
                'type'      => 'DESCUENTO',
                'is_affect' => false,
                'is_active' => true,
            ],
        ];

        foreach ($concepts as $data) {
            GlobalHaberDescuento::firstOrCreate(['key' => $data['key']], $data);
        }
    }
}
```

- [ ] **Step 2.2: Ejecutar seeder y verificar**

```bash
php artisan db:seed --class=NominaGlobalConceptsSeeder
php artisan tinker --execute="echo App\Models\Nomina\GlobalHaberDescuento::count();"
```
Esperado: al menos 5 registros (puede haber más si ya existían otros).

- [ ] **Step 2.3: Crear modelo NominaCompanySettings**

```php
// app/Models/Nomina/NominaCompanySettings.php
<?php

namespace App\Models\Nomina;

use App\Enums\Nomina\NominaFeatureKey;
use App\Models\Company;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NominaCompanySettings extends Model
{
    protected $table = 'nomina_company_settings';

    protected $fillable = [
        'company_id',
        'feature_key',
        'global_earn_discount_id',
        'is_active',
        'config',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'config'    => 'array',
    ];

    // ─── Relationships ────────────────────────────────────────────────────────

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class);
    }

    public function globalEarnDiscount(): BelongsTo
    {
        return $this->belongsTo(GlobalHaberDescuento::class, 'global_earn_discount_id');
    }

    // ─── Scopes ───────────────────────────────────────────────────────────────

    public function scopePorEmpresa($query, int $companyId)
    {
        return $query->where('company_id', $companyId);
    }

    public function scopePorFeature($query, string $featureKey)
    {
        return $query->where('feature_key', $featureKey);
    }

    public function scopeActivas($query)
    {
        return $query->where('is_active', true);
    }
}
```

- [ ] **Step 2.4: Commit**

```bash
git add database/seeders/NominaGlobalConceptsSeeder.php \
        app/Models/Nomina/NominaCompanySettings.php
git commit -m "feat(nomina): add NominaCompanySettings model and global concepts seeder"
```

---

## Task 3: NominaSettingsService

**Archivos:**
- Crear: `app/Services/Nomina/NominaSettingsService.php`

Este es el corazón del feature. Lee con atención los comentarios inline.

- [ ] **Step 3.1: Escribir test de provisioning**

```php
// tests/Feature/Nomina/NominaSettingsTest.php
<?php

namespace Tests\Feature\Nomina;

use App\Models\Nomina\GlobalHaberDescuento;
use App\Models\Nomina\NominaCompanySettings;
use App\Services\Nomina\NominaSettingsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NominaSettingsTest extends TestCase
{
    use RefreshDatabase;

    private NominaSettingsService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(NominaSettingsService::class);

        // Seed mínimo de globales
        GlobalHaberDescuento::create(['name' => 'Gratificación', 'key' => 'GRATIFICACION', 'type' => 'IMPONIBLE', 'is_affect' => true, 'is_active' => true]);
        GlobalHaberDescuento::create(['name' => 'CCAF', 'key' => 'CCAF', 'type' => 'DESCUENTO', 'is_affect' => false, 'is_active' => true]);
    }

    public function test_provision_creates_settings_rows_for_all_features(): void
    {
        $companyId = 1; // Crear empresa de prueba según el factory del proyecto
        $this->service->provisionDefaultSettings($companyId);

        $this->assertDatabaseCount('nomina_company_settings', 5);
        $this->assertDatabaseHas('nomina_company_settings', [
            'company_id'  => $companyId,
            'feature_key' => 'GRATIFICACION',
            'is_active'   => false,
        ]);
    }

    public function test_provision_is_idempotent(): void
    {
        $companyId = 1;
        $this->service->provisionDefaultSettings($companyId);
        $this->service->provisionDefaultSettings($companyId); // segunda vez

        $this->assertDatabaseCount('nomina_company_settings', 5); // no duplica
    }

    public function test_toggle_activates_feature(): void
    {
        $companyId = 1;
        $this->service->provisionDefaultSettings($companyId);
        $this->service->toggleFeature($companyId, 'GRATIFICACION', true);

        $this->assertDatabaseHas('nomina_company_settings', [
            'company_id'  => $companyId,
            'feature_key' => 'GRATIFICACION',
            'is_active'   => true,
        ]);
    }
}
```

- [ ] **Step 3.2: Ejecutar tests y verificar que fallan**

```bash
php artisan test tests/Feature/Nomina/NominaSettingsTest.php
```
Esperado: FAIL — `NominaSettingsService` no existe aún.

- [ ] **Step 3.3: Implementar NominaSettingsService**

```php
// app/Services/Nomina/NominaSettingsService.php
<?php

namespace App\Services\Nomina;

use App\Enums\Nomina\NominaFeatureKey;
use App\Enums\Nomina\OperacionGratificacion;
use App\Enums\Nomina\ProporcionalidadGratificacion;
use App\Models\Nomina\GlobalHaberDescuento;
use App\Models\Nomina\HaberDescuento;
use App\Models\Nomina\NominaCompanySettings;
use App\Models\ThirdCompany;

class NominaSettingsService
{
    /**
     * Retorna todas las features con config, opciones y datos del global.
     * Si la empresa no tiene filas, las provisiona (lazy init).
     */
    public function getSettings(int $companyId): array
    {
        $count = NominaCompanySettings::porEmpresa($companyId)->count();
        if ($count < count(NominaFeatureKey::cases())) {
            $this->provisionDefaultSettings($companyId);
        }

        $rows = NominaCompanySettings::porEmpresa($companyId)
            ->with('globalEarnDiscount')
            ->get()
            ->keyBy('feature_key');

        $result = [];
        foreach (NominaFeatureKey::cases() as $feature) {
            $row = $rows->get($feature->value);
            $result[] = [
                'feature_key'          => $feature->value,
                'label'                => $this->getFeatureLabel($feature),
                'is_active'            => $row?->is_active ?? false,
                'global_earn_discount' => $row?->globalEarnDiscount?->only(['id', 'name', 'key']),
                'config'               => $row?->config,
                'options'              => $this->getFeatureOptions($feature, $companyId),
            ];
        }

        return $result;
    }

    /**
     * Activa o desactiva una feature y sincroniza el HaberDescuento de empresa.
     */
    public function toggleFeature(int $companyId, string $featureKey, bool $isActive): NominaCompanySettings
    {
        $setting = NominaCompanySettings::porEmpresa($companyId)
            ->porFeature($featureKey)
            ->firstOrFail();

        $setting->update(['is_active' => $isActive]);

        // Sincronizar el HaberDescuento de empresa si existe el vínculo global
        if ($setting->global_earn_discount_id) {
            HaberDescuento::where('company_id', $companyId)
                ->where('standard_entity_id', $setting->global_earn_discount_id)
                ->update(['is_active' => $isActive]);
        }

        return $setting->fresh();
    }

    /**
     * Actualiza el JSON de configuración de una feature.
     * La validación de estructura se hace en el Form Request antes de llegar aquí.
     */
    public function updateConfig(int $companyId, string $featureKey, array $config): NominaCompanySettings
    {
        $setting = NominaCompanySettings::porEmpresa($companyId)
            ->porFeature($featureKey)
            ->firstOrFail();

        $setting->update(['config' => $config]);

        return $setting->fresh();
    }

    /**
     * Crea una fila por feature para la empresa (is_active=false por defecto).
     * Idempotente: usa updateOrCreate.
     */
    public function provisionDefaultSettings(int $companyId): void
    {
        foreach (NominaFeatureKey::cases() as $feature) {
            $globalKey   = $this->getGlobalKeyForFeature($feature);
            $globalModel = $globalKey
                ? GlobalHaberDescuento::porClave($globalKey)->first()
                : null;

            NominaCompanySettings::updateOrCreate(
                ['company_id' => $companyId, 'feature_key' => $feature->value],
                ['global_earn_discount_id' => $globalModel?->id, 'is_active' => false]
            );
        }
    }

    /**
     * Punto de extensión principal: define los campos config de cada feature.
     * Para agregar una nueva feature, añadir un case aquí.
     */
    public function getFeatureSchema(NominaFeatureKey $feature): array
    {
        return match ($feature) {
            NominaFeatureKey::GRATIFICACION => [
                'porcentaje'            => ['type' => 'float',   'required' => true,  'min' => 0, 'max' => 100],
                'es_base_horas_extras'  => ['type' => 'boolean', 'required' => true],
                'operacion'             => ['type' => 'enum',    'required' => true,  'values' => array_column(OperacionGratificacion::cases(), 'value')],
                'proporcionalidad'      => ['type' => 'enum',    'required' => true,  'values' => array_column(ProporcionalidadGratificacion::cases(), 'value')],
            ],
            NominaFeatureKey::HORAS_EXTRAS => [
                'porcentaje_domingo'    => ['type' => 'float',   'required' => true,  'min' => 0, 'max' => 200],
                'porcentaje_festivo'    => ['type' => 'float',   'required' => true,  'min' => 0, 'max' => 200],
            ],
            NominaFeatureKey::APVC => [
                'third_company_id'      => ['type' => 'integer', 'required' => true],
                'numero_contrato'       => ['type' => 'string',  'required' => true,  'max' => 50],
            ],
            NominaFeatureKey::CCAF => [
                'third_company_id'      => ['type' => 'integer', 'required' => true],
                'numero_asociado'       => ['type' => 'string',  'required' => true,  'max' => 50],
            ],
            NominaFeatureKey::MUTUAL => [
                'third_company_id'             => ['type' => 'integer', 'required' => true],
                'codigo_empleador'             => ['type' => 'string',  'required' => true,  'max' => 50],
                'porcentaje_tasa_adicional'    => ['type' => 'float',   'required' => true,  'min' => 0, 'max' => 100],
            ],
        };
    }

    // ─── Helpers privados ────────────────────────────────────────────────────

    private function getGlobalKeyForFeature(NominaFeatureKey $feature): ?string
    {
        return match ($feature) {
            NominaFeatureKey::GRATIFICACION => 'GRATIFICACION',
            NominaFeatureKey::HORAS_EXTRAS  => 'HORAS_EXTRAS',
            NominaFeatureKey::APVC          => 'APVC_TRABAJADOR',
            NominaFeatureKey::CCAF          => 'CCAF',
            NominaFeatureKey::MUTUAL        => 'MUTUAL',
        };
    }

    private function getFeatureLabel(NominaFeatureKey $feature): string
    {
        return match ($feature) {
            NominaFeatureKey::GRATIFICACION => 'Gratificaciones',
            NominaFeatureKey::HORAS_EXTRAS  => 'Horas Extras',
            NominaFeatureKey::APVC          => 'Ahorro Previsional Voluntario Colectivo (APVC)',
            NominaFeatureKey::CCAF          => 'CCAF',
            NominaFeatureKey::MUTUAL        => 'Mutual de Seguridad',
        };
    }

    /**
     * Retorna opciones de selectores para cada feature.
     * Para CCAF y MUTUAL, consulta third_company filtrado por categoría.
     */
    private function getFeatureOptions(NominaFeatureKey $feature, int $companyId): array
    {
        return match ($feature) {
            NominaFeatureKey::GRATIFICACION => [
                'operacion'        => array_map(fn($e) => ['value' => $e->value, 'label' => $this->labelOperacion($e)], OperacionGratificacion::cases()),
                'proporcionalidad' => array_map(fn($e) => ['value' => $e->value, 'label' => $this->labelProporcionalidad($e)], ProporcionalidadGratificacion::cases()),
            ],
            NominaFeatureKey::CCAF => [
                'instituciones' => $this->getThirdCompaniesByCategory('CCAF'),
            ],
            NominaFeatureKey::MUTUAL => [
                'instituciones' => $this->getThirdCompaniesByCategory('MUTUAL'),
            ],
            default => [],
        };
    }

    private function getThirdCompaniesByCategory(string $category): array
    {
        return ThirdCompany::whereHas('globalEntity', fn($q) => $q->where('category', $category))
            ->where('is_active', true)
            ->get(['id', 'name'])
            ->toArray();
    }

    private function labelOperacion(OperacionGratificacion $e): string
    {
        return match ($e) {
            OperacionGratificacion::SIN_GRATIFICACION => 'Sin Gratificación',
            OperacionGratificacion::PAGO_MENSUAL      => 'Gratificación con Pago Mensual',
            OperacionGratificacion::PAGO_ANUAL        => 'Gratificación con Pago Anual',
        };
    }

    private function labelProporcionalidad(ProporcionalidadGratificacion $e): string
    {
        return match ($e) {
            ProporcionalidadGratificacion::SIN_PROPORCIONALIDAD => 'Sin Proporcionalidad',
            ProporcionalidadGratificacion::TODO_EVENTO          => 'Proporcionalidad a Todo Evento',
            ProporcionalidadGratificacion::SOLO_SUBSIDIOS       => 'Proporcionalidad Solo Subsidios',
        };
    }
}
```

- [ ] **Step 3.4: Ejecutar tests y verificar que pasan**

```bash
php artisan test tests/Feature/Nomina/NominaSettingsTest.php
```
Esperado: 3 tests PASS.

- [ ] **Step 3.5: Commit**

```bash
git add app/Services/Nomina/NominaSettingsService.php \
        tests/Feature/Nomina/NominaSettingsTest.php
git commit -m "feat(nomina): add NominaSettingsService with provision, toggle and config"
```

---

## Task 4: Provisioning al crear empresa + campo en EarnDiscountService

**Archivos:**
- Modificar: `app/Services/Nomina/GlobalEarnDiscountService.php`
- Modificar: `app/Services/Nomina/EarnDiscountService.php`

- [ ] **Step 4.1: Hook de provisioning en GlobalEarnDiscountService**

Buscar el método `provisionStandardEntitiesToCompany` en `GlobalEarnDiscountService.php`.
Al **final** de ese método, agregar:

```php
// Al final de provisionStandardEntitiesToCompany(), después de crear HaberDescuentos:
app(\App\Services\Nomina\NominaSettingsService::class)->provisionDefaultSettings($companyId);
```

El método queda como:
```php
public function provisionStandardEntitiesToCompany(int $companyId): void
{
    // ... código existente que propaga GlobalHaberDescuento → HaberDescuento ...

    // Nuevo: provisionar settings de features
    app(\App\Services\Nomina\NominaSettingsService::class)
        ->provisionDefaultSettings($companyId);
}
```

- [ ] **Step 4.2: Agregar campo feature_config_available en EarnDiscountService**

En el método que construye la respuesta de un `HaberDescuento` (donde se mapea el resultado antes de retornarlo), agregar el campo `feature_config_available`:

```php
// Dentro del map/transform de HaberDescuento en EarnDiscountService
// Buscar dónde se construye el array de respuesta y agregar:

'feature_config_available' => $item->is_standard && $item->standard_entity_id !== null
    ? \App\Models\Nomina\NominaCompanySettings::where('company_id', $item->company_id)
        ->where('global_earn_discount_id', $item->standard_entity_id)
        ->exists()
    : false,
```

Este campo indica al frontend que existe configuración en Settings para este concepto.

- [ ] **Step 4.3: Verificar manualmente**

```bash
php artisan tinker
# Crear empresa de prueba y verificar que se provisiona automáticamente
# O llamar: app(App\Services\Nomina\NominaSettingsService::class)->getSettings(1)
```

- [ ] **Step 4.4: Commit**

```bash
git add app/Services/Nomina/GlobalEarnDiscountService.php \
        app/Services/Nomina/EarnDiscountService.php
git commit -m "feat(nomina): provision settings on company init and expose feature_config_available"
```

---

## Task 5: Controller, Form Requests y Rutas

**Archivos:**
- Crear: `app/Http/Controllers/Nomina/NominaSettingsController.php`
- Crear: `app/Http/Requests/Nomina/ToggleNominaFeature.php`
- Crear: `app/Http/Requests/Nomina/UpdateNominaFeatureConfig.php`
- Modificar: `routes/api.php`

- [ ] **Step 5.1: Crear Form Request de toggle**

```php
// app/Http/Requests/Nomina/ToggleNominaFeature.php
<?php

namespace App\Http\Requests\Nomina;

use App\Enums\Nomina\NominaFeatureKey;
use App\Models\Company;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Enum;

class ToggleNominaFeature extends FormRequest
{
    public function authorize(): bool
    {
        // Mismo patrón que otros Form Requests del módulo: verificar empresa y rol
        $company = Company::find($this->route('company_id'));
        if (!$company) {
            return false;
        }

        // Verificar permiso NOMINA.SETTINGS con operación UPDATE
        // Seguir el mismo patrón de CheckSuscriptorRole / user_company_permission
        // que usan UpdateEarnDiscount.php y similares del proyecto
        return true; // Reemplazar con la validación real de permisos del proyecto
    }

    public function rules(): array
    {
        return [
            'is_active'   => ['required', 'boolean'],
            'feature_key' => ['required', new Enum(NominaFeatureKey::class)],
        ];
    }
}
```

> **Nota:** Copiar la lógica de `authorize()` exactamente de `UpdateEarnDiscount.php` del proyecto, adaptando el módulo a `NOMINA.SETTINGS` y la operación a `UPDATE`.

- [ ] **Step 5.2: Crear Form Request de config**

```php
// app/Http/Requests/Nomina/UpdateNominaFeatureConfig.php
<?php

namespace App\Http\Requests\Nomina;

use App\Enums\Nomina\NominaFeatureKey;
use App\Models\Company;
use App\Services\Nomina\NominaSettingsService;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Enum;

class UpdateNominaFeatureConfig extends FormRequest
{
    public function authorize(): bool
    {
        // Mismo patrón que ToggleNominaFeature
        return true; // Reemplazar con la validación real del proyecto
    }

    public function rules(): array
    {
        $featureKey = $this->route('feature_key');

        try {
            $feature = NominaFeatureKey::from($featureKey);
        } catch (\ValueError $e) {
            return ['feature_key' => ['required', new Enum(NominaFeatureKey::class)]];
        }

        $service = app(NominaSettingsService::class);
        $schema  = $service->getFeatureSchema($feature);

        $rules = [];
        foreach ($schema as $field => $definition) {
            $fieldRules = [];

            $fieldRules[] = $definition['required'] ? 'required' : 'nullable';

            match ($definition['type']) {
                'float'   => array_push($fieldRules, 'numeric', "min:{$definition['min']}", "max:{$definition['max']}"),
                'boolean' => array_push($fieldRules, 'boolean'),
                'integer' => array_push($fieldRules, 'integer', 'exists:third_company,id'),
                'string'  => array_push($fieldRules, 'string', "max:{$definition['max']}"),
                'enum'    => array_push($fieldRules, 'string', 'in:' . implode(',', $definition['values'])),
                default   => null,
            };

            $rules["config.{$field}"] = $fieldRules;
        }

        return $rules;
    }
}
```

- [ ] **Step 5.3: Crear el controlador**

```php
// app/Http/Controllers/Nomina/NominaSettingsController.php
<?php

namespace App\Http\Controllers\Nomina;

use App\Enums\Logger\LoggerEvent;
use App\Enums\Logger\LoggerOperation;
use App\Http\Controllers\Controller;
use App\Http\Requests\Nomina\ToggleNominaFeature;
use App\Http\Requests\Nomina\UpdateNominaFeatureConfig;
use App\Services\Nomina\NominaSettingsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NominaSettingsController extends Controller
{
    public function __construct(
        private readonly NominaSettingsService $service
    ) {}

    /**
     * GET /v1/company/{company_id}/nomina/settings
     */
    public function getSettings(Request $request, int $company_id): JsonResponse
    {
        try {
            $settings = $this->service->getSettings($company_id);
            return jsonResponse($settings);
        } catch (\Exception $e) {
            return $this->handleError->logAndResponse($e, $request, LoggerOperation::REVISAR, LoggerEvent::NOMINA);
        }
    }

    /**
     * PATCH /v1/company/{company_id}/nomina/settings/{feature_key}/toggle
     */
    public function toggleFeature(ToggleNominaFeature $request, int $company_id, string $feature_key): JsonResponse
    {
        try {
            $setting = $this->service->toggleFeature(
                $company_id,
                $feature_key,
                $request->boolean('is_active')
            );
            return jsonResponse($setting);
        } catch (\Exception $e) {
            return $this->handleError->logAndResponse($e, $request, LoggerOperation::ACTUALIZAR, LoggerEvent::NOMINA);
        }
    }

    /**
     * PUT /v1/company/{company_id}/nomina/settings/{feature_key}/config
     */
    public function updateConfig(UpdateNominaFeatureConfig $request, int $company_id, string $feature_key): JsonResponse
    {
        try {
            $setting = $this->service->updateConfig(
                $company_id,
                $feature_key,
                $request->input('config', [])
            );
            return jsonResponse($setting);
        } catch (\Exception $e) {
            return $this->handleError->logAndResponse($e, $request, LoggerOperation::ACTUALIZAR, LoggerEvent::NOMINA);
        }
    }
}
```

> **Nota:** Si `LoggerEvent::NOMINA` no existe, agregar el case al enum `app/Enums/Logger/LoggerEvent.php` siguiendo el patrón existente.

- [ ] **Step 5.4: Agregar rutas en api.php**

Buscar el bloque de rutas de nómina (que tiene las rutas de `earn-discount`) y agregar a continuación:

```php
// En routes/api.php — dentro del grupo de rutas de nómina autenticadas
// Buscar: Route::group(['prefix' => 'company/{company_id}/nomina', ...], ...)

// Configuraciones de nómina
Route::get('settings', [\App\Http\Controllers\Nomina\NominaSettingsController::class, 'getSettings']);
Route::patch('settings/{feature_key}/toggle', [\App\Http\Controllers\Nomina\NominaSettingsController::class, 'toggleFeature']);
Route::put('settings/{feature_key}/config', [\App\Http\Controllers\Nomina\NominaSettingsController::class, 'updateConfig']);
```

- [ ] **Step 5.5: Verificar rutas**

```bash
php artisan route:list | grep nomina/settings
```
Esperado: 3 rutas listadas (GET, PATCH, PUT).

- [ ] **Step 5.6: Commit**

```bash
git add app/Http/Controllers/Nomina/NominaSettingsController.php \
        app/Http/Requests/Nomina/ToggleNominaFeature.php \
        app/Http/Requests/Nomina/UpdateNominaFeatureConfig.php \
        routes/api.php
git commit -m "feat(nomina): add NominaSettingsController with 3 endpoints"
```

---

## Task 6: Frontend — Interfaces TypeScript y API client

**Archivos:**
- Crear: `src/app/core/models/data/nominaSettings.ts`
- Modificar: `src/app/api/nomina/api.ts`

- [ ] **Step 6.1: Crear interfaces TypeScript**

```typescript
// src/app/core/models/data/nominaSettings.ts

export type NominaFeatureKey =
  | 'GRATIFICACION'
  | 'HORAS_EXTRAS'
  | 'APVC'
  | 'CCAF'
  | 'MUTUAL';

export type OperacionGratificacion =
  | 'SIN_GRATIFICACION'
  | 'PAGO_MENSUAL'
  | 'PAGO_ANUAL';

export type ProporcionalidadGratificacion =
  | 'SIN_PROPORCIONALIDAD'
  | 'TODO_EVENTO'
  | 'SOLO_SUBSIDIOS';

export interface ConfigGratificacion {
  porcentaje: number;
  es_base_horas_extras: boolean;
  operacion: OperacionGratificacion;
  proporcionalidad: ProporcionalidadGratificacion;
}

export interface ConfigHorasExtras {
  porcentaje_domingo: number;
  porcentaje_festivo: number;
}

export interface ConfigApvc {
  third_company_id: number;
  numero_contrato: string;
}

export interface ConfigCcaf {
  third_company_id: number;
  numero_asociado: string;
}

export interface ConfigMutual {
  third_company_id: number;
  codigo_empleador: string;
  porcentaje_tasa_adicional: number;
}

export type NominaFeatureConfig =
  | ConfigGratificacion
  | ConfigHorasExtras
  | ConfigApvc
  | ConfigCcaf
  | ConfigMutual
  | null;

export interface NominaFeatureOption {
  value: string;
  label: string;
}

export interface NominaInstitucion {
  id: number;
  name: string;
}

export interface NominaFeatureOptions {
  operacion?: NominaFeatureOption[];
  proporcionalidad?: NominaFeatureOption[];
  instituciones?: NominaInstitucion[];
}

export interface NominaGlobalEarnDiscount {
  id: number;
  name: string;
  key: string;
}

export interface NominaFeatureSetting {
  feature_key: NominaFeatureKey;
  label: string;
  is_active: boolean;
  global_earn_discount: NominaGlobalEarnDiscount | null;
  config: NominaFeatureConfig;
  options: NominaFeatureOptions;
}
```

- [ ] **Step 6.2: Agregar métodos en NominaApi**

En `src/app/api/nomina/api.ts`, agregar al final de la clase (siguiendo el patrón de los métodos existentes):

```typescript
// Configuraciones de nómina

nomina_settings(company_id: number): Observable<JsonResponse<NominaFeatureSetting[]>> {
  return this._httpClient.get<JsonResponse<NominaFeatureSetting[]>>(
    this._baseApi.setUrl(`company/${company_id}/nomina/settings`),
    { headers: this._baseApi.setHeadersJson() }
  );
}

nomina_toggle_feature(
  company_id: number,
  feature_key: string,
  is_active: boolean
): Observable<JsonResponse<NominaFeatureSetting>> {
  return this._httpClient.patch<JsonResponse<NominaFeatureSetting>>(
    this._baseApi.setUrl(`company/${company_id}/nomina/settings/${feature_key}/toggle`),
    { is_active, feature_key },
    { headers: this._baseApi.setHeadersJson() }
  );
}

nomina_update_feature_config(
  company_id: number,
  feature_key: string,
  config: Record<string, unknown>
): Observable<JsonResponse<NominaFeatureSetting>> {
  return this._httpClient.put<JsonResponse<NominaFeatureSetting>>(
    this._baseApi.setUrl(`company/${company_id}/nomina/settings/${feature_key}/config`),
    { config },
    { headers: this._baseApi.setHeadersJson() }
  );
}
```

Agregar el import de `NominaFeatureSetting` en el archivo:
```typescript
import { NominaFeatureSetting } from 'app/core/models/data/nominaSettings';
```

- [ ] **Step 6.3: Commit**

```bash
git add src/app/core/models/data/nominaSettings.ts \
        src/app/api/nomina/api.ts
git commit -m "feat(nomina): add TypeScript interfaces and API client methods for settings"
```

---

## Task 7: Frontend — SettingsService Angular

**Archivos:**
- Crear: `src/app/modules/admin/nomina/settings/settings.service.ts`

- [ ] **Step 7.1: Implementar el servicio**

```typescript
// src/app/modules/admin/nomina/settings/settings.service.ts
import { Injectable, inject } from '@angular/core';
import { BehaviorSubject, Observable, tap } from 'rxjs';
import { map } from 'rxjs/operators';
import { NominaApi } from 'app/api/nomina/api';
import { UserService } from 'app/core/user/user.service';
import { NominaFeatureSetting } from 'app/core/models/data/nominaSettings';

@Injectable({ providedIn: 'root' })
export class NominaSettingsService {
  private _nominaApi = inject(NominaApi);
  private _userService = inject(UserService);

  private _settings$: BehaviorSubject<NominaFeatureSetting[]> =
    new BehaviorSubject<NominaFeatureSetting[]>([]);

  get settings$(): Observable<NominaFeatureSetting[]> {
    return this._settings$.asObservable();
  }

  getSettings(): Observable<NominaFeatureSetting[]> {
    const companyId = this._userService.currentUser?.company?.id;
    return this._nominaApi.nomina_settings(companyId).pipe(
      map(res => res.data),
      tap(settings => this._settings$.next(settings))
    );
  }

  toggleFeature(featureKey: string, isActive: boolean): Observable<NominaFeatureSetting> {
    const companyId = this._userService.currentUser?.company?.id;
    return this._nominaApi.nomina_toggle_feature(companyId, featureKey, isActive).pipe(
      map(res => res.data),
      tap(updated => {
        const current = this._settings$.getValue();
        const idx = current.findIndex(s => s.feature_key === featureKey);
        if (idx !== -1) {
          current[idx] = { ...current[idx], ...updated };
          this._settings$.next([...current]);
        }
      })
    );
  }

  updateConfig(featureKey: string, config: Record<string, unknown>): Observable<NominaFeatureSetting> {
    const companyId = this._userService.currentUser?.company?.id;
    return this._nominaApi.nomina_update_feature_config(companyId, featureKey, config).pipe(
      map(res => res.data),
      tap(updated => {
        const current = this._settings$.getValue();
        const idx = current.findIndex(s => s.feature_key === featureKey);
        if (idx !== -1) {
          current[idx] = { ...current[idx], ...updated };
          this._settings$.next([...current]);
        }
      })
    );
  }
}
```

- [ ] **Step 7.2: Commit**

```bash
git add src/app/modules/admin/nomina/settings/settings.service.ts
git commit -m "feat(nomina): add Angular NominaSettingsService"
```

---

## Task 8: Frontend — SettingsComponent (cards + formularios dinámicos)

**Archivos:**
- Crear: `src/app/modules/admin/nomina/settings/settings.component.ts`
- Crear: `src/app/modules/admin/nomina/settings/settings.component.html`
- Crear: `src/app/modules/admin/nomina/settings/settings.routes.ts`
- Modificar: routing principal del módulo nómina

- [ ] **Step 8.1: Crear el componente TypeScript**

```typescript
// src/app/modules/admin/nomina/settings/settings.component.ts
import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { AsyncPipe, NgFor, NgIf, NgSwitch, NgSwitchCase } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatDividerModule } from '@angular/material/divider';
import { NominaSettingsService } from './settings.service';
import { NominaFeatureSetting } from 'app/core/models/data/nominaSettings';

@Component({
  selector: 'app-nomina-settings',
  standalone: true,
  imports: [
    AsyncPipe, NgFor, NgIf, NgSwitch, NgSwitchCase,
    ReactiveFormsModule,
    MatCardModule, MatSlideToggleModule, MatFormFieldModule,
    MatInputModule, MatSelectModule, MatCheckboxModule,
    MatButtonModule, MatIconModule, MatDividerModule,
  ],
  templateUrl: './settings.component.html',
})
export class NominaSettingsComponent implements OnInit {
  private _service    = inject(NominaSettingsService);
  private _fb         = inject(FormBuilder);
  private _router     = inject(Router);
  private _route      = inject(ActivatedRoute);

  settings$ = this._service.settings$;

  // Un FormGroup por feature_key
  forms: Record<string, FormGroup> = {};

  // Controla qué cards están expandidos (solo los activos)
  expandedKeys: Set<string> = new Set();

  saving: Record<string, boolean> = {};
  toggling: Record<string, boolean> = {};

  ngOnInit(): void {
    // Los datos ya vienen del resolver; inicializar formularios
    this._service.settings$.subscribe(settings => {
      settings.forEach(s => {
        this.forms[s.feature_key] = this._buildForm(s);
        if (s.is_active) this.expandedKeys.add(s.feature_key);
      });
    });

    // Si viene query param highlight, hacer scroll
    const highlight = this._route.snapshot.queryParamMap.get('highlight');
    if (highlight) {
      setTimeout(() => {
        document.getElementById(`feature-${highlight}`)?.scrollIntoView({ behavior: 'smooth' });
        this.expandedKeys.add(highlight);
      }, 300);
    }
  }

  onToggle(setting: NominaFeatureSetting, isActive: boolean): void {
    this.toggling[setting.feature_key] = true;
    this._service.toggleFeature(setting.feature_key, isActive).subscribe({
      next: () => {
        if (isActive) this.expandedKeys.add(setting.feature_key);
        else this.expandedKeys.delete(setting.feature_key);
        this.toggling[setting.feature_key] = false;
      },
      error: () => { this.toggling[setting.feature_key] = false; }
    });
  }

  onSaveConfig(featureKey: string): void {
    const form = this.forms[featureKey];
    if (form.invalid) { form.markAllAsTouched(); return; }

    this.saving[featureKey] = true;
    this._service.updateConfig(featureKey, form.value).subscribe({
      next: () => { this.saving[featureKey] = false; },
      error: () => { this.saving[featureKey] = false; }
    });
  }

  navigateToConcepts(globalKey: string): void {
    this._router.navigate(['../concepts'], {
      relativeTo: this._route,
      queryParams: { globalKey }
    });
  }

  isExpanded(featureKey: string): boolean {
    return this.expandedKeys.has(featureKey);
  }

  private _buildForm(setting: NominaFeatureSetting): FormGroup {
    const cfg = setting.config as Record<string, unknown> | null ?? {};

    switch (setting.feature_key) {
      case 'GRATIFICACION':
        return this._fb.group({
          porcentaje:           [cfg['porcentaje'] ?? null, [Validators.required, Validators.min(0), Validators.max(100)]],
          es_base_horas_extras: [cfg['es_base_horas_extras'] ?? false, Validators.required],
          operacion:            [cfg['operacion'] ?? null, Validators.required],
          proporcionalidad:     [cfg['proporcionalidad'] ?? null, Validators.required],
        });
      case 'HORAS_EXTRAS':
        return this._fb.group({
          porcentaje_domingo: [cfg['porcentaje_domingo'] ?? null, [Validators.required, Validators.min(0), Validators.max(200)]],
          porcentaje_festivo: [cfg['porcentaje_festivo'] ?? null, [Validators.required, Validators.min(0), Validators.max(200)]],
        });
      case 'APVC':
        return this._fb.group({
          third_company_id: [cfg['third_company_id'] ?? null, Validators.required],
          numero_contrato:  [cfg['numero_contrato']  ?? '',   [Validators.required, Validators.maxLength(50)]],
        });
      case 'CCAF':
        return this._fb.group({
          third_company_id: [cfg['third_company_id'] ?? null, Validators.required],
          numero_asociado:  [cfg['numero_asociado']  ?? '',   [Validators.required, Validators.maxLength(50)]],
        });
      case 'MUTUAL':
        return this._fb.group({
          third_company_id:          [cfg['third_company_id']          ?? null, Validators.required],
          codigo_empleador:          [cfg['codigo_empleador']          ?? '',   [Validators.required, Validators.maxLength(50)]],
          porcentaje_tasa_adicional: [cfg['porcentaje_tasa_adicional'] ?? null, [Validators.required, Validators.min(0), Validators.max(100)]],
        });
      default:
        return this._fb.group({});
    }
  }
}
```

- [ ] **Step 8.2: Crear el template HTML**

```html
<!-- src/app/modules/admin/nomina/settings/settings.component.html -->
<div class="flex flex-col gap-4 p-6">
  <h2 class="text-2xl font-semibold">Configuraciones de Nómina</h2>

  @for (setting of (settings$ | async); track setting.feature_key) {
    <mat-card [id]="'feature-' + setting.feature_key" class="w-full">
      <mat-card-header class="flex items-center justify-between">
        <mat-card-title>{{ setting.label }}</mat-card-title>
        <mat-slide-toggle
          [checked]="setting.is_active"
          [disabled]="toggling[setting.feature_key]"
          (change)="onToggle(setting, $event.checked)">
        </mat-slide-toggle>
      </mat-card-header>

      @if (isExpanded(setting.feature_key) && forms[setting.feature_key]) {
        <mat-card-content class="mt-4">
          <mat-divider class="mb-4"></mat-divider>

          <form [formGroup]="forms[setting.feature_key]">

            <!-- GRATIFICACION -->
            @if (setting.feature_key === 'GRATIFICACION') {
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <mat-form-field>
                  <mat-label>Porcentaje (%)</mat-label>
                  <input matInput type="number" formControlName="porcentaje" min="0" max="100">
                </mat-form-field>

                <mat-checkbox formControlName="es_base_horas_extras" class="self-center">
                  Base para cálculo de Horas Extras
                </mat-checkbox>

                <mat-form-field>
                  <mat-label>Operación</mat-label>
                  <mat-select formControlName="operacion">
                    @for (op of setting.options.operacion; track op.value) {
                      <mat-option [value]="op.value">{{ op.label }}</mat-option>
                    }
                  </mat-select>
                </mat-form-field>

                <mat-form-field>
                  <mat-label>Proporcionalidad</mat-label>
                  <mat-select formControlName="proporcionalidad">
                    @for (p of setting.options.proporcionalidad; track p.value) {
                      <mat-option [value]="p.value">{{ p.label }}</mat-option>
                    }
                  </mat-select>
                </mat-form-field>
              </div>
            }

            <!-- HORAS_EXTRAS -->
            @if (setting.feature_key === 'HORAS_EXTRAS') {
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <mat-form-field>
                  <mat-label>% Recargo Día Domingo</mat-label>
                  <input matInput type="number" formControlName="porcentaje_domingo" min="0" max="200">
                </mat-form-field>
                <mat-form-field>
                  <mat-label>% Recargo Día Festivo</mat-label>
                  <input matInput type="number" formControlName="porcentaje_festivo" min="0" max="200">
                </mat-form-field>
              </div>
            }

            <!-- APVC -->
            @if (setting.feature_key === 'APVC') {
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <mat-form-field>
                  <mat-label>Institución</mat-label>
                  <mat-select formControlName="third_company_id">
                    @for (inst of setting.options.instituciones; track inst.id) {
                      <mat-option [value]="inst.id">{{ inst.name }}</mat-option>
                    }
                  </mat-select>
                </mat-form-field>
                <mat-form-field>
                  <mat-label>Número de Contrato</mat-label>
                  <input matInput formControlName="numero_contrato" maxlength="50">
                </mat-form-field>
              </div>
            }

            <!-- CCAF -->
            @if (setting.feature_key === 'CCAF') {
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <mat-form-field>
                  <mat-label>Institución CCAF</mat-label>
                  <mat-select formControlName="third_company_id">
                    @for (inst of setting.options.instituciones; track inst.id) {
                      <mat-option [value]="inst.id">{{ inst.name }}</mat-option>
                    }
                  </mat-select>
                </mat-form-field>
                <mat-form-field>
                  <mat-label>Número Asociado</mat-label>
                  <input matInput formControlName="numero_asociado" maxlength="50">
                </mat-form-field>
              </div>
            }

            <!-- MUTUAL -->
            @if (setting.feature_key === 'MUTUAL') {
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <mat-form-field>
                  <mat-label>Institución Mutual</mat-label>
                  <mat-select formControlName="third_company_id">
                    @for (inst of setting.options.instituciones; track inst.id) {
                      <mat-option [value]="inst.id">{{ inst.name }}</mat-option>
                    }
                  </mat-select>
                </mat-form-field>
                <mat-form-field>
                  <mat-label>Código Empleador</mat-label>
                  <input matInput formControlName="codigo_empleador" maxlength="50">
                </mat-form-field>
                <mat-form-field>
                  <mat-label>% Tasa Adicional Cargo Empleador</mat-label>
                  <input matInput type="number" formControlName="porcentaje_tasa_adicional" min="0" max="100">
                </mat-form-field>
              </div>
            }

          </form>
        </mat-card-content>

        <mat-card-actions class="flex justify-between px-4 pb-4">
          @if (setting.global_earn_discount) {
            <button mat-stroked-button
              (click)="navigateToConcepts(setting.global_earn_discount!.key)">
              <mat-icon>open_in_new</mat-icon>
              Ver en Conceptos
            </button>
          } @else {
            <span></span>
          }
          <button mat-flat-button color="primary"
            [disabled]="saving[setting.feature_key]"
            (click)="onSaveConfig(setting.feature_key)">
            {{ saving[setting.feature_key] ? 'Guardando...' : 'Guardar' }}
          </button>
        </mat-card-actions>
      }
    </mat-card>
  }
</div>
```

- [ ] **Step 8.3: Crear settings.routes.ts**

```typescript
// src/app/modules/admin/nomina/settings/settings.routes.ts
import { inject } from '@angular/core';
import { Routes } from '@angular/router';
import { CompanySelectedRequiredGuard } from 'app/core/guards/company-selected-required.guard';
import { NominaSettingsComponent } from './settings.component';
import { NominaSettingsService } from './settings.service';

export default [
  {
    path: '',
    canActivate: [CompanySelectedRequiredGuard],
    component: NominaSettingsComponent,
    resolve: {
      settings: () => inject(NominaSettingsService).getSettings(),
    },
  },
] as Routes;
```

- [ ] **Step 8.4: Agregar ruta settings en el routing principal del módulo nómina**

Buscar el routing del módulo nómina (donde está la ruta `concepts`) y agregar:

```typescript
{
  path: 'settings',
  loadChildren: () => import('./settings/settings.routes'),
},
```

- [ ] **Step 8.5: Commit**

```bash
git add src/app/modules/admin/nomina/settings/ \
        src/app/modules/admin/nomina/  # el archivo de routing modificado
git commit -m "feat(nomina): add NominaSettings component with dynamic feature cards"
```

---

## Task 9: Link bidireccional desde módulo Conceptos

**Archivos:**
- Modificar: `src/app/modules/admin/nomina/concepts/list/list.component.ts`
- Modificar: `src/app/modules/admin/nomina/concepts/list/list.component.html`

- [ ] **Step 9.1: Agregar columna y lógica en list.component.ts**

Agregar `Router` e inyectar en el constructor (o con `inject()`), y agregar el método:

```typescript
// En list.component.ts, agregar:
private _router = inject(Router);

navigateToSettings(globalKey: string): void {
  this._router.navigate(['../settings'], {
    relativeTo: this._route, // inyectar ActivatedRoute si no está
    queryParams: { highlight: globalKey }
  });
}
```

En la definición de columnas, agregar `'acciones'` al array si no existe o está al final:
```typescript
displayedColumns: string[] = [
  // ...columnas existentes...,
  'feature_config'  // nueva columna
];
```

- [ ] **Step 9.2: Agregar columna en template HTML**

Dentro de la `mat-table`, agregar la definición de la columna antes del `matColumnDef` de acciones:

```html
<!-- Columna: Configuración de feature (solo para estándar con config disponible) -->
<ng-container matColumnDef="feature_config">
  <th mat-header-cell *matHeaderCellDef></th>
  <td mat-cell *matCellDef="let row">
    @if (row.feature_config_available) {
      <button mat-icon-button
        matTooltip="Configurar en Nómina > Configuraciones"
        (click)="navigateToSettings(row.standard_entity?.key)">
        <mat-icon>settings</mat-icon>
      </button>
    }
  </td>
</ng-container>
```

Agregar `'feature_config'` al array `displayedColumns` del `mat-header-row` y `mat-row`.

- [ ] **Step 9.3: Verificar flujo completo**

1. Ir a Nómina → Conceptos
2. Verificar que los haberes estándar (GRATIFICACION, HORAS_EXTRAS, etc.) muestren el ícono ⚙️
3. Click en ⚙️ → navega a Configuraciones con el card correspondiente abierto
4. Ir a Nómina → Configuraciones
5. Activar un toggle → verificar que el botón "Ver en Conceptos" aparece
6. Click en "Ver en Conceptos" → navega a la lista de conceptos

- [ ] **Step 9.4: Commit final**

```bash
git add src/app/modules/admin/nomina/concepts/list/
git commit -m "feat(nomina): bidirectional link between Concepts and Settings"
```

---

## Cómo agregar una nueva feature en el futuro

Si se necesita agregar, por ejemplo, **Sueldo Mínimo**:

| # | Archivo | Cambio |
|---|---------|--------|
| 1 | `NominaGlobalConceptsSeeder.php` | Agregar registro `{ key: 'SUELDO_MINIMO', ... }` |
| 2 | `NominaFeatureKey.php` | Agregar `case SUELDO_MINIMO = 'SUELDO_MINIMO'` |
| 3 | `NominaSettingsService::getFeatureSchema()` | Agregar `case NominaFeatureKey::SUELDO_MINIMO => [...]` |
| 4 | `NominaSettingsService::getGlobalKeyForFeature()` | Agregar `case NominaFeatureKey::SUELDO_MINIMO => 'SUELDO_MINIMO'` |
| 5 | `NominaSettingsService::getFeatureLabel()` | Agregar label |
| 6 | `nominaSettings.ts` | Agregar interface `ConfigSueldoMinimo` y union type |
| 7 | `settings.component.ts` | Agregar case en `_buildForm()` |
| 8 | `settings.component.html` | Agregar `@if (setting.feature_key === 'SUELDO_MINIMO') { ... }` |

Sin nuevas tablas. Sin cambios en la API. Sin cambios en el routing.

---

## Self-review checklist

- [x] Toggle activa/desactiva feature y sincroniza HaberDescuento de empresa
- [x] Config de Gratificación: porcentaje, base HH.EE, operación (3 opciones), proporcionalidad (3 opciones)
- [x] Config de Horas Extras: % domingo, % festivo
- [x] Config de APVC: institución, número contrato
- [x] Config de CCAF: institución filtrada por categoría CCAF, número asociado
- [x] Config de Mutual: institución filtrada por MUTUAL, código empleador, % tasa adicional
- [x] Provisioning automático al crear empresa
- [x] Lazy init si empresa no tiene rows
- [x] Acceso desde Conceptos → Settings (ícono ⚙️ en haberes estándar)
- [x] Acceso desde Settings → Conceptos (botón "Ver en Conceptos")
- [x] Pattern maintainable: nueva feature = agregar cases, no nuevas tablas
- [x] Permiso `NOMINA.SETTINGS` (submódulo ya creado en migración `2026_03_23_153632_add_nomina_module.php`)

# Pest PHP — Estándares de Testing Laravel 11

> Usa este archivo para cualquier test de backend en el ERP Qdoora.
> Stack: Laravel 11 · Pest PHP · PostgreSQL · RefreshDatabase

---

## Tabla de Contenidos
1. [Configuración y Convenciones](#1-configuración-y-convenciones)
2. [Tests Unitarios — Services](#2-tests-unitarios--services)
3. [Tests Feature — Endpoints API](#3-tests-feature--endpoints-api)
4. [Seguridad Multitenant — Regla de Oro](#4-seguridad-multitenant--regla-de-oro)
5. [Mocks Obligatorios — AWS, Email, SII](#5-mocks-obligatorios--aws-email-sii)
6. [Tests de Módulos Críticos](#6-tests-de-módulos-críticos)

---

## 1. Configuración y Convenciones

```php
// Estructura de carpetas
// tests/
// ├── Unit/           → Services, Helpers, Enums, cálculos puros
// ├── Feature/        → Endpoints HTTP (actingAs + assertStatus)
// └── Pest.php        → configuración global de Pest

// pest.php — configuración base
uses(Tests\TestCase::class, RefreshDatabase::class)->in('Feature');
uses(Tests\TestCase::class)->in('Unit');

// Naming convention: describe lo que el test verifica, no cómo
// ✅ 'calcula correctamente el descuento de AFP para un trabajador dependiente'
// ❌ 'test_payroll_afp_calculation'
```

---

## 2. Tests Unitarios — Services

Los Services son el corazón de la lógica de negocio en Qdoora. Cada método público de un Service
que ejecute cálculos, transformaciones o decisiones de negocio debe tener un test unitario aislado.

```php
// tests/Unit/Payroll/AfpCalculationServiceTest.php
use App\Services\Payroll\AfpCalculationService;
use App\Enums\Payroll\AfpProvider;

describe('AfpCalculationService', function () {
    beforeEach(function () {
        $this->service = new AfpCalculationService();
    });

    it('calcula la cotización de AFP correctamente para renta imponible estándar', function () {
        $rentaImponible = 1_500_000; // CLP
        $proveedor = AfpProvider::CAPITAL;

        $resultado = $this->service->calcularCotizacion($rentaImponible, $proveedor);

        // AFP Capital: tasa 11.44% (2024)
        expect($resultado->monto)->toBe(171_600)
            ->and($resultado->tasa)->toBe(0.1144)
            ->and($resultado->proveedor)->toBe(AfpProvider::CAPITAL);
    });

    it('retorna cero si la renta imponible es menor al mínimo legal', function () {
        $resultado = $this->service->calcularCotizacion(0, AfpProvider::HABITAT);
        expect($resultado->monto)->toBe(0);
    });

    it('aplica el tope imponible cuando la renta supera el máximo legal', function () {
        $rentaExcesiva = 20_000_000;
        $resultado = $this->service->calcularCotizacion($rentaExcesiva, AfpProvider::PROVIDA);
        // El cálculo debe usar el tope, no la renta real
        expect($resultado->baseCalculo)->toBeLessThanOrEqual(config('payroll.tope_imponible'));
    });
});
```

```php
// tests/Unit/Accounting/DoubleEntryValidatorTest.php
use App\Services\Accounting\DoubleEntryValidator;

describe('DoubleEntryValidator', function () {
    it('valida que el debe y haber sean iguales', function () {
        $asientos = [
            ['cuenta' => '1101', 'debe' => 100000, 'haber' => 0],
            ['cuenta' => '2101', 'debe' => 0, 'haber' => 100000],
        ];
        expect(DoubleEntryValidator::validate($asientos))->toBeTrue();
    });

    it('lanza excepción cuando el asiento no está balanceado', function () {
        $asientos = [
            ['cuenta' => '1101', 'debe' => 100000, 'haber' => 0],
            ['cuenta' => '2101', 'debe' => 0, 'haber' => 50000],
        ];
        expect(fn() => DoubleEntryValidator::validate($asientos))
            ->toThrow(\App\Exceptions\UnbalancedEntryException::class);
    });
});
```

---

## 3. Tests Feature — Endpoints API

```php
// tests/Feature/Api/Accounting/VoucherControllerTest.php
use App\Models\User;
use App\Models\Company;
use App\Models\Accounting\Voucher;
use Laravel\Sanctum\Sanctum;

describe('VoucherController', function () {
    beforeEach(function () {
        $this->company = Company::factory()->create();
        $this->user = User::factory()->for($this->company)->create();
        Sanctum::actingAs($this->user);
    });

    it('crea un comprobante con datos válidos', function () {
        $payload = [
            'date'        => now()->format('Y-m-d'),
            'description' => 'Pago proveedor',
            'lines'       => [
                ['account_id' => 1, 'debit' => 100000, 'credit' => 0],
                ['account_id' => 2, 'debit' => 0,      'credit' => 100000],
            ],
        ];

        $this->postJson('/api/accounting/vouchers', $payload)
             ->assertCreated()
             ->assertJsonStructure(['data' => ['id', 'date', 'description', 'lines']]);
    });

    it('rechaza un comprobante con asientos desbalanceados', function () {
        $payload = [
            'date'  => now()->format('Y-m-d'),
            'lines' => [
                ['account_id' => 1, 'debit' => 100000, 'credit' => 0],
                ['account_id' => 2, 'debit' => 0,      'credit' => 50000], // desbalanceado
            ],
        ];

        $this->postJson('/api/accounting/vouchers', $payload)
             ->assertUnprocessable()
             ->assertJsonValidationErrors(['lines']);
    });
});
```

---

## 4. Seguridad Multitenant — Regla de Oro

Todo endpoint protegido DEBE tener estos dos tests. Sin ellos, el PR no puede mergearse.

```php
// tests/Feature/Security/MultitenantAuthorizationTest.php
describe('Aislamiento Multitenant — VoucherController', function () {

    it('bloquea a un usuario sin permiso contable', function () {
        $company = Company::factory()->create();
        $userSinPermiso = User::factory()->for($company)->create(['role' => 'VIEWER']);

        Sanctum::actingAs($userSinPermiso);

        $this->postJson('/api/accounting/vouchers', [/* payload válido */])
             ->assertStatus(403);
    });

    it('bloquea a un usuario que intenta acceder a datos de otra empresa', function () {
        $empresaA  = Company::factory()->create();
        $empresaB  = Company::factory()->create();
        $userA     = User::factory()->for($empresaA)->create();
        $voucherB  = Voucher::factory()->for($empresaB)->create();

        Sanctum::actingAs($userA);

        // Usuario A intenta leer comprobante de Empresa B
        $this->getJson("/api/accounting/vouchers/{$voucherB->id}")
             ->assertStatus(403); // o 404 si usas Global Scope (preferible para no revelar existencia)
    });

    it('permite acceso a un usuario con permisos correctos', function () {
        $company = Company::factory()->create();
        $user    = User::factory()->for($company)->withRole('ACCOUNTANT')->create();
        $voucher = Voucher::factory()->for($company)->create();

        Sanctum::actingAs($user);

        $this->getJson("/api/accounting/vouchers/{$voucher->id}")
             ->assertOk()
             ->assertJsonPath('data.id', $voucher->id);
    });
});
```

---

## 5. Mocks Obligatorios — AWS, Email, SII

```php
// ✅ CORRECTO — S3 con Storage::fake()
it('adjunta evidencia al ticket y la sube a S3', function () {
    Storage::fake('s3');

    $ticket  = Ticket::factory()->create();
    $archivo = UploadedFile::fake()->create('evidencia.pdf', 500);

    $this->actingAs($this->user)
         ->postJson("/api/support/tickets/{$ticket->id}/evidence", [
             'file' => $archivo,
         ])
         ->assertCreated();

    Storage::disk('s3')->assertExists("tickets/{$ticket->id}/evidencia.pdf");
    // ❌ NUNCA: Storage::disk('s3')->put() sin fake → toca S3 real
});

// ✅ CORRECTO — Email con Mail::fake()
it('envía notificación de cambio de email al email anterior', function () {
    Mail::fake();

    $user     = User::factory()->create(['email' => 'original@empresa.cl']);
    $oldEmail = $user->email;

    $this->actingAs($user)
         ->putJson('/api/profile/email', [
             'email'            => 'nuevo@empresa.cl',
             'current_password' => 'Pass1234!',
         ])
         ->assertOk();

    Mail::assertSent(\App\Mail\EmailChangedNotification::class, fn($mail) =>
        $mail->hasTo($oldEmail)
    );
});

// ✅ CORRECTO — API externa SII con Http::fake()
it('emite el DTE al SII usando el proveedor correcto', function () {
    Http::fake([
        'https://api.proveedor-dte.cl/*' => Http::response(['folio' => 12345], 200),
    ]);

    $factura = Factura::factory()->create();

    $resultado = app(DteEmissionService::class)->emitir($factura);

    expect($resultado->folio)->toBe(12345);
    Http::assertSent(fn($req) => str_contains($req->url(), 'api.proveedor-dte.cl'));
});
```

---

## 6. Tests de Módulos Críticos

Para los estándares de cobertura mínima por módulo, leer `references/critical-modules-qa.md`.

```php
// Comandos de ejecución
php artisan test                          // todos los tests
php artisan test --filter=Multitenant     // solo tests de seguridad
php artisan test --coverage               // con cobertura (requiere XDEBUG o PCOV)
php artisan test tests/Feature/Security/ // carpeta específica
```

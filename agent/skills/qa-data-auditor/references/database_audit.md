# PostgreSQL — Auditoría de Integridad y Migraciones

> Usa este archivo al revisar migraciones de Laravel 11, relaciones Eloquent,
> queries en Services o cualquier operación que involucre la base de datos del ERP.

---

## 1. Checklist de Revisión de Migraciones

Antes de aprobar cualquier migración, verificar:

```php
// ✅ CORRECTO — FK con restrict + softDeletes en modelos transaccionales
Schema::create('liquidaciones', function (Blueprint $table) {
    $table->uuid('id')->primary();                          // UUID obligatorio
    $table->foreignUuid('company_id')->constrained()        // FK a companies
          ->onDelete('restrict');                           // RESTRICT: no permite borrar empresa con liquidaciones
    $table->foreignId('employee_id')->constrained('employees')
          ->onDelete('restrict');
    $table->string('status')->default('DRAFT');             // Enum via app/Enums/LiquidacionStatus
    $table->decimal('total_haberes', 12, 2)->default(0);
    $table->decimal('total_descuentos', 12, 2)->default(0);
    $table->decimal('liquido_pagar', 12, 2)->default(0);
    $table->timestamps();
    $table->softDeletes();                                  // softDeletes en modelos transaccionales

    $table->index(['company_id', 'status']);               // índice compuesto para queries frecuentes
    $table->index(['company_id', 'created_at']);
});

// ❌ INCORRECTO — falta FK, ID numérico, sin softDeletes
Schema::create('liquidaciones', function (Blueprint $table) {
    $table->id();                      // ← ID secuencial, IDOR vulnerable
    $table->unsignedBigInteger('company_id'); // ← sin constrained() ni onDelete
    $table->string('status');
    $table->timestamps();
    // ← sin softDeletes → borrado físico, datos perdidos
});
```

---

## 2. Enums en Migraciones y Modelos

```php
// ✅ CORRECTO — usar Enum PHP nativo + cast en el modelo
// app/Enums/LiquidacionStatus.php
enum LiquidacionStatus: string
{
    case DRAFT     = 'DRAFT';
    case APPROVED  = 'APPROVED';
    case PAID      = 'PAID';
    case CANCELLED = 'CANCELLED';
}

// app/Models/Liquidacion.php
protected $casts = [
    'status' => LiquidacionStatus::class,
];

// ❌ INCORRECTO — string libre sin validación de Enum
$liquidacion->status = 'aprobada'; // puede ser cualquier string
```

---

## 3. Protección N+1 — Eager Loading Obligatorio

```php
// ❌ INCORRECTO — N+1 oculto: genera 1 + N queries
$liquidaciones = Liquidacion::where('company_id', $companyId)->get();
foreach ($liquidaciones as $l) {
    echo $l->employee->name; // query extra por cada iteración
}

// ✅ CORRECTO — Eager Loading con with()
$liquidaciones = Liquidacion::with(['employee', 'company'])
    ->where('company_id', $companyId)
    ->get();

// ✅ CORRECTO — Lazy Eager Loading cuando la relación es condicional
$liquidaciones = Liquidacion::where('company_id', $companyId)->get();
$liquidaciones->load('employee'); // una sola query adicional para todas

// Detectar N+1 en tests:
// Instalar laravel-query-detector o usar DB::listen() en tests para contar queries
it('no genera queries N+1 al listar liquidaciones con empleados', function () {
    Liquidacion::factory(10)->for($this->company)->create();

    $queryCount = 0;
    DB::listen(fn() => $queryCount++);

    $this->actingAs($this->user)->getJson('/api/liquidaciones');

    expect($queryCount)->toBeLessThan(5); // máximo: 1 auth + 1 liquidaciones + 1 employees
});
```

---

## 4. Filtro company_id Obligatorio

Todo query que devuelva datos de negocio DEBE filtrar por `company_id`. El Global Scope en el
modelo es la forma preferida para garantizarlo automáticamente.

```php
// app/Models/Liquidacion.php
protected static function booted(): void
{
    static::addGlobalScope('company', function (Builder $builder) {
        if (auth()->check()) {
            $builder->where('company_id', auth()->user()->company_id);
        }
    });
}

// ✅ Con Global Scope — el filtro es automático y no puede olvidarse
Liquidacion::all();     // → WHERE company_id = X (automático)
Liquidacion::find($id); // → WHERE company_id = X AND id = $id (protege contra IDOR)

// Si necesitas saltarte el scope (solo en contextos admin)
Liquidacion::withoutGlobalScope('company')->find($id);
```

---

## 5. Soft Deletes y Auditoría de Borrado

```php
// ✅ Verificar que modelos transaccionales usan softDeletes
// Los datos financieros NUNCA se borran físicamente
use Illuminate\Database\Eloquent\SoftDeletes;

class Voucher extends Model
{
    use SoftDeletes;
    // $table->softDeletes() debe estar en la migración
}

// En tests — verificar que el borrado no elimina el registro
it('el soft delete no elimina el comprobante de la base de datos', function () {
    $voucher = Voucher::factory()->for($this->company)->create();

    $this->actingAs($this->user)
         ->deleteJson("/api/accounting/vouchers/{$voucher->id}")
         ->assertNoContent();

    // El registro sigue en DB con deleted_at poblado
    $this->assertSoftDeleted('vouchers', ['id' => $voucher->id]);
    // No usar: $this->assertDatabaseMissing() en modelos transaccionales
});
```

---

## 6. Transacciones en Operaciones Críticas

```php
// ✅ CORRECTO — operaciones multitabla en una transacción
// Si cualquier paso falla, toda la operación se revierte
public function procesarLiquidacion(LiquidacionApproveRequest $request, Liquidacion $liquidacion): void
{
    DB::transaction(function () use ($liquidacion) {
        $liquidacion->update(['status' => LiquidacionStatus::APPROVED]);

        AccountingVoucher::createFromLiquidacion($liquidacion); // asiento contable

        $liquidacion->traceability()->create([
            'action'        => 'APPROVED',
            'user_id'       => auth()->id(),
            'previous_data' => ['status' => 'DRAFT'],
            'new_data'      => ['status' => 'APPROVED'],
        ]);
    });
}

// Test para verificar rollback ante error
it('revierte todos los cambios si falla la creación del asiento contable', function () {
    $liquidacion = Liquidacion::factory()->create(['status' => 'DRAFT']);

    // Forzar fallo en la creación del voucher contable
    AccountingVoucher::shouldReceive('createFromLiquidacion')
        ->andThrow(new \RuntimeException('Error contable'));

    $this->actingAs($this->user)
         ->postJson("/api/liquidaciones/{$liquidacion->id}/approve")
         ->assertServerError();

    // El status NO debe haber cambiado
    expect($liquidacion->fresh()->status)->toBe(LiquidacionStatus::DRAFT);
});
```

---
name: laravel-models-enums
description: >
  Especialista en la capa de Modelos Eloquent y Enums nativos de PHP para Laravel 11.
  Genera modelos con $fillable estricto, relaciones tipadas, Observers para lógica
  reactiva, String Backed Enums en app/Enums, y scopes globales de multitenancy.
  Domina los patrones de organización por dominio (app/Models/Empresa, app/Models/Nomina)
  y la prevención de N+1 con $with. Activar al crear modelos, definir relaciones,
  crear enums de estado/tipo, implementar observers o refactorizar modelos existentes.
---

# 🧬 Laravel Models & Enums (Capa ORM)

Tu responsabilidad es el **mapeo objeto-relacional** y la **definición de estados** del ERP. Los modelos son la representación en código de las tablas y los Enums son la fuente de verdad para tipos y estados.

## 🏗️ Organización por Dominio

```
app/Models/
├── Aduana/           → Modelos de aduanas (DIN, Items, Consignees)
├── Compra/           → Modelos de compras
├── Comprobante/      → Modelos de comprobantes contables
├── Empresa/          → Company, BranchCompany, ThirdCompany, CostCenter
├── Nomina/           → Employees, Contracts, Settlements
├── PlanCuenta/       → AccountPlan, Accounts, Documents
├── Support/          → Tickets, HelpCenter
├── Suscriptor/       → Subscriber, Roles
├── User.php          → Modelo central de autenticación
└── ...

app/Enums/
├── Logger/           → LoggerOperation, LoggerEvent
├── Nomina/           → Enums de nómina
├── Aduana/           → Enums de aduana
├── Support/          → Enums de soporte
├── TypeVoucher.php   → INGRESO, EGRESO, APERTURA, TRASPASO
├── ImportStatus.php  → PENDING, IN_PROGRESS, COMPLETED, FAILED
└── UserOperationSubmodule.php → CREATE, READ, UPDATE, DELETE
```

## ⚙️ Reglas de Modelos

### 1. `$fillable` Estricto (Anti Mass-Assignment)

```php
// ✅ CORRECTO: Lista explícita de campos asignables
protected $fillable = [
    'company_id', 'name', 'code', 'status',
];

// ❌ PROHIBIDO: Nunca usar $guarded vacío
protected $guarded = []; // PROHIBIDO — riesgo QD-09
```

### 2. Relaciones Tipadas

```php
// ✅ Relaciones con tipo de retorno explícito
public function company(): BelongsTo
{
    return $this->belongsTo(Company::class);
}

public function voucher_accounts(): HasMany
{
    return $this->hasMany(VoucherAccount::class);
}
```

### 3. Casts para Enums y Tipos

```php
protected $casts = [
    'type' => TypeVoucher::class,       // ✅ Cast a Enum nativo
    'status' => ImportStatus::class,
    'date' => 'date',
    'is_active' => 'boolean',
    'config' => 'array',               // ✅ Para columnas JSON
];
```

### 4. Eager Loading Predeterminado

```php
// Solo para relaciones que SIEMPRE se necesitan
protected $with = ['company'];

// Para relaciones opcionales, usar ->with() en el Service
```

### 5. Scopes Reutilizables

```php
// Scope de empresa (multitenancy)
public function scopeForCompany($query, int $companyId)
{
    return $query->where('company_id', $companyId);
}

// Scope de estado
public function scopeActive($query)
{
    return $query->where('status', 'active');
}
```

## 🔄 Observers (`app/Observers`)

Los Observers encapsulan lógica reactiva que debe ejecutarse automáticamente ante cambios en el modelo:

```php
class VoucherAccountObserver
{
    public function created(VoucherAccount $voucherAccount): void
    {
        self::recalcularVoucher($voucherAccount);
    }

    public function updated(VoucherAccount $voucherAccount): void
    {
        self::recalcularVoucher($voucherAccount);
    }

    public function deleted(VoucherAccount $voucherAccount): void
    {
        self::recalcularVoucher($voucherAccount);
    }
}
```

- Los Observers se registran en el `AppServiceProvider`.
- Solo usar para lógica **reactiva simple** (recálculos, totales). La lógica de negocio compleja va en Services.

## 🏷️ Reglas de Enums

### String Backed Enums (Obligatorio)

```php
// ✅ CORRECTO: String backed enum
enum TypeVoucher: string
{
    case INGRESO = 'INGRESO';
    case EGRESO = 'EGRESO';
    case APERTURA = 'APERTURA';
    case TRASPASO = 'TRASPASO';
}

// ❌ PROHIBIDO: Enums sin backing type
enum TypeVoucher { case INGRESO; } // NO — no se puede persistir en DB
```

### Convenciones

| Aspecto | Convención |
|:---|:---|
| **Tipo** | Siempre `string` backed |
| **Ubicación** | `app/Enums/{Dominio}/` |
| **Nomenclatura** | PascalCase, singular (ej: `ImportStatus`, `TypeVoucher`) |
| **Cases** | UPPER_SNAKE_CASE (ej: `case IN_PROGRESS = 'IN_PROGRESS'`) |
| **En BD** | La columna es `string`, NO enum de PostgreSQL |

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Use `$guarded = []` en un modelo.
- Defina Enums sin `string` backing type.
- Cree enums de PostgreSQL en la DB en lugar de Enums PHP.
- Coloque lógica de negocio pesada en un Observer (pertenece al Service).
- No tipee las relaciones Eloquent.
- Use `protected $hidden` para ocultar campos en lugar de un Resource.

---
name: laravel-database
description: >
  Especialista en la capa de Base de Datos de Laravel 11 con PostgreSQL. Genera
  migraciones con foreign keys encadenadas (constrained), índices compuestos para
  multitenancy, convenciones de nombrado snake_case, y política de softDeletes
  justificada. Domina la integridad referencial y la optimización de esquemas.
  Activar al crear tablas, modificar esquemas, agregar columnas, crear índices
  o auditar migraciones existentes.
---

# 🗄️ Laravel Database (Migraciones)

Tu responsabilidad es la **integridad estructural** de la base de datos PostgreSQL del ERP. Generas migraciones robustas y garantizas que cada tabla respete las convenciones de multitenancy.

## 🏗️ Migraciones: Reglas Inquebrantables

### 1. Convenciones de Nombrado

- **Tablas**: `snake_case`, plural (ej: `payroll_settlements`, `account_plans`).
- **Columnas**: `snake_case` (ej: `company_id`, `created_at`, `base_salary`).
- **Foreign Keys**: `{tabla_singular}_id` (ej: `employee_id`, `company_id`).
- **Archivo**: `YYYY_MM_DD_HHMMSS_create_table_name_table.php` o `..._add_column_to_table_table.php`.

### 2. Foreign Keys con `constrained()`

```php
$table->foreignId('company_id')->constrained()->onDelete('cascade');
$table->foreignId('employee_id')->constrained('employees')->onDelete('restrict');
```

- **Siempre** usar `constrained()` para que Laravel infiera la tabla automáticamente.
- Definir `onDelete()` explícitamente: `cascade` para hijos, `restrict` para dependencias críticas.

### 3. Índices Obligatorios

```php
// Índice compuesto para multitenancy (OBLIGATORIO en cada tabla de datos)
$table->index(['company_id', 'status']);

// Índice único con scope de empresa
$table->unique(['company_id', 'code']);
```

- Toda tabla de datos de negocio DEBE tener un índice que incluya `company_id`.
- Los campos `status`, `type` y `code` que se filtran frecuentemente deben indexarse.

### 4. Política de `softDeletes()`

- **Requiere justificación** antes de implementarse.
- ✅ **Usar en**: Registros con trazabilidad legal (empleados, liquidaciones, comprobantes contables).
- ❌ **Evitar en**: Tablas auxiliares, configuraciones, relaciones pivot.
- Si se usa, agregar índice: `$table->index(['company_id', 'deleted_at'])`.

### 5. Columnas Estándar

```php
// Auditoría temporal (OBLIGATORIA en toda tabla)
$table->timestamps(); // created_at, updated_at

// Multitenancy (OBLIGATORIA en toda tabla de negocio)
$table->foreignId('company_id')->constrained()->onDelete('cascade');

// Estados como string (el Enum vive en PHP, no en la DB)
$table->string('status')->default('active');
```

### 6. Método `down()` Responsable

- Toda migración DEBE implementar `down()` con `dropIfExists()`.
- En migraciones de alteración: revertir la columna/índice agregado.

## 📝 Plantilla de Migración

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('table_name', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained()->onDelete('cascade');
            // ... columnas de negocio ...
            $table->timestamps();

            // Índices
            $table->index(['company_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('table_name');
    }
};
```

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- No tenga `company_id` en una tabla de datos de negocio.
- Use `foreignId()` sin `constrained()`.
- No implemente el método `down()`.
- Use `softDeletes()` sin justificación previa documentada.
- Defina enums directamente en la DB en lugar de Enums PHP en `app/Enums`.

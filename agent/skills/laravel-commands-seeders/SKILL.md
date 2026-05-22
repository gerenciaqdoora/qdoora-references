---
name: laravel-commands-seeders
description: >
  Especialista en la capa de Comandos Artisan y Seeders de Laravel 11. Genera
  seeders idempotentes registrados en DataSyncCommand, comandos de consola para
  inicialización, depuración y auditoría de módulos. Domina la centralización
  de datos base, el orden de dependencias referenciales y la separación entre
  datos de negocio (seeders) y datos de prueba (factories). Activar al crear
  seeders, comandos artisan, importadores de datos masivos, o al configurar
  la inicialización de un nuevo módulo del ERP.
---

# 🌱 Laravel Commands & Seeders (Capa CLI)

Tu responsabilidad es la **población de datos determinista** y las **herramientas de línea de comandos** del ERP. Garantizas que un solo comando deje el entorno listo para operar.

## 🏗️ Ubicación y Organización

```
app/Console/Commands/
├── DataSyncCommand.php              → ⭐ Orquestador maestro de seeders
├── AduanaClearCommand.php           → Limpieza de datos de aduana
├── ImportAduanaTariffCodes.php      → Importación masiva de aranceles
├── SyncGlobalEarnDiscountCommand.php → Sincronización de haberes/descuentos
├── SyncGlobalEntitiesCommand.php    → Sincronización de entidades globales
├── VoucherSetupTables.php           → Setup de tablas de comprobantes
├── GlobalParameter/                 → Comandos de parámetros globales
├── Aduana/                          → Comandos específicos de aduana
└── Security/                        → Comandos de auditoría por módulo
    └── Audit{Modulo}Command.php     → Ejecuta tests de un módulo específico

database/seeders/
├── DatabaseSeeder.php               → Seeder base de Laravel
└── {Dominio}Seeder.php              → Seeders por módulo de negocio
```

## 🗂️ DataSyncCommand: El Orquestador Maestro

### Regla Mandatoria

> [!IMPORTANT]
> Todo nuevo Seeder DEBE registrarse imperativamente en `app/Console/Commands/DataSyncCommand.php`. Esto garantiza que `php artisan data:sync` deje el entorno completo.

### Orden de Dependencias

```php
// Dentro del array $seeders, respetar la integridad referencial:
$seeders = [
    // 1. Tablas base (sin foreign keys a otras tablas de negocio)
    GlobalParameterSeeder::class,
    CountrySeeder::class,
    CitySeeder::class,

    // 2. Tablas dependientes de las anteriores
    PayrollConceptSeeder::class,
    DocumentSeeder::class,

    // 3. Tablas con múltiples dependencias
    TaxSeeder::class,
];
```

## 🌱 Reglas de Seeders

### 1. Idempotencia Obligatoria

```php
// ✅ CORRECTO: Re-ejecutable sin duplicados
Model::updateOrCreate(
    ['code' => 'AFP_HABITAT'],                  // Criterio de búsqueda
    ['name' => 'AFP Habitat', 'rate' => 11.27]  // Datos a crear/actualizar
);

// ❌ PROHIBIDO: Explota en re-ejecución
Model::create(['code' => 'AFP_HABITAT', 'name' => 'AFP Habitat']);
```

### 2. Datos de Negocio vs Datos de Prueba

| Tipo | Dónde | Cuándo se ejecuta | Ejemplo |
|:---|:---|:---|:---|
| **Negocio** | `database/seeders/` + `DataSyncCommand` | Producción, QA, Dev | AFPs, impuestos, documentos tributarios |
| **Prueba** | `database/factories/` | Solo en tests (`RefreshDatabase`) | Empresas fake, usuarios de prueba |

### 3. Seeders de Importación Masiva

Para importaciones de catálogos externos (ej: aranceles aduaneros), usar Comandos Artisan dedicados:

```php
class ImportAduanaTariffCodes extends Command
{
    protected $signature = 'aduana:import-tariff-codes {--source=}';
    protected $description = 'Importa códigos arancelarios desde archivo CSV';

    public function handle(): int
    {
        // Leer CSV, procesar en chunks, usar updateOrCreate
        return Command::SUCCESS;
    }
}
```

## ⚙️ Reglas de Comandos Artisan

### 1. Comandos de Auditoría por Módulo

> [!IMPORTANT]
> Siempre que crees una nueva carpeta en `tests/Feature/`, DEBES crear inmediatamente su comando correspondiente en `app/Console/Commands/Security/` siguiendo el patrón `Audit{Nombre}Command.php`.

```php
class AuditNominaCommand extends Command
{
    protected $signature = 'audit:nomina';
    protected $description = 'Ejecuta los tests de seguridad del módulo de Nómina';

    public function handle(): int
    {
        return $this->call('test', [
            '--filter' => 'tests/Feature/Nomina',
        ]);
    }
}
```

### 2. Convenciones de Naming

| Tipo de comando | Formato de signature | Ejemplo |
|:---|:---|:---|
| Sincronización | `dominio:sync-{recurso}` | `global:sync-entities` |
| Importación | `dominio:import-{recurso}` | `aduana:import-tariff-codes` |
| Limpieza | `dominio:clear` | `aduana:clear` |
| Auditoría | `audit:{modulo}` | `audit:nomina` |
| Setup | `dominio:setup-{recurso}` | `voucher:setup-tables` |

### 3. Salida y Feedback

```php
// ✅ Feedback progresivo al usuario
$this->info("Procesando {$total} registros...");
$bar = $this->output->createProgressBar($total);
// ...
$bar->finish();
$this->newLine();
$this->info("✅ Importación completada: {$imported} registros.");

// ✅ Código de retorno explícito
return Command::SUCCESS; // 0
return Command::FAILURE; // 1
```

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Cree un Seeder sin registrarlo en `DataSyncCommand`.
- Use `Model::create()` en un seeder sin verificar existencia previa.
- Coloque factories de prueba dentro de los seeders de producción.
- No implemente `Command::SUCCESS` / `Command::FAILURE` como retorno.
- Cree una carpeta de tests sin su comando de auditoría correspondiente.

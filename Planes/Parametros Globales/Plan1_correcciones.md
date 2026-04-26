# Plan: Punto 1 — Scheduler Backup (Parámetros Globales)

## Contexto

El scheduler principal (`routes/console.php`) despacha el job `ClonePeriodParameters` para clonar parámetros al período siguiente. Si el job falla (DB lock, servidor caído, driver de cola inactivo), no hay reintentos configurados ni mecanismo secundario de recuperación. El período queda sin parámetros y nadie se entera hasta que falla una liquidación.

**Objetivo:** Garantizar que siempre existan parámetros para el período actual, aunque el scheduler principal y/o la cola de jobs fallen.

---

## Diagnóstico técnico confirmado

| Problema | Archivo | Línea |
|---|---|---|
| Sin `$tries`, `$backoff`, ni `$timeout` en el job | `app/Jobs/ClonePeriodParameters.php` | clase completa |
| Sin método `failed()` en el job — fallo silencioso | `app/Jobs/ClonePeriodParameters.php` | clase completa |
| `onFailure()` en schedulers solo loguea en disco | `routes/console.php` | L21-23, L38-40 |
| No existe scheduler de backup | `routes/console.php` | — |

---

## Archivos a modificar (solo 2)

- `qdoora-api/app/Jobs/ClonePeriodParameters.php`
- `qdoora-api/routes/console.php`

---

## Cambios a implementar

### Cambio 1 — `ClonePeriodParameters.php`: Reintentos + alerta en fallo definitivo

Agregar propiedades de reintento y un método `failed()` que envíe mail cuando se agotan los 3 intentos.

```php
// Agregar ANTES del constructor:
public int $tries = 3;
public array $backoff = [60, 300, 900]; // reintentos a 1min, 5min, 15min
public int $timeout = 120;

// Agregar DESPUÉS de handle():
public function failed(\Throwable $exception): void
{
    Log::critical("[ClonePeriodParameters] Job agotó {$this->tries} intentos. Periodo: {$this->targetPeriod}. Error: " . $exception->getMessage());

    try {
        Mail::to(config('services.administrator_mail', env('ADMINISTRATOR_MAIL', 'gerencia@iozean.com')))
            ->send(new \App\Mail\ParameterCloningNotification(
                'error',
                $this->targetPeriod,
                $this->sourcePeriod,
                "Job agotó {$this->tries} intentos. Error definitivo: " . $exception->getMessage()
            ));
    } catch (\Exception $e) {
        Log::error("[ClonePeriodParameters] No se pudo enviar email de alerta en failed(): " . $e->getMessage());
    }
}
```

Agregar imports necesarios:
```php
use Illuminate\Support\Facades\Mail;
use Throwable;
```

---

### Cambio 2 — `routes/console.php`: Agregar dos schedulers de backup

Los backups llaman `ensurePeriodHasData()` **directamente** (sin queue), para ser resilientes cuando el driver de cola está caído. El método ya es idempotente: si los datos existen, retorna `true` sin hacer nada.

**Estrategia de timing:**
- Scheduler principal mensual → último día del mes 23:00 → clona mes siguiente
- **Backup mensual → 1er día del mes 01:00** → verifica que el período actual existe

- Scheduler principal diario → cada día 23:30 → clona día siguiente
- **Backup diario → cada día 00:30** → verifica que el día actual existe (creado ayer a las 23:30)

```php
// BACKUP MENSUAL — corre el día 1 de cada mes a las 01:00
Schedule::call(function () {
    $currentPeriod = Carbon::now()->startOfMonth()->toDateString();

    $cloningService = app(\App\Services\GlobalParameter\ParameterCloningService::class);
    $result = $cloningService->ensurePeriodHasData($currentPeriod, 0, 'monthly');

    if ($result) {
        Log::info("[Scheduler Backup Mensual] Parámetros del período {$currentPeriod} verificados/restaurados.");
    } else {
        Log::critical("[Scheduler Backup Mensual] FALLO CRÍTICO: no se pudieron garantizar parámetros para {$currentPeriod}.");
    }
})
->monthlyOn(1, '01:00')
->onFailure(function () {
    Log::critical("[Scheduler Backup Mensual] El scheduler de backup mensual también falló.");
});

// BACKUP DIARIO — corre cada día a las 00:30
Schedule::call(function () {
    $today = Carbon::today()->toDateString();

    $cloningService = app(\App\Services\GlobalParameter\ParameterCloningService::class);
    $result = $cloningService->ensurePeriodHasData($today, 0, 'daily');

    if ($result) {
        Log::info("[Scheduler Backup Diario] Parámetros del día {$today} verificados/restaurados.");
    } else {
        Log::critical("[Scheduler Backup Diario] FALLO CRÍTICO: no se pudieron garantizar parámetros para {$today}.");
    }
})
->dailyAt('00:30')
->onFailure(function () {
    Log::critical("[Scheduler Backup Diario] El scheduler de backup diario también falló.");
});
```

---

## Cómo funciona el mecanismo completo

```
Scheduler principal (23:00/23:30)
    ↓ despacha ClonePeriodParameters (job en cola)
    ↓ si la cola falla → $tries = 3 con backoff [1min, 5min, 15min]
    ↓ si agotan los 3 intentos → failed() envía email crítico

Scheduler backup (00:30 / 01:00 del día siguiente)
    ↓ llama ensurePeriodHasData() DIRECTAMENTE (sin cola)
    ↓ si ya clonó el job → detecta datos existentes → no hace nada
    ↓ si el job falló → clona en el momento → envía mail de éxito vía ParameterCloningService
    ↓ si la clonación también falla → Log::critical (auditoría mínima garantizada)
```

---

## Verificación

1. Correr `php artisan schedule:list` y confirmar que aparecen los 4 schedules (2 principales + 2 backups).
2. Simular fallo del job comentando temporalmente `handle()` y verificar que `failed()` envía el mail.
3. Simular fallo del scheduler principal borrando parámetros de un período y verificar que el backup los recrea.
4. Verificar en la cola de jobs que tras un fallo, aparecen los reintentos con el delay correcto.

---
name: laravel-jobs-events
description: >
  Especialista en la capa de procesamiento asíncrono y reactividad de Laravel 11.
  Genera Jobs (ShouldQueue), Events (ShouldBroadcast) y configuraciones de canales
  para el ERP QdoorA. Domina la inyección de Services en handle(), el reporte de
  progreso vía Websockets (broadcast), el rollback transaccional en Jobs fallidos
  y la configuración de colas SQS. Activar al crear operaciones masivas, importaciones
  asíncronas, cálculos de nómina en background, notificaciones en tiempo real, o
  cualquier tarea que deba ejecutarse fuera del ciclo request-response.
---

# ⚡ Laravel Jobs & Events (Capa Asíncrona)

Tu responsabilidad es gestionar todo lo que ocurre **fuera del ciclo HTTP síncrono**: importaciones masivas, cálculos de nómina, clonación de períodos y notificaciones en tiempo real.

## 🏗️ Ubicación y Organización

```
app/Jobs/
├── GlobalParameter/          → Jobs de parámetros globales
├── Nomina/                   → Jobs de cálculo de nómina
├── ClonePeriodParameters.php → Clonación de períodos
├── ImportPurchaseJob.php     → Importación RCV compras
├── ImportSaleJob.php         → Importación RCV ventas
└── PropagateGlobalEntityJob.php

app/Events/
├── AccountPlanCloned.php     → Plan de cuentas clonado
├── ParameterCloningProgress.php → Progreso de clonación
├── PayrollMassCalculationCompleted.php → Cálculo masivo finalizado
└── RCVImported.php           → Progreso de importación RCV
```

## ⚙️ Anatomía de un Job Estándar

```php
class ImportSaleJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        protected SesionImportacion $sesion,
        protected User $user
    ) {}

    /**
     * ✅ REGLA: Inyectar Services en handle(), NO en el constructor.
     * El constructor solo recibe datos serializables (Modelos, IDs, arrays).
     */
    public function handle(SaleService $saleService): void
    {
        // 1. Procesar items
        // 2. Reportar progreso vía broadcast
        // 3. Manejar rollback en caso de error
    }
}
```

### Reglas Inquebrantables para Jobs

1. **Inyección en `handle()`**: Los Services se inyectan como parámetros de `handle()`, no del constructor. El constructor solo recibe datos serializables (Modelos Eloquent, IDs, arrays primitivos).
2. **Progreso vía Broadcast**: Para operaciones largas, emitir eventos de progreso con porcentaje:
   ```php
   broadcast(new RCVImported(
       "Documento {$current} de {$total} importado.",
       $userId, 'success', $progress
   ));
   ```
3. **Rollback Manual**: Si un item falla en un lote, eliminar los registros creados previamente antes de relanzar la excepción.
4. **Cola Específica**: Definir la cola por tipo de operación: `$queue = 'imports'`, `$queue = 'payroll'`.

## 📡 Anatomía de un Event Broadcast

```php
class RCVImported implements ShouldBroadcast, ShouldQueue
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $queue = 'imports';

    public function __construct(
        public string $message,
        protected int $user_id,
        public string $status,
        public float $progress = 0
    ) {}

    // ✅ Canal privado con autenticación
    public function broadcastOn()
    {
        return new PrivateChannel("rcvChannel.{$this->user_id}");
    }

    // ✅ Nombre de evento personalizado
    public function broadcastAs(): string
    {
        return 'rcv.imported';
    }

    // ✅ Solo los datos necesarios para el frontend
    public function broadcastWith()
    {
        return [
            'message' => $this->message,
            'status' => $this->status,
            'progress' => $this->progress,
        ];
    }
}
```

### Reglas Inquebrantables para Events

1. **PrivateChannel**: Todo evento de negocio usa `PrivateChannel` con autenticación en `channels.php`.
2. **broadcastAs()**: Siempre definir un nombre custom con formato `modulo.accion` (ej: `rcv.imported`, `payroll.calculated`).
3. **broadcastWith()**: Solo exponer los datos mínimos necesarios. Nunca enviar modelos completos ni datos sensibles.
4. **Cola dedicada**: El evento DEBE especificar `$queue` para no saturar la cola default.

## ⏰ Scheduler (`routes/console.php`)

Las tareas programadas siguen un patrón de **clonación de períodos** y **sincronización de indicadores**:

```php
// Parámetros mensuales → último día del mes a las 23:00
Schedule::call(function () {
    ClonePeriodParameters::dispatch($nextPeriod, $currentPeriod, 'monthly');
})->lastDayOfMonth('23:00');

// Backup de verificación → día 1 a las 01:00
Schedule::call(function () {
    $cloningService = app(ParameterCloningService::class);
    $cloningService->ensurePeriodHasData($currentPeriod, 0, 'monthly');
})->monthlyOn(1, '01:00');
```

- **Siempre** implementar `onSuccess()` y `onFailure()` con logging para trazabilidad.
- Los indicadores económicos (UF, USD, UTM) tienen schedules dedicados.

## 🚨 Señales de Refutación

Rechaza cualquier código que:
- Inyecte Services en el constructor del Job (no es serializable).
- Use `BroadcastChannel` público en lugar de `PrivateChannel`.
- No implemente rollback en Jobs que procesan lotes.
- Defina un Event sin `broadcastAs()` ni `broadcastWith()`.
- No asigne una cola específica a Jobs/Events de operaciones pesadas.

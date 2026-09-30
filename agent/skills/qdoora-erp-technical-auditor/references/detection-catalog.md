# Catálogo de Detección — Auditoría Técnica ERP

> Patrones detectables por eje, con síntoma, criticidad base y remediación en el stack real de QdoorA
> (Laravel 11 · PostgreSQL · Angular 18 Cliente / Angular 21 Zoneless Soporte).
> La criticidad base se **ajusta según volumen de datos y concurrencia real** del módulo auditado.

---

## EJE 1 — Integridad de Datos (Transacciones ACID)

### 1.1 Operación multi-tabla sin transacción
**Síntoma**: un método de Service escribe en 2+ tablas (cabecera + detalle, documento + movimiento contable) sin `DB::transaction()`.
**Riesgo**: si la segunda escritura falla, queda una cabecera huérfana. En Contabilidad esto produce un comprobante descuadrado que **no se puede corregir** (registros históricos inmutables).
**Criticidad base**: 🔴 CRÍTICA.

```php
// ❌ HALLAZGO
$voucher = Voucher::create($data);
foreach ($lines as $line) {
    VoucherLine::create([...$line, 'voucher_id' => $voucher->id]); // si falla: cabecera sin líneas
}

// ✅ REMEDIACIÓN
return DB::transaction(function () use ($data, $lines) {
    $voucher = Voucher::create($data);
    $voucher->lines()->createMany($lines);
    $this->assertBalanced($voucher); // lanza excepción → rollback automático
    return $voucher;
});
```

### 1.2 Side effects irreversibles dentro de la transacción
**Síntoma**: subida a S3, envío de correo, `dispatch()` de un Job o llamada HTTP al SII **dentro** del `DB::transaction()`.
**Riesgo doble**: (a) si la transacción hace rollback, el efecto externo ya ocurrió (correo enviado de un documento inexistente); (b) el Job puede ejecutarse antes del `COMMIT` y no encontrar el registro.
**Criticidad base**: 🟠 ALTA.

```php
// ✅ REMEDIACIÓN: efectos externos después del commit
$dte = DB::transaction(fn () => $this->createDte($data));
DteSendJob::dispatch($dte->id)->afterCommit(); // o mover fuera del closure
```

### 1.3 Captura de excepción que anula el rollback
**Síntoma**: `try/catch` **dentro** del closure de la transacción que loguea y continúa, en vez de relanzar.
**Riesgo**: la transacción commitea un estado parcial. Es el fallo de integridad más silencioso.
**Criticidad base**: 🔴 CRÍTICA.

### 1.4 Rollback manual sin `DB::rollBack()` en todos los caminos
**Síntoma**: uso de `DB::beginTransaction()` con retornos tempranos (`return` / `throw`) que no pasan por el rollback.
**Remediación**: preferir siempre el closure `DB::transaction()`, que gestiona commit/rollback automáticamente.
**Criticidad base**: 🟠 ALTA.

### 1.5 Estado derivado sin fuente única de verdad
**Síntoma**: un saldo, total o stock se guarda desnormalizado y se actualiza con `increment()`/`decrement()` desde varios Services.
**Riesgo**: divergencia permanente entre el agregado y el detalle. Sin un recálculo de reconciliación, el error es indetectable.
**Criticidad base**: 🟠 ALTA (🔴 si es un saldo contable o de tesorería).

---

## EJE 2 — Concurrencia (Race Conditions)

### 2.1 Correlativo/folio calculado con `MAX()+1`
**Síntoma**: `$next = Model::where('company_id', $id)->max('number') + 1;` fuera de un lock.
**Riesgo**: dos peticiones simultáneas obtienen el mismo número → **folio DTE duplicado rechazado por el SII**, o dos comprobantes con el mismo correlativo. Es el hallazgo más frecuente y más caro en un ERP.
**Criticidad base**: 🔴 CRÍTICA.

```php
// ✅ REMEDIACIÓN A — Bloqueo pesimista sobre la fila del correlativo
return DB::transaction(function () use ($companyId, $type) {
    $sequence = DocumentSequence::where('company_id', $companyId)
        ->where('document_type', $type)
        ->lockForUpdate()   // SELECT ... FOR UPDATE: serializa a los competidores
        ->first();

    if (!$sequence) {
        throw new BusinessException('No existe correlativo configurado para el tipo de documento.');
    }

    $sequence->increment('last_number');
    return $sequence->last_number;
});
```
**Remediación B (defensa en profundidad)**: índice único compuesto `UNIQUE (company_id, document_type, number)` en la migración. Sin él, cualquier bug futuro vuelve a duplicar.

### 2.2 Patrón "leer → decidir → escribir" (check-then-act)
**Síntoma**: se lee un estado (`if ($doc->status === 'pendiente')`), se hace trabajo y luego se escribe, sin lock ni condición en el `UPDATE`.
**Riesgo**: doble contabilización del mismo documento, doble pago, doble envío al SII.
**Criticidad base**: 🔴 CRÍTICA si el efecto es financiero; 🟠 ALTA en el resto.

```php
// ✅ REMEDIACIÓN — UPDATE condicional atómico (compare-and-swap)
$claimed = Document::where('id', $id)
    ->where('company_id', $companyId)
    ->where('status', DocumentStatus::PENDING->value)
    ->update(['status' => DocumentStatus::PROCESSING->value]);

if ($claimed === 0) {
    throw new BusinessException('El documento ya fue procesado por otra operación.');
}
```

### 2.3 Bloqueo pesimista mal dimensionado
**Síntoma**: `lockForUpdate()` sobre un rango amplio (`where('company_id', $id)->lockForUpdate()->get()`) o lock sostenido mientras se hace I/O externo.
**Riesgo**: serialización de toda la empresa; el ERP "se congela" para todos los usuarios de ese tenant.
**Criticidad base**: 🟠 ALTA.
**Remediación**: bloquear la **mínima fila necesaria**, nunca un listado; sacar el I/O externo del lock.

### 2.4 Bloqueo optimista ausente en edición concurrente
**Síntoma**: dos usuarios editan la misma ficha (empleado, producto, configuración) y el último sobrescribe silenciosamente al primero (*lost update*).
**Criticidad base**: 🟡 MEDIA (🟠 ALTA si son datos de nómina o parámetros de cálculo).

```php
// ✅ REMEDIACIÓN — version tracking (bloqueo optimista)
// Migración: $table->unsignedInteger('version')->default(0);
$affected = Employee::where('id', $id)
    ->where('company_id', $companyId)
    ->where('version', $request->version)   // versión que el cliente leyó
    ->update([...$data, 'version' => $request->version + 1]);

if ($affected === 0) {
    throw new BusinessException('El registro fue modificado por otro usuario. Recargue e intente nuevamente.');
}
```

### 2.5 `firstOrCreate` / `updateOrCreate` sin índice único
**Síntoma**: se confía en el método de Eloquent para evitar duplicados, sin constraint en base de datos.
**Riesgo**: dos peticiones concurrentes pasan ambas por la rama `create`.
**Criticidad base**: 🟠 ALTA.

### 2.6 Job idempotente por omisión
**Síntoma**: un Job de cola (SQS) que centraliza, envía o calcula sin marca de idempotencia. SQS garantiza *at-least-once*: **el Job se reintentará**.
**Riesgo**: doble centralización contable, doble liquidación.
**Criticidad base**: 🔴 CRÍTICA si el efecto es financiero.
**Remediación**: clave de idempotencia persistida + verificación al inicio de `handle()`, o `ShouldBeUnique`.

---

## EJE 3 — Rendimiento Backend (PostgreSQL + Eloquent)

### 3.1 Consulta N+1
**Síntoma**: iteración sobre una colección accediendo a una relación (`$line->product->name`, `$employee->contract->salary`) sin `with()`.
**Criticidad base**: 🟡 MEDIA en catálogos pequeños · 🟠 ALTA sobre listados operativos (libro de compras/ventas, líneas de nómina, movimientos de conciliación).

```php
// ❌ 1 + N consultas
$vouchers = Voucher::where('company_id', $companyId)->get();
foreach ($vouchers as $v) { $total += $v->lines->sum('amount'); }

// ✅ REMEDIACIÓN A — Eager loading
$vouchers = Voucher::with('lines:id,voucher_id,amount')->where('company_id', $companyId)->get();

// ✅ REMEDIACIÓN B — mejor aún: agregar en SQL, no en PHP
$totals = VoucherLine::selectRaw('voucher_id, SUM(amount) AS total')
    ->whereIn('voucher_id', $ids)
    ->groupBy('voucher_id')
    ->pluck('total', 'voucher_id');
```

### 3.2 Índice faltante en filtro multi-tenant
**Síntoma**: tabla de alto volumen filtrada por `company_id` + otra columna (`period`, `status`, `document_date`) sin índice compuesto.
**Riesgo**: *sequential scan* que crece linealmente con todos los tenants; el módulo se degrada a medida que entran clientes.
**Criticidad base**: 🟠 ALTA (🔴 si la tabla supera el millón de filas).

```php
// ✅ REMEDIACIÓN — el orden importa: primero la columna de igualdad más selectiva
$table->index(['company_id', 'period', 'status'], 'idx_vouchers_company_period_status');
```
**Verificación exigible**: `EXPLAIN ANALYZE` de la consulta real. No afirmes "falta índice" sin revisar la migración.

### 3.3 Agregación o filtrado en PHP en vez de SQL
**Síntoma**: `->get()->filter(...)->sum(...)`, `collect($rows)->groupBy(...)` sobre miles de registros.
**Riesgo**: memoria del contenedor + latencia. En exportaciones masivas provoca `Allowed memory size exhausted`.
**Criticidad base**: 🟠 ALTA en reportes/exportaciones · 🟡 MEDIA en el resto.

### 3.4 Listado sin paginación server-side
**Síntoma**: endpoint que retorna `->get()` de una tabla operativa completa.
**Riesgo**: payload de decenas de MB; el navegador y la API se saturan con el mismo tenant grande.
**Criticidad base**: 🟠 ALTA.
**Remediación QdoorA**: paginación server-side con el trait `PaginatesResults` en el Service + `generic-table` en el frontend (ver skill `qdoora-new-table-page`).

### 3.5 Over-fetching (`SELECT *` y Resources gordos)
**Síntoma**: `Model::all()` / ausencia de `select()`, o un `JsonResource` que carga relaciones que la vista no usa.
**Riesgo**: ancho de banda y memoria desperdiciados; además **riesgo de exposición** de columnas sensibles.
**Criticidad base**: 🟡 MEDIA.
**Remediación**: `select()` explícito + `whenLoaded()` en el Resource.

### 3.6 Operación masiva síncrona
**Síntoma**: importación, centralización por lote o cálculo de nómina de toda la empresa dentro del ciclo request-response.
**Riesgo**: timeout de nginx/PHP-FPM a mitad de proceso → estado parcial + usuario sin feedback.
**Criticidad base**: 🟠 ALTA.
**Remediación**: mover a Job (`ShouldQueue`) con reporte de progreso vía broadcast (ver skill `qdoora-laravel-jobs-events`).

### 3.7 Inserción masiva fila por fila
**Síntoma**: `foreach ($rows as $row) { Model::create($row); }` con miles de filas.
**Remediación**: `insert()` por lotes (chunks de 500–1000) dentro de la transacción.
**Criticidad base**: 🟡 MEDIA (🟠 ALTA sobre 10.000 filas).

---

## EJE 4 — Rendimiento Frontend (Interfaz Ligera)

### 4.1 Ruta/módulo pesado sin lazy loading
**Síntoma**: componente de módulo grande importado estáticamente en las rutas raíz.
**Riesgo**: bundle inicial inflado; login lento para todos, incluso para quien nunca abre ese módulo.
**Criticidad base**: 🟡 MEDIA (🟠 ALTA si infla el *initial bundle* de forma notoria).
**Remediación**: `loadComponent: () => import('./x/x.component').then(m => m.XComponent)` y `@defer` para bloques pesados (gráficos, visores PDF).

### 4.2 Tabla larga sin virtualización ni paginación
**Síntoma**: `@for` sobre cientos/miles de filas renderizadas al DOM completo.
**Riesgo**: el navegador **se congela segundos** al abrir la vista; scroll con saltos.
**Criticidad base**: 🟠 ALTA.
**Remediación por orden de preferencia**:
1. Paginación server-side con `generic-table` (estándar QdoorA — resuelve el problema en el origen).
2. `cdk-virtual-scroll-viewport` del CDK si el dataset debe estar completo en cliente.
3. `@for (item of items; track item.id)` — **`track` por id, nunca por `$index`**, o Angular recrea todo el DOM en cada cambio.

### 4.3 Cambio de detección por defecto en componentes de listado
**Síntoma**: componente sin `ChangeDetectionStrategy.OnPush` (Portal Cliente, Angular 18) o con estado mutable en vez de signals (Portal Soporte, Angular 21 zoneless).
**Criticidad base**: 🟡 MEDIA.

### 4.4 Cálculo o llamada a función en el template
**Síntoma**: `{{ calcularTotal(item) }}`, `[disabled]="validarPermisos()"`, o un pipe impuro dentro de un `@for`.
**Riesgo**: la función se reevalúa en **cada ciclo** de detección de cambios, multiplicado por cada fila.
**Criticidad base**: 🟡 MEDIA (🟠 ALTA dentro de una tabla larga).
**Remediación**: `computed()` / signal derivada, o precalcular el campo en el modelo de la fila.

### 4.5 DTO pesado hacia el frontend
**Síntoma**: la respuesta del listado incluye relaciones anidadas completas que la tabla no muestra (empresa completa, historial, adjuntos en base64).
**Riesgo**: payload multiplicado por N filas; parseo JSON que bloquea el hilo principal.
**Criticidad base**: 🟡 MEDIA (🟠 ALTA si viaja binario/base64).
**Remediación**: DTO de listado plano y delgado; el detalle se pide al abrir el registro.

### 4.6 Fugas de suscripción y peticiones en cascada
**Síntoma**: `subscribe()` sin `takeUntilDestroyed()`; peticiones encadenadas secuencialmente que podrían ir en paralelo (`forkJoin`); búsqueda sin `debounceTime` + `distinctUntilChanged`.
**Criticidad base**: 🟡 MEDIA.

---

## EJE 5 — Seguridad

### 5.1 Brecha multi-tenant (consulta sin `company_id`)
**Síntoma**: cualquier query que no fuerce el filtro de la empresa del token.
**Riesgo**: un tenant lee o modifica datos de otro. En un SaaS B2B chileno esto es incidente reportable, no un bug.
**Criticidad base**: 🔴 CRÍTICA — **siempre**, sin importar el volumen.

### 5.2 IDOR (Insecure Direct Object Reference)
**Síntoma**: el `id` llega por request y se usa directo, sin validar pertenencia a la empresa/usuario del token.
**Criticidad base**: 🔴 CRÍTICA.

```php
// ✅ REMEDIACIÓN — validar pertenencia en el FormRequest (authorize) y en el Service
public function authorize(): bool
{
    $companyId = auth()->user()->current_company_id;

    return Document::where('id', $this->route('document'))
        ->where('company_id', $companyId)
        ->exists();
}
```

### 5.3 Validación de input ausente o permisiva
**Síntoma**: se leen datos con `$request->all()` / `$request->input()` sin FormRequest; reglas sin tipo, sin `max`, sin `exists` con scope de empresa.
**Riesgo**: mass assignment, montos negativos, fechas fuera de período contable cerrado, desbordes numéricos.
**Criticidad base**: 🟠 ALTA (🔴 si permite mass assignment sobre campos de estado o `company_id`).
**Nota QdoorA**: `exists:table,id` **sin** cláusula de empresa es una brecha multi-tenant disfrazada de validación:
```php
'third_company_id' => ['required', Rule::exists('third_companies', 'id')->where('company_id', $companyId)],
```

### 5.4 SQL crudo con interpolación
**Síntoma**: `DB::raw("... WHERE name = '{$request->name}'")`, `whereRaw` con concatenación, `orderByRaw` con columna que viene del request.
**Riesgo**: inyección SQL.
**Criticidad base**: 🔴 CRÍTICA.
**Remediación**: bindings (`whereRaw('x = ?', [$value])`) y, para ordenamiento dinámico, **whitelist** de columnas permitidas.

### 5.5 Manejo inseguro de sesión y tokens
**Síntomas y criticidad**:
- Token/permisos de admin en `localStorage` → 🟠 ALTA (estándar QdoorA: `sessionStorage`).
- JWT sin expiración corta o sin rotación de refresh token → 🟠 ALTA.
- Cookies de sesión sin `HttpOnly` + `Secure` + `SameSite` → 🟠 ALTA.
- Autorización decidida en el cliente (menús ocultos sin guard server-side) → 🔴 CRÍTICA (vector QD-01).
- Endpoint de autenticación sin rate limiting (`throttle.api`) → 🟠 ALTA.

### 5.6 Fuga de información
**Síntoma**: modelo Eloquent retornado crudo desde el controlador (expone `password_hash`, tokens, columnas internas); traza de excepción devuelta al cliente; secretos en logs.
**Criticidad base**: 🟠 ALTA (🔴 si expone credenciales — vector QD-02).
**Remediación**: `JsonResource` con campos explícitos + `$hidden` en el modelo + handler global de excepciones con mensaje en español.

### 5.7 Archivos y almacenamiento
**Síntoma**: escritura en disco local del contenedor en vez de S3; ausencia de validación de `mime`/tamaño en la subida; URL de descarga sin firmar.
**Criticidad base**: 🟠 ALTA.

---

## Ajuste de Criticidad por Contexto

Antes de fijar la etiqueta final, pondera:

| Factor | Sube la criticidad | Baja la criticidad |
|--------|--------------------|--------------------|
| Volumen de la tabla | > 100k filas y creciendo | catálogo fijo < 1k |
| Concurrencia | varios usuarios/jobs sobre el mismo registro | operación de un solo usuario |
| Reversibilidad | registro histórico inmutable (Contabilidad, Nómina, Aduana, Facturación) | dato editable sin trazabilidad legal |
| Alcance del fallo | afecta a todos los tenants | afecta una pantalla poco usada |
| Exposición | endpoint público o de bajo privilegio | comando interno de mantención |

**Regla de desempate**: si el fallo puede producir un **documento tributario incorrecto o duplicado** ante el SII, o una **liquidación de nómina errónea**, es CRÍTICA por definición.

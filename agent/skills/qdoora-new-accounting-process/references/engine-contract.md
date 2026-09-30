# Contrato del Motor Genérico (`AccountingEntryService`)

El motor recibe líneas **ya resueltas** por el dominio y aplica lo transversal: inversión por reversa, cuadratura, persistencia. No conoce reglas de negocio — no sabe qué es un "valor afecto", una "gratificación" ni un "flete internacional".

**No abre transacción**: la controla el servicio dueño del documento, que además persiste la vinculación del voucher en su propio modelo. **No se expone por endpoints**: es infraestructura interna de Contabilidad.

## La spec: expresa la naturaleza como dato

La spec es un array plano con los datos del documento y las constantes del dominio. Su valor está en que **elimina los `if` de la lógica de armado**. Comparación real entre venta y compra — difieren en 7 campos y en nada más:

| Campo | Venta | Compra |
|---|---|---|
| `operation` | `sale` | `purchase` |
| `third_id` | `client_id` | `provider_id` |
| `tax_module` | `venta` | `compra` |
| `master_third` | `CLIENTE_NACIONAL` | `PROVEEDOR_NACIONAL` |
| `master_iva` | `IVA_DEBITO_FISCAL` | `IVA_CREDITO_FISCAL` |
| `base_side` / `third_side` | `credit` / `debit` | `debit` / `credit` |
| `voucher_origin` | `LIBRO_VENTA` | `LIBRO_COMPRA` |

Gracias a eso `RcvCentralizationService` no tiene un solo `if ($esVenta)` en la lógica de armado (solo uno cosmético para la glosa "Cliente"/"Proveedor"). **Si tu resolutor empieza a ramificar por tipo de documento, mueve esa diferencia a la spec.**

```php
/** Spec del dominio para el motor de centralización. */
private function buildSpec(MiDocumento $doc): array
{
    return [
        'company_id'        => $doc->company_id,
        'third_id'          => $doc->tercero_id,
        // Constantes del dominio: la naturaleza vive aquí, no en ifs
        'base_side'         => 'debit',
        'third_side'        => 'credit',
        'master_third'      => AccountCategories::HONORARIO_POR_PAGAR,
        // Montos
        'amount_bruto'      => (float) $doc->total_bruto,
        'amount_retencion'  => (float) $doc->retencion,
        'amount_total'      => (float) $doc->total,
        // Cabecera del comprobante
        'voucher_origin'    => VoucherType::BOLETA_HONORARIO->value,
        'voucher_type_code' => TypeVoucher::TRASPASO->value,
        'norma'             => NormaVoucher::AMBOS->value,
    ];
}
```

### Valores válidos de la cabecera

| Campo | Enum | Valores |
|---|---|---|
| `voucher_origin` | `App\Enums\VoucherType` | `CC` manual · `LV` libro venta · `LC` libro compra · `BH` boleta honorario · `LR` nómina · `TS` tesorería · `AP` apertura · `CR` cierre |
| `voucher_type_code` | `App\Enums\TypeVoucher` | `INGRESO` · `EGRESO` · `TRASPASO` · `APERTURA` |
| `norma` | `App\Enums\NormaVoucher` | `AMBOS` · `TRIBUTARIO` · `IFRS` |

Un proceso automático nuevo casi siempre usa `TRASPASO` + `AMBOS`, y necesita su **propio** `VoucherType` si no encaja en los existentes.

## `buildLine(array $node, array $attributes): array`

Arma una línea a partir de un nodo contable ya resuelto.

```php
$lines[] = $this->accountingEntryService->buildLine($node, [
    'concept'        => 'retencion',        // clave estable, la usa el frontend
    'label'          => 'Retención',        // glosa en español
    'side'           => $spec['base_side'], // 'debit' | 'credit'
    'amount'         => $monto,             // se redondea a 2 decimales
    'auxiliary_id'   => $config->auxiliary_id,   // opcional
    'cost_center_id' => $config->cost_center_id, // opcional
    'max_amount'     => $montoTotal,        // SOLO la línea de cobro/pago
]);
```

El `$node` viene de `nodeFromModel()`, `resolveMasterNode()` o `resolveTaxNode*()` y tiene el shape `{node_id, type, account_label}`.

> **`max_amount` es lo que habilita la línea en Tesorería.** Solo la línea del tercero (la partida por cobrar/pagar) lo lleva; el resto va con `0`. Ponerlo en varias líneas ofrece a Tesorería partidas que no corresponden.

## `postEntry(array $header, array $lines, ?User $user): array{id, year}`

```php
return $this->accountingEntryService->postEntry(
    [
        'company_id'        => $spec['company_id'],
        'date'              => $fechaDMY,        // OBLIGATORIO formato 'd/m/Y'
        'voucher_origin'    => $spec['voucher_origin'],
        'voucher_type_code' => $spec['voucher_type_code'],
        'norma'             => $spec['norma'],
        'currency'          => 'CLP',
        'description'       => $doc->description,
        'document_id'       => $doc->doc_id,
        'document_number'   => (string) $doc->num_doc,
        'is_note_credit'    => false,            // true invierte TODAS las líneas
    ],
    $lines,
    $user   // nullable: un scheduler contabiliza como "sistema"
);
```

Lo que hace por ti, en orden:

1. Rechaza líneas vacías
2. Si `is_note_credit`, invierte los lados (`invertEntryLines`)
3. **Cuadratura obligatoria** (`assertLinesBalanced`) — nunca persiste un asiento descuadrado
4. Crea la cabecera del comprobante
5. Inserta los movimientos **en lote**, con un único recálculo al cerrar

`$user` nullable es intencional: los procesos automáticos (scheduler RCV) contabilizan como sistema.

## Lo que el motor NO hace

- **No valida requisitos de cuenta.** Inserta lo que le des. Auxiliar y centro de costo se validan al configurar la imputación, no aquí.
- **No abre transacción.** Es tuya.
- **No muta tu documento.** El `voucher_id`, `voucher_year` y `accounting_status` los persiste el servicio dueño (Service Ownership, regla HARD REJECT #4).

## Orden obligatorio en el servicio dueño

```php
$this->assertCentralizable($doc);              // 1. guarda temprana, sin bloqueo

$spec = $this->buildSpec($doc);
$resolution = $this->xCentralizationService->resolverCuentas($spec);

if (!empty($resolution['missing'])) {          // 2. faltan cuentas -> queda PENDING
    $detalle = $this->xCentralizationService->describeMissing($resolution['missing']);
    throw new GenericException("No se puede centralizar: faltan cuentas ({$detalle}).");
}

// 3. DDL FUERA de la transacción de negocio
$this->voucherPartitionService->ensureYearForDate($doc->date);

DB::transaction(function () use ($doc, $spec, $resolution, $user) {
    // 4. relectura con bloqueo: serializa manual + masivo + scheduler
    $locked = MiDocumento::where('id', $doc->id)->lockForUpdate()->first();
    if (!$locked) throw new GenericException('Documento no está disponible.');

    $this->assertCentralizable($locked);       // 5. segunda guarda, la real

    $voucher = $this->xCentralizationService->crearComprobante(...);

    $doc->update([                             // 6. vinculación y estado
        'voucher_id'        => $voucher['id'],
        'voucher_year'      => $voucher['year'],
        'accounting_status' => DocumentAccountingStatus::JOURNALIZED->value,
        'updated_at'        => Carbon::now('America/Santiago'),
    ]);
});
```

Cada paso responde a un fallo real: sin el 3 el DDL queda atado al rollback; sin el 4 y 5 dos procesos concurrentes generan dos comprobantes para el mismo documento.

## Contratos de modelo

Si tu documento va a participar de la re-contabilización reactiva, implementa `App\Contracts\JournalizableDocument` (`getAccountingStatus`, `getVoucherId`, `getVoucherYear`, `getCompanyId`, `isJournalized`, `isSiiLocked`, `getAccountingSyncService`) y que su servicio implemente `App\Contracts\SyncableAccountingDocument`.

## Vía legacy: no la repitas

`HonorariumSlipService` y `TreasuryService` todavía llaman `VoucherService::crearCabeceraComprobante()` + `crearCuentasComprobante()` directo. Eso **salta la cuadratura obligatoria y la inversión por reversa**. Es deuda técnica conocida, no un patrón a copiar: todo proceso nuevo entra por `postEntry`.

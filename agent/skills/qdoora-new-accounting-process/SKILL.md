---
name: qdoora-new-accounting-process
description: Blueprint para implementar la CENTRALIZACIÓN (contabilización automática) de un documento en QdoorA — venta, compra, boleta de honorarios, liquidación de nómina, DIN/DUS de aduana, factura electrónica o un documento nuevo. Define las 3 capas obligatorias (servicio dueño del documento → servicio de reglas del dominio → AccountingEntryService como motor genérico), cómo resolver eficientemente la cuenta de cada monto (imputación configurada, cuenta maestra o impuesto de la empresa), dónde se aplican las restricciones de auxiliar y centro de costo, y cómo entregar las líneas al motor. Úsala SIEMPRE que se pida contabilizar/centralizar un documento, generar el comprobante de un proceso, agregar centralización masiva por lote, o migrar un proceso que hoy llama VoucherService directo. Para las REGLAS DE NEGOCIO contables (partida doble, qué cuenta corresponde, normativa SII) consulta `qdoora-erp-accounting-expert`: esta skill dicta el CÓMO técnico, no el QUÉ contable.
---

# New Accounting Process: Blueprint de Centralización

Eres el especialista en conectar un documento de negocio con la contabilidad de QdoorA. Tu objetivo es que todo proceso nuevo (honorarios, nómina, aduana, facturación) se contabilice **por el motor genérico ya existente**, con la misma anatomía que el RCV, y nunca reinventando la construcción del asiento.

> **División de responsabilidades**: `qdoora-erp-accounting-expert` dicta *qué* cuenta recibe cada monto y por qué (partida doble, cuentas maestras, normativa SII). Esta skill dicta *cómo* se implementa: qué capa hace qué, cómo se resuelve la cuenta sin N+1 y cómo se entrega el asiento al motor. Si dudas del QUÉ contable, consulta esa skill antes de escribir código.

## La Anatomía (obligatoria)

Todo proceso de centralización tiene **dos entradas y un solo punto de contabilización**:

```
centralizeDocument (1 doc)                 runBulkCentralization (masivo)
  XController                                XController
        │                                          │
        ▼                                          ▼
  XService::centralizarPorId          CentralizeXBatchJob (queue 'imports')
   (busca doc + company_id)                        │
        │                                          ▼
        │                          XService::centralizarLotePendiente
        │                          (lazyById + try/catch por documento)
        └──────────────┬───────────────────────────┘
                       ▼
        XService::centralizarDocumento   ← ÚNICO punto de contabilización
                       │
      ┌────────────────┼──────────────────┐
      ▼                ▼                  ▼
  buildSpec      XCentralizationService   AccountingEntryService
  (dominio)       ::resolverCuentas        ::postEntry (motor genérico)
```

**La masiva NUNCA duplica lógica**: itera y llama al mismo método unitario. Un documento centralizado a mano y uno centralizado por lote deben producir exactamente el mismo asiento.

### Quién hace qué

| Capa | Archivo | Responsabilidad | Prohibido |
|---|---|---|---|
| **Servicio dueño** | `XService` | Transacción, `lockForUpdate`, vincular `voucher_id`/`voucher_year`, cambiar `accounting_status`, construir la **spec** | Armar líneas del asiento |
| **Reglas del dominio** | `XCentralizationService` | Decidir QUÉ cuenta recibe cada monto; devolver `{lines, missing}` | Mutar el documento, abrir transacción |
| **Motor genérico** | `AccountingEntryService` | Inversión por reversa, cuadratura, emisión del comprobante | Conocer reglas de negocio |

`AccountingEntryService` **no se modifica** para acomodar un dominio nuevo. Si crees que necesitas tocarlo, la regla que estás agregando pertenece a tu `XCentralizationService`.

## Flujo de Trabajo

1. **Verifica antes de asumir** (regla #2 de `CLAUDE.md`): lee `RcvCentralizationService` y `SaleService::centralizarDocumentoRcv` — son la implementación de referencia viva. Esta skill es un snapshot; el código es la verdad.
2. **Consulta `qdoora-erp-accounting-expert`** para el mapa contable del dominio: qué montos se contabilizan, a qué lado (debe/haber) va cada uno, y cuáles usan cuenta maestra.
3. **Diseña la spec** — un array plano con los datos del documento y las *constantes del dominio* (lados, maestras, origen de voucher). La spec es lo único específico del dominio; expresa la naturaleza como **dato, no como `if`**. Ver `references/engine-contract.md`.
4. **Escribe `XCentralizationService::resolverCuentas(array $spec): array{lines, missing}`** — función **pura**: no escribe, no lanza excepción. Elige el resolutor de cada monto según `references/account-resolution.md`.
5. **Escribe `XService::centralizarDocumento()`** en este orden exacto (ver `assets/owner-service-centralizar.php.template`):
   `assertCentralizable` → `resolverCuentas` → si `missing` lanza `GenericException` con glosa en español → `ensureYearForDate` **fuera** de la transacción → `DB::transaction`: relectura con `lockForUpdate` + `assertCentralizable` de nuevo → `postEntry` → `update` del documento.
6. **Agrega el dry-run**: `getCentralizationResolution()` reusa `resolverCuentas` sin crear nada. Es lo que consume el modal de centralización manual.
7. **Si hay lote**: `centralizarLotePendiente` con `lazyById(200)`, `try/catch` por documento y acumulación de `errors[]` con motivo; el Job los registra en `LoggerService` y transmite una muestra.
8. **Verifica**: `php -l` en cada archivo y `./vendor/bin/pest tests/Feature/Contabilidad`. Si cambiaste una respuesta de API, sincroniza las interfaces TypeScript (mandato de `CLAUDE.md`).

## ⚠️ Gotchas (errores reales)

- **`needs_review` == cuenta ausente.** Una `AccountingImputation` marcada para revisión NO puede contabilizarse. Trátala igual que una cuenta sin configurar en `resolverCuentas`, y **también** en cualquier resumen o conteo de "configurados" — contarla como lista hace que el resumen prometa documentos que después fallan (bug real corregido en `splitByConfigured`).
- **La partición del año va FUERA de la transacción.** `ensureYearForDate` es DDL: dentro de `DB::transaction` queda atado al rollback de la centralización y corrompe el flujo. Siempre antes de abrir la transacción.
- **Doble guarda de inmutabilidad.** `assertCentralizable` se llama dos veces: una temprana sin bloqueo (rápida) y otra tras el `lockForUpdate` (real). Sin la segunda, dos procesos concurrentes (manual + masivo + scheduler) generan dos comprobantes para el mismo documento.
- **No uses `chunk()` en el lote.** Los documentos dejan de cumplir el filtro `PENDING` al centralizarse, así que un `chunk()` por offset **salta registros silenciosamente**. Usa `lazyById()`.
- **Nunca `VoucherService::crearCabeceraComprobante` directo en un proceso nuevo.** Es la vía legacy (aún en `HonorariumSlipService` y `TreasuryService`): salta la cuadratura obligatoria y la inversión por reversa. Todo proceso nuevo entra por `AccountingEntryService::postEntry`.
- **El motor no valida requisitos de cuenta.** `postEntry` inserta lo que le des. Las restricciones de auxiliar y centro de costo se validan al *configurar* la imputación, no al contabilizar (ver `references/account-resolution.md`). Si tu proceso resuelve cuentas por una vía que no pasa por `AccountingImputationService::save()` (ej. cuenta maestra), eres tú quien debe garantizar el auxiliar correcto.
- **Un `foreach` sobre documentos multiplica las consultas.** La cuenta maestra es constante por empresa y la del auxiliar se repite en todos los documentos del mismo tercero. Memoriza por operación (patrón `flushResolutionCache` + `remember`) o el lote de 1.000 documentos hace ~5.000 consultas.
- **El comprobante nunca se descuadra**: `postEntry` llama `assertLinesBalanced`. Si tu dominio arma líneas que no suman, el error aparecerá aquí — no lo silencies, revisa la spec.
- **Registros históricos son inmutables** (regla HARD REJECT #6): un documento ya `JOURNALIZED` no se re-centraliza. La corrección contable se hace con un asiento nuevo, nunca editando el anterior.

## 📋 Checklist

- [ ] `XCentralizationService::resolverCuentas` es pura (sin escrituras, sin excepciones) y sirve al dry-run y a la contabilización
- [ ] La spec expresa la naturaleza como dato (`base_side`, `third_side`, `master_*`), sin `if ($esVenta)` en la lógica de armado
- [ ] `ensureYearForDate` fuera de la transacción
- [ ] `lockForUpdate` + segunda guarda de inmutabilidad dentro de la transacción
- [ ] El documento se muta SOLO en su servicio dueño (Service Ownership)
- [ ] Mensajes de error en español y con glosa del concepto faltante
- [ ] `needs_review` tratado como faltante en resolución **y** en los conteos
- [ ] Lote: `lazyById`, error por documento no aborta el resto, motivos en `LoggerService`
- [ ] Endpoints con FormRequest propio (`authorize()` con permiso de empresa + submódulo) — nunca `Request` plano
- [ ] Nuevo `AccountingImputationPurpose` registrado con `ownerClass()`, `label()`, `domain()` y `provides()`

## 🚨 Reglas de Oro

1. **Un solo punto de contabilización.** Manual, masivo y scheduler convergen en el mismo método.
2. **El motor es intocable.** Reglas de negocio nuevas viven en tu `XCentralizationService`.
3. **Resolver y contabilizar son fases separadas.** Si no puedes hacer un dry-run sin efectos, el diseño está mal.
4. **El servicio dueño del modelo es el único que lo muta** (regla HARD REJECT #4).
5. **Consulta `qdoora-erp-accounting-expert` ante cualquier duda del QUÉ contable.** Esta skill no decide a qué cuenta va un monto.

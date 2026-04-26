# Cobertura Mínima por Módulo Crítico

> Este archivo define los tests OBLIGATORIOS antes de mergear cualquier PR en los módulos
> críticos del ERP: Nómina, Contabilidad y Aduana.
> Un PR sin esta cobertura debe ser rechazado por el QA Auditor.

---

## 💰 Módulo REMUNERACIONES (Nómina)

Los cálculos de remuneraciones afectan directamente los ingresos de personas reales. Un error
aquí tiene consecuencias legales y económicas. La cobertura es no-negociable.

### Tests Obligatorios Backend (Pest)

| Test | Descripción | Archivo sugerido |
|---|---|---|
| Cálculo AFP por proveedor | Verifica tasa correcta para cada AFP (Habitat, Capital, Provida, etc.) | `Unit/Payroll/AfpCalculationServiceTest.php` |
| Cálculo Isapre/Fonasa | Verifica cotización de salud según plan | `Unit/Payroll/HealthCalculationServiceTest.php` |
| Tope imponible | No calcula sobre el máximo legal | `Unit/Payroll/ImposableLimitTest.php` |
| Gratificación legal | Calcula correctamente el 25% o 4.75% según corresponda | `Unit/Payroll/GratificationServiceTest.php` |
| Horas extras | Diferencia entre 50% y 100% recargo | `Unit/Payroll/OvertimeCalculationTest.php` |
| Liquidación final | Resultado total coincide con suma de haberes menos descuentos | `Unit/Payroll/FinalLiquidationTest.php` |
| Multitenant — acceso entre empresas | Usuario de empresa A no ve liquidaciones de empresa B | `Feature/Security/PayrollMultitenantTest.php` |
| Permiso de aprobación | Solo rol PAYROLL_APPROVER puede aprobar liquidaciones | `Feature/Security/PayrollAuthorizationTest.php` |
| Mock de email Previred | El envío no toca el servicio SMTP real | `Feature/Payroll/PreviredExportTest.php` |

### Tests Obligatorios Frontend (Jest)

| Test | Descripción |
|---|---|
| LiquidacionDetailComponent | Muestra todos los haberes y descuentos correctamente |
| PayrollCalculatorService | Los valores calculados coinciden con los del backend (smoke test) |
| FormatAmountPipe | Montos negativos, cero y decimales se muestran correctamente |

---

## ⚖️ Módulo CONTABILIDAD

La contabilidad es la fuente de verdad financiera de la empresa. Los asientos deben estar siempre
balanceados y los datos nunca deben mezclarse entre empresas.

### Tests Obligatorios Backend (Pest)

| Test | Descripción | Archivo sugerido |
|---|---|---|
| Partida doble | El debe siempre iguala el haber | `Unit/Accounting/DoubleEntryValidatorTest.php` |
| Comprobante multitenant | Solo se ven comprobantes de la propia empresa | `Feature/Security/AccountingMultitenantTest.php` |
| Cierre de periodo | No se pueden crear asientos en un periodo cerrado | `Unit/Accounting/PeriodStatusTest.php` |
| Tipo de cambio UF/UTM | Se usa el valor del día correcto desde GlobalVariable | `Unit/Accounting/ExchangeRateApplicationTest.php` |
| Mock de SII | El DTE no se emite realmente en tests | `Feature/Accounting/DteEmissionTest.php` |
| Libro de ventas/compras | Los totales coinciden con la suma de documentos del periodo | `Unit/Accounting/BookTotalsTest.php` |

### Tests Obligatorios Frontend (Jest)

| Test | Descripción |
|---|---|
| VoucherListComponent | Muestra la lista paginada y filtra correctamente por fecha |
| VoucherService | Adjunta el header de Authorization en cada request |
| AccountBalanceComponent | Los saldos se muestran con el signo correcto (Debe/Haber) |

---

## 🚢 Módulo ADUANA

Los documentos aduaneros son registros legales. Un error en el número de DIN o en los datos de
un manifiesto puede generar multas o rechazos en la aduana.

### Tests Obligatorios Backend (Pest)

| Test | Descripción | Archivo sugerido |
|---|---|---|
| Estado del DIN | Las transiciones de estado siguen la máquina de estado definida | `Unit/Customs/DinStateMachineTest.php` |
| Descarga de documentos S3 | Solo se puede descargar con company_id válido | `Feature/Security/DocumentAccessTest.php` |
| UUID en documentos | No se aceptan IDs numéricos secuenciales en la ruta | `Feature/Customs/DocumentUuidTest.php` |
| Mock de S3 | Ningún test sube archivos reales a S3 | `Feature/Customs/DocumentUploadTest.php` |
| Presigned URL expira en 5 min | La URL generada tiene TTL ≤ 5 minutos | `Unit/Customs/PresignedUrlExpiryTest.php` |
| Libro Circunstanciado | Los registros del libro cuadran con los DINs del periodo | `Unit/Customs/LedgerBalanceTest.php` |

### Tests Obligatorios Frontend (Jest)

| Test | Descripción |
|---|---|
| DinFormComponent | Los campos de cabecera se validan antes de enviar |
| DocumentDownloadService | La URL de descarga se solicita correctamente al backend |
| DinStateBadgeComponent | El badge muestra el color/texto correcto por estado |

---

## 🎟️ Módulo SOPORTE (Portal Soporte/Admin — Angular 21)

### Tests Obligatorios Frontend (Vitest)

| Test | Descripción |
|---|---|
| TicketStatusMachine | Todas las transiciones válidas e inválidas cubiertas |
| TicketDetailComponent | Renderiza correctamente el estado, prioridad y cliente |
| TraceabilityService | Se registra la traza después de cada cambio de estado |
| PermissionGuard | Valida contra el backend — no contra localStorage |
| TicketInteractionComponent | Las notas internas no se muestran al cliente |

---

## 📊 Cobertura Mínima Esperada

| Módulo | Cobertura Unitaria | Cobertura Feature |
|---|---|---|
| Nómina | ≥ 90% en Services de cálculo | 100% en tests de multitenant |
| Contabilidad | ≥ 85% en validators y services | 100% en tests de multitenant |
| Aduana | ≥ 80% en state machines y services | 100% en tests de descarga S3 |
| Soporte | ≥ 80% en state machine y traceabilidad | 100% en tests de guards |

```bash
# Verificar cobertura en Laravel
php artisan test --coverage --min=80

# Verificar cobertura en Angular 18
ng test --coverage --codeCoverageExclude="**/*.module.ts"

# Verificar cobertura en Angular 21
vitest run --coverage
```

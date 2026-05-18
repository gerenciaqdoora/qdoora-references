# Motor de Cálculo de Liquidación de Remuneraciones

## Resumen del Estado Actual

El sistema ya cuenta con una estructura base funcional:

- ✅ `LiquidacionService.php` existe con ~486 líneas
- ✅ Tablas `liquidaciones` y `liquidacion_novedades` creadas
- ✅ Modelos `Liquidacion`, `LiquidacionNovedad`, `EmployeeRemuneration`, `EmployeeWorkContract` presentes
- ✅ Enums `GratificationType`, `ContractType`, `OvertimeSubtype`, `AbsenceSubtype` definidos

**Problema crítico identificado:** El `generateOrRefreshLiquidacion` actual es un monolito que calcula incorrectamente. Específicamente:

- El `imponible_total` se calcula como `base_salary + haberesImponibles` (duplicando el sueldo base ya incluido en novedades)
- No calcula AFP, Salud, AFC ni Impuesto Único (los descuentos legales)
- No diferencia la lógica de mes parcial vs. mes completo para sueldo base
- El Sueldo Base no crea su registro en `liquidacion_novedades` (lo suma hardcodeado)
- La Gratificación no está implementada en el flujo de cálculo
- El `liquid_total` sería incorrecto porque los descuentos legales no existen

---

## Arquitectura Propuesta: Motor por Capas

```
LiquidacionService (Orquestador)
│
├── LiquidacionContextBuilder (Prepara el contexto: UF, UTM, parámetros, días)
│
├── Calculators/
│   ├── SueldoBaseCalculator       → Sueldo Base (mes completo/parcial) + registro novedad
│   ├── GratificacionCalculator    → Gratificación mensual/legal + registro novedad
│   ├── HorasExtrasCalculator      → VHO + HE por subtype + Horas Atraso + registros novedades
│   ├── AfpCalculator              → AFP Trabajador + SIS Empleador
│   ├── SaludCalculator            → Fonasa / Isapre + Adicional Isapre
│   ├── AfcCalculator              → Seguro Cesantía (Indefinido / Plazo Fijo / +11 años)
│   └── ImpuestoUnicoCalculator    → Tramos SII en UTM → pesos
│
└── LiquidacionCentralizadorService → Genera asiento contable vía evento
```

---

## Propuesta de Cambios

### Componente 1: Migraciones de Base de Datos

#### [MODIFY] `liquidaciones` — Campos faltantes para desglose legal

La tabla actual no tiene columnas para almacenar los totales de descuentos legales individuales. Necesitamos ampliarla para tener trazabilidad en el asiento contable.

**Nueva migración:** `2026_05_XX_000000_add_legal_totals_to_liquidaciones_table.php`

Campos a agregar:

```php
$table->decimal('dias_trabajados', 5, 2)->default(30);
$table->decimal('afp_trabajador', 14, 2)->default(0);
$table->decimal('sis_empleador', 14, 2)->default(0);
$table->decimal('salud_total', 14, 2)->default(0);
$table->decimal('afc_trabajador', 14, 2)->default(0);
$table->decimal('afc_empleador', 14, 2)->default(0);
$table->decimal('impuesto_unico', 14, 2)->default(0);
$table->decimal('tributable_total', 14, 2)->default(0); // VTHI - AFP - Salud
$table->decimal('descuentos_legales_total', 14, 2)->default(0);
$table->decimal('descuentos_voluntarios_total', 14, 2)->default(0);
// Snapshot de UF/UTM del período (inmutabilidad histórica)
$table->decimal('uf_valor', 14, 4)->nullable();
$table->decimal('utm_valor', 14, 4)->nullable();
```

> [!IMPORTANT]
> La adición de `tributable_total` elimina el campo duplicado del servicio actual donde se igualaba al `imponible_total`.

---

### Componente 2: Contexto del Cálculo (Value Object)

#### [NEW] `app/Services/Nomina/Calculators/LiquidacionContext.php`

Un objeto de datos (no un service) que se construye una sola vez al inicio del cálculo y se pasa a todos los calculadores. Evita N+1 queries.

```php
class LiquidacionContext
{
    public float $valorUF;
    public float $valorUTM;
    public float $sueldoMinimo;
    public float $factorIMM;
    public float $taa;          // Tope AFP en pesos (TAA * UF)
    public float $tsc;          // Tope AFC en pesos (TSC * UF)
    public array $tramosImpuesto; // Tabla SII en UTM
    public array $leyes;        // Porcentajes leyes sociales
    public int $diasTrabajados;
    public bool $mesParcial;
    public EmployeeRemuneration $remuneration;
    public EmployeeWorkContract $contract;
    public ?array $afpData;     // GlobalList AFP seleccionada
    public string $healthType;  // 'FONASA' | 'ISAPRE'
    public string $contractCategory; // 'INDEFINIDO' | 'PLAZO_FIJO' | 'ONCE_ANIOS'
}
```

#### [NEW] `app/Services/Nomina/Calculators/LiquidacionContextBuilder.php`

Responsable de construir el `LiquidacionContext`:

1. Consultar UF (último día del mes) via `ExchangeRateService` con fallback a `exchange_rate_cache`
2. Consultar UTM (primer día del mes) via `ExchangeRateService`
3. Consultar parámetros globales: `SUELDOS_GRATIFICACIONES`, `LEYES_SOCIALES`, `TRAMOS_IMPUESTO`
4. Calcular `dias_trabajados` desde `liquidacion_novedades` (ausencias) y `employee_work_contract` (inicio/fin contrato)
5. Determinar si el mes es **completo o parcial**
6. Clasificar el contrato: `INDEFINIDO`, `PLAZO_FIJO`, o `ONCE_ANIOS` (contrato con +11 años)

---

### Componente 3: Calculadores Especializados

#### [NEW] `app/Services/Nomina/Calculators/SueldoBaseCalculator.php`

```
Lógica:
1. Leer salary_unit (CLP/UF) y base_salary de EmployeeRemuneration
2. Si UF → base_salary * context->valorUF
3. Si mes completo → Sueldo Base = valor calculado
4. Si mes parcial → Sueldo Base = (valor / 30) * context->diasTrabajados
5. Crear/Actualizar registro en liquidacion_novedades con key='SUELDO_BASE'
Retorna: float $sueldoBase
```

#### [NEW] `app/Services/Nomina/Calculators/GratificacionCalculator.php`

```
Lógica:
1. Verificar payroll_earnings_discounts where key='GRATIFICACION' AND is_active=true
2. Si no activa → return 0
3. Calcular tope = (context->factorIMM * context->sueldoMinimo) / 12
4. LEGAL_GARANTIZADA_25 → paga tope directamente
5. MENSUAL_25 → min(sueldoBase * 0.25, tope)
6. Si mes parcial → proporcionar por diasTrabajados / 30
7. Crear registro novedad con key='GRATIFICACION'
Retorna: float $gratificacion
```

#### [MODIFY] `app/Services/Nomina/Calculators/HorasExtrasCalculator.php`

> Refactorizar `recalculateOvertimeNovedades()` actual.

```
Lógica actual corregida:
1. Calcular VHO correctamente con la fórmula del manual:
   - MENSUAL: ((sueldoBase + gratificacion*) / 30) * (7 / jornadaSemanal)
   - SEMANAL: sueldoSemanal / jornadaSemanal
   - DIARIO: (sueldoDiario + semana_corrida) / horasTrabajadas
   - POR_HORA: valor_hora_pactado + (semana_corrida / horas_semana)
2. Calcular Valor HE por subtipo con factor correcto
3. Calcular Horas Atraso: VHO * THD * -1 → novedad DESCUENTO
Corrección crítica: La fórmula actual usa (28/30) que es incorrecta.
La fórmula correcta es (7 / jornadaSemanal).
```

#### [NEW] `app/Services/Nomina/Calculators/AfpCalculator.php`

```
Lógica:
1. Base AFP efectiva = min(VTHI, context->taa)
2. Cotización AFP = BaseAFP * tasa_trabajador (desde GlobalList AFP)
3. SIS Empleador = BaseAFP * tasa_SIS (H/M según gender en EmployeeProfile)
4. Crear novedad: AFP con key='AFP' (trabajador)
5. SIS Empleador NO genera novedad de descuento, solo se almacena en liquidacion.sis_empleador
Retorna: ['afp' => float, 'sis_empleador' => float, 'base_afp' => float]
```

#### [NEW] `app/Services/Nomina/Calculators/SaludCalculator.php`

```
Lógica:
1. Determinar tipo: FONASA o ISAPRE desde health_id
2. FONASA: cotizacion = BaseAFP * 0.07 → novedad key='SALUD_FONASA'
3. ISAPRE:
   a. Monto mínimo = BaseAFP * 0.07
   b. Plan pesos = health_additional_amount * UF (si health_payment_unit='UF')
   c. Cotización = max(mínimo, plan pesos) → novedad key='SALUD_ISAPRE'
   d. Si plan > mínimo → adicional = plan - mínimo → novedad key='ADICIONAL_ISAPRE'
Retorna: float $saludTotal
```

#### [NEW] `app/Services/Nomina/Calculators/AfcCalculator.php`

```
Lógica:
1. Base AFC = min(VTHI, context->tsc)
2. Clasificar contrato: INDEFINIDO | PLAZO_FIJO/OBRA | ONCE_ANIOS (>11 años)
   - ONCE_ANIOS: verificar start_date del primer contrato activo INDEFINIDO → si > 11 años
3. Calcular:
   - INDEFINIDO: Trabajador = Base * 0.6%, Empleador = Base * 2.4%
   - PLAZO_FIJO: Trabajador = $0, Empleador = Base * 3.0%
   - ONCE_ANIOS: Trabajador = $0, Empleador = Base * 0.8%
4. Si AFC trabajador > 0: novedad key='FONDO_CENSATIA_TRABAJADOR'
Retorna: ['afc_trabajador' => float, 'afc_empleador' => float]
```

#### [NEW] `app/Services/Nomina/Calculators/ImpuestoUnicoCalculator.php`

```
Lógica:
1. Base Tributable = VTHI - AFP_Trabajador - Salud
2. Renta en UTM = Base Tributable / context->valorUTM
3. Buscar tramo en context->tramosImpuesto (ordenados por límite inferior UTM)
4. Impuesto UTM = (Renta_UTM * factor_tramo) - rebaja_tramo
5. Impuesto Pesos = Impuesto_UTM * context->valorUTM
6. Si <= 0 → Impuesto = $0
7. Redondear a entero chileno (round)
Retorna: float $impuestoUnico
```

---

### Componente 4: Refactorización del Orquestador Principal

#### [MODIFY] `app/Services/Nomina/LiquidacionService.php`

Refactorizar `generateOrRefreshLiquidacion()` para orquestar los calculadores:

```php
// Flujo correcto:
$context = LiquidacionContextBuilder::build($liquidacion, $period);

// 1. Calcular Sueldo Base (registra novedad)
$sueldoBase = SueldoBaseCalculator::calculate($liquidacion, $context);

// 2. Calcular Gratificación (registra novedad)
$gratificacion = GratificacionCalculator::calculate($liquidacion, $context, $sueldoBase);

// 3. Sincronizar movimientos de ficha (haberes/descuentos fijos)
$this->syncMovimientosFicha($liquidacion, $employeeId, $period);

// 4. Recalcular Horas Extras y Atraso (actualiza novedades existentes)
HorasExtrasCalculator::recalculate($liquidacion, $context, $sueldoBase, $gratificacion);

// 5. Leer VTHI y VTHNI desde novedades
$vthi = $novedades->filter(imponibles)->sum('amount');
$vthni = $novedades->filter(noImponibles)->sum('amount');
$vthi_total = $vthi; // No sumar base_salary por separado, ya está en novedades

// 6. Descuentos Legales
$afp    = AfpCalculator::calculate($liquidacion, $context, $vthi);
$salud  = SaludCalculator::calculate($liquidacion, $context, $afp['base_afp']);
$afc    = AfcCalculator::calculate($liquidacion, $context, $vthi);
$impuesto = ImpuestoUnicoCalculator::calculate($context, $vthi, $afp['afp'], $salud);

// 7. Descuentos Voluntarios
$descuentosVoluntarios = $novedades->filter(descuentos_voluntarios)->sum('amount');

// 8. Calcular Sueldo Líquido
$totalDescuentosLegales = $afp['afp'] + $salud + $afc['afc_trabajador'] + $impuesto;
$sueldoLiquido = ($vthi + $vthni) - $totalDescuentosLegales - abs($descuentosVoluntarios);

// 9. Persistir snapshot en liquidacion
$liquidacion->update([...todos los campos...]);

// 10. Emitir evento para asiento contable - Para futuro - Existira boton de centralizacion contable desde portal
// Nunca se ejecutara de manera automatica en los calculos de liquidacion
new LiquidacionCalculadaEvent($liquidacion)
```

> [!WARNING]
> **Cambio de lógica crítico:** El `imponible_total` actual suma `base_salary + haberesImponibles`, lo cual **duplica** el sueldo base cuando este ya existe como novedad. El nuevo flujo lo elimina: el VTHI es simplemente la suma de todas las novedades con `type='IMPONIBLE'`.

---

### Componente 5: Job Asíncrono para Procesamiento Masivo

#### [NEW] `app/Jobs/Nomina/CalculateMonthlyPayrollJob.php`

Para el cierre de mes (todas las liquidaciones de un período), que solo considere los empleados que no tengan una liquidacion, con esto se asegura de la existencia pero no toca las realizadas por el cliente:

```php
class CalculateMonthlyPayrollJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 300;
    public int $tries = 3;

    public function __construct(
        private readonly int $companyId,
        private readonly string $period
    ) {}

    public function handle(LiquidacionService $service): void
    {
        // Obtener empleados activos y calcular uno a uno en chunks
        ThirdCompany::where('company_id', $this->companyId)
            ->isEmployee()
            ->whereHas('workContracts', fn($q) => $q->where('is_active', true))
            ->chunk(50, function ($employees) use ($service) {
                foreach ($employees as $employee) {
                    $service->generateOrRefreshLiquidacion(
                        $this->companyId,
                        $employee->id,
                        $this->period
                    );
                }
            });
    }
}
```

---

### Componente 6: Evento de Centralización Contable

#### [NEW] `app/Events/Nomina/LiquidacionCalculadaEvent.php`

```php
// El PayrollService emite este evento.
// El módulo de Contabilidad lo escucha en un Listener separado.
// Respeta Service Ownership: Nómina NO escribe en tablas contables.
// Por ahora solo un mapeo, sin ejecucion real
class LiquidacionCalculadaEvent
{
    public function __construct(public readonly Liquidacion $liquidacion) {}
}
```

#### [NEW] `app/Listeners/Nomina/GenerarAsientoLiquidacionListener.php`

Implementa la lógica del asiento:

```
DEBE:
  Gasto Remuneraciones = haberes_total
  Gasto SIS Empleador  = sis_empleador
  Gasto AFC Empleador  = afc_empleador

HABER:
  Sueldos por Pagar    = liquid_total
  AFP por Pagar        = afp_trabajador
  Salud por Pagar      = salud_total
  AFC por Pagar        = afc_trabajador + afc_empleador
  Impuesto por Pagar   = impuesto_unico

Verificar: Total DEBE == Total HABER
```

---

### Componente 7: FormRequests de Seguridad

#### [NEW] `app/Http/Requests/Nomina/CalculateLiquidacionRequest.php`

```php
// authorize(): Valida NOMINA.LIQUIDACIONES + CREATE
// rules(): company_id, period (YYYY-MM format), employee_ids? (array para masivo)
```

#### [MODIFY] `app/Http/Requests/Nomina/AddNovedadRequest.php`

Agregar validaciones faltantes para `subtype` según `type` seleccionado.

---

### Componente 8: Interfaces TypeScript (Angular)

#### [MODIFY] `fuse-starter/src/app/modules/nomina/liquidacion/`

Interfaces a crear/actualizar:

```typescript
export interface ILiquidacion {
  id: number;
  period: string;
  status: 'BORRADOR' | 'GENERADA' | 'ENVIADA';
  diasTrabajados: number;
  sueldoBase: number;
  gratificacion: number;
  vthi: number; // Total Haberes Imponibles
  vthni: number; // Total Haberes No Imponibles
  haberesTotal: number;
  afpTrabajador: number;
  sisEmpleador: number;
  saludTotal: number;
  afcTrabajador: number;
  afcEmpleador: number;
  impuestoUnico: number;
  descuentosLegalesTotal: number;
  descuentosVoluntariosTotal: number;
  descuentosTotal: number;
  liquidTotal: number; // Sueldo Líquido
  ufValor: number;
  utmValor: number;
  calculatedAt: string | null;
  novedades: ILiquidacionNovedad[];
}
```

---

### Componente 9: Tests Pest Obligatorios

#### [NEW] `tests/Unit/Nomina/Calculators/`

| Test                          | Escenario cubierto                                                             |
| ----------------------------- | ------------------------------------------------------------------------------ |
| `SueldoBaseCalculatorTest`    | Mes completo CLP, mes parcial UF, días trabajados con ausencia                 |
| `GratificacionCalculatorTest` | LEGAL_GARANTIZADA_25, MENSUAL_25 por encima/debajo del tope, sin gratificación |
| `AfpCalculatorTest`           | Base < Tope AFP, Base > Tope AFP, régimen IPS                                  |
| `SaludCalculatorTest`         | FONASA, ISAPRE < mínimo, ISAPRE > mínimo (adicional)                           |
| `AfcCalculatorTest`           | Contrato indefinido, plazo fijo, +11 años                                      |
| `ImpuestoUnicoCalculatorTest` | Renta exenta, tramo 1, tramo 2, Impuesto = $0                                  |
| `LiquidacionIntegrationTest`  | Liquidación completa empleado tipo, partida doble balanceada                   |

---

## Brechas a Atender (Gaps del Borrador)

> [!IMPORTANT]
> Las siguientes brechas identificadas en `Calculo_Liquidacion_borrador.md` **no bloquean** el motor matemático pero deben estar en el backlog:

1. **🏦 Información Bancaria:** Campos `banco`, `tipo_cuenta`, `numero_cuenta` ausentes en `ThirdCompany`/`Employee`. Requerido para Previred y dispersión de pagos.
2. **📜 Clasificación +11 años:** El `ContractType` enum no tiene un valor `ONCE_ANIOS`. Se debe **calcular** comparando `start_date` del primer contrato indefinido activo contra hoy. Agregar lógica en `AfcCalculator`.
3. **🧬 SIS por Género:** El campo `gender` en `EmployeeProfile` debe integrarse para seleccionar automáticamente la tasa SIS del GlobalList (H/M).

---

## Plan de Ejecución por Sprints

### Sprint 1 — Fundación del Motor (Prioridad Crítica)

- [ ] Migración: campos legales en `liquidaciones`
- [ ] `LiquidacionContextBuilder` (UF, UTM, parámetros, días trabajados)
- [ ] `SueldoBaseCalculator` con registro de novedad
- [ ] `GratificacionCalculator` con registro de novedad
- [ ] Refactorizar `HorasExtrasCalculator` (fórmula VHO correcta)
- [ ] Tests: `SueldoBaseCalculatorTest`, `GratificacionCalculatorTest`

### Sprint 2 — Descuentos Legales

- [ ] `AfpCalculator` (AFP + SIS Empleador)
- [ ] `SaludCalculator` (Fonasa + Isapre + Adicional)
- [ ] `AfcCalculator` (Indefinido / Plazo Fijo / +11 años)
- [ ] `ImpuestoUnicoCalculator` (Tramos SII en UTM)
- [ ] Tests: 4 calculadores de descuentos legales

### Sprint 3 — Orquestación y Cierre

- [ ] Refactorizar `LiquidacionService.generateOrRefreshLiquidacion()`
- [ ] Eliminar lógica duplicada de `base_salary` en el orquestador
- [ ] `CalculateMonthlyPayrollJob` para cierre masivo
- [ ] `LiquidacionCalculadaEvent` + `GenerarAsientoLiquidacionListener`
- [ ] Test de integración: liquidación completa + partida doble balanceada

### Sprint 4 — API Contract y Frontend

- [ ] `FormRequest` actualizado con nuevas reglas
- [ ] Interfaces TypeScript `ILiquidacion` actualizada
- [ ] Servicio Angular: manejar estados BORRADOR/GENERADA/ENVIADA
- [ ] Polling frontend para Job asíncrono de cierre masivo

---

## Verificación

### Tests Automáticos

```bash
# Ejecutar suite completa de nómina
php artisan test --filter=Nomina

# Test específico de integración
php artisan test tests/Unit/Nomina/LiquidacionIntegrationTest
```

### Verificación Manual

1. Crear empleado con contrato INDEFINIDO y AFP + FONASA → verificar que partida doble balancea
2. Crear empleado con contrato PLAZO_FIJO e ISAPRE → verificar AFC = $0 trabajador
3. Empleado con renta > Tope AFP (90 UF) → verificar que AFP se calcula sobre el tope
4. Empleado con renta en tramo exento de Impuesto Único → verificar Impuesto = $0

---

## Auditoría de Seguridad (QD-01, QD-05, QD-08)

- **QD-01 (Bypass de autorización):** Todos los endpoints de liquidación pasan por `FormRequest::authorize()` con validación `NOMINA.LIQUIDACIONES` + operación correspondiente.
- **QD-05 (IDs secuenciales):** Los PDFs generados se guardan en S3 con path UUID, nunca con ID secuencial expuesto.
- **QD-08 (Rate Limiting):** El endpoint de cálculo masivo (`POST /nomina/liquidaciones/calcular-periodo`) se dispatcha como Job — responde inmediatamente con 202 Accepted, sin proceso síncrono explotable.

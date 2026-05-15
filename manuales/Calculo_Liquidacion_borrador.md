# 📊 Guía Técnica: Mapeo y Estructuración del Cálculo de Liquidación

Este documento detalla las reglas de negocio, fórmulas y el **mapeo exacto de datos** (tablas, campos y parámetros del sistema) necesarios para el motor de cálculo.

---

## 📌 0. Parámetros del Sistema y Constantes

Todos estos valores deben ser consultados desde los parámetros globales del sistema antes de iniciar el cálculo.

### 0.1 Indicadores Económicos (Tablas de Series)

- **Valor UF (Último día del mes):**
  - _Consulta:_ `SELECT ID FROM public.series WHERE alias = 'UF'` y luego en `public.exchange_rate_cache`.
  - _Fallback:_ `ExchangeRateService::getExchangeRate(last_day_month, 'UF')`.
- **Valor UTM (Primer día del mes):**
  - _Consulta:_ `SELECT ID FROM public.series WHERE alias = 'UTM'` y luego en `public.exchange_rate_cache`.
  - _Fallback:_ `ExchangeRateService::getExchangeRate(first_day_month, 'UTM')`.

### 0.2 Parámetro de Sueldos y Gratificaciones

| Dato                             | Valor / Regla |
| :------------------------------- | :------------ |
| **Sueldo Mínimo Vigente**        | `$539.000`    |
| **Factor Ingreso Mínimo**        | `4.75`        |
| **Gratificación Mínimo Mensual** | `25%`         |
| **TAA (Tope Afiliado AFP)**      | `90 UF`       |
| **TSC (Tope Seguro Cesantía)**   | `135.20 UF`   |
| **TIPS (Tope Para IPS)**         | `60 UF`       |
| **TAPV (Tope Mensual APV)**      | `50 UF`       |

### 0.3 Parámetro de Leyes Sociales (Porcentajes)

| Dato                                        | Valor   |
| :------------------------------------------ | :------ |
| **CEM (Cargo Empleador Mutual)**            | `0.93%` |
| **FIPS (Salud para IPS)**                   | `7%`    |
| **FSANNA (Ley 21.010 - SANNA)**             | `0.03%` |
| **FET11 (Empleador - Contrato > 11 años)**  | `0.8%`  |
| **FEPF (Empleador - Plazo Fijo)**           | `3.0%`  |
| **FECI (Empleador - Contrato Indefinido)**  | `2.4%`  |
| **FTCI (Trabajador - Contrato Indefinido)** | `0.6%`  |

---

## 💰 1. Cálculo de Haberes

### 1.1 Determinación de Días Trabajados

- **Base:** 30 días.
- **Mapeo de Descuentos de Días:**
  - _Días de Licencia:_ Registrados en la tabla `liquidacion_novedades` con `type` en `AbsenceSubtype`.
  - _Inasistencias:_ Registradas en `liquidacion_novedades` con `type` en `AbsenceSubtype`.
  - _Ingreso/Egreso:_ Se verifica la fecha en el último contrato activo en `employee_work_contract`.

### 1.2 Sueldo Base

- **Origen del Dato:** Ficha del empleado -> `EmployeeRemuneration` (campos `salary_unit` [CLP/UF] y `base_salary`).
- **Fórmula Mes Parcial:** `(Sueldo Base Mensual Planificado / 30) * Días Trabajados`.
- 💾 **Persistencia:** Crear registro en `liquidacion_novedades` con `haber_descuento_id` apuntando a `payroll_earnings_discounts` donde `key = 'SUELDO_BASE'`.

### 1.3 Gratificación

- **Validación de Empresa:** Verificar si está activa en `payroll_earnings_discounts` donde `key = 'GRATIFICACION' AND is_active = true`.
- **Tipos Dinámicos:** Definidos en `App\Enums\Nomina\GratificationType`. Se obtienen vía API (`GET /nomina/gratification-types`) con labels resueltos dinámicamente según parámetros globales (`SUELDOS_GRATIFICACIONES`).
- **Parámetros Globales (Config/DB):** 
    - `gratificacion_maxima`: Porcentaje base (por defecto 25% configurado en `nomina.defaults.sueldos_gratificaciones`).
    - `factor_gratification`: Tope en IMM (por defecto 4.75 IMM).
- **Base de Cálculo (HE):** Campo `is_gratification_he_base` en `EmployeeRemuneration`. Si es `true`, la gratificación mensual se considera base imponible para el cálculo del valor hora extra.
- **Fórmulas de Cálculo:**
    - `Tope Gratificación Mensual` = `(Factor IMM (4.75) * Sueldo Mínimo Vigente) / 12`.
    - `LEGAL_GARANTIZADA_25` = Paga directamente el `Tope Gratificación Mensual`.
    - `MENSUAL_25` = `min(Sueldo Base * 25%, Tope Gratificación Mensual)`.
- 💾 **Persistencia:** Crear registro en `liquidacion_novedades` con `haber_descuento_id` apuntando a `payroll_earnings_discounts` donde `key = 'GRATIFICACION'`.

### 1.4 Horas Extras

- **Validación:** `payroll_earnings_discounts` donde `key = 'HORAS_EXTRAS' AND is_active = true`.
- **Tipos:** Enumeración `OvertimeSubtype` (`HORA_DIA`, `HORA_NOCHE`, `RECARGO_DOM`, etc.).
- **Tipo de Remuneración:** Tabla `employee_work_contract` -> campo `remuneration_type` (mensual, semanal, diario, por hora).
- **Cálculo Valor Hora Ordinaria (VHO):**
  - _Mensual:_ `((Sueldo Base + Gratificación*) / 30) * (7 / Jornada Semanal)`.
  - _*Nota:_ La gratificación solo se suma si `is_gratification_he_base = true` en la ficha del empleado.
  - _Nota:_ `Jornada Semanal` reside en `employee_work_contract` y/o `nomina_company_settings` (`feature_key: 'CONTRATO'`).
- 💾 **Persistencia:** Crear registro en `liquidacion_novedades` con `haber_descuento_id` a `payroll_earnings_discounts` donde `key = 'HORA_EXTRA'` y el `subtype` correspondiente.

### 1.5 Horas de Atraso

- **Cálculo:** `VHO * Total Horas Decimal (THD) * -1`.
- 💾 **Persistencia:** Registrar en `liquidacion_novedades` con `subtype` igual a `AbsenceSubtype.HORAS_POR_ATRASO`.

### 1.6 Bonos y Asignaciones (Imponibles y No Imponibles)

- **Origen:** Registrados en `liquidacion_novedades` con `haber_descuento_id` apuntando a `payroll_earnings_discounts` (evaluando el campo `type` como `"IMPONIBLE"` o `"NO_IMPONIBLE"`).
- **Frecuentes:** Se cargan desde la ficha del empleado en `employee_scheduled_movements` hacia `liquidacion_novedades`.
- **Totales:**
  - `VTHI` = Suma de Imponibles.
  - `VTHNI` = Suma de No Imponibles.
  - `VTH` (Total Haberes) = `VTHI + VTHNI`.

---

## 🛑 2. Cálculo de Descuentos

### 2.1 Previsión (AFP)

- **Base AFP Efectiva:** `min(VTHI, TAA * Valor_UF)`.
- **Tasa Trabajador:** Campo `% AFP TRABAJADOR` de la AFP seleccionada en `employee_remunerations`.
- **Tasa SIS (Empleador):** Campo `SIS - HOMBRE %` o `SIS - MUJER %` en `employee_remunerations` (según campo `gender` en `employee_profiles`).
- 💾 **Persistencia:** Crear registro en `liquidacion_novedades` con `haber_descuento_id` a `payroll_earnings_discounts` donde `key = 'AFP'`.

### 2.2 Salud

- **Si es FONASA:** Se usa la tasa `FIPS` (7%) y el tope `TAA`.
  - 💾 _Persistencia:_ `liquidacion_novedades` con `key = 'SALUD_FONASA'`.
- **Si es ISAPRE:** Se lee el Valor Plan en `employee_remunerations` (campos `health_payment_unit` / `health_additional_amount`).
  - `Cotización Salud = max(Base AFP * 7%, health_additional_amount * Valor_UF)`.
  - 💾 _Persistencia:_ `liquidacion_novedades` con `key = 'SALUD_ISAPRE'` y `key = 'ADICIONAL_ISAPRE'` si hay excedente sobre el 7%.

### 2.3 Seguro de Cesantía (AFC)

- **Base AFC Efectiva:** `min(VTHI, TSC * Valor_UF)`.
- **Reglas según tipo de contrato (`employee_work_contract`):**
  - _Indefinido:_ Trabajador = `Base * FTCI` (0.6%). Empleador = `Base * FECI` (2.4%).
  - _Plazo Fijo:_ Trabajador = `$0`. Empleador = `Base * FEPF` (3.0%).
  - _Más de 11 años:_ Trabajador = `$0`. Empleador = `Base * FET11` (0.8%).
- 💾 **Persistencia:** Si el descuento al trabajador es `> 0`, registrar en `liquidacion_novedades` con `key = 'FONDO_CENSATIA_TRABAJADOR'`.

### 2.4 Impuesto Único de Segunda Categoría

- **Base Imponible Impuesto:** `VTHI - Cotización AFP - Cotización Salud`.
- **Procedimiento:**
  1.  Convertir a UTM dividiendo por `Valor_UTM` (primer día del mes).
  2.  Buscar tramo en **"Parámetro de tramos"** (Tabla Impuesto Único del SII).
  3.  Aplicar factor y restar la cantidad a rebajar del tramo.
  4.  Reconvertir el impuesto a pesos multiplicando por `Valor_UTM`.

### 2.5 Descuentos Voluntarios

- **Origen:** `liquidacion_novedades` donde el `type` en `payroll_earnings_discounts` sea `"DESCUENTO"`.
- **Frecuentes:** Cargados desde `employee_scheduled_movements`.

---

## 💸 3. Sueldo Líquido

- **Fórmula:** `Total Haberes (VTH) - (AFP + Salud + AFC Trabajador + Impuesto Único + Descuentos Voluntarios)`.

---

## 🏛️ 4. Centralización en la Contabilización

El asiento contable utiliza los datos consolidados del cálculo:

| Lado      | Cuenta Contable               | Origen del Monto                    |
| :-------- | :---------------------------- | :---------------------------------- |
| **DEBE**  | Gasto Remuneraciones          | `VTHI + VTHNI`                      |
| **DEBE**  | Gasto SIS Empleador           | Calculado en sección 2.1            |
| **DEBE**  | Gasto AFC Empleador           | Calculado en sección 2.3            |
| **HABER** | Sueldos por Pagar             | Sueldo Líquido                      |
| **HABER** | AFP por Pagar                 | Cotización AFP                      |
| **HABER** | Salud por Pagar               | Cotización Salud                    |
| **HABER** | AFC por Pagar                 | AFC Trabajador + AFC Empleador      |
| **HABER** | Impuesto Único por Pagar      | Calculado en sección 2.4            |
| **HABER** | Asignación Familiar por Pagar | Si aplica (mencionado en borrador). |

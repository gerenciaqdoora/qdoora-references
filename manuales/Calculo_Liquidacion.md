Calculo Haberes

---

Tener Valor UF:
→ SELECT ID FROM public.series where alias = 'UF' → SELECT \* FROM public.exchange_rate_cache where series_id = ID and date = '2026-05-31';
→ Si no existe el dato: consultarlo con ExchangeRateService::getExchangeRate(last_day_month, 'UF').

Tener Sueldo Mínimo Vigente: $539.000 - Parametro de sueldos y gratificaciones
Tener Factor Ingreso Mínimo: 4.75 - Parametro de sueldos y gratificaciones (Factor de sueldos minimos)

---

---

Tener Días Trabajados del mes:
Los días trabajados = 30
− días de licencia (Ausencias dentro de liquidacion): tabla liquidacion_novedades y type esta en AbsenceSubtype (menos HORAS_POR_ATRASO)
− días no trabajados por inicio/término de contrato: Se revisa ultimo contrato activo en table employee_work_contract

---

---

Calcular: Sueldo Base \* Determinar si es mes completo o mes parcial.
→ Si ingresó durante el mes a liquidar, el mes es parcial.
→ Si hay finiquito con fecha dentro del mes: también es mes parcial.
→ Si hay licencia, el mes es parcial.
→ Si hay inasistencia injustificada, el mes es parcial.

    * Si el mes es completo
        → Sueldo Base: salary_unit (CLP/UF) con base_salary (Ficha empleado: EmployeeRemuneration).
            → Si salary_unit = CLP → Sueldo Base: base_salary
            → Si salary_unit = UF → Sueldo Base: valor UF (parametro, tabla exchange_rate_cache con último día del mes que se está liquidando) * base_salary

    * Si el mes es parcial
        → Sueldo Base Planificado: salary_unit (CLP/UF) - base_salary (Ficha empleado: EmployeeRemuneration).
            → Si salary_unit = CLP → Sueldo Base Planificado: base_salary
            → Si salary_unit = UF → Sueldo Base Planificado: valor UF (parametro, tabla exchange_rate_cache con último día del mes que se está liquidando) * base_salary
        → Sueldo Base:  Sueldo Base Mensual Planificado / 30 (siempre 30 dias) * Días Trabajados del mes

- Sueldo base deberia crear un registro en liquidacion_novedades con haber_descuento_id al payroll_earnings_discounts where key = 'SUELDO_BASE'
- De esta manera para cuando se calcule el total haberes imponibles y no imponibles, esten considerados y solo sumar lo que este en liquidacion_novedades.

---

---

Gratificación:

Revisar si empresa tiene gratificación
→ payroll_earnings_discounts where key = 'GRATIFICACION' and is_active = true -> Siempre debe ser true, ya no es manipulable como configuracion de empleador (Ausencias / Licencias y Permisos sin Goce de Sueldo tampoco debe estar)

Parametro de sueldos y gratificaciones:
Gratificación Mínimo Mensual: 25% - Parametro de sueldos y gratificaciones

Ya no aplica configuracion de empleador de la gratificacion solo a nivel de ficha de empleado

Remuneraciones: En globalService tengo la siguiente variable
public gratificationTypeOptions: any[] = [
{ id: 'LEGAL_GARANTIZADA_25', name: 'Legal garantizada 25% (Tope 4.75 IMM)' },
{ id: 'MENSUAL_25', name: 'Mensual 25% (Sin tope)' },
{ id: 'ANUAL_TOPE_LEGAL', name: 'Anual con tope legal' },
{ id: 'SIN_GRATIFICACION', name: 'Sin gratificación' }
]; Estas 4 opciones son las validas. El 25% viene desde parametro de nomina (Gratificacion mensual minima). Agregar a la ficha checkbox si es que la gratificacion es base para pago de de hora extra (solo para gratificacion mensual con/sin tope)

Calcular Tope Gratificacion minimo: (**Factor Ingreso Mínimo** (4.75) \* **Sueldo Mínimo Vigente** ($539.000)) / 12

Si opcion es LEGAL_GARANTIZADA_25: se paga directamente Tope Gratificacion minimo.

Si opcion es MENSUAL_25: se elije minimo(Sueldo Base \* 25%, Tope Gratificacion minimo)

- Gratificación deberia crear un registro en liquidacion_novedades con haber_descuento_id al payroll_earnings_discounts where key = 'GRATIFICACION'
- De esta manera para cuando se calcule el total haberes imponibles y no imponibles, esten considerados y solo sumar lo que este en liquidacion_novedades.

---

---

Horas extras

Configuracion de empleador si esta activo es porque quiere editar factores, si esta desactivado, muestro los factores por defecto del sistema. En ningun momento debo permitir que el usuario no puedo asignar horas extras.

Revisar si empresa tiene horas extras
→ payroll_earnings_discounts where key = 'HORAS_EXTRAS' and is_active = true

tipos en OvertimeSubtype:
HORA_DIA = 'HORA_DIA'; // Hora extra diurna
HORA_NOCHE = 'HORA_NOCHE'; // Hora extra nocturna
RECARGO_DOM = 'RECARGO_DOM'; // % Recargo sobre hora dominical
RECARGO_FEST = 'RECARGO_FEST'; // % Recargo sobre hora festiva (ya existía)
HORA_DOM = 'HORA_DOM'; // Hora extra dominical completa
HORA_FEST = 'HORA_FEST'; // Hora extra festiva completa

Solo considerar que Recargo Legal Mínimo (50%)
Tener valor de HE Día (%) (habitual 50%)
Tener valor de HE Noche (%) (habitual 50%)
Tener valor de Recargo HE Dominical (%) (habitual 100%)
Tener valor de Recargo HE Festivo (%) (habitual 100%)
Tener valor de HE Dominical (%) (habitual 150%)
Tener valor de HE Festivo (%) (habitual 150%)

Las horas se registran en liquidacion_novedades con subtype en OvertimeSubtype

Determinar el tipo de remuneración del trabajador del ultimo contrato activo
→ employee_work_contract -> tiene informacion remuneration_type (mensual, semanal, diario, por hora)

Se calcula Valor Hora Ordinaria: Sueldo Base se suma la gratificacion si esta en true el checkbox de uso para base de pago de horas extras

| Tipo de Contrato Fórmula Valor Hora Ordinaria (VHO)                      |
| ------------------------------------------------------------------------ |
| Mensual VHO=(Sueldo Base/30)×(7/Jornada Semanal)                         |
| Semanal VHO=Sueldo Semanal/Jornada Semanal                               |
| Diario VHO=(Sueldo Diario+Semana Corrida)/Horas Trabajadas Día           |
| Por Hora VHO=Valor Hora Pactado+(Semana Corrida/Horas Trabajadas Semana) |

Se calcula el valor de la hora extra
Valor HE = (Valor Hora Ordinaria) \* (1 + recargo segun tipo de OvertimeSubtype)

Ejemplos de recargos segun tipo de OvertimeSubtype:
HORA_DIA = 50% → factor 1.5
HORA_NOCHE = 50% → factor 1.5
RECARGO_DOM = 100% → factor 2.0
RECARGO_FEST = 100% → factor 2.0
HORA_DOM = 150% → factor 2.5
HORA_FEST = 150% → factor 2.5

- Jornada Semanal: Asegurar de que este valor sea dinámico (44, 42 o 40), ya que la ley está en plena transición en Chile. Tabla
- Tabla employee_work_contract tiene jornada, tipo de contrato, pago, etc. → revisar integridad de datos y si debemos modificar
  → Tambien tenemos Configuraciones de Contrato en nomina_company_settings feature_key: 'CONTRATO'

HORAS ATRASO

- Calcular THD (Total Horas Decimal): Horas + Minutos/60
- Se utiliza el VHO calculado anteriormente
- Multiplicar VHO por Total Horas Decimal y anotar en negativo = (VHO - THD) \* -1
- Este se anota en liquidacion_novedades con subtype igual a AbsenceSubtype.HORAS_POR_ATRASO
- HORA EXTRA deberia crear un registro en liquidacion_novedades con haber_descuento_id al payroll_earnings_discounts where key = 'HORA_EXTRA' y subtype segun el caso
- De esta manera para cuando se calcule el total haberes imponibles y no imponibles, esten considerados y solo sumar lo que este en liquidacion_novedades.

---

---

Bonos y Asignaciones Imponibles
→ Esta en liquidacion_novedades con un haber_descuento_id (tabla payroll_earnings_discounts y type debe ser "IMPONIBLE")
→ Se suman todos para obtener un VTHI (Valor Total Haber Imponible)

---

---

Bonos y Asignaciones No Imponibles
→ Esta en liquidacion_novedades con un haber_descuento_id (tabla payroll_earnings_discounts y type debe ser "NO_IMPONIBLE")
→ Se suman todos para obtener un VTHNI (Valor Total Haber No Imponible)
→ Se registran desde ficha si son frecuentes como employee_scheduled_movements en liquidacion_novedades

---

---

Total de Haberes
→ Es la suma de VTH = VTHI + VTHNI

---

Calculo Descuentos

---

Tener VUF (Valor UF):
→ SELECT ID FROM public.series where alias = 'UF' → SELECT \* FROM public.exchange_rate_cache where series_id = ID and date = '2026-05-31';
→ Si no existe el dato: consultarlo con ExchangeRateService::getExchangeRate(last_day_month, 'UF'). porque series tiene frequency daily.

Tener VUTM (Valor UTM):
→ SELECT ID FROM public.series where alias = 'UTM' → SELECT \* FROM public.exchange_rate_cache where series_id = ID and date = '2026-05-01';
→ Si no existe el dato: consultarlo con ExchangeRateService::getExchangeRate(first_day_month, 'UF'). porque series tiene frequency monthly.

Tener Sueldo Mínimo Vigente: $539.000 - Parametro de sueldos y gratificaciones
Tener Factor Ingreso Mínimo: 4.75 - Parametro de sueldos y gratificaciones (Factor de sueldos minimos)
Tener TAA (Tope Afiliado AFP): 90UF - Parametro de sueldos y gratificaciones
Tener TIPS (Tope Para IPS): 60UF - Parametro de sueldos y gratificaciones
Tener TAPV (Tope Mensual UF (APV)): 50UF - Parametro de sueldos y gratificaciones
Tener TSC (Tope Seguro Cesantía): 135.20 UF - Parametro de sueldos y gratificaciones

Tener Tabla Impuesto Único del SII - Parametro de tramos

Tener CEM (Cargo Empleador Mutual) 0.93 % - Parametro de Leyes Sociales
Tener FIPS (Salud para IPS) 7 % - Parametro de Leyes Sociales
Tener FSANNA (Ley 21.010 (SANNA)) 0.03 % - Parametro de Leyes Sociales
Tener FET11 (Empleador (Trabajador más de 11 años)) 0.8% - Parametro de Leyes Sociales
Tener FEPF (Empleador (Plazo Fijo)) 3% - Parametro de Leyes Sociales
Tener FECI (Empleador (Contrato Indefinido)) 2.4% - Parametro de Leyes Sociales
Tener FTCI (Trabajador (Contrato Indefinido)) 0.6% - Parametro de Leyes Sociales

---

Determinación de la Base Imponible
→ Base Imponible = VTHI (ValorTotal Haberes Imponibles)

Determinación de la Base AFP efectiva
→ Tope AFP del mes (en pesos) = TAA × VUF
→ Base AFP efectiva = min(Base Imponible, Tope AFP del mes)

- Si Base Imponible ≤ Tope AFP → se usa la Base Imponible completa.
- Si Base Imponible > Tope AFP → se usa el Tope AFP

---

Para el calculo de AFP:
→ si es régimen antiguo se considera siempre FIPS
→ si es AFP considera siempre TAA

Cotización AFP = Base AFP efectiva × Tasa AFP del trabajador (campo % AFP TRABAJADOR de la afp seleccionada en employee_remunerations)

SIS Empleador = Base AFP efectiva × Tasa SIS de la AFP (campo SIS - HOMBRE % o SIS - MUJER % de la afp seleccionada en employee_remunerations, se complementa con ficha employee_profiles campo gender)
→ Importante: Este monto es un costo de la empresa, va al asiento contable pero no aparece como descuento del trabajador.

- Para el monto AFP se deberia crear un registro en liquidacion_novedades con haber_descuento_id al payroll_earnings_discounts where key = 'AFP'

---

CALCULO calculo de salud

Para el calculo de salud
→ si es FONASA solo se considera siempre FIPS Y TOPE CON TAA
→ si es ISAPRE: Valor Plan en employee_remunerations (health_payment_unit/health_additional_amount)

Monto mínimo legal = Base AFP efectiva × 7%
Precio plan Isapre en pesos = health_additional_amount × VUF
Cotización Salud = max(Monto mínimo legal, Precio plan Isapre en pesos)

Ejemplo: Plan Isaper 5 UF \* 40.000 = 200.000

Base Imponible: 700.000
Salud Obligatoria 7% = 49.000
Salud Adicional = 3151.000

Base Imponible = 10.000.000
Debo considera el TOPE AFP = 3.000.000
7% Legal Salud =210.000
Adicional = 0

- SI ES FONASA deberia crear un registro en liquidacion_novedades con haber_descuento_id al payroll_earnings_discounts where key = 'SALUD_FONASA'
- SI ES ISAPRE deberia crear un registro en liquidacion_novedades con haber_descuento_id al payroll_earnings_discounts where key = 'SALUD_ISAPRE'
- SI ES ISAPRE Y HAY ADICIONAL se deberia crear un registro en liquidacion_novedades con haber_descuento_id al payroll_earnings_discounts where key = 'ADICIONAL_ISAPRE'
- De esta manera para cuando se calcule el total haberes descuentos, esten considerados y solo sumar lo que este en liquidacion_novedades.

---

Base Imponible AFC (Seguro de Cesantía)

Tope AFC del mes (en pesos) = TSC × VUF
Base AFC efectiva = min(Base Imponible, Tope AFC del mes)

- El tope AFC puede ser diferente al tope AFP: verificar ambos desde parametros_periodo.

Calculo Cotización AFC (Seguro de Cesantía)

DESDE tipo de contrato (employee_work_contract):

→ Contrato indefinido:
AFC Trabajador = Base AFC efectiva × FTCI
AFC Empleador = Base AFC efectiva × FECI ← costo empresa, no descuenta al trabajador

→ Contrato a plazo fijo u obra:
AFC Trabajador = $0 ← no se descuenta nada al trabajador
AFC Empleador = Base AFC efectiva × FEPF ← costo empresa

→ Contrato a mas de 11 años:
AFC Trabajador = $0 ← no se descuenta nada al trabajador
AFC Empleador = Base AFC efectiva × FET11 ← costo empresa

- SI AFC Trabajador > 0 se deberia crear un registro en liquidacion_novedades con haber_descuento_id al payroll_earnings_discounts where key = 'FONDO_CENSATIA_TRABAJADOR'
- De esta manera para cuando se calcule el total haberes descuentos, esten considerados y solo sumar lo que este en liquidacion_novedades.

---

Base Imponible para el Impuesto Único

Renta Imponible Impuesto = Base Imponible − Cotización AFP − Cotización Salud
o de otra forma
Renta Imponible Impuesto = VTHI (Total Haberes Imponibles) − Cotización AFP − Cotización Salud

---

Impuesto Único de Segunda Categoría

1. Convertir la Renta Imponible a UTM: Renta en UTM = Renta Imponible Impuesto / VUTM
2. Buscar el tramo en la tabla del SII para ese valor en UTM: Tabla Impuesto Único del SII

   Impuesto en UTM = (Renta en UTM × Factor del tramo -> tabla) − Cantidad a rebajar del tramo (rebaja en UTM)
   Impuesto en pesos = Impuesto en UTM × VUTM

3. Validar resultado:
   - Si Impuesto en pesos ≤ 0 → Impuesto Único = $0.
   - Si Renta en UTM ≤ primer tramo exento → Impuesto Único = $0.

4. Redondear al peso entero más cercano.

---

Descuentos Voluntarios

→ Esta en liquidacion_novedades con un haber_descuento_id (tabla payroll_earnings_discounts y type debe ser "DESCUENTO")
→ Se suman todos para obtener un VDSV (Valor Descuentos Voluntarios)
→ Se registran desde ficha si son frecuentes como employee_scheduled_movements en liquidacion_novedades

---

Cálculo del Sueldo Líquido

Total Descuentos Legales = AFP + Salud + AFC Trabajador + Impuesto Único
Total Descuentos = Total Descuentos Legales + Total Descuentos Voluntarios

SUELDO LÍQUIDO = VTH (Total Haberes) − Total Descuentos

- Verificar que el Sueldo Líquido no sea negativo. Si lo es, hay un error de datos o un caso excepcional (anticipo muy alto) que debe alertarse.

---

Generación del Asiento Contable

DEBE:
Gasto Remuneraciones = Total Haberes Imponibles + No Imponibles
Gasto SIS Empleador = SIS Empleador
Gasto AFC Empleador = AFC Empleador

HABER:
Sueldos por Pagar = Sueldo Líquido
AFP por Pagar = Cotización AFP
Salud por Pagar = Cotización Salud
AFC por Pagar = AFC Trabajador + AFC Empleador
Impuesto Único por Pagar = Impuesto Único
Asignación Familiar por Pagar = Monto Asig. Familiar (si aplica)

Verificar: Total DEBE = Total HABER

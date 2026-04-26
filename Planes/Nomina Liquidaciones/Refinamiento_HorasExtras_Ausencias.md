# Refinamiento Final: Horas Extras, Ausencias y PSGS (Pre-Liquidaciones)

> Decisiones confirmadas y listas para ejecución.

## ⚠️ Aclaraciones de Contexto

### 1. Diálogos son novedades dentro de la liquidación
Los diálogos de **Horas Extras**, **Ausencias** y **PSGS** se abren desde la lista de Liquidaciones (badge AU/HE/DD), NO desde la ficha del empleado.

```
Lista de Liquidaciones (list.component)
    ↓  Badge AU / HE clickeable en la fila
    ↓  Abre dialog correspondiente
    ↓  El diálogo recibe: liquidacion_id, company_id, empleado (readonly)
    ↓  Al guardar → POST /liquidaciones/{id}/novedades → crea LiquidacionNovedad
    ↓  Refresca automáticamente el row de esa liquidación
```

### 2. Conceptos Globales — Propagados a todas las empresas
**Horas Extras, Ausencias y PSGS viven en `GlobalHaberDescuento`** y se propagan automáticamente a `payroll_earnings_discounts` de **cada empresa** con `is_standard=true`.

**Flujo de propagación:**
```
GlobalHaberDescuento (plantilla global)
    ↓  Seeder/migración de datos: propaga a TODAS las empresas existentes
       payroll_earnings_discounts { is_standard=true, standard_entity_id=global_id, company_id=X }
    ↓  Al crear nueva empresa: se propagan automáticamente todos los globales activos
    ↓  liquidacion_novedades.haber_descuento_id → registro propagado de la empresa
```

**`NominaCompanySettings.global_earn_discount_id`** sigue apuntando al global (como referencia de configuración de tasas/config), pero la novedad referencia el registro de empresa propagado.

**Estos diálogos NO tocan:**
- `employee_scheduled_movements` (ficha permanente)
- Los registros en `payroll_earnings_discounts` con `is_standard=true` no se editan desde la liquidación (solo se referencian)

---

---

## Decisión Arquitectónica: Modelo Híbrido

**1 concepto padre + subtipo enum + tasas en campo `config` JSONB** de `NominaCompanySettings`.
Ver razonamiento en versión anterior. Decisiones confirmadas por el usuario.

---

## Parte 1: Horas Extras

### Clarificaciones confirmadas
- `% Recargo Domingo` existente → corresponde a `RECARGO_DOM` ✅
- `% Recargo Festivo` existente → corresponde a `RECARGO_FEST` ✅
- Se deben agregar las 4 tasas faltantes: `HORA_DIA`, `HORA_NOCHE`, `HORA_DOM`, `HORA_FEST`
- **Formato de ingreso en liquidación**: horas y minutos (ej: 2h 30min → se almacena como decimal: 2.5)

### Enum a crear
```php
// app/Enums/Nomina/OvertimeSubtype.php
enum OvertimeSubtype: string
{
    case HORA_DIA     = 'HORA_DIA';      // Hora extra diurna (nueva)
    case HORA_NOCHE   = 'HORA_NOCHE';    // Hora extra nocturna (nueva)
    case RECARGO_DOM  = 'RECARGO_DOM';   // % Recargo Domingo (ya existía como dato, mantener)
    case RECARGO_FEST = 'RECARGO_FEST';  // % Recargo Festivo (ya existía como dato, mantener)
    case HORA_DOM     = 'HORA_DOM';      // Hora extra dominical completa (nueva)
    case HORA_FEST    = 'HORA_FEST';     // Hora extra festiva completa (nueva)
}
```

### Migración del config JSONB (feature: HORAS_EXTRAS)
```php
// En la migración de actualización, mergear con los valores existentes
// Los valores de recargo_dom y recargo_fest se leen del config actual
{
  "HORA_DIA":    { "rate": 50,  "active": true },
  "HORA_NOCHE":  { "rate": 75,  "active": true },
  "RECARGO_DOM": { "rate": <valor_actual_domingo>, "active": true }, // migrar dato existente
  "RECARGO_FEST":{ "rate": <valor_actual_festivo>, "active": true }, // migrar dato existente
  "HORA_DOM":    { "rate": 150, "active": true },
  "HORA_FEST":   { "rate": 150, "active": true }
}
```

### Almacenamiento de horas en liquidacion_novedades
- El usuario ingresa en formato HH:MM en el diálogo.
- Se almacena como **decimal** en la columna `hours` (ej: 2h 30min → 2.5).
- El diálogo convierte: `horas + (minutos / 60)` antes de enviar al backend.

---

## Parte 2: Ausencias

### Clarificaciones confirmadas
- El campo "Día" en el diálogo es **calculado automáticamente** a partir del rango Desde-Hasta ✅
- No es editable por el usuario.

### Enum a crear
```php
// app/Enums/Nomina/AbsenceSubtype.php
enum AbsenceSubtype: string
{
    case SUBSIDIO          = 'SUBSIDIO';          // Previred: 3
    case PSGS              = 'PSGS';              // Previred: 4 — Permiso sin Goce de Sueldo (ver Parte 3)
    case INCORPORACION     = 'INCORPORACION';     // Previred: 5
    case ACCIDENTE_TRABAJO = 'ACCIDENTE_TRABAJO'; // Previred: 6
    case OTROS             = 'OTROS';             // Previred: 11
    case LICENCIA_PARCIAL  = 'LICENCIA_PARCIAL';  // Sin código Previred
}
```

### Concepto global (seeder de sistema) — propagado a todas las empresas
```
GlobalHaberDescuento: key='AUSENCIA_LABORAL', type=DESCUENTO, name='Ausencias', is_affect=null, is_active=true
```
> La migración de datos debe:
> 1. Insertar en `global_payroll_earnings_discounts`
> 2. Propagar a TODAS las empresas existentes en `payroll_earnings_discounts` (`is_standard=true`, `standard_entity_id=global_id`)
> 3. Al crear nueva empresa, el proceso de onboarding ya debe incluir la propagación de todos los globales activos.

### config JSONB (feature: AUSENCIAS)
No tienen tasa. El descuento se calcula como: `(sueldo_base / días_hábiles_mes) * días_ausentes`
```json
{
  "SUBSIDIO":          { "previred_code": 3,    "active": true },
  "INCORPORACION":     { "previred_code": 5,    "active": true },
  "ACCIDENTE_TRABAJO": { "previred_code": 6,    "active": true },
  "OTROS":             { "previred_code": 11,   "active": true },
  "LICENCIA_PARCIAL":  { "previred_code": null, "active": true }
}
```

> Nota: PSGS (Previred: 4) se excluye de este config porque tiene su propio concepto y feature (ver Parte 3).

### UI del diálogo de Ausencias (novedad dentro de liquidación)
- **Contexto**: Se abre desde el badge AU de la fila de la liquidación. Recibe `liquidacion_id` y muestra el nombre del empleado en modo readonly.
- **Mov. Personal**: selector de subtipo (opciones del enum AbsenceSubtype, sin PSGS)
- **Desde / Hasta**: date pickers, limitados al período de la liquidación (ej: 01-04-2026 a 30-04-2026)
- **Día**: calculado automáticamente = días hábiles entre Desde y Hasta, readonly
- **Glosa**: campo de texto libre
- **Renta Imponible**: calculado automáticamente = `(sueldo_base / días_hábiles_mes) * días`, readonly

---

## Parte 3: Permiso sin Goce de Sueldo (PSGS) — Descuento Independiente

El usuario confirma que PSGS debe ser un **concepto de descuento separado**, no agrupado en Ausencias genéricas. Esto lo distingue por su impacto en previsión (descuenta proporcional incluyendo cotizaciones).

### Nuevo feature en NominaFeatureKey
```php
case PSGS = 'PSGS';
```

### Concepto global (seeder de sistema) — propagado a todas las empresas
```
GlobalHaberDescuento: key='PSGS', type=DESCUENTO, name='Permiso sin Goce de Sueldo', is_affect=null, is_active=true
```
> Misma lógica de propagación que Ausencias.

### config JSONB (feature: PSGS)
```json
{
  "previred_code": 4,
  "active": true
}
```

### UI del diálogo de PSGS (novedad dentro de liquidación)
- **Contexto**: Badge DD en la fila de liquidación (Descuento). Recibe `liquidacion_id` y muestra nombre del empleado en readonly.
- **Desde / Hasta**: date pickers, limitados al período de la liquidación
- **Día**: calculado automáticamente (readonly)
- **Glosa**: campo de texto libre
- **Renta Imponible**: calculado automáticamente, readonly

---

## Impacto en liquidacion_novedades (actualización del plan original)

### Cambios en las columnas de la migración
`haber_descuento_id` se mantiene como única referencia de concepto (aplica tanto para conceptos globales propagados como para conceptos propios de la empresa).

```php
// 1. haber_descuento_id ya existe en el plan — aplica para TODOS los tipos de novedad
//    Para HE/Ausencias/PSGS: apunta al registro propagado (is_standard=true) de la empresa
//    Para haberes/descuentos propios: apunta al registro propio de la empresa

// 2. Subtipo del concepto (NUEVO)
$table->string('subtype', 30)->nullable()
      ->comment('OvertimeSubtype o AbsenceSubtype según el type de novedad');

// 3. Horas con precisión decimal para fracciones HH:MM
$table->decimal('hours', 8, 4)->nullable(); // 2h30m → 2.5
```

### Regla de uso de columnas
| Tipo de novedad | `haber_descuento_id` apunta a... | `subtype` |
|:---|:---|:---|
| HORA_EXTRA | Registro propagado de HE (is_standard=true) | OvertimeSubtype |
| AUSENCIA | Registro propagado de Ausencias (is_standard=true) | AbsenceSubtype |
| DESCUENTO (PSGS) | Registro propagado de PSGS (is_standard=true) | null |
| HABER / DESCUENTO empresa | Registro propio de la empresa (is_standard=false) | null |

### Ejemplos de registros
```
// Hora extra: 2h 30min diurna
type=HORA_EXTRA | haber_descuento_id={id HE propagado empresa} | subtype=HORA_DIA | hours=2.5 | amount=20000

// Ausencia 3 días por subsidio
type=AUSENCIA | haber_descuento_id={id Ausencias propagado empresa} | subtype=SUBSIDIO | days=3 | amount=-45000

// PSGS 5 días
type=DESCUENTO | haber_descuento_id={id PSGS propagado empresa} | subtype=null | days=5 | amount=-75000

// Haber empresa (colación, propio)
type=HABER | haber_descuento_id={id colación empresa} | subtype=null | amount=50000
```

---

## Lista Final de Archivos a Crear/Modificar

### Backend (ejecutar en orden)

| # | Archivo | Acción | Descripción |
|:--|:---|:---|:---|
| 1 | `app/Enums/Nomina/OvertimeSubtype.php` | NEW | 6 subtipos de hora extra |
| 2 | `app/Enums/Nomina/AbsenceSubtype.php` | NEW | 5 subtipos de ausencia (sin PSGS) |
| 3 | `app/Enums/Nomina/NominaFeatureKey.php` | MODIFY | Agregar `AUSENCIAS` y `PSGS` |
| 4 | `database/migrations/..._add_ausencias_psgs_overtime_config.php` | NEW | Migrar config HORAS_EXTRAS + seed conceptos globales AUSENCIA y PSGS |
| 5 | `Http/Requests/Nomina/UpdateNominaFeatureConfig.php` | MODIFY | Validar nuevo schema de HORAS_EXTRAS, AUSENCIAS y PSGS |

### Frontend (ejecutar en orden)

> ⚠️ Los ítems 9, 10, 11 son diálogos que se abren desde la lista de Liquidaciones, NO desde la ficha del empleado.

| # | Archivo | Acción | Descripción |
|:--|:---|:---|:---|
| 6 | Settings — bloque Horas Extras | MODIFY | Expandir de 2 a 6 campos de % configurables |
| 7 | Settings — card PSGS | NEW | Toggle activar/desactivar, sin tasas |
| 8 | Settings — card Ausencias | NEW | Toggle con 5 subtipos activables |
| 9 | `dialog/horas-extras-novedad-dialog/` | NEW | Parte de Liquidaciones: selector subtipo HH:MM, recibe liquidacion_id, guarda en liquidacion_novedades |
| 10 | `dialog/ausencia-novedad-dialog/` | NEW | Parte de Liquidaciones: selector subtipo, Desde/Hasta limitado al período, Día calculado, guarda en liquidacion_novedades |
| 11 | `dialog/psgs-novedad-dialog/` | NEW | Parte de Liquidaciones: Desde/Hasta limitado al período, Día calculado, guarda en liquidacion_novedades |

---

## Sin preguntas abiertas — LISTO PARA EJECUTAR

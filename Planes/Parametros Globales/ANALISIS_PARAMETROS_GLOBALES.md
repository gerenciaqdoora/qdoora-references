# 📊 ANÁLISIS COMPLETO: SISTEMA DE PARÁMETROS GLOBALES

## 🎯 OBJETIVO
Sistema escalable para administrar parámetros de nómina en Chile, permitiendo:
- ✅ Agregar nuevas variables sin modificar código
- ✅ Modificar porcentajes mensualmente
- ✅ Agregar/eliminar listas (AFP, Cajas, etc.)
- ✅ Mantener escalas por tramos (Impuesto Único, Asignación Familiar)

---

## 📋 ESTRUCTURA DE DATOS SEGÚN VISTAS

### 1️⃣ **LISTAS** (global_lists)

#### 🏦 AFP
**Campos requeridos:**
- `previred` (TEXT) - Código Previred
- `nombre` (TEXT) - Nombre de la AFP
- `tasa_trabajador` (PERCENT) - % AFP Trabajador
- `tasa_empleador` (PERCENT) - % AFP Cargo Empleador
- `sis_hombre` (CLP o PERCENT) - $ SIS Hombre
- `sis_mujer` (CLP o PERCENT) - $ SIS Mujer
- `ind` (PERCENT) - $ AFP Independiente
- `expectativa_vida` (PERCENT) - % Expectativa Vida
- `rentabilidad_protegida` (PERCENT) - % Rentabilidad Protegida

**✅ CUBIERTO**: El modelo actual soporta JSON con campos dinámicos ✓

---

#### 🏛️ REGIMEN_ANTIGUO
**Campos requeridos:**
- `previred` (TEXT) - Código Previred
- `nombre` (TEXT) - Nombre Caja/Previsión
- `prevision_1` (PERCENT) - % Previsión 1
- `prevision_2` (CLP) - $ Previsión 2

**✅ CUBIERTO**: Estructura actual es correcta ✓

---

#### 🏛️ REGIMEN_ANTIGUO_DESAHUCIO
**Campos requeridos:**
- `previred` (TEXT) - Código Previred
- `nombre` (TEXT) - Nombre Caja/Previsión
- `desahucio` (PERCENT) - % Desahucio

**✅ CUBIERTO**: Estructura actual es correcta ✓

---

### 2️⃣ **ESCALAS** (global_scales)

#### 📊 IMPUESTO_UNICO
**Referencia:** UTM  
**Campos por tramo:**
- `desde` (UTM) - Desde
- `hasta` (UTM) - Hasta (nullable para último tramo)
- `factor` (PERCENT) - % Factor
- `rebaja` (UTM) - % Rebaja

**✅ CUBIERTO**: La estructura actual soporta tramos correctamente ✓

---

#### 👨‍👩‍👧 ASIGNACION_FAMILIAR
**Referencia:** CLP  
**Campos por tramo:**
- `desde` (CLP) - Desde
- `hasta` (CLP) - Hasta (nullable)
- `paga` (CLP) - Paga

**✅ CUBIERTO**: Estructura actual es correcta ✓

---

### 3️⃣ **VARIABLES** (global_variable)

#### ⚖️ LEYES_SOCIALES
**Campos requeridos:**
- `ips` (PERCENT) - % IPS
- `ccaf` (PERCENT) - % CCAF (Caja Compensación)
- `mutual` (PERCENT) - % Mutual
- `sanna` (PERCENT) - % Sanna
- `expectativa_vida` (PERCENT) - % Expectativa Vida
- `rentabilidad_protegida` (PERCENT) - % Rentabilidad Protegida
- `empleador_indefinido` (PERCENT) - % Empleador Contrato Indefinido
- `trabajador_indefinido` (PERCENT) - % Trabajador Contrato Indefinido
- `empleador_fijo` (PERCENT) - % Empleador Contrato Fijo
- `empleador_11_años` (PERCENT) - % Empleador Más de 11 Años

**⚠️ PROBLEMA DETECTADO**: 
Actualmente `global_variable` solo soporta **UNA variable por registro** (un key, un value).
Para "LEYES_SOCIALES" necesitamos **10 variables diferentes**.

**🔧 SOLUCIÓN**:
- Cada variable es un registro separado con su propio `key`
- Ejemplo: 
  - `type='LEYES_SOCIALES'`, `key='ips'`, `value=1.5`
  - `type='LEYES_SOCIALES'`, `key='ccaf'`, `value=0.6`

**✅ CUBIERTO**: El modelo actual soporta esto correctamente ✓

---

#### 💰 SUELDOS_GRATIFICACIONES
**Campos requeridos:**
- `sueldo_minimo` (CLP) - Sueldo Mínimo
- `factor_ingreso_minimo_gratificaciones` (número) - Factor Ingreso Mínimo para Gratificaciones
- `gratificacion_minimo_mensual` (CLP) - Gratificación Mínimo Mensual
- `tope_afiliado_afp` (UF) - Tope Afiliado AFP
- `tope_seguro_cesantia` (UF) - Tope Seguro Cesantía
- `tope_ips` (UF) - Tope IPS
- `cotizacion_casa_particular` (PERCENT) - % Cotización Casa Particular
- `tope_ahorro_previsional_voluntario` (UF) - Tope Ahorro Previsional Voluntario
- `tope_rebaja_zonas_extremas` (UF) - Tope Rebaja Zonas Extremas
- `factor_tope_rebaja_zonas_extremas` (número) - Factor Tope Rebaja Zonas Extremas

**✅ CUBIERTO**: Cada una será un registro separado ✓

---

## 🔍 EVALUACIÓN DE MODELOS Y SERVICIOS

### ✅ **GlobalVariable** (Model + Service)
**Estado:** ✅ FUNCIONAL  
**Capacidades:**
- ✅ Soporta period, type, key, value, reference_unit, factor
- ✅ Calcula factores automáticamente (UF, UTM, PERCENT, CLP)
- ✅ Integración con ExchangeRateService para UF/UTM
- ✅ Scopes para búsquedas eficientes

**✨ Mejoras aplicadas:**
- ✅ Corrección de namespace
- ✅ Agregar métodos: `getVariable()`, `getVariableFactor()`, `listVariablesByType()`, `deleteVariable()`

---

### ✅ **GlobalList** (Model + Service)
**Estado:** ✅ FUNCIONAL  
**Capacidades:**
- ✅ Soporta JSON con estructura flexible: `{"campo": {"label", "value", "reference_unit", "factor"}}`
- ✅ Método `getNestedValue()` para acceder a atributos
- ✅ Calcula factores según unidad (PERCENT, UF, UTM, CLP, TEXT)

**✨ Mejoras aplicadas:**
- ✅ Corrección de namespace
- ✅ FIX: Agregar parámetro `$frequency` a `storeItem()`
- ✅ Agregar métodos: `getListByType()`, `getListItem()`, `deleteListItem()`

---

### ✅ **GlobalScale** (Model + Service)
**Estado:** ✅ FUNCIONAL  
**Capacidades:**
- ✅ Soporta arrays de tramos: `[{"desde": {...}, "hasta": {...}, "factor": {...}}]`
- ✅ Método `findRowByAmount()` para buscar tramo por monto
- ✅ Calcula factores según reference_unit

**✨ Mejoras aplicadas:**
- ✅ Corrección de namespace
- ✅ Cambio de `FACTOR_REF` a `UNIT_REF` para consistencia
- ✅ Agregar métodos: `getScale()`, `findScaleRow()`, `deleteScale()`

---

## 📊 DICCIONARIO ACTUALIZADO

### Estructura propuesta en `PayrollDictionary`:

```php
public const LISTS = [
    'AFP' => [
        'previred' => ['label' => 'Cód. Previred', 'unit' => 'TEXT'],
        'nombre' => ['label' => 'AFP', 'unit' => 'TEXT'],
        'tasa_trabajador' => ['label' => '% AFP Trabajador', 'unit' => 'PERCENT'],
        'tasa_empleador' => ['label' => '% AFP Cargo Empleador', 'unit' => 'PERCENT'],
        'sis_hombre' => ['label' => '$ SIS Hombre', 'unit' => 'CLP'],
        'sis_mujer' => ['label' => '$ SIS Mujer', 'unit' => 'CLP'],
        'ind' => ['label' => '$ AFP Ind.', 'unit' => 'CLP'],
        'expectativa_vida' => ['label' => '% Expectativa Vida', 'unit' => 'PERCENT'],
        'rentabilidad_protegida' => ['label' => '% Rentabilidad Protegida', 'unit' => 'PERCENT'],
    ],
    'REGIMEN_ANTIGUO' => [
        'previred' => ['label' => 'Cód. Previred', 'unit' => 'TEXT'],
        'nombre' => ['label' => 'Caja/Caja Previsión', 'unit' => 'TEXT'],
        'prevision_1' => ['label' => '% Previsión 1', 'unit' => 'PERCENT'],
        'prevision_2' => ['label' => '$ Previsión 2', 'unit' => 'CLP'],
    ],
    'REGIMEN_ANTIGUO_DESAHUCIO' => [
        'previred' => ['label' => 'Cód. Previred', 'unit' => 'TEXT'],
        'nombre' => ['label' => 'Caja/Caja Previsión', 'unit' => 'TEXT'],
        'desahucio' => ['label' => '% Desahucio', 'unit' => 'PERCENT'],
    ],
];

public const SCALES = [
    'IMPUESTO_UNICO' => [
        'default_reference_unit' => 'UTM',
        'columns' => [
            'desde' => ['label' => 'Desde', 'unit' => 'UNIT_REF'],
            'hasta' => ['label' => 'Hasta', 'unit' => 'UNIT_REF', 'nullable' => true],
            'factor' => ['label' => '% Factor', 'unit' => 'PERCENT'],
            'rebaja' => ['label' => '% Rebaja', 'unit' => 'UNIT_REF'],
        ]
    ],
    'ASIGNACION_FAMILIAR' => [
        'default_reference_unit' => 'CLP',
        'columns' => [
            'desde' => ['label' => 'Desde', 'unit' => 'UNIT_REF'],
            'hasta' => ['label' => 'Hasta', 'unit' => 'UNIT_REF', 'nullable' => true],
            'paga' => ['label' => 'Paga', 'unit' => 'UNIT_REF'],
        ]
    ]
];

// VARIABLES se almacenan individualmente con type + key
// Ejemplos:
// type='LEYES_SOCIALES', key='ips', value=1.5, unit='PERCENT'
// type='SUELDOS_GRATIFICACIONES', key='sueldo_minimo', value=500000, unit='CLP'
```

---

## 🎯 CONCLUSIONES

### ✅ **LO QUE FUNCIONA BIEN:**
1. ✅ Estructura de base de datos es correcta y escalable
2. ✅ Modelos soportan todas las necesidades
3. ✅ Servicios calculan factores automáticamente
4. ✅ Integración con Banco Central para UF/UTM

### 🔧 **LO QUE NECESITA AJUSTES:**
1. ⚠️ Corregir typo en migración: `'annually'` → `'annually'`
2. ⚠️ Unificar namespaces: Todos deben ser `App\Services\GlobalParameter`
3. ⚠️ Bug en `GlobalListService::storeItem()` (variable indefinida)
4. ⚠️ Falta controlador API y rutas
5. ⚠️ Sistema de caché para optimizar consultas en cálculos de nómina

### 📝 **DICCIONARIO AJUSTADO:**
El diccionario debe reflejar exactamente los campos de las vistas:
- AFP: 9 campos (previred, nombre, tasa_trabajador, tasa_empleador, sis_hombre, sis_mujer, ind, expectativa_vida, rentabilidad_protegida)
- REGIMEN_ANTIGUO: 4 campos
- REGIMEN_ANTIGUO_DESAHUCIO: 3 campos
- IMPUESTO_UNICO: 4 columnas por tramo
- ASIGNACION_FAMILIAR: 3 columnas por tramo
- LEYES_SOCIALES: 10 variables independientes
- SUELDOS_GRATIFICACIONES: 10 variables independientes

### 🚀 **PRÓXIMOS PASOS RECOMENDADOS:**
1. ✅ Aplicar correcciones a servicios existentes
2. ✅ Actualizar diccionario con campos exactos
3. ✅ Crear controlador GlobalParameterController
4. ✅ Agregar rutas API
5. ✅ Implementar sistema de caché
6. ✅ Crear FormRequests para validaciones

---

## 💡 **ESCALABILIDAD GARANTIZADA**

El sistema actual **YA ES ESCALABLE**:

✅ **Agregar nueva variable**: Solo agregar en diccionario, no tocar código
✅ **Modificar porcentaje**: Admin actualiza valor vía API
✅ **Agregar nueva lista**: Agregar tipo en diccionario, usar mismo servicio
✅ **Agregar nueva escala**: Agregar tipo en diccionario, usar mismo servicio
✅ **Eliminar items**: Soft delete o hard delete sin afectar otros

**Ejemplo de escalabilidad:**
Si mañana necesitas agregar "ISAPRE" como nueva lista:
```php
'ISAPRE' => [
    'previred' => ['label' => 'Cód. Previred', 'unit' => 'TEXT'],
    'nombre' => ['label' => 'Nombre Isapre', 'unit' => 'TEXT'],
    'tasa' => ['label' => '% Tasa', 'unit' => 'PERCENT'],
]
```
Y listo! Los servicios funcionan automáticamente. 🎉


## ✅ **SISTEMA DE CONSULTA DE PARÁMETROS GLOBALES - COMPLETADO**

He creado el sistema completo de **API de consulta (REVIEW)** para parámetros globales de nómina siguiendo tu estructura de proyecto. Aquí está todo lo implementado:

---

### 📦 **ARCHIVOS CREADOS:**

#### **1. API Resources** (transforman modelos a JSON)
- ✅ `GlobalVariableResource.php` - Para variables individuales
- ✅ `GlobalListResource.php` - Para listas (AFP, Régimen Antiguo, etc.)
- ✅ `GlobalScaleResource.php` - Para escalas (Impuesto Único, Asignación Familiar)

#### **2. FormRequest** (validación y permisos)
- ✅ `ReviewGlobalParameterRequest.php`
  - ✅ Valida permiso: Módulo **NOMINA** + Operación **REVIEW**
  - ✅ Valida parámetro `period` (formato: YYYY-MM-DD)
  - ✅ Suscriptores siempre pueden revisar
  - ✅ Usuarios necesitan permiso explícito

#### **3. Controlador**
- ✅ `GlobalParameterController.php` con 8 endpoints:
  1. `GET /api/v1/global-parameters/afp?period=2026-03-01`
  2. `GET /api/v1/global-parameters/regimen-antiguo?period=2026-03-01`
  3. `GET /api/v1/global-parameters/regimen-antiguo-desahucio?period=2026-03-01`
  4. `GET /api/v1/global-parameters/impuesto-unico?period=2026-03-01`
  5. `GET /api/v1/global-parameters/asignacion-familiar?period=2026-03-01`
  6. `GET /api/v1/global-parameters/leyes-sociales?period=2026-03-01`
  7. `GET /api/v1/global-parameters/sueldos-gratificaciones?period=2026-03-01`
  8. `GET /api/v1/global-parameters/dictionary` (sin period - devuelve estructura completa)

#### **4. Rutas API**
- ✅ Integradas en `routes/api.php`
- ✅ Protegidas con middleware `auth:api`
- ✅ Validación de permisos en cada endpoint

---

### 🎯 **CÓMO FUNCIONA:**

#### **Ejemplo de llamada desde Angular:**

```typescript
// En tu servicio Angular
getAFP(period: string): Observable<GlobalParameterResponse> {
  return this.http.get<GlobalParameterResponse>(
    `${this.apiUrl}/global-parameters/afp`,
    { params: { period } }
  );
}
```

#### **Respuesta del endpoint AFP:**
```json
{
  "data": [
    {
      "id": 1,
      "frequency": "monthly",
      "period": "2026-03-01",
      "type": "AFP",
      "key": "CAPITAL",
      "values": {
        "previred": {
          "label": "Cód. Previred",
          "value": "03",
          "reference_unit": "TEXT",
          "factor": "03"
        },
        "nombre": {
          "label": "AFP",
          "value": "AFP Capital",
          "reference_unit": "TEXT",
          "factor": "AFP Capital"
        },
        "tasa_trabajador": {
          "label": "% AFP Trabajador",
          "value": 11.44,
          "reference_unit": "PERCENT",
          "factor": 0.1144
        }
        // ... más campos
      },
      "created_at": "2026-03-19 17:00:00",
      "updated_at": "2026-03-19 17:00:00"
    }
  ],
  "definition": {
    "previred": {"label": "Cód. Previred", "unit": "TEXT"},
    "nombre": {"label": "AFP", "unit": "TEXT"},
    "tasa_trabajador": {"label": "% AFP Trabajador", "unit": "PERCENT"}
    // ... definición completa
  }
}
```

---

### 🎨 **PARA RENDERIZAR EN ANGULAR:**

Cada endpoint devuelve **`data`** (datos actuales) + **`definition`** (estructura para construir UI):

1. **Botón "AFP"** → Llama `/afp?period=2026-03-01`
2. **Botón "Impuesto Único"** → Llama `/impuesto-unico?period=2026-03-01`
3. **Botón "Leyes Sociales"** → Llama `/leyes-sociales?period=2026-03-01`

Angular usa `definition` para saber qué columnas mostrar y `data` para los valores.

---

### ✨ **BENEFICIOS:**

✅ **Sin company_id**: Los parámetros globales son para todo el sistema
✅ **Permisos NOMINA/REVIEW**: Solo usuarios autorizados pueden ver
✅ **API Resources**: Formato consistente para Angular
✅ **FormRequest**: Validación automática de permisos
✅ **Escalable**: Agregar nuevos tipos solo requiere actualizar diccionario
✅ **Documentado**: Anotaciones OpenAPI para Swagger

El sistema está listo para que Angular consuma los datos y los muestre en las vistas según los botones que el usuario presione. 🚀

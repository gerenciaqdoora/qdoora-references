# DIAGNÓSTICO COMPLETO — Sistema de Parámetros Globales

### 1. SCHEDULER BACKUP (Backend)

Scheduler Principal — routes/console.php

- Mensual: último día del mes 23:00 → dispara ClonePeriodParameters::dispatch($nextPeriod, $currentPeriod, 'monthly')
- Diario: diariamente 23:30 → dispara ClonePeriodParameters::dispatch($tomorrow, $today, 'daily')

| Problema                                                                        | Severidad | Impacto                                                                                     |
| ------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------- |
| onFailure() solo loguea en disco, sin alertas reales (email/Slack)              | CRÍTICO  | Si falla el último día del mes, el período nuevo queda sin parámetros y nadie se entera |
| Job ClonePeriodParameters no tiene reintentos configurados ($tries, $backoff) | CRÍTICO  | Si la cola falla (DB lock, servidor caído), el job se pierde silenciosamente               |
| No existe mecanismo secundario de scheduler (backup cron)                       | CRÍTICO  | Un fallo único destruye la cobertura del período                                          |

## 2. SERVICIO ON-DEMAND (Backend)

ParameterCloningService::ensurePeriodHasData() — llamado automáticamente desde getVariable(), getListByType(), getScale()

| Problema                                                                         | Severidad | Impacto                                                                            |
| -------------------------------------------------------------------------------- | --------- | ---------------------------------------------------------------------------------- |
| Si no hay período anterior, retorna false silenciosamente (no lanza excepción) | CRÍTICO  | El llamador no distingue entre "clonó exitoso" y "no había origen"               |
| Solo se activa al leer datos → no hay generación proactiva                     | ALTO      | Si nadie consulta ese período antes del cálculo de liquidación, el gap persiste |
| No existe endpoint dedicado para forzar clonación manual                        | ALTO      | No hay forma de recuperarse on-demand cuando ambos schedulers fallan               |

## 3. VALIDACIÓN DE COBERTURA (Backend + Frontend)

### Backend — ParameterCloningService

| Problema                                                                                      | Severidad | Impacto                                                                                      |
| --------------------------------------------------------------------------------------------- | --------- | -------------------------------------------------------------------------------------------- |
| performCloning() busca período anterior fuera de la transacción → window de race condition | ALTO      | Dos clonaciones concurrentes pueden intentar crear la misma clave → unique constraint crash |
| cloneGlobalVariables() hace check-then-act sin lock → race condition                         | ALTO      | Si dos jobs corren en paralelo, se rompe por unique constraint sin retry                     |
| Los endpoints devuelven 200 OK con array vacío cuando no hay parámetros para el período    | MEDIO     | El frontend no puede distinguir "período sin datos" de "período vacío normal"             |
| EmployeeService y EarnDiscountService no validan existencia de parámetros antes de calcular  | ALTO      | Errores genéricos en runtime durante cálculo de liquidación                               |

### Frontend — create.component.ts

| Problema                                                                        | Severidad | Impacto                                                                    |
| ------------------------------------------------------------------------------- | --------- | -------------------------------------------------------------------------- |
| No se valida si AFPs/Salud/Tramos están vacíos antes de mostrar el formulario | CRÍTICO  | Usuario puede crear empleado con parámetros inexistentes para el período |
| monto_asignacion_snapshot en cargas familiares nunca se captura ni calcula      | ALTO      | Liquidaciones quedan sin monto de asignación familiar                     |
| Tramos de asignación familiar se cargan sin contexto de período               | ALTO      | Pueden usarse tramos desactualizados                                       |

## 4. VULNERABILIDADES EN FICHA EMPLEADO Y HABERES/DESCUENTOS

Ficha empleado:  afp_id, health_id → FK → ThirdCompany
ThirdCompany:    standard_entity_id → FK → GlobalEntity (category: AFP/SALUD/CCAF...)
GlobalEntity:    key (ej. "AFP_HABITAT") → lookup en GlobalVariable(period, key) → tasa

### V2 — ALTO: family_allowance_tramo es string, no FK

EmployeeRemuneration.php línea 37: guarda el código del tramo como string (ej. "A", "B")
EmployeeFamiliarCharge sí usa global_scale_tramo_id (FK real)
Riesgo: al liquidar, si el cálculo usa family_allowance_tramo del modelo de remuneración en lugar del global_scale_tramo_id de la carga familiar, busca por código de tramo sin fijar el período → puede tomar el tramo de una escala equivocada si hay múltiples escalas en distintos períodos

### V3 — ALTO: monto_asignacion_snapshot es auditoría, no debe usarse en cálculo

El snapshot se congela en el momento de crear la carga familiar (EmployeeService línea 345-346)
Cuando se liquide en un período posterior, el monto del tramo puede haber cambiado
Riesgo: si el futuro FamilyAllowanceCalculator usa el snapshot en lugar de revaluar por GlobalScaleTramo del período de liquidación → paga el monto desactualizado

### V4 — MEDIO: NominaSettingsService no incluye AFP ni SALUD

**getFeatureOptions**() construye opciones para CCAF, MUTUAL, APVC
AFP y SALUD se manejan sólo a nivel de EmployeeRemuneration, sin una feature **togglable** en settings
Riesgo menor: cuando el futuro cálculo valide si la empresa tiene AFP habilitada, no encontrará el toggle en NominaCompanySettings → tendrá que buscar directamente en la ficha del empleado, lo cual es correcto pero debe estar documentado en el calculador

### V5 — MEDIO: No hay validación de que el auxiliar tenga standard_entity_id antes de la liquidación

Un ThirdCompany podría tener standard_entity_id = null (auxiliar genérico como cliente/proveedor)
Si se asigna ese auxiliar como afp_id de un empleado y el calculador intenta hacer el lookup GlobalEntity.key → GlobalVariable, falla con null
No hay restricción a nivel de FK ni validación en el FormRequest de empleado

| Problema                                                                 | Severidad | Cuándo impacta                                       |
| ------------------------------------------------------------------------ | --------- | ----------------------------------------------------- |
| family_allowance_tramo como string rompe el lookup por período          | ALTO      | Primer cálculo de asignación familiar               |
| monto_asignacion_snapshot no debe usarse en cálculo, solo en auditoría | ALTO      | Si el calculador toma el snapshot en vez de revaluar  |
| AFP/SALUD sin feature toggle en NominaSettings                           | MEDIO     | Al diseñar validaciones en PayrollCalculationService |
| Auxiliar sin standard_entity_id puede asignarse como AFP/SALUD           | MEDIO     | Al momento de crear/editar ficha de empleado          |

### 5 - VULNERABILIDADES GENERALES

| Problema                                                                                                                        | Archivo                     | Severidad                                 |
| ------------------------------------------------------------------------------------------------------------------------------- | --------------------------- | ----------------------------------------- |
| No hay índice simple en columna period — las búsquedas de clonación hacen WHERE period < ? ORDER BY period DESC sin índice | migrations/2026_03_18...    | ALTO                                      |
| Race condition entre scheduler (23:30) y usuario que accede a las 00:00 del día siguiente antes de que el job se ejecute       | console.php                 | MEDIO — mitigado por ensurePeriodHasData |
| Notificaciones de administrador (notifyAdmin) no tienen reintentos — si falla el email, el error queda sin alertar             | ParameterCloningService.php | BAJO                                      |
| Frontend no refresca caché después de que completa una clonación vía Pusher                                                 | global.service.ts	BAJO      |                                           |

# Resumen Ejecutivo — Qué está en riesgo hoy

## CRÍTICO (3 issues que pueden romper liquidaciones en producción):

1. Job sin reintentos → scheduler falla → mes sin parámetros
2. No hay endpoint on-demand para forzar clonación manual
3. Frontend no valida existencia de parámetros al crear empleado

## ALTO (5 issues que degradan integridad de datos):

4. Race condition en clonación concurrente (unique constraint crash)
5. monto_asignacion_snapshot nunca se captura en cargas familiares
6. EarnDiscountService sin validación de período antes de calcular
7. Sin alertas reales cuando el scheduler falla
8. Índices faltantes en columna period

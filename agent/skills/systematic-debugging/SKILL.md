---
name: systematic-debugging
description: >
  Proceso sistemático de debugging en 4 fases para diagnosticar y resolver bugs, fallos
  de tests o comportamientos inesperados en el stack QdoorA. USAR antes de proponer
  cualquier fix.

  Activar AUTOMÁTICAMENTE ante: bug reportado, test fallando (Pest/Vitest/Jest), error
  500 en API, excepción PHP no esperada, comportamiento Angular inesperado, query SQL
  incorrecta, job SQS fallando, error de Docker/contenedor, o cualquier situación donde
  el desarrollador diga "no funciona", "está fallando", "error en producción", "por qué
  hace esto". Activar ESPECIALMENTE bajo presión de tiempo — es cuando más se necesita
  el proceso.
---

# Systematic Debugging — QdoorA Edition

## Ley de Hierro

```
NINGÚN FIX SIN INVESTIGACIÓN DE CAUSA RAÍZ PRIMERO
```

Los fixes rápidos enmascaran problemas de fondo. Los parches acumulados crean deuda técnica irreparable. **Si no completaste la Fase 1, no puedes proponer código.**

---

## Las Cuatro Fases

### Fase 1 — Investigación de Causa Raíz

**ANTES de escribir una sola línea de código corrector:**

1. **Leer el error completo** — Stack traces de PHP/Angular, nunca saltarse líneas. Los números de archivo y línea son la verdad.

2. **Reproducir consistentemente** — ¿Se puede triggear el error de forma determinista? Si no es reproducible, recolectar más datos antes de actuar.

3. **Revisar cambios recientes** — `git diff`, últimos commits, nuevas dependencias, variables de entorno modificadas.

4. **Instrumentar sistemas multi-capa** — Cuando el stack QdoorA involucra múltiples capas, añadir diagnóstico en cada boundary antes de proponer fixes:

```php
// Laravel — trazar qué llega al servicio
Log::debug('PayrollService::calculate input', [
    'company_id' => $companyId,
    'period'     => $period,
    'employee'   => $employeeId,
]);

// Verificar que el scope multitenant aplica
Log::debug('Query company_id filter', [
    'query' => $query->toSql(),
    'bindings' => $query->getBindings(),
]);
```

```typescript
// Angular — trazar qué sale del servicio y qué recibe el componente
console.debug('[PayrollComponent] ngOnInit payload:', this.data);
console.debug('[PayrollService] response raw:', response);
```

5. **Trazar el flujo de datos** — ¿Dónde entra el valor corrupto? Remontar hacia atrás hasta el origen real, no el síntoma.

---

### Fase 2 — Análisis de Patrones

1. **Encontrar código equivalente que sí funciona** — Buscar en el codebase un módulo similar operativo. ¿Qué hace distinto?

2. **Comparar contra la referencia** — Leer la implementación correcta en su totalidad. Sin atajos.

3. **Listar todas las diferencias** — Aunque parezcan irrelevantes. "Eso no puede importar" es el origen del 40% de los bugs.

4. **Verificar dependencias del contexto** — `company_id`, `period`, `scope` (support/admin), estado del JWT, Redis caché.

---

### Fase 3 — Hipótesis y Prueba

1. **Una sola hipótesis** — Formular: *"Creo que X es la causa raíz porque Y"*. Escribirla antes de actuar.

2. **Cambio mínimo para probar** — Una variable a la vez. No agrupar múltiples cambios exploratorios.

3. **Verificar antes de continuar** — ¿Funcionó? Sí → Fase 4. No → nueva hipótesis desde cero.

4. **Si no se sabe** — Decir explícitamente "No entiendo X todavía". No fingir certeza.

---

### Fase 4 — Implementación

1. **Crear el test fallando primero** (TDD obligatorio en QdoorA):

```php
// Pest — el test DEBE fallar antes del fix
it('calcula correctamente el imponible con tope AFP', function () {
    $result = app(PayrollService::class)->calculateImponible(3_000_000, $period);
    expect($result)->toBe(2_981_832); // tope AFP vigente
});
```

```typescript
// Vitest — Angular 21 / Jest — Angular 18
it('should apply company_id filter on load', () => {
    expect(service.getEmployees).toHaveBeenCalledWith({ company_id: mockCompanyId });
});
```

2. **Fix al origen, no al síntoma** — Un único cambio que resuelve la causa raíz identificada en Fase 1.

3. **Verificar** — Test pasa. Otros tests no rompen. El comportamiento en contexto real es el esperado.

4. **Si el fix no funciona → DETENERSE**:
   - 1er intento fallido: volver a Fase 1 con la nueva información
   - 2do intento fallido: volver a Fase 1, cuestionar los supuestos
   - **3+ intentos fallidos: cuestionar la arquitectura**, no seguir parchando

---

## Señales de Alerta — PARAR y Reiniciar Proceso

Si te encuentras pensando cualquiera de estas cosas, es una señal de que debes parar y volver a la Fase 1:

| Racionalización | Realidad |
|----------------|---------|
| "Fix rápido por ahora, investigamos después" | El después nunca llega |
| "Pruebo este cambio a ver si funciona" | Debugging al azar es más lento que sistemático |
| "Múltiples cambios a la vez para ahorrar tiempo" | Imposible aislar qué funcionó; se crean nuevos bugs |
| "Es un bug simple, no necesita proceso" | Los bugs simples también tienen causa raíz |
| "Estamos bajo presión, no hay tiempo" | El proceso sistemático es más rápido que el ensayo-error |
| "Un intento más" (después de 2+ fallidos) | 3+ fallos = problema arquitectónico |

---

## Patrones Específicos QdoorA

### Bug de Multitenancy (el más peligroso)
Cuando los datos de una empresa aparecen en otra, verificar en este orden:
1. ¿El modelo tiene scope global de `company_id`?
2. ¿El FormRequest valida `company_id` en `authorize()`?
3. ¿Algún join omite el filtro de la empresa relacionada?
4. ¿Hay caché de Redis sin partición por `company_id`?

### Bug de Inmutabilidad Histórica
Cuando se modifican registros que no deberían cambiar (Nómina/Contabilidad/Aduana):
1. Verificar que no hay `UPDATE` o `DELETE` en tablas de historial
2. Buscar si se está editando el registro original en vez de crear un registro de reversa
3. Revisar si algún Observer o Event dispara una mutación no intencionada

### Error 500 en API Laravel
Secuencia de diagnóstico:
1. `storage/logs/laravel.log` — el stack trace real
2. ¿Pasa por el FormRequest? ¿El `authorize()` retorna `false`?
3. ¿El Service lanza excepción controlada o sin capturar?
4. ¿El Controller tiene el trait `HandlesControllerLogs`?

### Test Fallando en Angular (Vitest/Jest)
1. ¿El mock del servicio tiene la firma correcta?
2. ¿Se están usando `signal()` y el test espera valores síncronos?
3. ¿Hay `takeUntil` o subscripciones no cerradas que contaminan el test?

---

## Referencia Rápida

| Fase | Actividades Clave | Criterio de Salida |
|------|------------------|-------------------|
| **1. Causa Raíz** | Leer errores, reproducir, revisar cambios, instrumentar | Entender QUÉ y POR QUÉ ocurre |
| **2. Patrones** | Encontrar equivalente funcional, comparar diferencias | Identificar la discrepancia |
| **3. Hipótesis** | Formular teoría, prueba mínima | Hipótesis confirmada o nueva |
| **4. Implementación** | Test fallando → fix → test verde | Bug resuelto, sin regresiones |

---

> **Skills relacionadas**: `qa-data-auditor` (para escribir tests de cobertura tras el fix) · `ethical-hacking-auditor` (si el bug tiene implicaciones de seguridad) · `laravel-services` / `laravel-controllers` (para el fix en backend) · `prompt-architect-master` (si el fix requiere un plan arquitectónico mayor)

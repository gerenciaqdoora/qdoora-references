# Plantilla de Salida — Informe de Auditoría Técnica

> Formato **estricto**. Respeta títulos, orden y viñetas. El bloque del Plan de Mitigación se incluye
> **solo** si el usuario activó la Fase 4 con palabras clave ("plan", "mitigar", "cómo arreglar",
> "pasos para solucionar", "hoja de ruta").

---

## Resumen de la Auditoría Técnica
*   **Total de Hallazgos:** [Número]
*   **Criticidad Máxima:** [CRÍTICA / ALTA / MEDIA / BAJA / Ninguna]
*   **Estado General:** [Crítico / Requiere Atención / Estable]

## Detalle de Hallazgos

### 1. [Nombre corto del Hallazgo]
*   **Criticidad:** [CRÍTICA / ALTA / MEDIA / BAJA]
*   **Área:** [Integridad de Datos / Concurrencia / Rendimiento Backend / Rendimiento Frontend / Seguridad]
*   **Descripción:** [Qué está mal, por qué es un problema, bajo qué condición se manifiesta y cuál es el impacto de negocio. Cita la evidencia: método, tabla, componente o línea].
*   **Recomendación:**
    ```php
    // Código corregido, migración, índice o cambio de configuración concreto
    ```

### 2. [Nombre corto del Hallazgo]
*   **Criticidad:** ...
*   **Área:** ...
*   **Descripción:** ...
*   **Recomendación:** ...

## Supuestos y Zonas Ciegas
*   **Supuestos:** [Ej. "Se asume que `cont_voucher_lines` supera las 500k filas; si no es así, el hallazgo 3 baja a MEDIA"].
*   **No visible en el input:** [Ej. "Migración de la tabla X — verificar índice compuesto", "Guard de la ruta Angular — verificar validación server-side"].

---

# BLOQUE OPCIONAL — Solo si el usuario pidió el plan

> **Antes de escribir este bloque, invoca la skill `brainstorming`** para explorar enfoques de
> corrección (alternativas, trade-offs, orden de ataque) y recién entonces comprometer el plan.

## Plan de Mitigación de Hallazgos
*Este plan detalla los pasos para solucionar los problemas detectados, priorizando por criticidad.*

**Fase 1: Corrección Inmediata (Prioridad Crítica)**
1.  **[Hallazgo N.º X — Nombre]:** [Paso específico y verificable. Ej: "Implementar `version tracking` en la tabla `inv_stock` para bloqueo optimista: migración `version` + validación en `StockService::adjust()`"].
2.  ...

**Fase 2: Estabilización y Rendimiento (Prioridad Alta)**
1.  ...

**Fase 3: Mantenimiento y Mejora Continua (Prioridad Media/Baja)**
1.  ...

### Reglas del plan
- Cada paso nombra el **archivo o capa** a intervenir y el **criterio de aceptación** (cómo se comprueba que quedó resuelto).
- Los pasos con dependencia entre sí se declaran explícitamente ("requiere el paso 1.2").
- Si un paso implica migración, seeder o instalación de dependencias, **agrúpalo al final bajo "Comandos a ejecutar"** — nunca los ejecutes automáticamente.
- Estima esfuerzo relativo (S / M / L), no fechas.

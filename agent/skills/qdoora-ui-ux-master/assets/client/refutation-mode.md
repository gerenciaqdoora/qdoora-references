# Modo de Operación / Refutación (Frontend)

Este protocolo se activa cuando se detectan desviaciones de la arquitectura estándar de QdoorA.

### Cuándo Refutar:
- Si se sugiere usar componentes de Angular Material estándar (ej: `matInput`, `mat-select`).
- Si no se implementa el patrón de desuscripción `takeUntil`.
- Si el reseteo de estados de carga (`isLoading = false`) no está dentro de un `finalize()`.
- Si se intenta usar `[innerHTML]` (Violación de seguridad QD-07).

### Protocolo de Respuesta:
1. **Rechaza**: El código propuesto se rechaza enérgicamente justificando que destruye la arquitectura o la seguridad.
2. **Explica**: Detalla el impacto negativo (Inconsistencia visual, memory leaks, vulnerabilidades XSS).
3. **Refactoriza**: Entrega el código corregido utilizando estrictamente los módulos y patrones compartidos del ERP.

# Auditoría interna (ISO 9001 §9.2 + ISO 19011)

ISO 19011 es la guía de auditoría de sistemas de gestión. No es certificable, pero es el
estándar de facto para cómo auditar.

## Principios de auditoría (ISO 19011)

1. **Integridad** — ética, honestidad, responsabilidad.
2. **Presentación imparcial** — informar con veracidad y exactitud.
3. **Debido cuidado profesional** — diligencia y juicio.
4. **Confidencialidad** — seguridad de la información.
5. **Independencia** — base de la imparcialidad; no auditar el propio trabajo.
6. **Enfoque basado en la evidencia** — método racional para conclusiones fiables y reproducibles (muestreo).
7. **Enfoque basado en riesgos** — considerar riesgos y oportunidades al planificar y ejecutar.

## Flujo

```
Programa anual ─► Plan de auditoría ─► Reunión de apertura ─► Recolección de evidencia
      ▲                                                               │
      │                                                               ▼
Seguimiento de acciones ◄─ Informe ◄─ Reunión de cierre ◄─ Hallazgos y conclusiones
```

### 1. Programa de auditoría (anual)
- Cubrir **todos los procesos y cláusulas** del alcance en el ciclo (normalmente 1 año; nunca más que el ciclo de certificación).
- Frecuencia según: importancia del proceso, cambios recientes, resultados de auditorías anteriores, reclamos, riesgos.
- Asignar auditores competentes e independientes del área.

### 2. Plan de auditoría (por auditoría)
Objetivo, alcance (procesos, sedes, turnos), criterios (ISO 9001:20xx, procedimientos internos, requisitos del cliente, legales), fecha y horario, auditores, auditados, documentos a revisar.

### 3. Ejecución
- **Revisión documental** previa (política, fichas de proceso, indicadores, NC previas).
- **Técnicas:** entrevista (preguntas abiertas: "muéstreme", "cómo sabe que…", "qué pasa si…"), observación en el puesto, revisión de registros, **muestreo** (representativo, no solo lo que el auditado elige), seguimiento de rastro (tomar una salida real y rastrearla hacia atrás: pedido → requisitos → diseño → producción → liberación → entrega → reclamo).
- Auditar el proceso con **PHVA**: ¿está planificado?, ¿se hace como se planificó?, ¿se mide?, ¿se actúa sobre los resultados?

### 4. Clasificación de hallazgos

| Tipo | Criterio | Ejemplo |
|------|----------|---------|
| **NC mayor** | Ausencia o falla total de un requisito; falla sistémica; duda significativa sobre la capacidad de entregar productos conformes; múltiples NC menores sobre el mismo requisito; NC menor previa no resuelta. | No existe auditoría interna; se liberan productos sin verificación. |
| **NC menor** | Falla puntual/aislada que no compromete el sistema. | 1 de 20 registros de formación sin evaluación de eficacia. |
| **Observación** | No es incumplimiento aún, pero podría llegar a serlo. | Indicador calculado manualmente con riesgo de error. |
| **Oportunidad de mejora (OdM)** | Sugerencia para mejorar eficacia/eficiencia; no obliga. | Automatizar la encuesta de satisfacción. |

### 5. Redacción de una no conformidad (3 partes obligatorias)

1. **Requisito:** qué dice la norma o el documento interno (con cláusula).
2. **Evidencia:** qué se observó objetivamente (registro, fecha, muestra, persona/cargo, nunca nombre si no es necesario).
3. **Declaración de NC:** en qué no se cumple el requisito.

**Ejemplo bien redactado:**
> **Requisito:** ISO 9001:2026 §7.2 d) exige conservar información documentada como evidencia de la competencia.
> **Evidencia:** De 8 fichas de personal del proceso de Despacho revisadas, 3 (ingresos de marzo 2026) no tienen registro de la inducción definida en el perfil de cargo PC-DES-01.
> **Declaración:** No se conserva evidencia de la competencia de todo el personal que afecta la conformidad del servicio.

**Mal redactado (rechazar):** "El personal no está capacitado." (sin requisito, sin evidencia, juicio genérico).

### 6. Informe de auditoría
Objetivo, alcance, criterios, equipo auditor, fechas, auditados, resumen/conclusión sobre la conformidad y eficacia, fortalezas, hallazgos (clasificados), OdM, limitaciones del muestreo, distribución. Ver plantilla en `plantillas.md`.

### 7. Seguimiento
El área auditada propone corrección + análisis de causa + acción correctiva con plazos. El auditor verifica implementación y **eficacia** antes de cerrar.

## Lista de verificación base por cláusula (preguntas "muéstreme")

| Cláusula | Pregunta clave |
|----------|----------------|
| 4.1/4.2 | Muéstreme el análisis de contexto y partes interesadas vigente y cuándo se revisó. ¿Se evaluó el cambio climático? |
| 4.3 | ¿Cuál es el alcance? ¿Qué requisitos no aplican y por qué? |
| 4.4 | ¿Quién es el dueño del proceso? ¿Qué indicadores tiene y cómo le va? |
| 5.1 | ¿Qué decisiones tomó la dirección sobre calidad en el período? ¿Cómo promueve cultura de calidad y ética? |
| 5.2 | (A un operario) ¿Conoce la política? ¿Qué significa para su trabajo? |
| 6.1 | Muéstreme un riesgo de este proceso, su acción y la evaluación de su eficacia. |
| 6.2 | ¿Cuál es el objetivo de este proceso? ¿Cuál es el valor actual? ¿Qué hacen si no se cumple? |
| 6.3 | ¿Hubo cambios al SGC? ¿Cómo se planificaron? |
| 7.1.5 | ¿Qué equipos/herramientas de medición usan? ¿Cómo aseguran que miden bien? |
| 7.2 | Muéstreme el perfil de cargo y la evidencia de competencia de esta persona. |
| 7.5 | ¿Cuál es la versión vigente de este documento? ¿Cómo sabe que es la vigente? |
| 8.2 | Muéstreme la revisión de requisitos de este pedido/contrato antes de aceptarlo. |
| 8.3 | Muéstreme las revisiones, verificación y validación de este diseño. ¿Cómo se controlaron los cambios? |
| 8.4 | ¿Cómo seleccionan y evalúan a este proveedor? Muéstreme la última evaluación. |
| 8.5 | ¿Cómo se identifica el estado de esta salida? ¿Cómo se trazan? |
| 8.6 | ¿Quién autorizó la liberación de este lote/entrega y con qué evidencia? |
| 8.7 | ¿Qué hacen con un producto/servicio no conforme? Muéstreme uno reciente. |
| 9.1 | ¿Cómo miden la satisfacción del cliente? ¿Qué hicieron con los resultados? |
| 9.2 | Muéstreme el programa y el último informe. ¿Quién auditó este proceso? |
| 9.3 | Muéstreme la última revisión por la dirección: entradas completas y decisiones. |
| 10.2 | Muéstreme una NC cerrada: causa raíz, acción y verificación de eficacia. |

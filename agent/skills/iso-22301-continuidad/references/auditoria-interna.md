# Auditoría interna del SGCN (§9.2)

Guía: **ISO 19011**. Competencia de auditores de certificación: ISO/IEC TS 17021-6.

## Principios (ISO 19011)
Integridad · Presentación imparcial · Debido cuidado profesional · Confidencialidad ·
Independencia · Enfoque basado en la evidencia · Enfoque basado en riesgos.

## Flujo
Programa anual (todas las cláusulas y todas las actividades prioritarias en el ciclo; más
frecuencia donde hubo incidentes, cambios o resultados débiles) → plan → apertura → evidencia →
hallazgos → cierre → informe → seguimiento de acciones y eficacia.

## Técnica clave: rastreo vertical

Toma una actividad prioritaria y sigue la cadena completa:

```
Producto/servicio en alcance → BIA (impacto, MTPD, RTO, MBCO, RPO, aprobado)
→ Recursos y dependencias → Riesgos de disrupción → Estrategia y solución
→ Plan (activación, roles, pasos) → Último ejercicio (resultado vs RTO) → Acciones cerradas
→ Evidencia en la revisión por la dirección
```

Cualquier eslabón roto es un hallazgo. Complementa con:
- **Pruebas en terreno:** pedir a un miembro del equipo que muestre dónde está su copia del plan sin usar la red corporativa; llamar a un contacto del directorio; verificar que el sitio alterno existe y tiene capacidad.
- **Muestreo** de contactos, proveedores críticos e informes de ejercicios.

## Clasificación de hallazgos

| Tipo | Criterio | Ejemplo |
|------|----------|---------|
| **NC mayor** | Ausencia o falla sistémica de un requisito; incapacidad demostrada de recuperar actividades prioritarias. | No existe BIA; ningún ejercicio en el ciclo; RTO crítico superado sistemáticamente sin acción. |
| **NC menor** | Falla aislada. | 2 de 15 contactos del plan de finanzas desactualizados. |
| **Observación** | Podría derivar en NC. | Sitio alterno con capacidad justa para MBCO sin margen de crecimiento. |
| **Oportunidad de mejora** | Sugerencia. | Automatizar la prueba del árbol de llamadas. |

## Redacción de una NC (requisito + evidencia + declaración)

> **Requisito:** ISO 22301:2019 §8.5 exige que el programa de ejercicios valide la eficacia de las estrategias y soluciones, y el Plan de Recuperación TIC PRT-02 v4 fija un RTO de 4 h para el sistema de facturación.
> **Evidencia:** El informe de la prueba de DR del 2026-06-18 registra una restauración en 11 h. No existe acción registrada ni actualización del plan ni del BIA posterior a esa fecha (revisado el 2026-09-10).
> **Declaración:** No se tomaron acciones tras un ejercicio que demostró que la solución no cumple el RTO requerido.

## Lista de verificación base

| Ref. | Pregunta ("muéstreme") |
|------|------------------------|
| 4.1 / 4.2 | Contexto (incluida la evaluación del cambio climático); partes interesadas; **matriz legal y regulatoria actualizada**. |
| 4.3 | Alcance: productos/servicios incluidos y explicación de exclusiones. |
| 5.1 / 5.3 | Compromiso de la dirección; comité de crisis designado con suplentes. |
| 5.2 / 7.3 | (A un empleado) ¿Qué hace usted si no puede acceder a la oficina o a los sistemas? |
| 6.1 / 6.2 | Riesgos del SGCN; objetivos medibles y su avance. |
| 7.2 | Formación de los equipos de respuesta; evidencia. |
| 8.1 | Control de procesos externalizados y cadena de suministro. |
| 8.2.2 | BIA: criterios, MTPD/RTO/MBCO/RPO, recursos, dependencias, aprobación, fecha. |
| 8.2.3 | Riesgos de disrupción evaluados y tratados; puntos únicos de falla. |
| 8.3 | Estrategias por actividad prioritaria; justificación; implementación real. |
| 8.4.2 | Estructura de respuesta, umbrales de activación. |
| 8.4.3 | Plan de comunicaciones, medios alternativos, bitácora de un incidente real. |
| 8.4.4 | Plan: activación, desactivación, contactos vigentes, disponibilidad fuera de línea. |
| 8.4.5 | Procedimiento de retorno a la normalidad. |
| 8.5 | Programa de ejercicios; informes; tiempos reales vs RTO; acciones. |
| 8.6 | Evaluación de documentación y capacidades; evaluación de proveedores críticos; evaluación tras incidentes. |
| 9.1 | Indicadores de continuidad y su análisis. |
| 9.2 | Programa y resultados de auditoría; independencia. |
| 9.3 | Acta con entradas específicas de continuidad (BIA, 8.6, cuasi-incidentes) y decisiones. |
| 10.1 | NC cerrada con causa raíz y verificación de eficacia. |

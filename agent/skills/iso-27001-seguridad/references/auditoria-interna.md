# Auditoría interna del SGSI (§9.2)

Guías: **ISO 19011** (auditoría de sistemas de gestión), **ISO/IEC 27007** (auditoría de SGSI)
e **ISO/IEC TS 27008** (evaluación de controles de seguridad).

## Principios (ISO 19011)
Integridad · Presentación imparcial · Debido cuidado profesional · **Confidencialidad** (el
auditor accede a información sensible) · Independencia · Enfoque basado en la evidencia ·
Enfoque basado en riesgos.

## Dos niveles de auditoría

| Nivel | Qué verifica | Ejemplo |
|-------|--------------|---------|
| **Sistema de gestión** (cláusulas 4–10) | Que el SGSI está diseñado, operado y mejorado. | ¿La apreciación de riesgos se repitió tras la migración a la nube? |
| **Controles** (Anexo A / SoA, 27008) | Que cada control declarado "implementado" existe y es **eficaz**. | Tomar una muestra de 10 bajas de personal y verificar la revocación de accesos en ≤ 24 h. |

Técnicas de verificación de controles (27008): revisión documental, entrevista, observación,
**inspección técnica** (configuraciones, consolas, políticas del IdP), **pruebas** (muestreo de
registros, ejecución de consultas, reprocesar un control). Toda prueba técnica intrusiva requiere
autorización y plan (control 8.34).

## Flujo

1. **Programa anual:** cubrir todas las cláusulas y los controles aplicables de la SoA en el ciclo; frecuencia según riesgo, cambios, incidentes y resultados previos. Auditores competentes e independientes del área.
2. **Plan:** objetivo, alcance, criterios (27001:2022, SoA, políticas internas, requisitos legales/contractuales), fechas, auditados, accesos requeridos (de solo lectura), manejo de la evidencia confidencial.
3. **Ejecución:** revisión documental → entrevistas → inspección y pruebas → muestreo representativo.
4. **Hallazgos** clasificados y redactados en 3 partes.
5. **Reunión de cierre e informe** (clasificado como confidencial).
6. **Seguimiento** de correcciones, acciones correctivas y su eficacia.

## Clasificación de hallazgos

| Tipo | Criterio | Ejemplo |
|------|----------|---------|
| **NC mayor** | Ausencia o falla sistémica de un requisito; riesgo significativo no tratado; SoA o apreciación de riesgos inexistentes; control crítico declarado implementado que no existe. | No hay apreciación de riesgos; accesos de ex-empleados activos de forma generalizada. |
| **NC menor** | Falla aislada que no compromete el sistema. | 1 de 15 revisiones de acceso trimestrales no se ejecutó. |
| **Observación** | Situación que podría derivar en NC. | Logs centralizados sin revisión definida. |
| **Oportunidad de mejora** | Sugerencia. | Automatizar la revisión de accesos. |

## Redacción de una no conformidad

1. **Requisito** (cláusula o control + documento interno).
2. **Evidencia** objetiva (qué, dónde, cuándo, muestra).
3. **Declaración** del incumplimiento.

> **Requisito:** ISO/IEC 27001:2022 Anexo A control 5.18 y la Política de Control de Acceso PCA-01 v3 §4.2 exigen retirar los accesos al término de la relación laboral dentro de 24 horas.
> **Evidencia:** De 12 desvinculaciones entre enero y junio de 2026, 3 cuentas permanecían activas en el sistema de gestión de clientes entre 9 y 41 días después de la fecha de término (reporte del IdP del 2026-07-10).
> **Declaración:** Los derechos de acceso no se retiran oportunamente al término de la relación laboral.

**Rechazar:** "La gestión de accesos es deficiente" (sin requisito, sin evidencia).

**Nunca** incluyas en el informe credenciales, datos personales ni detalles explotables más allá de lo necesario; referencia la evidencia en su repositorio controlado.

## Lista de verificación base

| Ref. | Pregunta clave ("muéstreme") |
|------|------------------------------|
| 4.1/4.2 | Análisis de contexto y partes interesadas vigente; requisitos que aborda el SGSI; evaluación del cambio climático. |
| 4.3 | Alcance, interfaces y dependencias. ¿Qué queda fuera y por qué? |
| 5.1 | Decisiones y recursos de la dirección para seguridad. |
| 5.2 / 7.3 | (A un empleado) ¿Conoce la política? ¿Cómo reporta un incidente? |
| 6.1.2 | Metodología, criterios de aceptación, última apreciación, dueños de riesgo. |
| 6.1.3 | SoA completa (93 controles) con justificaciones; plan aprobado; aceptación del residual. |
| 6.2 | Objetivos medibles, valor actual, seguimiento. |
| 6.3 | Cambios al SGSI y su planificación. |
| 7.2 | Competencias del equipo de seguridad y TI; evidencia. |
| 7.5 | Versión vigente de la política; control de acceso a documentos del SGSI. |
| 8.1 | Control de procesos externalizados (nube, MSP, desarrollo tercerizado). |
| 8.2 / 8.3 | Apreciación repetida en el período y ante cambios; avance del plan. |
| 9.1 | Métricas, método, resultados, análisis. |
| 9.2 | Programa, informes, independencia de auditores. |
| 9.3 | Acta con todas las entradas y decisiones. |
| 10.2 | NC cerrada con causa raíz y verificación de eficacia. |
| 5.9 | Inventario: tomar un activo al azar en terreno y buscarlo en el inventario (y viceversa). |
| 5.15–5.18 / 8.2 / 8.5 | Muestra de altas, bajas, cambios de rol y cuentas privilegiadas; MFA habilitado. |
| 5.19–5.23 | Evaluación de un proveedor crítico y de un servicio cloud; responsabilidad compartida. |
| 5.24–5.28 | Último incidente: registro, clasificación, respuesta, lecciones, evidencia. |
| 5.30 / 8.13 | Última prueba de restauración y de continuidad; RTO/RPO alcanzados. |
| 6.3 | Registros de formación y resultados de simulaciones. |
| 8.8 | Últimos escaneos, vulnerabilidades críticas abiertas y fuera de plazo. |
| 8.9 | Línea base y detección de desviaciones de configuración. |
| 8.15 / 8.16 | Logs de un sistema crítico: existencia, retención, protección, revisión de alertas. |
| 8.25–8.29 / 8.32 | Un cambio reciente en producción: requisito, revisión, pruebas de seguridad, aprobación. |
| 8.31 / 8.33 | Separación de entornos; origen de los datos de prueba. |

# Estrategias y soluciones de continuidad (§8.3)

Guías: ISO 22313, **ISO/TS 22331** (estrategia de continuidad), **ISO/TS 22318** (cadena de
suministro), **ISO/IEC 27031** (preparación TIC).

## Marco temporal (§8.3.2)

| Momento | Objetivo | Ejemplos |
|---------|----------|----------|
| **Antes** (protección, mitigación) | Reducir probabilidad o impacto | Redundancia, respaldo, contratos, formación cruzada, UPS |
| **Durante** (respuesta, continuidad) | Mantener actividades prioritarias a MBCO | Sitio alterno, trabajo remoto, procedimientos manuales, proveedor alternativo |
| **Después** (recuperación) | Volver a la normalidad | Reconstrucción, reposición, sincronización de datos, desactivación |

## Opciones por recurso (§8.3.4)

| Recurso | Opciones de estrategia | Preguntas de validación |
|---------|------------------------|-------------------------|
| **Personas** | Formación cruzada, documentación de conocimiento crítico, suplentes designados, equipos distribuidos geográficamente, acuerdos con terceros/temporales, trabajo remoto | ¿Hay al menos 2 personas capaces de cada tarea crítica? ¿Pueden trabajar sin el sitio principal? |
| **Información y datos** | Respaldos (regla 3-2-1, copia inmutable/fuera de línea), replicación, registros vitales en papel o fuera del sitio | ¿Se cumple el RPO? ¿Se probó la restauración? ¿El respaldo sobrevive a un ransomware? |
| **Edificios / espacio** | Sitio alterno propio, sitio de proveedor (espacio de recuperación), trabajo remoto, reubicación entre sedes, acuerdos recíprocos | ¿Capacidad suficiente para MBCO? ¿Tiempo real de habilitación < RTO? |
| **Equipos y consumibles** | Stock de reserva, proveedores alternativos, contratos de reposición urgente | ¿Plazo de reposición < RTO? |
| **Sistemas TIC** | Alta disponibilidad, DR en otra región/sitio, *warm/cold standby*, respaldo y restauración, SaaS alternativo, modo degradado | ¿La arquitectura real cumple RTO/RPO? ¿Se probó la conmutación? |
| **Transporte y logística** | Rutas y transportistas alternativos, inventario distribuido | ¿Qué pasa si el centro de distribución queda inaccesible? |
| **Finanzas** | Fondos de contingencia, líneas de crédito, seguros de interrupción de negocio, pagos de emergencia | ¿Se puede pagar nómina y proveedores críticos sin el sistema principal? |
| **Socios y proveedores** | Proveedores múltiples, evaluación de su continuidad, cláusulas contractuales (RTO, notificación, pruebas conjuntas), stock de seguridad, plan de salida | ¿El RTO del proveedor ≤ nuestro RTO? ¿Tiene plan probado? ¿Hay proveedor alternativo calificado? |

## Selección (§8.3.3)

Evalúa cada opción con:

| Criterio | Pregunta |
|----------|----------|
| Cumplimiento de tiempos | ¿Permite reanudar dentro del RTO y a MBCO? ¿Protege el RPO? |
| Cobertura | ¿Cuántos escenarios de pérdida de recurso cubre? |
| Apetito de riesgo | ¿El riesgo residual es aceptable para la dirección? |
| Costo / beneficio | Costo de implementar y mantener vs impacto evitado (del BIA). |
| Factibilidad | ¿Realista con recursos, tecnología y plazos disponibles? |
| Dependencias | ¿Introduce nuevos puntos únicos de falla? |

Si ninguna opción cumple el RTO a un costo aceptable, la dirección tiene dos caminos: invertir
más o **aceptar formalmente** un RTO mayor (siempre < MTPD) y registrar la decisión.

## Tabla de estrategias

| Actividad prioritaria | RTO / MBCO / RPO | Escenario de pérdida (recurso) | Estrategia | Solución concreta | Costo estimado | Estado (implementada / en curso / propuesta) | Validada en ejercicio (fecha) |
|-----------------------|------------------|-------------------------------|-----------|-------------------|----------------|---------------------------------------------|------------------------------|

## Implementación (§8.3.5)

Una solución no está implementada hasta que: los recursos existen o están contratados; hay
procedimiento de activación; las personas están formadas; y se ha **ejercitado** al menos una vez.

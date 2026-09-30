# No conformidades, acción correctiva y revisión post-incidente

## Distinciones

| Concepto | Qué es | Ejemplo |
|----------|--------|---------|
| **Disrupción / incidente real** | Evento que interrumpe o amenaza las actividades. | Corte eléctrico de 9 h en la sede principal. |
| **Cuasi-incidente** | Evento que casi causa disrupción. | El generador arrancó con 40 min de atraso, pero la UPS alcanzó. |
| **No conformidad** | Incumplimiento de un requisito (norma, SGCN, ley, contrato). | El plan exige activar el sitio alterno en 2 h; se activó en 6 h. |
| **Corrección** | Arreglar la NC detectada. | Actualizar los contactos erróneos. |
| **Acción correctiva** | Eliminar la causa. | Proceso trimestral automatizado de verificación de contactos vinculado a RR. HH. |

Toda activación real o cuasi-incidente → **revisión post-incidente** (§8.6) y entrada a la
revisión por la dirección (§9.3.2). Si la respuesta no cumplió lo planificado → NC (§10.1).

## Flujo de acción correctiva (§10.1)

1. Registrar (origen: auditoría, ejercicio, incidente real, cuasi-incidente, evaluación de proveedor, reclamo).
2. Contener y corregir; atender consecuencias.
3. Evaluar si requiere acción correctiva (decisión registrada).
4. **Causa raíz** (5 porqués, Ishikawa, línea de tiempo).
5. ¿NC similares en otros planes, sedes o proveedores?
6. Implementar acciones (qué, quién, cuándo).
7. **Verificar eficacia** con criterio predefinido, idealmente **con un nuevo ejercicio** (p. ej., "prueba de DR repetida cumple RTO de 4 h").
8. Actualizar BIA, riesgos, estrategias, planes.
9. Cerrar con evidencia.

### Ejemplo de 5 porqués
> Problema: la restauración del sistema de facturación tardó 11 h frente a un RTO de 4 h.
> 1. ¿Por qué? La restauración de la base de datos tomó 8 h.
> 2. ¿Por qué? El respaldo completo se restaura desde almacenamiento de archivo lento.
> 3. ¿Por qué? La política de respaldos se diseñó por costo sin considerar el RTO.
> 4. ¿Por qué? El RTO del BIA nunca se tradujo a requisitos para los sistemas TIC.
> 5. ¿Por qué? No existe el paso "tabla de RTO/RPO por sistema" en el proceso de BIA.
> **Causa raíz:** falta de vínculo BIA → requisitos TIC. **Acciones:** tabla por sistema con RTO/RPO exigidos; rediseño del respaldo (réplica + instantáneas); nueva prueba.

**Anti-patrones:** "el plan no se siguió" como causa final (¿por qué no se pudo seguir?);
"capacitar" como única acción; cerrar sin reejercitar.

## Revisión post-incidente (formato)

| Campo | Contenido |
|-------|-----------|
| Incidente / fecha y duración | |
| Actividades afectadas | |
| ¿Se activó el plan? ¿Cuándo? ¿Quién? | |
| Línea de tiempo (detección, alerta, activación, soluciones, recuperación, desactivación) | |
| **Tiempos reales vs RTO / RPO / MBCO** | |
| Impacto real (por tipo del BIA) | |
| Qué funcionó | |
| Qué no funcionó | |
| Comunicación (interna, clientes, reguladores, medios) | |
| Desempeño de proveedores | |
| Causa raíz del incidente y de las fallas de respuesta | |
| Acciones (responsable, fecha) | |
| Actualizaciones a BIA / riesgos / estrategias / planes | |
| Notificaciones regulatorias realizadas (si aplica) | |

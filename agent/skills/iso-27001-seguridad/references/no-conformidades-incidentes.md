# No conformidades, acción correctiva e incidentes

## Distinciones clave

| Concepto | Qué es | Ejemplo |
|----------|--------|---------|
| **Evento de seguridad** | Algo que podría indicar un problema. | Alerta de inicio de sesión desde un país inusual. |
| **Incidente de seguridad** | Evento(s) con probabilidad significativa de comprometer CID u operaciones. | Cuenta comprometida usada para exfiltrar datos. |
| **No conformidad** | Incumplimiento de un requisito (norma, SGSI, ley, contrato). | El procedimiento exige MFA y la cuenta comprometida no lo tenía. |
| **Corrección** | Eliminar la NC detectada. | Activar MFA en esa cuenta. |
| **Acción correctiva** | Eliminar la causa para que no se repita. | Política de acceso condicional que impide cuentas sin MFA + control de cumplimiento automático. |

Un incidente **no siempre** es una NC (puede ocurrir con todos los controles funcionando), pero si
se originó en un control faltante, ineficaz o no cumplido, **sí** genera NC y acción correctiva.
Todo incidente debe alimentar el aprendizaje (5.27) y la apreciación de riesgos (§8.2).

## Flujo de acción correctiva (§10.2)

1. **Registrar** (origen: auditoría, incidente, pentest, escaneo, reclamo de cliente, revisión de cumplimiento, métrica).
2. **Contener y corregir**; atender consecuencias (incluidas notificaciones legales si aplican).
3. **Evaluar si requiere acción correctiva** y registrar la decisión.
4. **Analizar la causa raíz** (5 porqués, Ishikawa, línea de tiempo del incidente, árbol de fallas).
5. **Buscar NC similares** en otros sistemas, sedes o proveedores.
6. **Implementar acciones** (qué, quién, cuándo).
7. **Verificar eficacia** con criterio definido de antemano (p. ej. "0 cuentas sin MFA en 3 revisiones mensuales consecutivas").
8. **Actualizar** registro de riesgos, SoA, políticas, formación.
9. **Cerrar** con evidencia; si no fue eficaz, reabrir.

### Ejemplo de 5 porqués
> Problema: una base de datos de pruebas con datos reales de clientes quedó expuesta a internet.
> 1. ¿Por qué estaba expuesta? El grupo de seguridad permitía 0.0.0.0/0.
> 2. ¿Por qué? Se creó manualmente para depurar y no se revirtió.
> 3. ¿Por qué se pudo crear manualmente? No hay infraestructura como código ni detección de desviaciones (8.9).
> 4. ¿Por qué había datos reales en pruebas? No existe procedimiento de datos de prueba (8.33) ni enmascaramiento (8.11).
> 5. ¿Por qué no se detectó? No hay monitoreo de configuración cloud (8.16, 5.23).
> **Causas raíz:** ausencia de gestión de configuración y de gestión de datos de prueba. **Acciones:** IaC obligatoria + CSPM con alertas; datos de prueba sintéticos/enmascarados; actualizar riesgos.

**Anti-patrones:** "error humano" como causa final; "capacitar" como única acción; cerrar sin
verificar eficacia; confundir corrección con acción correctiva.

## Gestión de incidentes (controles 5.24 – 5.28, 6.8)

### Ciclo
```
Preparación (5.24) → Detección y reporte (6.8, 8.16) → Evaluación y clasificación (5.25)
→ Contención, erradicación, recuperación (5.26) → Notificación (5.5, 5.31, 5.34)
→ Lecciones aprendidas (5.27) → Evidencia preservada en todo el ciclo (5.28)
```

### Clasificación de severidad (ejemplo)

| Severidad | Criterio | Tiempo de respuesta objetivo |
|-----------|----------|------------------------------|
| Crítica | Datos personales/confidenciales comprometidos, servicio principal caído, ransomware | Inmediato; comité de crisis |
| Alta | Compromiso confirmado acotado; riesgo de escalamiento | < 4 h |
| Media | Intento con impacto limitado; malware contenido | < 24 h |
| Baja | Evento sin impacto confirmado | Próximo día hábil |

### Notificaciones
Identifica en la matriz legal (5.31) los plazos de notificación aplicables: autoridad de
protección de datos, CSIRT/agencia nacional de ciberseguridad, reguladores sectoriales,
clientes (según contratos). Los plazos varían por jurisdicción y sector (a menudo entre
**horas y pocos días**): **verifícalos con el área legal**, no los supongas.

### Registro de incidente (mínimo)
ID · fecha/hora de detección y de ocurrencia · quién reportó · descripción · activos afectados ·
propiedad afectada (C/I/D) · severidad · acciones de contención/erradicación/recuperación con
horas · notificaciones realizadas (a quién, cuándo) · evidencia preservada (ubicación, cadena de
custodia) · causa raíz · NC asociada · lecciones aprendidas · cierre.

### Post-mortem sin culpables
Línea de tiempo · qué funcionó · qué falló · causa raíz · acciones con responsable y fecha ·
actualización de riesgos/controles · métrica de verificación.

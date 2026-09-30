# No conformidades y acción correctiva (§8.7 y §10.2)

## Distinción clave

| Concepto | Qué ataca | Ejemplo |
|----------|-----------|---------|
| **Contención** | El impacto inmediato | Retener el lote, avisar al cliente, revertir el despliegue. |
| **Corrección** | El síntoma (la NC concreta) | Reprocesar la pieza, corregir el dato erróneo. |
| **Acción correctiva** | La **causa raíz** | Cambiar el proceso para que no vuelva a pasar. |
| **Acción preventiva** (concepto 2008) | Causa potencial | En 9001:2015/2026 se absorbe en el pensamiento basado en riesgos (§6.1). |

## Flujo obligatorio

1. **Registrar** la NC (origen: auditoría, reclamo, inspección, indicador, proveedor, interno).
2. **Contener y corregir** (§10.2.1 a): controlar, corregir, hacer frente a consecuencias.
3. **Evaluar si requiere acción correctiva** (según gravedad, recurrencia, riesgo). No toda NC la requiere, pero la decisión debe ser consciente y registrada.
4. **Analizar la causa raíz** (método proporcional a la complejidad).
5. **Buscar NC similares** existentes o potenciales en otros procesos/productos (extensión).
6. **Definir e implementar acciones** (qué, quién, cuándo, recursos).
7. **Verificar la eficacia** tras un plazo razonable y con **criterio definido de antemano** (p. ej., "0 reincidencias en 3 meses", "indicador X > 95% por 2 períodos").
8. **Actualizar** riesgos y oportunidades y, si procede, el SGC (documentos, formación, controles).
9. **Cerrar** solo con evidencia de eficacia. Si no fue eficaz, reabrir y volver a 4.

## Métodos de análisis de causa raíz

### 5 Porqués (problemas simples/moderados)
Preguntar "¿por qué?" sucesivamente hasta llegar a una causa sobre la que se puede actuar en el
**proceso** (no en la persona). Validar hacia atrás: "si eliminamos esta causa, ¿desaparece el problema?".

> Problema: se entregó al cliente una versión con un defecto crítico.
> 1. ¿Por qué? El defecto no se detectó en pruebas.
> 2. ¿Por qué? No había caso de prueba para ese flujo.
> 3. ¿Por qué? El requisito se agregó por correo y no quedó en el backlog.
> 4. ¿Por qué? No hay un canal formal para cambios de requisitos del cliente.
> 5. ¿Por qué? El proceso comercial no define cómo se registran cambios (§8.2.4).
> **Causa raíz:** ausencia de control de cambios en requisitos. **Acción:** canal único de cambios + revisión de requisitos que dispare actualización de pruebas.

### Diagrama de Ishikawa (6M) — problemas con múltiples causas posibles
Categorías: **Método, Mano de obra (personas), Máquina, Material, Medición, Medio ambiente**
(en servicios/software: Procesos, Personas, Herramientas, Información, Medición, Entorno).
Generar hipótesis por categoría, luego **verificarlas con datos** antes de elegir la causa.

### 8D — problemas graves, recurrentes o con cliente involucrado
D0 preparar · D1 equipo · D2 describir el problema (qué, dónde, cuándo, cuánto; es / no es) ·
D3 contención · D4 causa raíz (de ocurrencia **y** de no detección) · D5 elegir y verificar
acciones · D6 implementar y validar · D7 prevenir recurrencia (sistematizar) · D8 reconocer al equipo.

### Otras herramientas
Pareto (priorizar las pocas causas vitales), análisis de tendencia, diagrama de flujo del proceso,
árbol de fallas, AMFE/FMEA (preventivo, útil para §6.1).

## Anti-patrones en el análisis de causa

- **"Error humano" como causa raíz.** Pregunta por qué el proceso permitió el error (§8.5.1 g exige acciones para prevenir el error humano).
- **"Capacitar nuevamente"** como única acción: solo es válida si la causa es realmente falta de competencia y se verifica eficacia.
- **Acción = corrección.** Arreglar el caso no evita que vuelva a pasar.
- **Cerrar sin verificar eficacia** o verificar solo que "se hizo la acción".
- **Plazos irreales** o sin responsable.

## Registro mínimo de NC (§10.2.2)

Código · fecha · origen · proceso · descripción (requisito + evidencia) · clasificación ·
contención/corrección · ¿requiere AC? (sí/no + justificación) · análisis de causa · acciones
(responsable, fecha) · criterio y fecha de verificación de eficacia · resultado de eficacia ·
actualización de riesgos/SGC · cierre (quién, cuándo). Plantilla en `plantillas.md`.

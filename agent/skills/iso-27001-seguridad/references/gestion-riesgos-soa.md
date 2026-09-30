# Gestión de riesgos y Declaración de Aplicabilidad (§6.1.2, §6.1.3, §8.2, §8.3)

Guía de apoyo: **ISO/IEC 27005:2022** (gestión de riesgos de seguridad de la información).
ISO 27001 no impone método; exige que sea definido, repetible y comparable.

## 1. Definir la metodología (una vez, documentada)

| Elemento | Decisión a documentar |
|----------|----------------------|
| Enfoque de identificación | **Basado en activos** (activo → amenaza → vulnerabilidad) o **basado en eventos/escenarios** (fuente de riesgo → evento → consecuencia). 27005:2022 admite ambos. |
| Escala de consecuencia | 1–5 con descripciones concretas (financiera, legal, reputacional, operativa, personas afectadas). |
| Escala de probabilidad | 1–5 con frecuencias concretas (p. ej. 1 = < 1 vez en 10 años … 5 = varias veces al año). |
| Nivel de riesgo | Consecuencia × Probabilidad (1–25) u otra combinación definida. |
| **Criterios de aceptación** | Nivel bajo el cual se acepta sin tratamiento (p. ej. ≤ 6); quién puede aceptar cada nivel. |
| Frecuencia | Al menos anual + ante cambios significativos (§8.2). |
| Roles | Quién facilita, quién es dueño de riesgo, quién aprueba. |

### Escala de ejemplo (ajustar a la organización)

| Nivel | Consecuencia | Probabilidad |
|-------|--------------|--------------|
| 1 | Insignificante: sin impacto en clientes ni datos sensibles | Rara: < 1 vez en 10 años |
| 2 | Menor: impacto interno acotado | Improbable: 1 vez en 3–10 años |
| 3 | Moderada: afecta a clientes o datos internos; recuperable | Posible: 1 vez en 1–3 años |
| 4 | Mayor: filtración de datos personales/confidenciales, incumplimiento legal, caída prolongada | Probable: 1 vez al año |
| 5 | Crítica: daño severo, sanciones, pérdida de clientes clave, riesgo a personas | Casi cierta: varias veces al año |

| Nivel de riesgo | Rango | Tratamiento | Aprueba residual |
|-----------------|-------|-------------|------------------|
| Bajo | 1–6 | Aceptar y monitorear | Dueño del riesgo |
| Medio | 8–12 | Tratar en plazo planificado | Dueño del riesgo + responsable SGSI |
| Alto | 15–25 | Tratamiento prioritario | Alta dirección |

## 2. Identificar

- Parte del **inventario de activos** (control 5.9) y del alcance: información, aplicaciones, infraestructura, servicios cloud, proveedores, personas, instalaciones.
- Fuentes: catálogos de amenazas (27005 Anexo A, MITRE ATT&CK, OWASP), incidentes previos, resultados de pentests y escaneos, auditorías, inteligencia de amenazas (5.7), requisitos legales.
- **Redacción:** "Debido a *[vulnerabilidad/causa]*, *[amenaza/fuente]* podría *[evento]* sobre *[activo]*, afectando su *[C/I/D]*, con *[consecuencia]*."

## 3. Analizar y evaluar

- Valorar consecuencia y probabilidad **considerando los controles existentes** (riesgo actual).
- Comparar con criterios de aceptación y priorizar.

## 4. Tratar

| Opción | Cuándo |
|--------|--------|
| **Modificar (mitigar)** | Aplicar controles para reducir probabilidad y/o consecuencia. |
| **Evitar** | Eliminar la actividad o el activo que genera el riesgo. |
| **Compartir (transferir)** | Seguros, tercerización con contrato (la responsabilidad legal no se transfiere). |
| **Retener (aceptar)** | Decisión informada del dueño dentro de los criterios. |

Luego:
1. Determinar **todos los controles necesarios** (pueden venir de cualquier marco, no solo del Anexo A).
2. **Compararlos con los 93 controles del Anexo A** para no omitir ninguno necesario.
3. Estimar el **riesgo residual** esperado.
4. Plan de tratamiento: acción, responsable, recursos, plazo, riesgo residual objetivo.
5. **Aprobación del plan y aceptación del residual por el dueño del riesgo** (registro fechado).

## 5. Registro de riesgos (formato)

| ID | Activo / proceso | Amenaza | Vulnerabilidad | C/I/D | Dueño | Controles existentes | Cons. | Prob. | Nivel actual | Opción | Controles a implementar (Anexo A) | Responsable | Plazo | Cons. res. | Prob. res. | Nivel residual | Aceptado por / fecha |
|----|------------------|---------|----------------|-------|-------|---------------------|-------|-------|--------------|--------|-----------------------------------|-------------|-------|-----------|-----------|----------------|----------------------|

## 6. Declaración de Aplicabilidad (SoA) — §6.1.3 d

Documento obligatorio y el más revisado por el auditor. Debe contener los **93 controles**:

| Control | Título | ¿Aplicable? (Sí/No) | Justificación de inclusión (riesgo ID, requisito legal/contractual, buena práctica) | Justificación de exclusión | Estado (Implementado / Parcial / Planificado / No implementado) | Referencia a evidencia/documento | Dueño |
|---------|--------|---------------------|-------------------------------------------------------------------------------------|----------------------------|------------------------------------------------------------------|----------------------------------|-------|

**Reglas de calidad de la SoA:**
- Cada inclusión se vincula a al menos un riesgo o requisito.
- Cada exclusión tiene una justificación verificable (p. ej. "7.12 excluido: sin cableado propio; la infraestructura es 100% nube pública (ver alcance §4.3); la seguridad física del proveedor se gestiona vía 5.19–5.23").
- Exclusiones sospechosas que el auditor cuestionará: 5.7, 5.23, 8.9, 8.16, 8.28 en organizaciones que desarrollan o usan nube; 5.34 si se tratan datos personales; 6.7 si hay teletrabajo.
- Controles de otras fuentes (NIST, CIS, sectoriales) pueden añadirse como filas adicionales.
- Versión, fecha y aprobación.

## 7. Operación continua (§8.2, §8.3)

- Repetir la apreciación a intervalos planificados y **ante cambios significativos**: nuevo sistema, migración a la nube, nuevo proveedor crítico, incidente grave, cambio regulatorio, fusión.
- Conservar resultados de cada apreciación y del avance del plan de tratamiento.
- Reportar en la revisión por la dirección (§9.3.2 f).

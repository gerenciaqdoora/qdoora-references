# Certificación, familia ISO/IEC 27000 y marco legal

## Actores

- **Organismo de acreditación** (miembro del IAF; p. ej. INN en Chile, ENAC en España, UKAS, ANAB).
- **Organismo de certificación (OC)**: acreditado bajo **ISO/IEC 17021-1** + **ISO/IEC 27006-1** para SGSI. Verificar en IAF CertSearch.
- **Consultor**: no puede ser el mismo que certifica.

## Ciclo de certificación (3 años)

| Etapa | Qué evalúa el OC | Requisitos previos típicos |
|-------|------------------|----------------------------|
| **Preparación** | — | SGSI operando (típicamente ≥ 3 meses de registros), apreciación y tratamiento de riesgos completos, SoA aprobada, 1 auditoría interna completa, 1 revisión por la dirección. |
| **Etapa 1** | Alcance, SoA, metodología de riesgos, políticas, preparación para etapa 2. | Documentación obligatoria disponible. |
| **Etapa 2** | Implementación y eficacia: entrevistas, inspección técnica, muestreo de controles de la SoA. | Hallazgos de etapa 1 resueltos. |
| **Decisión** | Revisión independiente. | NC mayores cerradas con evidencia; NC menores con plan aceptado. |
| **Seguimiento** (años 1 y 2) | Muestreo; siempre cambios, auditoría interna, revisión por la dirección, NC, incidentes, riesgos. | — |
| **Recertificación** (año 3) | Evaluación completa. | — |

La duración de la auditoría depende del número de personas en el alcance y de la complejidad
(tablas de ISO/IEC 27006-1). El certificado indica alcance y **versión de la SoA**.

**Uso de la marca:** se certifica el sistema de gestión, no un producto; el logo de ISO no puede
usarse. Frase correcta: "SGSI certificado según ISO/IEC 27001:2022 por [OC], alcance: [..]".

## Familia ISO/IEC 27000 (normas útiles)

| Norma | Uso |
|-------|-----|
| 27000:2026 | Visión general y vocabulario. |
| 27001:2022 | Requisitos del SGSI (única certificable de la serie base). |
| 27002:2022 | Guía de implementación de los 93 controles. |
| 27003 | Guía para implementar el SGSI (cláusulas). |
| 27004 | Seguimiento, medición y evaluación (métricas). |
| 27005:2022 | Gestión de riesgos de seguridad de la información. |
| 27006-1 | Requisitos para organismos de certificación de SGSI. |
| 27007 / TS 27008 | Auditoría del SGSI / evaluación de controles. |
| 27017 | Controles para servicios en la nube. |
| 27018 | Protección de datos personales en nubes públicas (encargados). |
| 27035 (partes 1–3) | Gestión de incidentes. |
| 27036 | Seguridad en relaciones con proveedores. |
| 27701:2025 | Sistema de gestión de la privacidad (independiente). |
| ISO 22301 | Continuidad del negocio. |
| ISO/IEC 42001 | Sistema de gestión de IA. |
| ISO 9001 | Calidad (integrable por Estructura Armonizada). |

## Otros marcos que suelen mapearse

NIST Cybersecurity Framework 2.0 · CIS Controls v8 · SOC 2 (AICPA) · PCI DSS 4.0 · NIS2 y DORA
(UE) · ENS (España). Los atributos de 27002 facilitan el mapeo; ISO no reconoce equivalencias
automáticas: cada marco se audita por separado.

## Marco legal (requisitos para 5.31 y 5.34)

Identifica siempre la legislación del país y del sector de la organización. Ejemplos a verificar
con asesoría legal (no son asesoría jurídica):
- **Chile:** Ley 21.663 Marco de Ciberseguridad (ANCI, deberes de reporte de incidentes para servicios esenciales y operadores de importancia vital) y Ley 21.719 de protección de datos personales (nueva agencia y régimen de sanciones; verificar fecha de entrada en vigencia).
- **Unión Europea:** RGPD, NIS2, DORA (sector financiero).
- **España:** LOPDGDD, ENS.
- **Otros:** LGPD (Brasil), leyes sectoriales (banca, salud, telecomunicaciones).

ISO 27001 no garantiza cumplimiento legal: exige **identificar y cumplir** los requisitos aplicables.

# Plantillas del SGSI

Adáptalas. Todas llevan **encabezado de control documental con clasificación**:

```
Código: [XX-YYY-NN]   Versión: [N]   Fecha: [AAAA-MM-DD]   Clasificación: [Pública / Uso interno / Confidencial]
Elaborado por: [cargo]   Revisado por: [cargo]   Aprobado por: [cargo]
Historial: | Versión | Fecha | Cambio | Aprobó |
```

No completes nombres, firmas, fechas, IP, credenciales ni resultados con valores inventados: usa `[…]`.

---

## 1. Política de seguridad de la información (§5.2, control 5.1)

```markdown
# Política de Seguridad de la Información — [Organización]

## Propósito
Proteger la confidencialidad, integridad y disponibilidad de la información de [Organización],
de sus clientes y de sus partes interesadas, en coherencia con [propósito/estrategia].

## Alcance
[Referencia al alcance del SGSI, código ..].

## Compromisos
La dirección de [Organización] se compromete a:
1. Establecer objetivos de seguridad de la información y hacer seguimiento de su cumplimiento.
2. Gestionar los riesgos de seguridad de la información según la metodología [código].
3. Cumplir los requisitos legales, reglamentarios y contractuales aplicables.
4. Proveer los recursos, la formación y la concienciación necesarios.
5. Gestionar los incidentes de seguridad y aprender de ellos.
6. Mejorar continuamente el SGSI.

## Políticas temáticas
[Control de acceso, uso aceptable, clasificación, criptografía, respaldo, desarrollo seguro,
proveedores, nube, teletrabajo, gestión de incidentes, …] — ver lista maestra.

## Roles
[Responsable del SGSI, comité de seguridad, dueños de activos y de riesgos].

## Cumplimiento
El incumplimiento se tratará según el proceso disciplinario (control 6.4).

## Revisión
Al menos anualmente o ante cambios significativos.

[Cargo de la alta dirección] — [Fecha]
```

## 2. Documento de alcance (§4.3)

| Campo | Contenido |
|-------|-----------|
| Procesos / servicios incluidos | |
| Ubicaciones (sedes, regiones cloud) | |
| Sistemas y plataformas | |
| Unidades organizacionales / personas | |
| **Interfaces y dependencias** (proveedores, nube, casa matriz, clientes) | |
| Exclusiones y justificación | |
| Requisitos de partes interesadas considerados (§4.2) | |
| Cuestiones de contexto consideradas (§4.1, incluido cambio climático) | |

## 3. Objetivos de seguridad (§6.2)

| Objetivo | Indicador (fórmula) | Línea base | Meta | Frecuencia | Responsable | Recursos | Estado |
|----------|--------------------|-----------|------|-----------|-------------|----------|--------|
| Reducir exposición a vulnerabilidades críticas | % críticas remediadas en ≤ 15 días | [..] | ≥ 95% | Mensual | [cargo] | [..] | [..] |

## 4. Registro de riesgos y SoA
Ver formatos en `gestion-riesgos-soa.md` (§5 y §6).

## 5. Inventario de activos (control 5.9)

| ID | Activo | Tipo (información, software, hardware, servicio, persona) | Descripción | Ubicación | Dueño | Clasificación | C | I | D | Proveedor | Estado |
|----|--------|------|-----|-----|-----|-----|---|---|---|-----|-----|

## 6. Registro de incidente (5.24–5.28)
Campos en `no-conformidades-incidentes.md`.

## 7. Registro de NC y acción correctiva (§10.2)

| Campo | Contenido |
|-------|-----------|
| N.º / fecha / origen | |
| Cláusula o control | |
| Descripción (requisito + evidencia + declaración) | |
| Clasificación | Mayor / Menor |
| Contención y corrección | |
| ¿Requiere acción correctiva? (justificar) | |
| Causa raíz (método y resultado) | |
| ¿NC similares? | |
| Acciones (qué, responsable, fecha) | |
| Criterio de eficacia y fecha de verificación | |
| Resultado de eficacia | |
| Actualización de riesgos / SoA / políticas | |
| Cierre | |

## 8. Acta de revisión por la dirección (§9.3)

```markdown
# Revisión por la Dirección del SGSI — [período]
Fecha: [..]  Participantes: [cargos]  Clasificación: Confidencial

## Entradas (§9.3.2)
a) Estado de acciones de revisiones anteriores:
b) Cambios en cuestiones externas e internas (incl. amenazas, regulación, cambio climático):
c) Cambios en necesidades y expectativas de partes interesadas:
d) Desempeño de la seguridad de la información:
   1. No conformidades y acciones correctivas:
   2. Resultados de seguimiento y medición (métricas):
   3. Resultados de auditorías:
   4. Cumplimiento de objetivos de seguridad:
e) Retroalimentación de partes interesadas:
f) Resultados de la apreciación de riesgos y estado del plan de tratamiento:
g) Oportunidades de mejora:
(Recomendado) Incidentes relevantes del período y lecciones aprendidas; estado de proveedores críticos.

## Conclusión sobre la conveniencia, adecuación y eficacia del SGSI

## Salidas (§9.3.3) — decisiones
| Decisión / acción | Tipo (mejora / cambio SGSI / recursos / aceptación de riesgo) | Responsable | Fecha |
```

## 9. Programa anual de auditoría interna (§9.2)

| Proceso / grupo de controles | Cláusulas / controles | Criticidad / resultados previos | T1 | T2 | T3 | T4 | Auditor (independiente) | Estado |
|------------------------------|----------------------|--------------------------------|----|----|----|----|-------------------------|--------|

## 10. Informe de auditoría interna

```markdown
# Informe de Auditoría Interna del SGSI N.º [..]    Clasificación: Confidencial
Objetivo: | Alcance: | Criterios: ISO/IEC 27001:2022 + SoA v[..] + [políticas]
Fecha(s): | Auditor líder / equipo: | Auditados (cargos):

## Resumen y conclusión
## Fortalezas
## Hallazgos
| N.º | Tipo | Cláusula / control | Requisito | Evidencia (referencia, sin datos sensibles) | Declaración |
## Limitaciones (muestreo, sistemas no revisados)
## Distribución y plazo de respuesta
```

## 11. Evaluación de proveedores (5.19–5.22)

| Proveedor | Servicio | Datos a los que accede (clasificación) | Criticidad | Certificaciones (27001, SOC 2) | Cláusulas contractuales (NDA, DPA, auditoría, notificación de incidentes) | Riesgos | Resultado | Próxima revisión |
|-----------|----------|------|-----|-----|-----|-----|-----|-----|

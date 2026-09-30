# ISO 9001 aplicada a desarrollo de software y servicios TI

Guía complementaria: **ISO/IEC 90003** (aplicación de ISO 9001 al software). Úsala cuando el
alcance incluya desarrollo, mantenimiento u operación de software, o cuando te pidan evaluar un
repositorio o flujo de ingeniería.

## Principio

Las prácticas de ingeniería modernas (Git, pull requests, CI/CD, tickets, pruebas automatizadas)
**ya generan la mayor parte de la evidencia** que exige la norma. El trabajo es mapearla y
cerrar los huecos, no crear formularios paralelos.

## Mapeo cláusula → práctica → evidencia

| Cláusula | Práctica de ingeniería | Evidencia típica (dónde buscar) |
|----------|------------------------|---------------------------------|
| 4.4 | Flujo de trabajo definido (discovery → desarrollo → QA → release → soporte) | README/CONTRIBUTING, diagrama del flujo, definición de "Listo" (DoD) |
| 6.1 | Registro de riesgos técnicos y de proyecto; análisis de amenazas | Issues etiquetados "riesgo", ADRs con consecuencias, threat model |
| 6.2 | Objetivos medibles de calidad | Métricas DORA (frecuencia de despliegue, lead time, tasa de fallos de cambio, tiempo de restauración), SLO/SLA, densidad de defectos, cobertura |
| 6.3 / 8.5.6 | Control de cambios | Pull requests con revisión obligatoria, ramas protegidas, historial de despliegues, changelog |
| 7.1.3 | Infraestructura | Infraestructura como código (docker-compose, Terraform), entornos definidos |
| 7.1.5 | Recursos de seguimiento y medición | Suites de pruebas, herramientas de monitoreo, analizadores estáticos: validados y versionados (la "calibración" del software es la validación de la herramienta y de sus pruebas) |
| 7.1.6 | Conocimientos de la organización | Documentación técnica, ADRs, runbooks, post-mortems, wiki |
| 7.2 | Competencia | Onboarding técnico, revisión por pares como formación, certificaciones |
| 7.5 | Información documentada controlada | Documentos en el repositorio (versionado Git = control de cambios, autor, fecha, aprobación vía PR) |
| 8.2 | Requisitos del cliente | Historias de usuario con criterios de aceptación, acuerdos firmados, backlog priorizado, registro de cambios de alcance |
| 8.3.2 | Planificación del diseño | Roadmap, sprints/iteraciones, definición de etapas y revisiones |
| 8.3.3 | Entradas del diseño | Especificaciones, requisitos no funcionales (rendimiento, seguridad, accesibilidad), normativa aplicable |
| 8.3.4 | Revisión / verificación / validación | **Revisión:** code review, design review. **Verificación:** pruebas unitarias/integración en CI. **Validación:** UAT, demos al cliente, pruebas E2E en staging |
| 8.3.5 | Salidas del diseño | Código, artefactos de build, documentación de API (OpenAPI), manual de usuario |
| 8.3.6 | Cambios del diseño | PRs vinculados a tickets, migraciones reversibles, versionado semántico |
| 8.4 | Proveedores externos | Evaluación de proveedores cloud/SaaS/APIs de terceros (SLA, incidentes), dependencias open source (licencias, vulnerabilidades, SBOM), contratistas |
| 8.5.1 | Condiciones controladas | Pipelines reproducibles, entornos consistentes, *linters*, prevención del error humano mediante automatización |
| 8.5.2 | Identificación y trazabilidad | Versión etiquetada (tag), commit ↔ ticket ↔ requisito ↔ prueba ↔ release |
| 8.5.3 | Propiedad del cliente | Datos del cliente y datos personales (protección, respaldo, acceso), código o credenciales entregados por el cliente |
| 8.5.5 | Posterior a la entrega | Soporte, mesa de ayuda, corrección de incidentes, mantenimiento |
| 8.6 | Liberación | *Quality gates* del pipeline, aprobación de release, checklist de despliegue; registro de quién aprobó |
| 8.7 | Salidas no conformes | Gestión de bugs en producción, rollback, feature flags para contener, comunicación al cliente |
| 9.1 | Seguimiento y medición | Dashboards, monitoreo, métricas de calidad, satisfacción (NPS, CSAT, tickets de soporte) |
| 9.2 | Auditoría interna | Auditoría de proceso (no solo de código): ¿se sigue el flujo definido? |
| 10.2 | Acción correctiva | **Post-mortems sin culpables** con causa raíz, acciones y seguimiento de eficacia |

## Checklist rápido para auditar un repositorio

- [ ] ¿Rama principal protegida? ¿Se exige revisión antes de fusionar? (8.3.4, 8.5.6)
- [ ] ¿CI ejecuta pruebas en cada cambio y bloquea si fallan? (8.3.4, 8.6)
- [ ] ¿Cada cambio se vincula a un requisito/ticket? (8.5.2)
- [ ] ¿Las versiones se etiquetan y tienen changelog? (8.5.2, 8.3.6)
- [ ] ¿Los requisitos tienen criterios de aceptación verificables? (8.2, 8.3.5)
- [ ] ¿Hay validación con el usuario/cliente antes de liberar? (8.3.4)
- [ ] ¿Las migraciones de datos son reversibles y probadas? (8.5.6)
- [ ] ¿Los incidentes de producción generan post-mortem con acciones y verificación? (8.7, 10.2)
- [ ] ¿Se gestionan dependencias y proveedores (vulnerabilidades, licencias, SLA)? (8.4)
- [ ] ¿Hay documentación técnica viva (README, ADRs, runbooks)? (7.1.6, 7.5)
- [ ] ¿Se protegen datos de clientes y secretos (no en el repositorio)? (8.5.3)
- [ ] ¿Existen objetivos medibles (DORA, SLO) con seguimiento? (6.2, 9.1)
- [ ] ¿Quién y cómo aprueba el paso a producción queda registrado? (8.6)

## Metodologías ágiles

ISO 9001 es compatible con Scrum/Kanban: la planificación iterativa satisface §8.3.2 si define
revisiones, verificación y validación. Retrospectivas = mejora (§10). Sprint review = validación
con partes interesadas. El riesgo típico en ágil es **falta de registro** de decisiones de
requisitos y de aprobación de releases: verifica que exista.

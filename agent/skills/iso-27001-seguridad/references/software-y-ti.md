# ISO/IEC 27001 aplicada a desarrollo de software, TI y nube

Úsalo cuando el alcance incluya desarrollo, operación de plataformas o servicios en la nube, o
cuando pidan evaluar un repositorio o pipeline. Para hallazgos técnicos profundos (código
vulnerable, pentest), delega en una habilidad de seguridad ofensiva si existe y usa sus
resultados como evidencia de 8.8, 8.28 y 8.29.

## Principio

Git, pull requests, CI/CD, IaC, IdP y la consola cloud **ya generan evidencia** de muchos
controles. El trabajo es mapearla, cerrar huecos y mostrarla, no duplicarla.

## Mapeo control → práctica → evidencia

| Control | Práctica | Evidencia (dónde buscar) |
|---------|----------|--------------------------|
| 5.8 | Seguridad en proyectos | Definición de "Listo" con criterios de seguridad, threat model en épicas |
| 5.9 / 5.12 | Inventario y clasificación | Catálogo de servicios, etiquetas en recursos cloud, clasificación de datos por tabla/bucket |
| 5.15 – 5.18 / 8.2 / 8.5 | Identidad y acceso | SSO + MFA en Git, cloud y producción; roles mínimos; revisión trimestral de accesos; sin cuentas compartidas |
| 5.17 | Secretos | Gestor de secretos (vault/KMS); **cero secretos en el repositorio**; escaneo de secretos en CI; rotación |
| 5.19 – 5.22 / 8.30 | Proveedores y desarrollo externo | Evaluación de SaaS/APIs de terceros, contratos con requisitos de seguridad, acceso limitado de contratistas |
| 5.21 | Cadena de suministro de software | Dependencias fijadas (lockfiles), SCA (análisis de composición), **SBOM**, verificación de origen/firmas de imágenes |
| 5.23 | Nube | Matriz de responsabilidad compartida, CSPM, guía de configuración segura, estrategia de salida |
| 5.24 – 5.28 | Incidentes | Runbook de respuesta, on-call, post-mortems, preservación de logs |
| 5.30 / 8.13 / 8.14 | Continuidad | Respaldos automáticos, **restauraciones probadas**, multi-zona, RTO/RPO definidos y medidos |
| 5.34 / 8.11 / 8.33 | Datos personales y de prueba | Minimización, cifrado, datos sintéticos/enmascarados fuera de producción |
| 5.37 | Procedimientos | Runbooks, README de operación |
| 8.4 | Acceso al código | Permisos por equipo, ramas protegidas, CODEOWNERS |
| 8.8 | Vulnerabilidades | Escaneo de dependencias e imágenes, SLA de parchado por severidad, pentest periódico |
| 8.9 | Configuración | **IaC** (docker-compose, Terraform, Helm) revisada por PR, líneas base, detección de desviaciones |
| 8.15 / 8.16 / 8.17 | Logs y monitoreo | Logs centralizados sin datos sensibles, retención, alertas, NTP, auditoría de acciones administrativas |
| 8.20 – 8.22 | Redes | Segmentación (VPC/subredes), puertos mínimos expuestos, WAF, TLS |
| 8.24 | Criptografía | TLS 1.2+ en tránsito, cifrado en reposo, gestión de claves, hash de contraseñas con algoritmos adecuados (argon2/bcrypt) |
| 8.25 / 8.27 | SDLC seguro y arquitectura | SDLC documentado, revisiones de diseño, ADRs con consideraciones de seguridad |
| 8.26 | Requisitos de seguridad | Requisitos de autenticación, autorización, validación, registro en historias de usuario |
| 8.28 | Codificación segura | Guía de codificación (OWASP), linters de seguridad, **SAST** en CI, revisión de código obligatoria |
| 8.29 | Pruebas de seguridad | **DAST**, pruebas de autorización, pentest antes de salidas mayores |
| 8.31 | Entornos | Dev/test/prod separados (cuentas/proyectos), sin acceso de desarrolladores a producción por defecto |
| 8.32 | Gestión de cambios | PR aprobado + CI verde + registro de despliegue + capacidad de rollback |

## Checklist rápido para auditar un repositorio / plataforma

- [ ] ¿Hay secretos, llaves o `.env` versionados? (5.17) — revisar historial, no solo el HEAD.
- [ ] ¿La rama principal está protegida con revisión obligatoria? (8.4, 8.32)
- [ ] ¿CI ejecuta SAST, SCA y escaneo de secretos, y bloquea ante hallazgos críticos? (8.8, 8.28)
- [ ] ¿Dependencias fijadas y con proceso de actualización? ¿Existe SBOM? (5.21, 8.8)
- [ ] ¿Infraestructura definida como código y revisada? (8.9)
- [ ] ¿MFA/SSO en Git, nube y herramientas de producción? (8.5)
- [ ] ¿Separación de entornos y datos de prueba sin datos reales? (8.31, 8.33)
- [ ] ¿Logs de seguridad centralizados, sin datos sensibles, con alertas? (8.15, 8.16)
- [ ] ¿Cifrado en tránsito y en reposo; gestión de claves? (8.24)
- [ ] ¿Respaldos con prueba de restauración reciente? (8.13)
- [ ] ¿Migraciones de base de datos reversibles y probadas? (8.32)
- [ ] ¿Modelo de autorización probado (roles, multi-tenant, IDOR)? (8.3, 8.26, 8.29)
- [ ] ¿Dependencias de terceros (APIs, SaaS, LLM) evaluadas y con datos minimizados? (5.19, 5.23, 5.34)
- [ ] ¿Proceso de respuesta a incidentes conocido por el equipo? (5.24, 6.8)

## Ágil y DevSecOps

ISO 27001 es compatible con ágil: la seguridad se integra en la definición de "Listo", en los
pipelines ("shift-left") y en las retrospectivas. El riesgo típico es **falta de registro**:
decisiones de aceptación de riesgo tomadas en conversaciones sin dueño ni fecha. Exige que
queden registradas (ticket, ADR o registro de riesgos).

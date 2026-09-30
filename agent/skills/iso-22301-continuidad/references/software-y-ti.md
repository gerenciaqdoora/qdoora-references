# ISO 22301 aplicada a software, TI y nube

Guías: **ISO/IEC 27031** (preparación TIC para la continuidad), NIST SP 800-34. Úsalo cuando se
evalúe si una plataforma, repositorio o arquitectura puede cumplir los RTO/RPO del negocio.

## Principio

Los RTO/RPO **los fija el negocio (BIA)**; la arquitectura debe demostrar que los cumple.
"Estamos en la nube" no es una estrategia de continuidad: las regiones, los proveedores SaaS y
las configuraciones propias también fallan.

## Mapeo requisito → práctica → evidencia

| Cláusula | Práctica | Evidencia |
|----------|----------|-----------|
| 8.2.2 | Tabla de servicios con RTO/RPO/MBCO derivados del BIA | Catálogo de servicios con criticidad; SLO documentados |
| 8.2.2 h | Mapa de dependencias (internas y externas: nube, SaaS, APIs, DNS, IdP, pasarelas de pago, proveedores de IA) | Diagrama de arquitectura, inventario de dependencias externas con su SLA |
| 8.2.3 | Análisis de puntos únicos de falla y modos de falla | FMEA de arquitectura, registro de riesgos técnicos |
| 8.3 | Patrón de recuperación por servicio (ver tabla) | ADRs de resiliencia, costos estimados |
| 8.3.4 (información) | Respaldos automáticos, cifrados, **inmutables o fuera de línea**, en otra cuenta/región | Política de respaldo, configuración, **registros de restauración** |
| 8.3.4 (TIC) | Infraestructura como código para reconstruir el entorno | Repositorio IaC; tiempo medido de reconstrucción |
| 8.4 | Runbooks de DR y de incidentes; página de estado; guardias (on-call) | Runbooks versionados, roster de guardia, plantillas de comunicación |
| 8.4.4 | Runbooks accesibles sin el sistema caído | Copia fuera de la plataforma afectada (otro proveedor, impresa) |
| 8.4.5 | Procedimiento de retorno (failback) y reconciliación de datos | Runbook de failback, pruebas |
| 8.5 | Pruebas de DR, *game days*, ingeniería del caos, restauraciones programadas | Informes de prueba con **tiempos reales vs RTO/RPO** |
| 8.6 | Revisión de proveedores cloud/SaaS: su continuidad, SLA, historial de incidentes, certificaciones | Evaluaciones, informes SOC 2 / certificados 22301 o 27001 del proveedor |
| 9.1 | Métricas: disponibilidad vs SLO, MTTR, tiempo real de restauración, % de pruebas exitosas | Tableros, informes |
| 10.1 | Post-mortems sin culpables con acciones | Repositorio de post-mortems |

## Patrones de recuperación (de menor a mayor costo)

| Patrón | RTO típico | RPO típico | Descripción |
|--------|-----------|-----------|-------------|
| Respaldo y restauración | Horas–días | Horas (frecuencia del respaldo) | Reconstruir desde IaC + restaurar datos. |
| *Pilot light* | Decenas de minutos–horas | Minutos | Datos replicados; cómputo mínimo apagado que se escala al activar. |
| *Warm standby* | Minutos | Segundos–minutos | Copia reducida funcionando en otra región/sitio. |
| Activo-activo multi-región/sitio | ~0 | ~0 | Tráfico en ambos sitios; mayor complejidad (consistencia de datos). |

Los tiempos son orientativos: **solo cuenta el tiempo medido en una prueba**.

## Checklist rápido para una plataforma / repositorio

- [ ] ¿Hay RTO/RPO por servicio, y vienen del BIA?
- [ ] ¿La plataforma depende de **un solo host, región, cuenta o proveedor**? (p. ej., todo en un único `docker-compose` en un servidor) — punto único de falla documentado y aceptado o tratado.
- [ ] ¿Respaldos automáticos de **todas** las bases de datos y volúmenes con estado? ¿Cifrados, fuera del host y protegidos contra borrado/ransomware?
- [ ] ¿Restauración probada en los últimos 12 meses con tiempo medido?
- [ ] ¿El entorno se puede reconstruir desde el repositorio (IaC, imágenes versionadas, migraciones reproducibles)?
- [ ] ¿Secretos y configuración recuperables sin el entorno caído (gestor de secretos con respaldo)?
- [ ] ¿Dependencias externas críticas (IdP, APIs de terceros, LLM, correo, pagos) con modo degradado, *timeouts*, reintentos y alternativa?
- [ ] ¿Runbook de DR y de incidentes disponible fuera de la plataforma?
- [ ] ¿Monitoreo y alertas que detecten la caída antes que el cliente? ¿Página de estado externa?
- [ ] ¿Guardia definida con suplentes? ¿Conocimiento concentrado en una sola persona?
- [ ] ¿Migraciones de base de datos reversibles para poder volver atrás?
- [ ] ¿Post-mortems con acciones cerradas?

## DevOps / SRE y la norma

Prácticas SRE (SLO, presupuestos de error, post-mortems, *game days*, ingeniería del caos) son
evidencia válida de §8.5, §8.6, §9.1 y §10 si se **registran formalmente** (objetivos, resultados
vs RTO/RPO, acciones) y se vinculan al BIA.

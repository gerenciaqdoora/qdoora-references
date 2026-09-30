# Selección de marcos

## Regla general

| Marco | Entra si... | Queda fuera si... |
|---|---|---|
| `auditoria-appsec` | Hay código, configuración, IaC o CI en el alcance | Solo hay documentos de gestión |
| `iso-27001-seguridad` | El sistema trata información de clientes o personas, o el proyecto tiene/prepara un SGSI | Prototipo personal sin datos de terceros (y el usuario lo confirma) |
| `ley-21719-datos-personales` | Se tratan datos personales **y** la ley chilena aplica (responsable en Chile, o datos de personas en Chile por oferta de bienes/servicios o monitoreo de comportamiento) | No hay datos personales, o la jurisdicción es otra (decirlo: otra ley puede aplicar y queda fuera de esta revisión) |
| `iso-22301-continuidad` | El alcance toca infraestructura, respaldo, despliegue, migraciones, datos persistentes o dependencias externas críticas | El cambio es solo de UI o de lógica sin estado ni dependencias nuevas |
| `iso-9001-calidad` | El proyecto declara un SGC o el usuario lo pide | En cualquier otro caso (mencionarlo en una línea) |

En un alcance de **sistema**, normalmente entran todos los que apliquen al proyecto. En un **diff**,
solo los que el cambio activa.

## Señales en un diff

| Si el cambio... | Marcos que activa | Qué mirar primero |
|---|---|---|
| Agrega o modifica rutas, controladores, guards, middlewares | appsec, 27001 | Autenticación, autorización por recurso (BOLA/IDOR), validación, DTO de salida |
| Toca login, sesiones, tokens, cookies, API keys | appsec, 27001 | Sesión, rotación, revocación, fuerza bruta, CSRF |
| Agrega columnas o tablas con datos de personas (nombre, correo, RUT, teléfono, ubicación, salud) | 21.719, 27001, appsec | Finalidad, minimización, plazo de conservación, supresión, acceso por recurso, cifrado |
| Agrega logs, trazas o envío de errores a un tercero | 21.719, 27001 | Datos personales o secretos en logs; retención; encargado nuevo |
| Integra un servicio externo (correo, almacenamiento, IdP, API de IA, analítica, APM) | 21.719, 27001, 22301, appsec | Qué datos salen y a qué país; contrato de encargo; timeouts y modo degradado; SSRF; secretos |
| Envía datos a un modelo de lenguaje | 21.719, appsec, 27001 | Minimización y seudonimización; transferencia internacional; inyección de prompt; decisiones automatizadas sobre personas |
| Cambia docker-compose, Dockerfile, IaC, puertos, redes | appsec, 27001, 22301 | Exposición, contenedores sin root, secretos, puntos únicos de falla, reconstrucción desde el repositorio |
| Cambia migraciones, respaldos, scripts de despliegue o rollback | 22301, 27001, 9001 (si aplica) | Reversibilidad, respaldo previo, pérdida de datos, prueba de restauración |
| Cambia CI, protección de ramas, dependencias | 27001, appsec, 9001 (si aplica) | SAST/SCA/secretos en CI, lockfiles, revisión obligatoria |
| Borra o anonimiza datos | 21.719, 22301 | Supresión efectiva (también en respaldos según su ciclo), trazabilidad, irreversibilidad accidental |
| Agrega exportaciones o descargas de datos | 21.719, appsec | Autorización, portabilidad, `Content-Disposition`, límite de uso |
| Solo cambia estilos o textos de UI | appsec (mínimo: XSS, datos expuestos) | Normalmente nada más; decirlo |

## Preguntas de jurisdicción y alcance (si el perfil no responde)

1. ¿Hay datos de personas en Chile o el responsable está en Chile?
2. ¿Hay datos sensibles (salud, biométricos, origen, vida sexual, situación socioeconómica) o de
   menores de edad?
3. ¿Existe un SGSI, SGCN o SGC, o se prepara una certificación?
4. ¿Qué servicios externos reciben datos y desde qué país operan?

Supuestos por defecto si el usuario pide avanzar: datos personales de trabajadores o clientes en
Chile, sin datos sensibles, sin sistema de gestión formal. Se declaran en el informe.

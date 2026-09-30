---
name: auditoria-appsec
description: >
  Auditor de seguridad de aplicaciones (AppSec) para cualquier stack web/API, basado en OWASP
  ASVS 5, OWASP WSTG, OWASP API Security Top 10 y CWE, con severidad CVSS v4.0. Revisa código,
  diffs, endpoints, configuración e infraestructura como código en busca de fallos de autenticación,
  sesión, autorización (BOLA/IDOR, BFLA), inyección, XSS, SSRF, exposición de datos, secretos,
  cabeceras y límites de uso, y entrega hallazgos con evidencia y remediación en el stack del
  proyecto.
  Usar AUTOMÁTICAMENTE cuando el usuario pida: auditar seguridad, revisar vulnerabilidades, revisar
  un endpoint o un diff "desde seguridad", evaluar autenticación, sesiones, cookies, JWT, roles o
  permisos, buscar inyecciones o XSS, revisar CORS/CSP/cabeceras, o preparar un pentest. Para el
  marco de gestión (SGSI, SoA, riesgos) usar `iso-27001-seguridad`, que puede tomar estos hallazgos
  como evidencia.
license: MIT
metadata:
  author: francoalvaradot
  version: '2.0'
---

# Auditoría de seguridad de aplicaciones

Revisas como atacante y explicas como ingeniero: cada hallazgo lleva evidencia, impacto real y un
arreglo en el stack del proyecto.

## Perfil del proyecto

Lee `CLAUDE.md` / `AGENTS.md` y los archivos de reglas para conocer: stack, modelo de autenticación
(cookie de sesión, JWT, API key), roles, qué datos son sensibles, dónde está la frontera de
confianza y qué controles globales existen (guards, pipes, filtros, interceptores). **No reportes
como ausente un control que ya existe de forma global:** verifícalo en el código antes de afirmar.

Si el proyecto tiene un catálogo propio de vectores conocidos (por ejemplo, en sus referencias de
seguridad), úsalo además de esta lista.

## Alcance y ética

- **Revisión estática** (código, configuración, diff): siempre permitida.
- **Pruebas activas** (`curl` contra un entorno, fuzzing, fuerza bruta): solo con autorización
  explícita y sobre entornos acordados. Nunca contra producción sin un compromiso formal. Deja el
  alcance escrito en el informe.

## Lista de revisión

Para cada punto: ¿aplica?, ¿dónde está el control?, ¿funciona?

1. **Autenticación:** fuerza bruta y enumeración (mismo mensaje y tiempo para usuario inexistente),
   límite de intentos, MFA o delegación a un IdP, re-autenticación para cambios sensibles, flujo
   OAuth/OIDC con `state`, `nonce` y PKCE, validación de `redirect_uri`.
2. **Sesión:** cookie `HttpOnly`, `Secure`, `SameSite` adecuado, `Path` y dominio mínimos; token
   de sesión aleatorio y guardado como hash; expiración por inactividad y absoluta; rotación al
   iniciar sesión; invalidación real al cerrar sesión; protección CSRF si hay cookies y
   `SameSite=None`. Con JWT: algoritmo fijo, expiración corta, revocación, nunca en `localStorage`
   si hay alternativa.
3. **Autorización (lo más importante):**
   - **Cerrado por defecto:** guard global y rutas públicas marcadas explícitamente.
   - **BFLA:** cada endpoint administrativo exige rol en el servidor.
   - **BOLA/IDOR:** toda consulta por id filtra por dueño, equipo o tenant; nunca confiar en un id
     que venga del cliente sin verificar pertenencia.
   - **Mass assignment:** la lista blanca del DTO impide campos como `rol`, `dueño` o `estado`.
   - Las credenciales máquina a máquina (API key) tienen alcance mínimo y no heredan poderes de persona.
   - El frontend nunca es la frontera: ocultar un botón no es control de acceso.
4. **Entradas:** validación con lista blanca en el borde; consultas parametrizadas (sin concatenar
   SQL, incluso en `QueryBuilder` u ORM crudo); rutas de archivos normalizadas; límites de tamaño.
5. **Salida y lado del cliente:** sin `innerHTML` / `bypassSecurityTrust*` con datos del servidor;
   CSP; archivos subidos servidos con `Content-Disposition: attachment` y tipo verificado.
6. **SSRF e integraciones:** URLs salientes con lista permitida; sin seguir redirecciones a redes
   internas; webhooks con firma verificada; timeouts.
7. **Exposición de datos:** DTOs de respuesta explícitos (nunca la entidad completa); sin datos de
   otras personas; `Cache-Control: no-store` en respuestas con datos personales; logs sin secretos
   ni datos personales en claro.
8. **Errores:** respuesta saneada y uniforme; stack traces solo en logs internos; identificador de
   petición para correlacionar.
9. **Secretos y configuración:** nada en el repositorio ni en imágenes; `.env` validado al arrancar;
   CORS con orígenes explícitos (nunca `*` con credenciales); cabeceras (`HSTS`,
   `X-Content-Type-Options`, `Referrer-Policy`, `frame-ancestors`); modo debug apagado.
10. **Abuso y disponibilidad:** límites de uso por ruta costosa (login, correo, exportaciones,
    llamadas a LLM); paginación con máximo; tamaño de cuerpo limitado.
11. **LLM (si aplica):** inyección de prompt desde datos del usuario o de terceros; herramientas del
    modelo con permisos mínimos; la salida del modelo se trata como entrada no confiable.
12. **Dependencias e infraestructura:** auditoría de dependencias, imágenes base actualizadas,
    contenedores sin root, puertos mínimos, base de datos no expuesta.

## Flujo

1. Delimitar el alcance (diff, módulo, endpoint, sistema) y leer el perfil.
2. Mapear la superficie: rutas, cuáles son públicas, qué credencial acepta cada una, qué datos devuelve.
3. Recorrer la lista con evidencia del código (archivo:línea). **Sin evidencia no hay hallazgo**;
   lo dudoso va como "a verificar".
4. Clasificar con CVSS v4.0 (o Crítico/Alto/Medio/Bajo/Informativo si no hay datos para el vector)
   y mapear a CWE y a ASVS.
5. Proponer la remediación en el stack del proyecto (ver `references/remediacion-por-stack.md`),
   con un test que demuestre el arreglo.
6. Entregar el informe con `references/plantilla-informe.md`.

## Principios

- **Impacto de negocio primero:** "cualquier persona autenticada puede leer las notas de otra", no
  "falta verificación de ownership".
- **Pocos hallazgos verdaderos valen más que muchos dudosos.**
- **Defensa en profundidad:** el servidor decide; el cliente solo mejora la experiencia.

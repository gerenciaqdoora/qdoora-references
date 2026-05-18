# Guía Universal de Blindaje de Backend (Backend Hardening)

> Directrices y patrones de arquitectura seguros para mitigar vulnerabilidades críticas en el backend.
> Aplicable a arquitecturas REST, GraphQL y MVC bajo cualquier stack (Node.js, Python, PHP, Java, Go, C#).

---

## 1. Interceptación y Control Seguro de Errores (Safe Exception Handling)
**Vectores Asociados**: QD-10 (Debug Information Leak).

**Regla de Oro**: Ningún detalle interno de ejecución (stack traces, paths de archivos, queries SQL o variables de entorno) debe ser devuelto en las respuestas HTTP en entornos de producción.

### Patrón de Remediación (Pseudo-código / Estructura):
1. **Middleware de Captura Global**: Implementar un manejador de excepciones global en el arranque de la aplicación.
2. **Filtrado por Entorno**:
   * Si `environment == development`: Permitir el renderizado detallado.
   * Si `environment == production`: Purgar la traza, loguear el error internamente con un ID de tracking, y retornar un mensaje genérico.

```javascript
// Ejemplo conceptual en Node.js/Express
app.use((err, req, res, next) => {
    const errorId = generateUniqueId();
    logger.error(`Error ID: ${errorId} | Stack: ${err.stack}`); // Registro seguro en el servidor

    if (process.env.APP_ENV === 'production') {
        return res.status(err.status || 500).json({
            message: 'Ha ocurrido un error interno en el servidor. Por favor contacte soporte.',
            tracking_id: errorId
        });
    }
    next(err); // En dev expone detalles
});
```

---

## 2. Enforzamiento Estricto de Autorización Server-Side
**Vectores Asociados**: QD-01 (Auth Bypass), QD-04 (BFLA).

**Regla de Oro**: El servidor NUNCA debe confiar en los datos de privilegios, roles o menús enviados desde el cliente. Toda operación HTTP debe re-validar la autorización antes de modificar o exponer datos.

### Patrón de Remediación:
1. **Middlewares Basados en Permisos**: Crear interceptores en las rutas que verifiquen el Bearer Token (JWT o sesión) y auditen de forma activa si el usuario posee los permisos mínimos necesarios en la base de datos.
2. **Validación Atómica en el Controlador**: No delegues la seguridad únicamente a las declaraciones de rutas del router; re-valida las relaciones a nivel de negocio.

```python
# Ejemplo conceptual en Python (Django/FastAPI)
def delete_user(request, user_id):
    # 1. ¿Está autenticado?
    if not request.user.is_authenticated:
        raise UnauthorizedException()
    
    # 2. ¿Posee el permiso para esta operación (BFLA)?
    if not request.user.has_permission('users:delete'):
        raise ForbiddenException("No posees los privilegios requeridos.")
        
    # 3. Proceder de forma segura...
```

---

## 3. Rate Limiting Multi-Capa (Control de Frecuencia)
**Vectores Asociados**: QD-03 (Brute Force), QD-08 (Rate Limiting).

**Regla de Oro**: Rutas críticas que realicen procesamiento costoso (ej. PDFs, emails, DTEs, login, reset de contraseñas) deben poseer cuotas estrictas de frecuencia por IP y por identificador de cuenta para prevenir DoS y brute-force.

### Patrón de Remediación:
*   **Throttle de Autenticación**: Máximo 5-10 intentos de inicio de sesión por cuenta/IP en una ventana de 15 minutos. Si se excede, retornar `HTTP 429 Too Many Requests` y bloquear temporalmente el acceso.
*   **Throttle de Generación de Archivos/Correos**: Limitar la generación masiva de PDFs/Emails a cuotas razonables (ej. 30 por minuto).

---

## 4. Flujo Seguro de Modificación de Cuentas (ATO Protection)
**Vectores Asociados**: QD-03 (Account Takeover).

**Regla de Oro**: El cambio de parámetros de autenticación esenciales (email, contraseña, factor doble) debe requerir imperativamente la validación de la contraseña actual del usuario (`current_password`).

### Patrón de Remediación:
```go
// Ejemplo conceptual en Go
type UpdateEmailRequest struct {
    NewEmail        string `json:"new_email" validate:"required,email"`
    CurrentPassword string `json:"current_password" validate:"required"`
}

func UpdateEmailHandler(w http.ResponseWriter, r *http.Request) {
    var req UpdateEmailRequest
    // Decodificar request...
    
    // 1. Validar la contraseña actual de forma criptográficamente segura
    if !ComparePasswords(currentUser.PasswordHash, req.CurrentPassword) {
        RespondWithError(w, http.StatusUnauthorized, "La contraseña actual es incorrecta.")
        return
    }
    
    // 2. Proceder con el cambio de correo y enviar notificación inmediata a ambos correos (antiguo y nuevo)
}
```

---

## 5. Aislamiento Estricto Multi-Tenant (BOLA / IDOR Protection)
**Vectores Asociados**: QD-05 (BOLA/IDOR).

**Regla de Oro**: Todo recurso privado expuesto mediante APIs debe utilizar identificadores no deducibles (UUID v4) y forzar que las consultas a la base de datos incluyan implícitamente el Tenant ID (`tenant_id` o `company_id`) recuperado del token JWT verificado.

### Patrón de Remediación:
*   **UUIDs sobre IDs secuenciales**: Utiliza identificadores secuenciales únicamente de forma interna (indices de bases de datos), pero expón únicamente UUIDs v4 en la API REST.
*   **Filtros de Consultas Automáticos (Global Scopes)**: Implementar capas ORM que filtren automáticamente cualquier consulta basándose en el contexto del usuario autenticado.

```sql
-- Ejemplo conceptual de consulta forzada:
SELECT * FROM invoices 
WHERE id = :requested_id 
  AND company_id = :authenticated_user_company_id; -- ← Inyección obligatoria del Tenant
```

---

## 6. Separación de Portales por Scopes JWT
**Vectores Asociados**: QD-06 (Cross-Portal privilege escalation).

**Regla de Oro**: Los tokens JWT deben incluir un claim inalterable firmado en el servidor que identifique explícitamente el portal al cual tiene derecho de acceso el usuario (ej. `'scope': 'client'` o `'scope': 'admin'`).

### Patrón de Remediación:
```javascript
// Middleware de verificación de Scope
function verifyPortalScope(requiredScope) {
    return (req, res, next) => {
        const tokenPayload = req.user; // Decodificado y validado previamente
        if (tokenPayload.portal_scope !== requiredScope) {
            return res.status(403).json({ message: 'Forbidden. Requiere scope: ' + requiredScope });
        }
        next();
    };
}
```

---

## 7. Cifrado de Secretos a Nivel de Aplicación (Encryption at Rest)
**Vectores Asociados**: QD-02 (Secrets exposure).

**Regla de Oro**: Las credenciales SMTP, llaves de API externas o tokens de terceros almacenados en la base de datos deben guardarse **cifrados** mediante criptografía simétrica (ej. AES-256-GCM) utilizando una llave maestra gestionada fuera del entorno de la base de datos.

---

## 8. Sanitización Sistemática de Entradas (Prevention of XSS and SQLi)
**Vectores Asociados**: QD-07 (Stored XSS), QD-11 (HTML Injection).

**Regla de Oro**: Todas las entradas de usuario de texto libre deben codificarse y sanitizarse en una capa intermedia previa a su almacenamiento o procesamiento en motores de renderizado.

*   **Codificación de Salida (Output Encoding)**: Codificar caracteres especiales (`<` a `&lt;`, `>` a `&gt;`) por defecto.
*   **Limpieza Estricta de HTML**: Si se requiere permitir HTML formateado, usar librerías de saneamiento robustas (ej. HTMLPurifier, DOMPurify) con listas blancas rigurosas de etiquetas permitidas.

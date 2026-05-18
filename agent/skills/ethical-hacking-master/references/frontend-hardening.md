# Guía Universal de Blindaje de Frontend (Frontend Hardening)

> Directrices y patrones de desarrollo seguro para mitigar vulnerabilidades en el cliente.
> Aplicable a aplicaciones SPA y SSR bajo cualquier framework (React, Angular, Vue, Next.js, Svelte).

---

## 1. Evitar Inyecciones de Código en Renderizado Dinámico (XSS Prevention)
**Vectores Asociados**: QD-07 (Stored XSS).

**Regla de Oro**: Evitar por completo el uso de directivas que inserten y rendericen HTML sin depurar directamente en la vista. Utilizar codificación por defecto (escapado automático).

### Análisis Comparativo de Inserciones Inseguras vs Seguras:

| Framework | ❌ Uso Vulnerable (HTML Crudo) | ✅ Uso Seguro (Codificado / Limpio) |
|-----------|---------------------------------|--------------------------------------|
| **React** | `<div dangerouslySetInnerHTML={ {__html: payload} } />` | `<div>{payload}</div>` (Interpolación estándar) |
| **Angular** | `<div [innerHTML]="payload"></div>` | `<div>{{ payload }}</div>` (Interpolación nativa) |
| **Vue** | `<div v-html="payload"></div>` | `<div>{{ payload }}</div>` (Doble llave segura) |
| **Svelte** | `{@html payload}` | `<div>{payload}</div>` (Llave nativa) |

### Patrón de Renderizado HTML Formateado Controlado:
Si el negocio requiere mostrar HTML rico de procedencia controlada (ej. blogs, descripciones enriquecidas), debe sanitizarse activamente en el cliente utilizando librerías robustas de desinfección como **DOMPurify** antes de su renderizado.

```javascript
import DOMPurify from 'dompurify';

// Sanitizar de forma explícita antes de inyectar en la vista:
const cleanHTML = DOMPurify.sanitize(userInput);
```

---

## 2. Almacenamiento Seguro de Sesiones (`sessionStorage`)
**Vectores Asociados**: QD-01 (Token Exfiltration).

**Regla de Oro**: No guardes información confidencial de autenticación ni tokens de sesión (JWT) en `localStorage`, ya que persiste indefinidamente en el sistema de archivos del navegador y es altamente vulnerable ante ataques XSS.

### Criterio Seguro de Almacenamiento:
1. **`sessionStorage`**: Limita el ciclo de vida del token a la pestaña/ventana abierta. Al cerrar la pestaña, los secretos se eliminan de forma atómica.
2. **Cookies `HttpOnly` y `Secure`**: El estándar más robusto de la industria para evitar que scripts del lado del cliente accedan al token. Delegar la persistencia de autenticación a cookies manejadas únicamente en cabeceras HTTP del servidor.

---

## 3. Guards de Navegación con Revalidación Asíncrona Server-Side
**Vectores Asociados**: QD-01 (Client-Side Auth Bypass).

**Regla de Oro**: Ningún Guard o ruta de navegación local en el frontend debe autorizar el acceso basándose exclusivamente en el JSON decodificado del JWT en local. Toda ruta restringida debe validar activamente el estado de autorización de forma asíncrona contra la API del servidor.

### Estructura de Navegación Segura (RxJS / Promesas):
1. El Guard intercepta la transición de la ruta.
2. Realiza una petición `GET /api/auth/check-permission/{{REQUIRED_PERMISSION}}`.
3. Si el servidor responde `allowed: true`, permite el renderizado del componente.
4. Si responde `false` o da error, borra la sesión local y redirige al inicio de sesión.

---

## 4. Interceptores HTTP de Seguridad Centralizados
**Vectores Asociados**: QD-01 (Token Hijack), QD-08 (Rate Limiting).

**Regla de Oro**: Encapsular la inyección de Bearer Tokens y el control de errores HTTP en un interceptor central para garantizar uniformidad en todas las comunicaciones del cliente.

### Patrón Universal de Interceptor (Conceptual):
*   **Inyección Automática**: Leer el token activo desde `sessionStorage` e inyectar `Authorization: Bearer {{TOKEN}}` en todas las peticiones salientes dirigidas a la API.
*   **Mapeo de Errores Críticos**:
    *   `401 Unauthorized`: Forzar redirección al login y purgar storage local.
    *   `403 Forbidden`: Redirigir a vista genérica de permisos insuficientes.
    *   `429 Too Many Requests`: Interceptar cabeceras `Retry-After`, lanzar alertas o Toasts no intrusivos al usuario advirtiendo del bloqueo temporal.

---

## 5. Separación Dinámica de Módulos (Lazy Loading por Portal)
**Vectores Asociados**: QD-06 (Cross-Portal privilege escalation).

**Regla de Oro**: Separar los portales en diferentes proyectos físicos o módulos independientes cargados de manera diferida (Lazy Loading) asociados a sus respectivos Guards de portal, evitando descargar código de administración a clientes no autorizados.

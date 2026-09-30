# Lógica Compartida y Jerarquía de Portales

> Guía para el manejo de abstracciones entre Soporte, Admin y Cliente.

## 🏛️ Jerarquía de Acceso

1.  **Portal Cliente**: Acceso limitado a su propia `company_id`.
2.  **Portal Soporte**: Acceso a múltiples suscriptores para gestión de tickets y ayuda.
3.  **Portal Admin**: Control total del sistema, configuración global y depuración.

## 🔄 Reutilización de Lógica (DRY)

### Backend
- Los servicios deben ser agnósticos al portal.
- La distinción de permisos se maneja en el `FormRequest` o mediante `Scopes` de Eloquent.
- **Shared Exceptions**: Usa excepciones personalizadas para mensajes consistentes en todos los portales.

### Frontend
- **Shared Abstract Components**: El `support-portal` y el `admin-portal` deben compartir componentes base para evitar duplicidad de lógica de tickets.
- **Signals**: Usa Signals para estados globales que deban persistir durante la navegación administrativa.

---
> [!WARNING]
> Nunca permitas que un token con scope de 'Cliente' acceda a un endpoint prefijado con 'v1/support'.

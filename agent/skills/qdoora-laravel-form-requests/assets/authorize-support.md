# Patrón de Autorización: Portal de Soporte / Admin

Aplica a los FormRequests de la API consumidos por el Portal de Soporte y Administración (`support-portal`), típicamente bajo el prefijo de rutas `v1/support`.

## ✅ Estándar vigente: trait `AuthorizesSupportRequests`

```php
<?php

namespace App\Http\Requests\Support\PUC;

use App\Traits\AuthorizesSupportRequests;
use Illuminate\Foundation\Http\FormRequest;

class CrearAlgoRequest extends FormRequest
{
    use AuthorizesSupportRequests;

    public function authorize(): bool
    {
        return $this->authorizeAdmin();
    }
}
```

## Cuál de los dos métodos usar

| Método | Roles aceptados | Cuándo |
|:---|:---|:---|
| `authorizeAdmin()` | Solo `ADMIN_ROLE` | **Default.** Es el patrón real en 42 de 43 FormRequests de este portal. |
| `authorizeSupportStaff()` | `ADMIN_ROLE` + `SUPPORT_ROLE` | **Excepción.** Solo 1 archivo real lo usa. Requiere justificación explícita: endpoint de bajo riesgo, sin mutación de datos sensibles ni de configuración global. |

> [!WARNING]
> No uses `authorizeSupportStaff()` "por si acaso". Otorgar `SUPPORT_ROLE` donde la convención real exige `ADMIN_ROLE` es sobre-otorgamiento de privilegios, y el portal de soporte opera **sobre todos los tenants a la vez** — el radio de impacto de un error acá es el SaaS completo, no una empresa.

## Capas de autorización que ya existen (no las dupliques ni las reemplaces)

Este portal tiene tres mecanismos independientes conviviendo. Antes de crear algo nuevo, verifica cuál aplica:

1. **Trait `AuthorizesSupportRequests`** — el estándar para FormRequests nuevos.
2. **Clase base `App\Http\Requests\AdminOnlyRequest`** — existe y algunos Requests la extienden. Si estás modificando uno que ya la extiende, déjalo así; no lo migres al trait sin que te lo pidan.
3. **Middleware `CheckAdminRole`** — gatea `ADMIN_ROLE` a nivel de ruta, en paralelo y con independencia del FormRequest. Que una ruta lo tenga **no exime** al FormRequest de autorizar: son defensa en profundidad.

### Caso especial: autenticación por API Key

`AduanaSubscriberRequest` tiene un tercer camino — si la request llega autenticada por **API Key** (no por JWT de usuario), el middleware ya validó el secreto y no hay `$user` que evaluar. Ese patrón queda **fuera del alcance de estos traits**; no intentes forzarlo dentro de `authorizeAdmin()`.

## ⛔ Anti-patrón: `isExclusiveAdminEndpoint()`

Versiones anteriores de esta guía proponían un método privado `isExclusiveAdminEndpoint()` que decidía en runtime si el endpoint era exclusivo de admin, con `ADMIN_ROLE || SUPPORT_ROLE` como fallback. **No existe en el código real y no debe introducirse**: un FormRequest atiende un solo endpoint, así que su nivel de acceso es una decisión de diseño fija, no una condición a evaluar. Elige `authorizeAdmin()` o `authorizeSupportStaff()` y ya.

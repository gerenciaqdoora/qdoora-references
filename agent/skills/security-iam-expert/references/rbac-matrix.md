# Matriz de Roles, Permisos y Scopes — Qdoora ERP

> Usa este archivo al definir reglas de acceso, separación de portales, validaciones en FormRequests o al decidir si un usuario puede ejecutar una acción específica en el ERP.

---

## 1. Arquitectura de Permisos de Qdoora (Multinivel)

El sistema de permisos de Qdoora NO utiliza tablas de permisos genéricas (`role_permission`). Utiliza un modelo de autorización en capas basado en el contexto del usuario:

1. **Scope del Portal (JWT)**: Determina qué portal (Client, Support, Admin) puede consumir la petición.
2. **Tenancy / Empresa (`user_company_permission`)**: Determina a qué empresas tiene acceso el usuario y qué tipo de acciones generales puede hacer en ellas (`show`, `update`, `transaction`).
3. **Submódulo Funcional (`users_permission_submodule`)**: Autorización granular CRUD (`review`, `create`, `update`, `delete`) por cada submódulo del sistema (Ej: `PLAN_DE_CUENTA`, `COMPROBANTE`).

---

## 2. Permisos a Nivel de Empresa (`user_company_permission`)

Esta tabla rige el acceso y la mutación global de una empresa.

| Permiso | Descripción |
| :--- | :--- |
| `show` | Permite visualizar la empresa en el selector y leer sus datos. |
| `update` | Permite actualizar la configuración general de la empresa. |
| `transaction` | **Crítico**: Permite generar transacciones operativas en la empresa (facturas, comprobantes, pagos). Debe validarse antes de acciones masivas o contables. |

---

## 3. Permisos a Nivel de Submódulo (`users_permission_submodule`)

Define el CRUD por usuario en cada submódulo. Se valida utilizando el Enum `App\Enums\UserOperationSubmodule`.

```php
namespace App\Enums;

enum UserOperationSubmodule: string
{
    case REVIEW = 'review';
    case CREATE = 'create';
    case UPDATE = 'update';
    case DELETE = 'delete';
}
```

---

## 4. Validación en Backend (FormRequests y Policies)

**⚠️ Regla Estricta:** Todo FormRequest que cree, actualice, elimine o liste recursos DEBE validar ambas capas (Empresa y Submódulo) en su método `authorize()`.

```php
use App\Enums\UserOperationSubmodule;
use Illuminate\Support\Facades\Gate;

class StoreVoucherRequest extends FormRequest
{
    public function authorize(): bool
    {
        // 1. Validar permiso de Submódulo (Ej: CREATE en COMPROBANTE)
        $hasSubmodulePerm = Gate::check('access-submodule', [
            'COMPROBANTE', 
            UserOperationSubmodule::CREATE
        ]);

        // 2. Validar permiso de Empresa (Ej: transaction)
        $companyId = $this->header('X-Company-Id') ?? $this->user()->company_selected_id;
        $hasCompanyPerm = Gate::check('company-action', [
            $companyId, 
            'transaction'
        ]);

        return $hasSubmodulePerm && $hasCompanyPerm;
    }

    public function rules(): array
    {
        return [ ... ];
    }
}
```
*(Nota: Asume que las Gates `access-submodule` y `company-action` se registran en AuthServiceProvider verificando contra `users_permission_submodule` y `user_company_permission`)*.

---

## 5. Implementación en el Frontend (Angular)

### Frontend Service (State)
Nunca confíes los permisos al Payload del JWT (esto engorda el JWT y retrasa la actualización de accesos).
El Portal Cliente (Angular 18) debe utilizar un servicio inyectable (ej. `PermissionService`) soportado por **Signals** que, al montar un módulo, descargue de un endpoint ligero los permisos correspondientes.

### Ocultar Elementos UI (Directivas)
Para ocultar botones o secciones, utiliza una directiva personalizada o un control de flujo:

```html
<!-- Ejemplo con sintaxis Angular 17/18 Control Flow + Signal -->
@if (permissionService.hasAccess('COMPROBANTE', 'create')()) {
  <button (click)="createVoucher()">Crear Comprobante</button>
}
```

> **Advertencia de Seguridad (Anti-Patrón):** Ocultar el botón en el frontend NO reemplaza la validación en el `FormRequest`. Es solo UX. Si un usuario inyecta una petición por Postman, el backend debe rechazarla.

---

## 6. JWT y Scopes (El JWT Delgado)

El token JWT **solamente** debe contener:
- Identificador de usuario (`sub`).
- Rol genérico (`role`).
- Scope de acceso al portal (`portal_scope`: `client`, `support`, `admin`).
- (Opcional) Empresa seleccionada en el header o payload ligero.

**Prohibido:**
❌ Incluir arrays de permisos `[ { submodule: '...', create: true } ]` dentro del JWT. Esto provoca la vulnerabilidad de Information Disclosure, JWTs pesados y riesgo de persistencia local.

# Patrón de Autorización: Portal de Clientes

Aplica a los FormRequests de la API Global (`qdoora-api`) consumidos por el Portal de Clientes (`fuse-starter`).

## ✅ Estándar vigente: trait `AuthorizesClientRequests`

```php
<?php

namespace App\Http\Requests\Comprobante;

use App\Enums\UserOperationSubmodule;
use App\Traits\AuthorizesClientRequests;
use Illuminate\Foundation\Http\FormRequest;

class CreaAlgoRequest extends FormRequest
{
    use AuthorizesClientRequests;

    public function authorize(): bool
    {
        return $this->authorizeSubmodule(
            (int) $this->route('company_id'),
            'COMPROBANTE',
            UserOperationSubmodule::CREATE
        );
    }
}
```

### Variantes

```php
// 1. Habilidad especial (no-CRUD): emitir NC/ND, cambiar consignatario DIN, cierre contable.
//    El 3er argumento se IGNORA cuando pasas ability_code — la operación prerrequisito real
//    la define submodule_action.requires_operation en la BD, no este parámetro.
return $this->authorizeSubmodule($companyId, 'COMPROBANTE', UserOperationSubmodule::CREATE, 'NOTA_CREDITO_DEBITO');

// 2. Solo pertenencia de empresa, sin permiso de submódulo (ficha de empresa, dashboards).
return $this->authorizeCompany($companyId);

// 3. Ficha de empresa con permiso distinto de TRANSACTION (el default).
return $this->authorizeCompany($companyId, CompanyPermissionAbility::SHOW);
```

> **Catálogos compartidos entre módulos** (selectores de cuentas, auxiliares, centros de costo, productos): **no crees un FormRequest nuevo**. Reutiliza `App\Http\Requests\CompanyAccessRequest`, que valida solo pertenencia de empresa. Exigir el permiso de un submódulo concreto rompe a los demás módulos que consumen el mismo endpoint.

## Métodos reales de `User` (los únicos que existen)

| Método | Qué valida |
|:---|:---|
| `canOperateOnSubmodule($companyId, $submodule, UserOperationSubmodule $operation, ?$abilityCode)` | Punto único: bypass suscriptor + empresa + submódulo (o ability). Es lo que invoca el trait. |
| `userCanPerformSubmoduleAction($companyId, $submodule, $actionCode)` | Habilidad especial del catálogo `submodule_action`. |
| `ownsCompany($companyId)` | La empresa pertenece al suscriptor del usuario. |
| `userHasCompanyPermission($companyId, $ability = 'transaction')` | Permiso sobre la empresa (`show`/`update`/`transaction`). |
| `usersPermissionSubmodules($submoduleCode, $operation)` | Permiso CRUD del submódulo (+ CAPA 1 de contratación). |
| `hasRole($role)` | Comparación simple de rol. |

> ⛔ **`hasPermission()` NO existe.** Si lo ves en código o documentación, es un error a corregir.

### Qué argumentos van tipados con enum y cuáles no

| Argumento | Tipo | Por qué |
|:---|:---|:---|
| `$operation` | **`UserOperationSubmodule`** | Conjunto **cerrado** de 4 valores que refleja columnas fijas de `users_permission_submodule`. Antes era string y `usersPermissionSubmodules()` lo validaba en runtime lanzando `InvalidArgumentException` (406): tiparlo mueve ese fallo a tiempo de compilación. |
| `$submodule_code` | `string` | Catálogo **abierto** en BD (`submodule.code`), crece con cada módulo. Un código inexistente ya se resuelve fail-closed: se loguea un warning y se deniega, nunca 500. |
| `$ability_code` | `string` | Catálogo **abierto** en BD (`submodule_action.code`), poblado por seeders. |

> ⚠️ **No confundas `UserOperationSubmodule` con `SubmoduleActionTrigger`.** El segundo tiene un caso extra `SPECIAL` y aplica **solo** a `submodule_action.requires_operation` (acciones sin prerrequisito CRUD). Pasarlo como `$operation` sería inválido — por eso el tipado con el enum correcto importa.
>
> El método legado `usersPermissionSubmodules($code, string $column)` **mantiene su firma con string**: lo llaman ~150 FormRequests existentes con `->value`. El tipado fuerte empieza en la API nueva, no se propaga hacia atrás.

## Patrón legado (~150 archivos existentes — NO replicar en Requests nuevos)

Documentado solo para que puedas **leer y modificar** los FormRequests antiguos sin romperlos:

```php
public function authorize(): bool
{
    $user = Auth::guard('api')->user();
    if (!$user) {
        return false;
    }

    switch ($user->role) {
        case 'SUBSCRIBER_ROLE':
            return Company::where('id', $this->route('company_id'))
                ->where('suscriptor_id', $user->getSuscriptorByRole()?->id)
                ->exists();

        case 'USER_ROLE':
            return $user->userHasCompanyPermission($this->route('company_id'))
                && $user->usersPermissionSubmodules('COMPROBANTE', UserOperationSubmodule::CREATE->value);

        default: // ← obligatorio: sin esta rama el request queda fail-open (QD-04)
            return false;
    }
}
```

### Errores frecuentes en este patrón legado

- **`SUPPORT_ROLE` en la rama de bypass del suscriptor**: incorrecto. `getSuscriptorByRole()` solo resuelve para `SUBSCRIBER_ROLE` y `USER_ROLE`; el personal de soporte no accede a datos de cliente por esta vía.
- **Omitir el `default`/`else` final**: cualquier rol no contemplado quedaría autorizado por caída del flujo. Siempre denegar explícitamente.
- **Asumir que `userHasCompanyPermission()` sin argumento valida `show`**: el default real es `transaction`.

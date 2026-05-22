# Patrón de Autorización: Portal de Clientes

Este patrón se aplica a los FormRequests de la API Global (`qdoora-api`) consumidos por el Portal de Clientes.

```php
public function authorize(): bool
{
    $user = Auth::guard('api')->user();
    $companyId = $this->route('company_id');

    if ($user->role === 'SUBSCRIBER_ROLE' || $user->role === 'SUPPORT_ROLE') {
        // El suscriptor solo puede acceder a sus propias empresas
        return Company::where('id', $companyId)
            ->where('suscriptor_id', $user->getSuscriptorByRole()?->id)
            ->exists();
    }

    if ($user->role === 'USER_ROLE') {
        // El usuario debe tener permiso explícito sobre la empresa y el submódulo
        return $user->userHasCompanyPermission($companyId)
            && $user->usersPermissionSubmodules(
                'NOMBRE_SUBMODULO',
                UserOperationSubmodule::CREATE->value
            );
    }

    return false;
}
```

# Patrón de Autorización: Portal de Soporte / Admin

Este patrón se aplica a los FormRequests de la API consumidos por el Portal de Soporte y Administración.

```php
public function authorize(): bool
{
    $user = Auth::guard('api')->user();

    // Si es un endpoint exclusivo de administración
    if ($this->isExclusiveAdminEndpoint()) {
        return $user->role === 'ADMIN_ROLE';
    }

    // Caso contrario, autoriza a ADMIN_ROLE y SUPPORT_ROLE
    return $user->role === 'ADMIN_ROLE' || $user->role === 'SUPPORT_ROLE';
}

/**
 * Define aquí si el endpoint es exclusivo de ADMIN_ROLE
 */
private function isExclusiveAdminEndpoint(): bool
{
    // Lógica para determinar exclusividad
    return false;
}
```

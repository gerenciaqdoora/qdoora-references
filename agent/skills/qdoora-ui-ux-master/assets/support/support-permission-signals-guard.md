# Permission Guard con Signals

> Validación de acceso server-side para el Portal Admin.

## 🛡️ Implementación

```typescript
import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthService } from '@app/core/auth/auth.service';
import { catchError, map, of } from 'rxjs';

export const permissionGuard: CanActivateFn = (route, state) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    // ✅ Validación proactiva contra el Backend
    return authService.checkPermission(state.url).pipe(
        map((hasAccess) => {
            if (hasAccess) return true;
            
            router.navigate(['/unauthorized']);
            return false;
        }),
        catchError(() => {
            router.navigate(['/login']);
            return of(false);
        })
    );
};
```

## 🚨 Mandatos Críticos
- **Validación Continua**: NO confiar en el estado local. Cada navegación crítica debe ser validada contra `/api/auth/check-permission/`.
- **RBAC**: El guard debe manejar los scopes `support` y `admin` de forma aislada.
- **Fail-Safe**: Si hay un error de red o timeout, la navegación debe ser rechazada por defecto.

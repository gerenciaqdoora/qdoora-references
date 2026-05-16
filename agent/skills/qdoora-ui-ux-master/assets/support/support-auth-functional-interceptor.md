# Auth Interceptor Funcional (Angular 21)

> Patrón funcional para la inyección de tokens de administración.

## 🛠️ Implementación

```typescript
import { HttpInterceptorFn, HttpRequest, HttpHandlerFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '@app/core/auth/auth.service';

export const authInterceptor: HttpInterceptorFn = (req: HttpRequest<unknown>, next: HttpHandlerFn) => {
    const authService = inject(AuthService);
    const token = authService.getToken(); // ✅ Obtener de sessionStorage (NO localStorage)

    if (token) {
        const cloned = req.clone({
            setHeaders: {
                Authorization: `Bearer ${token}`
            }
        });
        return next(cloned);
    }

    return next(req);
};
```

## ⚙️ Registro en `app.config.ts`

```typescript
export const appConfig: ApplicationConfig = {
    providers: [
        provideHttpClient(
            withInterceptors([authInterceptor]) // ✅ Registro funcional
        ),
    ]
};
```

## 🚨 Reglas de Seguridad
- El interceptor debe asegurar que el scope enviado sea compatible con el endpoint de administración.
- Prohibido el uso de clases interceptoras antiguas (Legacy Interceptors).

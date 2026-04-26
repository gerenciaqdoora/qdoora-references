# Angular 18 — Autenticación Portal Cliente (fuse-starter)

> Usa este archivo para el Portal Cliente en Angular 18 con RxJS y módulos tradicionales.
> El portal consume rutas prefijadas con `/api/client/*` y el scope del token es `client`.

---

## 1. Token Storage — sessionStorage (nunca localStorage)

```typescript
// src/app/core/auth/token-storage.service.ts
import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class TokenStorageService {
    private readonly TOKEN_KEY  = 'access_token';
    // ⚠️ El refresh token NO va aquí — idealmente viene en cookie HttpOnly del servidor
    // Si el backend no soporta HttpOnly cookie todavía, usar sessionStorage como medida temporal

    save(token: string): void {
        sessionStorage.setItem(this.TOKEN_KEY, token);
        // ❌ NUNCA: localStorage.setItem('token', token)
        // localStorage persiste entre pestañas y hasta que el usuario lo borre manualmente
        // → accesible por XSS de cualquier script de la página
    }

    get(): string | null {
        return sessionStorage.getItem(this.TOKEN_KEY);
    }

    clear(): void {
        sessionStorage.clear();
    }
}
```

---

## 2. Auth Interceptor — Inyección Automática del Bearer Token

```typescript
// src/app/core/interceptors/jwt.interceptor.ts
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, switchMap, throwError } from 'rxjs';
import { TokenStorageService } from '../auth/token-storage.service';
import { AuthService } from '../auth/auth.service';

export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
    const tokenStorage = inject(TokenStorageService);
    const authService  = inject(AuthService);
    const router       = inject(Router);
    const token        = tokenStorage.get();

    // Inyectar token si existe y la petición va a la API
    const authReq = token && req.url.includes('/api/')
        ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
        : req;

    return next(authReq).pipe(
        catchError((error: HttpErrorResponse) => {
            if (error.status === 401 && token) {
                // Token expirado → intentar refresh automático
                return authService.refresh().pipe(
                    switchMap((newToken) => {
                        tokenStorage.save(newToken);
                        return next(req.clone({
                            setHeaders: { Authorization: `Bearer ${newToken}` },
                        }));
                    }),
                    catchError(() => {
                        // Refresh también falló → cerrar sesión
                        tokenStorage.clear();
                        router.navigate(['/sign-in']);
                        return throwError(() => error);
                    })
                );
            }

            if (error.status === 403) {
                router.navigate(['/access-denied']);
            }

            if (error.status === 429) {
                console.warn('Rate limit alcanzado. Reintentar en:', error.headers.get('Retry-After'), 's');
            }

            return throwError(() => error);
        })
    );
};

// app.config.ts — registrar interceptor funcional
import { provideHttpClient, withInterceptors } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
    providers: [
        provideHttpClient(withInterceptors([jwtInterceptor])),
    ],
};
```

---

## 3. AuthService — Login, Logout y Validación de Permiso

```typescript
// src/app/core/auth/auth.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap, map } from 'rxjs';
import { TokenStorageService } from './token-storage.service';
import { environment } from 'environments/environment';

export interface LoginResponse {
    token:      string;
    expires_in: number;
    user: { id: string; name: string; email: string; portal: string };
}

@Injectable({ providedIn: 'root' })
export class AuthService {
    private readonly http  = inject(HttpClient);
    private readonly store = inject(TokenStorageService);
    private readonly base  = `${environment.apiUrl}/auth`;

    login(credentials: { email: string; password: string }): Observable<LoginResponse> {
        return this.http.post<LoginResponse>(`${this.base}/login`, credentials).pipe(
            tap(res => this.store.save(res.token))
        );
    }

    logout(): Observable<void> {
        return this.http.post<void>(`${this.base}/logout`, {}).pipe(
            tap(() => this.store.clear())
        );
    }

    refresh(): Observable<string> {
        return this.http.post<{ token: string }>(`${this.base}/refresh`, {}).pipe(
            map(res => res.token)
        );
    }

    // ✅ Validación server-side — el permiso se verifica en el backend, no en el token local
    checkPermission(permission: string): Observable<boolean> {
        return this.http
            .get<{ allowed: boolean }>(`${this.base}/check-permission/${permission}`)
            .pipe(map(res => res.allowed));
    }

    isAuthenticated(): boolean {
        return !!this.store.get();
    }
}
```

---

## 4. Guard de Autenticación — Server-Side (Anti QD-01)

```typescript
// src/app/core/guards/auth.guard.ts
import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthService } from '../auth/auth.service';
import { map, catchError, of } from 'rxjs';

// Guard básico: ¿hay token y es válido?
export const authGuard: CanActivateFn = () => {
    const auth   = inject(AuthService);
    const router = inject(Router);

    if (!auth.isAuthenticated()) {
        router.navigate(['/sign-in']);
        return false;
    }

    // Verificar que el token sigue siendo válido contra el backend
    return auth.checkPermission('authenticated').pipe(
        map(valid => valid || (router.navigate(['/sign-in']), false)),
        catchError(() => { router.navigate(['/sign-in']); return of(false); })
    );
};

// Guard de permiso específico — factory function
export const permissionGuard = (requiredPermission: string): CanActivateFn => {
    return () => {
        const auth   = inject(AuthService);
        const router = inject(Router);

        return auth.checkPermission(requiredPermission).pipe(
            map(allowed => allowed || (router.navigate(['/access-denied']), false)),
            catchError(() => { router.navigate(['/sign-in']); return of(false); })
        );
    };
};

// Aplicar en rutas
export const CLIENT_ROUTES: Routes = [
    {
        path: '',
        canActivate: [authGuard], // protege toda el área cliente
        children: [
            {
                path: 'liquidaciones',
                loadComponent: () => import('./liquidaciones/liquidaciones.component'),
                canActivate: [permissionGuard('view-liquidaciones')],
            },
            {
                path: 'liquidaciones/:id/approve',
                loadComponent: () => import('./liquidaciones/approve.component'),
                canActivate: [permissionGuard('approve-liquidaciones')],
            },
        ],
    },
];
```

---

## 5. Componente de Login

```typescript
// src/app/auth/sign-in/sign-in.component.ts
import { Component, signal, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/auth/auth.service';
import { finalize } from 'rxjs';

@Component({
    standalone: true,
    imports: [ReactiveFormsModule],
    template: `
        <form [formGroup]="form" (ngSubmit)="submit()">
            <input id="email"    formControlName="email"    type="email"    autocomplete="username" />
            <input id="password" formControlName="password" type="password" autocomplete="current-password" />
            <button type="submit" [disabled]="form.invalid || isLoading()">
                {{ isLoading() ? 'Ingresando...' : 'Ingresar' }}
            </button>
            @if (errorMessage()) {
                <app-shared-alert type="error" [message]="errorMessage()!" />
            }
        </form>
    `,
})
export class SignInComponent {
    private readonly fb     = inject(FormBuilder);
    private readonly auth   = inject(AuthService);
    private readonly router = inject(Router);

    readonly isLoading    = signal(false);
    readonly errorMessage = signal<string | null>(null);

    readonly form = this.fb.group({
        email:    ['', [Validators.required, Validators.email]],
        password: ['', [Validators.required]],
    });

    submit(): void {
        if (this.form.invalid) return;
        this.isLoading.set(true);
        this.errorMessage.set(null);

        this.auth.login(this.form.getRawValue() as any).pipe(
            finalize(() => this.isLoading.set(false))
        ).subscribe({
            next:  () => this.router.navigate(['/dashboard']),
            error: (e) => this.errorMessage.set(e.error?.message ?? 'Credenciales inválidas.'),
        });
    }
}
```

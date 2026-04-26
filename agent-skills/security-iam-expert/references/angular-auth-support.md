# Angular 21 Zoneless — Autenticación Portal Soporte/Admin (support-portal)

> Usa este archivo para el Portal Soporte/Admin en Angular 21 Zoneless con Signals.
> El portal tiene dos scopes: `support` (agentes) y `admin` (super-administradores).
> Rutas backend: `/api/support/*` y `/api/admin/*`.

---

## 1. Auth Store — Estado Reactivo con Signals

```typescript
// src/app/core/auth/auth.store.ts
import { Injectable, signal, computed, inject } from '@angular/core';
import { AuthService } from './auth.service';

export interface AuthUser {
    id:     string;
    name:   string;
    email:  string;
    portal: 'support' | 'admin';
}

@Injectable({ providedIn: 'root' })
export class AuthStore {
    // Estado privado — solo mutable internamente
    private readonly _user    = signal<AuthUser | null>(null);
    private readonly _token   = signal<string | null>(sessionStorage.getItem('access_token'));
    private readonly _loading = signal(false);

    // Estado público — solo lectura
    readonly user        = this._user.asReadonly();
    readonly token       = this._token.asReadonly();
    readonly isLoading   = this._loading.asReadonly();
    readonly isAuthenticated = computed(() => !!this._token());
    readonly portalScope     = computed(() => this._user()?.portal ?? null);
    readonly isAdmin         = computed(() => this._user()?.portal === 'admin');
    readonly isSupport       = computed(() => ['admin', 'support'].includes(this._user()?.portal ?? ''));

    setToken(token: string, user: AuthUser): void {
        sessionStorage.setItem('access_token', token);
        this._token.set(token);
        this._user.set(user);
    }

    clear(): void {
        sessionStorage.removeItem('access_token');
        this._token.set(null);
        this._user.set(null);
    }

    setLoading(loading: boolean): void {
        this._loading.set(loading);
    }
}
```

---

## 2. Auth Interceptor Funcional (Zoneless)

```typescript
// src/app/core/interceptors/auth.interceptor.ts
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, switchMap, throwError } from 'rxjs';
import { AuthStore } from '../auth/auth.store';
import { AuthService } from '../auth/auth.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
    const store       = inject(AuthStore);
    const authService = inject(AuthService);
    const router      = inject(Router);
    const token       = store.token();

    // Solo adjuntar token en peticiones a la API
    const secureReq = token && req.url.includes('/api/')
        ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
        : req;

    return next(secureReq).pipe(
        catchError((error: HttpErrorResponse) => {
            if (error.status === 401 && token) {
                return authService.refresh().pipe(
                    switchMap(({ token: newToken, user }) => {
                        store.setToken(newToken, user);
                        return next(req.clone({
                            setHeaders: { Authorization: `Bearer ${newToken}` },
                        }));
                    }),
                    catchError(() => {
                        store.clear();
                        router.navigate(['/login']);
                        return throwError(() => error);
                    })
                );
            }
            if (error.status === 403) router.navigate(['/unauthorized']);
            if (error.status === 429) {
                const retryAfter = error.headers.get('Retry-After');
                console.warn(`Rate limited. Retry after ${retryAfter}s`);
            }
            return throwError(() => error);
        })
    );
};

// app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';

export const appConfig: ApplicationConfig = {
    providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
    ],
};
```

---

## 3. Auth Service con Signals

```typescript
// src/app/core/auth/auth.service.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap, map } from 'rxjs';
import { AuthStore, AuthUser } from './auth.store';
import { environment } from 'environments/environment';

@Injectable({ providedIn: 'root' })
export class AuthService {
    private readonly http  = inject(HttpClient);
    private readonly store = inject(AuthStore);
    private readonly base  = `${environment.apiUrl}/auth`;

    login(credentials: { email: string; password: string }): Observable<void> {
        return this.http.post<{ token: string; user: AuthUser }>(`${this.base}/login`, credentials)
            .pipe(tap(res => this.store.setToken(res.token, res.user)), map(() => void 0));
    }

    logout(): Observable<void> {
        return this.http.post<void>(`${this.base}/logout`, {})
            .pipe(tap(() => this.store.clear()));
    }

    refresh(): Observable<{ token: string; user: AuthUser }> {
        return this.http.post<{ token: string; user: AuthUser }>(`${this.base}/refresh`, {});
    }

    // ✅ Validación server-side de permisos (anti QD-01)
    checkPermission(permission: string): Observable<boolean> {
        return this.http
            .get<{ allowed: boolean }>(`${this.base}/check-permission/${permission}`)
            .pipe(map(r => r.allowed));
    }
}
```

---

## 4. Guards Funcionales — Support Portal (Anti QD-01 y QD-06)

```typescript
// src/app/core/guards/support-auth.guard.ts
import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthStore } from '../auth/auth.store';
import { AuthService } from '../auth/auth.service';
import { map, catchError, of } from 'rxjs';

// Guard de autenticación base
export const supportAuthGuard: CanActivateFn = () => {
    const store  = inject(AuthStore);
    const router = inject(Router);

    if (!store.isAuthenticated()) {
        router.navigate(['/login']);
        return false;
    }

    // Verificar que el scope es support o admin (anti QD-06: token de cliente no puede entrar)
    if (!store.isSupport()) {
        router.navigate(['/unauthorized']);
        return false;
    }

    return true;
};

// Guard de permiso — siempre valida contra el servidor
export const supportPermissionGuard = (permission: string): CanActivateFn => {
    return () => {
        const auth   = inject(AuthService);
        const store  = inject(AuthStore);
        const router = inject(Router);

        if (!store.isAuthenticated()) {
            router.navigate(['/login']);
            return false;
        }

        return auth.checkPermission(permission).pipe(
            map(allowed => allowed || (router.navigate(['/unauthorized']), false)),
            catchError(() => { router.navigate(['/login']); return of(false); })
        );
    };
};

// Guard que solo permite admin (para rutas de gestión de usuarios y empresas)
export const adminOnlyGuard: CanActivateFn = () => {
    const store  = inject(AuthStore);
    const router = inject(Router);

    if (!store.isAdmin()) {
        router.navigate(['/unauthorized']);
        return false;
    }
    return true;
};

// Rutas del portal Soporte/Admin
export const SUPPORT_ROUTES: Routes = [
    {
        path: '',
        canActivate: [supportAuthGuard],
        children: [
            {
                path:          'tickets',
                loadComponent: () => import('./tickets/ticket-list.component'),
                // Solo support y admin pueden ver tickets
            },
            {
                path:          'admin/users',
                loadComponent: () => import('./admin/users/user-management.component'),
                canActivate:   [adminOnlyGuard], // solo admins
            },
            {
                path:          'admin/companies',
                loadComponent: () => import('./admin/companies/company-management.component'),
                canActivate:   [supportPermissionGuard('manage-companies')],
            },
        ],
    },
];
```

---

## 5. Componente de Login — Zoneless con Signals

```typescript
// src/app/auth/login/login.component.ts
import { Component, signal, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/auth/auth.service';
import { AuthStore } from '../../core/auth/auth.store';
import { finalize } from 'rxjs';

@Component({
    standalone: true,
    imports: [ReactiveFormsModule],
    template: `
        <form [formGroup]="form" (ngSubmit)="submit()">
            <input id="email"    formControlName="email"    type="email"    autocomplete="username" />
            <input id="password" formControlName="password" type="password" autocomplete="current-password" />
            <button type="submit" [disabled]="form.invalid || store.isLoading()">
                {{ store.isLoading() ? 'Autenticando...' : 'Ingresar al Portal' }}
            </button>
            @if (errorMessage()) {
                <p class="error">{{ errorMessage() }}</p>
            }
        </form>
    `,
})
export class LoginComponent {
    private readonly fb     = inject(FormBuilder);
    private readonly auth   = inject(AuthService);
    private readonly router = inject(Router);
    readonly store          = inject(AuthStore);

    readonly errorMessage = signal<string | null>(null);

    readonly form = this.fb.group({
        email:    ['', [Validators.required, Validators.email]],
        password: ['', [Validators.required]],
    });

    submit(): void {
        if (this.form.invalid) return;
        this.store.setLoading(true);
        this.errorMessage.set(null);

        this.auth.login(this.form.getRawValue() as any).pipe(
            finalize(() => this.store.setLoading(false))
        ).subscribe({
            next: () => {
                // Redirigir según el scope del portal
                const target = this.store.isAdmin() ? '/admin/dashboard' : '/support/tickets';
                this.router.navigate([target]);
            },
            error: (e) => this.errorMessage.set(e.error?.message ?? 'Credenciales inválidas.'),
        });
    }
}
```

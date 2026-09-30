# Angular 21 Zoneless — Autenticación Portal Soporte/Admin

> Usa este archivo para el Portal Soporte/Admin en Angular 21 Zoneless con Signals.
> El portal tiene dos scopes: `support` (agentes) y `admin` (super-administradores).
> Rutas backend: `/api/support/*` y `/api/admin/*`.

---

## 1. Auth Store — Estado Reactivo con Signals

```typescript
// src/app/core/auth/auth.store.ts
import { Injectable, signal, computed } from '@angular/core';

export interface AuthUser {
    id:     string;
    name:   string;
    email:  string;
    portal: 'support' | 'admin';
}

@Injectable({ providedIn: 'root' })
export class AuthStore {
    private readonly _user    = signal<AuthUser | null>(null);
    private readonly _token   = signal<string | null>(sessionStorage.getItem('access_token'));
    private readonly _loading = signal(false);

    readonly user            = this._user.asReadonly();
    readonly token           = this._token.asReadonly();
    readonly isLoading       = this._loading.asReadonly();
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

    checkPermission(permission: string): Observable<boolean> {
        return this.http
            .get<{ allowed: boolean }>(`${this.base}/check-permission/${permission}`)
            .pipe(map(r => r.allowed));
    }
}
```

---

## 4. Guards Funcionales

```typescript
// src/app/core/guards/support-auth.guard.ts
import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthStore } from '../auth/auth.store';
import { AuthService } from '../auth/auth.service';
import { map, catchError, of } from 'rxjs';

export const supportAuthGuard: CanActivateFn = () => {
    const store  = inject(AuthStore);
    const router = inject(Router);

    if (!store.isAuthenticated()) {
        router.navigate(['/login']);
        return false;
    }

    if (!store.isSupport()) {
        router.navigate(['/unauthorized']);
        return false;
    }

    return true;
};

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

export const adminOnlyGuard: CanActivateFn = () => {
    const store  = inject(AuthStore);
    const router = inject(Router);

    if (!store.isAdmin()) {
        router.navigate(['/unauthorized']);
        return false;
    }
    return true;
};
```

# Angular 18 — Autenticación Portal Cliente (fuse-starter)

> Usa este archivo para el Portal Cliente en Angular 18 con RxJS y módulos tradicionales.
> El portal consume rutas prefijadas con `/api/client/*` y el scope del token es `client`.

---

## 1. Token Storage — sessionStorage

```typescript
// src/app/core/auth/token-storage.service.ts
import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class TokenStorageService {
    private readonly TOKEN_KEY  = 'access_token';

    save(token: string): void {
        sessionStorage.setItem(this.TOKEN_KEY, token);
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

## 2. Auth Interceptor — Inyección de Bearer Token

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

    const authReq = token && req.url.includes('/api/')
        ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
        : req;

    return next(authReq).pipe(
        catchError((error: HttpErrorResponse) => {
            if (error.status === 401 && token) {
                return authService.refresh().pipe(
                    switchMap((newToken) => {
                        tokenStorage.save(newToken);
                        return next(req.clone({
                            setHeaders: { Authorization: `Bearer ${newToken}` },
                        }));
                    }),
                    catchError(() => {
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
```

---

## 3. AuthService — Validación de Permiso Server-Side

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

## 4. Guards de Autenticación

```typescript
// src/app/core/guards/auth.guard.ts
import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthService } from '../auth/auth.service';
import { map, catchError, of } from 'rxjs';

export const authGuard: CanActivateFn = () => {
    const auth   = inject(AuthService);
    const router = inject(Router);

    if (!auth.isAuthenticated()) {
        router.navigate(['/sign-in']);
        return false;
    }

    return auth.checkPermission('authenticated').pipe(
        map(valid => valid || (router.navigate(['/sign-in']), false)),
        catchError(() => { router.navigate(['/sign-in']); return of(false); })
    );
};

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
```

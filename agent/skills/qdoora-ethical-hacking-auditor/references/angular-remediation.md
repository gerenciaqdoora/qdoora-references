# Angular 18/21 — Snippets de Remediación de Seguridad

> Usa este archivo al proponer correcciones frontend para hallazgos del catastro QdoorA.
> Stack: Angular 18 (Portal Cliente) · Angular 21 (Portal Admin/Soporte) · Standalone Components · Signals · RxJS

---

## 1. Guard con Validación Server-Side Asíncrona (Signals + RxJS)
**Remedia**: QD-01 (client-side authorization bypass).

Los Guards clásicos confían en la decodificación local del JWT en `localStorage` para verificar permisos. Esto es vulnerable a manipulación mediante Burp Suite. Enforzamos la re-verificación asíncrona contra la API del backend.

```typescript
// permission.guard.ts
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { map, catchError, of } from 'rxjs';

export const permissionGuard = (requiredPermission: string): CanActivateFn => {
  return () => {
    const auth   = inject(AuthService);
    const router = inject(Router);

    return auth.checkPermission(requiredPermission).pipe(
      map(allowed => {
        if (!allowed) {
          router.navigate(['/unauthorized']);
          return false;
        }
        return true;
      }),
      catchError(() => {
        router.navigate(['/login']);
        return of(false);
      })
    );
  };
};

// app.routes.ts — Aplicar en routing standalone
export const routes: Routes = [
  {
    path: 'admin/parametros',
    loadComponent: () => import('./parametros/parametros.component').then(c => c.ParametrosComponent),
    canActivate: [permissionGuard('manage-settings')],
  },
];
```

```typescript
// auth.service.ts
import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, tap, catchError } from 'rxjs/operators';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  
  // Estado reactivo react-safe del usuario
  readonly currentUser = signal<any | null>(null);

  // ✅ CORRECTO: Consulta dinámica al backend
  checkPermission(permission: string): Observable<boolean> {
    return this.http
      .get<{ allowed: boolean }>(`/api/v1/auth/check-permission/${permission}`)
      .pipe(
        map(r => r.allowed),
        catchError(() => of(false))
      );
  }

  // ❌ EVITAR SIEMPRE: Confiar en JSON descifrado en el navegador
  // hasPermission(p: string): boolean {
  //   const payload = JSON.parse(atob(localStorage.getItem('token')!.split('.')[1]));
  //   return payload.permissions.includes(p);
  // }
}
```

---

## 2. Interceptor HTTP de Seguridad Global
**Remedia**: QD-01 (token injection), QD-08 (manejo de rate limits).

```typescript
// security.interceptor.ts
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { TokenStorageService } from '../services/token-storage.service';

export const securityInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const tokenService = inject(TokenStorageService);
  const token = tokenService.get();

  // Inyectar Bearer token seguro de forma centralizada
  const secureReq = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(secureReq).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) {
        tokenService.clear();
        router.navigate(['/login']);
      }
      
      if (err.status === 403) {
        router.navigate(['/unauthorized']);
      }
      
      if (err.status === 429) {
        // Capturar rate limit (económico/fuerza bruta) y notificar al usuario
        const retryAfter = err.headers.get('Retry-After') || '60';
        console.warn(`Petición bloqueada por exceso de frecuencia. Intentar de nuevo en ${retryAfter} segundos.`);
        // Disparar un Toast o alerta global al usuario...
      }

      return throwError(() => err);
    })
  );
};

// app.config.ts — Registrar en bootstrap
export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withInterceptors([securityInterceptor])),
  ],
};
```

---

## 3. Almacenamiento Seguro de Sesión (`sessionStorage`)
**Remedia**: QD-01 (XSS exfiltration).

`localStorage` persiste indefinidamente y es compartido en todas las pestañas de un mismo origen, lo que aumenta la superficie de ataque ante vulnerabilidades XSS. Forzamos el uso de `sessionStorage`.

```typescript
// token-storage.service.ts
import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class TokenStorageService {
  private readonly TOKEN_KEY = 'access_token';

  save(token: string): void {
    // sessionStorage se limpia automáticamente al cerrar la pestaña/ventana
    sessionStorage.setItem(this.TOKEN_KEY, token);
  }

  get(): string | null {
    return sessionStorage.getItem(this.TOKEN_KEY);
  }

  clear(): void {
    sessionStorage.removeItem(this.TOKEN_KEY);
    sessionStorage.clear();
  }
}
```

---

## 4. Renderizado Seguro — Prohibición Estricta de `[innerHTML]`
**Remedia**: QD-07 (Stored XSS).

Angular desinfecta automáticamente el contenido insertado mediante interpolación estándar `{{ }}`. El uso de `[innerHTML]` bypassa esta protección y ejecuta código JS malicioso persistente.

```typescript
// ❌ VULNERABLE — Ejecuta scripts inyectados en DB
// <div [innerHTML]="parameter.value"></div>

// ✅ 100% SEGURO — Interpolación nativa con sanitización automática
// <div>{{ parameter.value }}</div>

// ✅ Si es estrictamente necesario renderizar HTML formateado (ej. posts de editores controlados)
// se implementa una directiva o componente de saneamiento explícito:
import { Component, input, computed, inject } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Component({
  selector: 'app-safe-rich-text',
  standalone: true,
  template: `<div [innerHTML]="sanitizedContent()"></div>`
})
export class SafeRichTextComponent {
  private readonly sanitizer = inject(DomSanitizer);
  
  // Entrada reactiva (Signal)
  readonly content = input.required<string>();

  // Solo aplicar bypass tras justificar su procedencia y origen controlado
  readonly sanitizedContent = computed((): SafeHtml => {
    return this.sanitizer.bypassSecurityTrustHtml(this.content());
  });
}
```

---

## 5. Formulario de Cambio de Email con Confirmación de Password
**Remedia**: QD-03 (ATO via email change).

```typescript
// email-change.component.ts
import { Component, signal, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ProfileService } from '../../services/profile.service';

@Component({
  selector: 'app-email-change',
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="onSubmit()">
      <div>
        <label>Nuevo Correo Electrónico</label>
        <input formControlName="email" type="email" />
      </div>
      <div>
        <label>Contraseña Actual (Requerida por seguridad)</label>
        <input formControlName="current_password" type="password" />
      </div>
      
      <button type="submit" [disabled]="form.invalid || isLoading()">
        {{ isLoading() ? 'Procesando...' : 'Actualizar Correo' }}
      </button>
      
      @if (errorMessage()) {
        <div class="alert-error">{{ errorMessage() }}</div>
      }
    </form>
  `
})
export class EmailChangeComponent {
  private readonly fb = inject(FormBuilder);
  private readonly profileService = inject(ProfileService);
  
  readonly isLoading = signal(false);
  readonly errorMessage = signal<string | null>(null);

  readonly form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    current_password: ['', [Validators.required, Validators.minLength(6)]]
  });

  onSubmit(): void {
    if (this.form.invalid) return;
    
    this.isLoading.set(true);
    this.errorMessage.set(null);
    
    this.profileService.changeEmail(this.form.getRawValue()).subscribe({
      next: () => {
        // Correo modificado con éxito, mostrar mensaje y limpiar formulario
        this.form.reset();
        this.isLoading.set(false);
      },
      error: (err) => {
        this.errorMessage.set(err.error?.message || 'Error en el servidor.');
        this.isLoading.set(false);
      }
    });
  }
}
```

---

## 6. Separación Dinámica de Portales y Lazy Loading
**Remedia**: QD-06 (cross-portal privilege escalation).

El acceso a rutas privilegiadas y la navegación entre portales (Admin, Soporte, Cliente) se gestiona de forma diferida según el scope retornado por el backend, bloqueando la descarga de componentes no autorizados en el cliente.

```typescript
// portal-router.service.ts
import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class PortalRouterService {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  routeToPortal(): void {
    this.auth.checkPortalScope().subscribe({
      next: (portal) => {
        const routesMap: Record<string, string> = {
          'admin':   '/admin/dashboard',
          'support': '/support/tickets',
          'client':  '/client/dashboard'
        };
        const dest = routesMap[portal] || '/unauthorized';
        this.router.navigate([dest]);
      },
      error: () => this.router.navigate(['/login'])
    });
  }
}

// app.routes.ts — Lazy loading segregado con Guards
export const appRoutes: Routes = [
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(r => r.adminRoutes),
    canActivate: [permissionGuard('portal:admin')]
  },
  {
    path: 'support',
    loadChildren: () => import('./support/support.routes').then(r => r.supportRoutes),
    canActivate: [permissionGuard('portal:support')]
  },
  {
    path: 'client',
    loadChildren: () => import('./client/client.routes').then(r => r.clientRoutes),
    canActivate: [permissionGuard('portal:client')]
  }
];
```

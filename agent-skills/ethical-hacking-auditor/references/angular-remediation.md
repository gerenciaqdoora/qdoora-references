# Angular 18/21 — Snippets de Remediación de Seguridad

> Usa este archivo al proponer correcciones frontend para hallazgos del catastro Qdoora.
> Stack: Angular 18 (Portal Cliente) · Angular 21 (Portal Admin/Soporte) · Standalone Components · Signals

---

## 1. Guard con Validación Server-Side
**Remedia**: QD-01 (client-side authorization bypass).

El problema raíz es que los Guards leen permisos de `localStorage` o del token decodificado
localmente. Esto permite a un atacante manipular la respuesta de login con Burp y obtener acceso.
La solución es validar contra el backend en cada navegación crítica.

```typescript
// auth.guard.ts
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { map, catchError, of } from 'rxjs';

// Factory que crea un guard para un permiso específico
export const permissionGuard = (requiredPermission: string): CanActivateFn => {
  return () => {
    const auth   = inject(AuthService);
    const router = inject(Router);

    return auth.checkPermission(requiredPermission).pipe(
      map(allowed => {
        if (!allowed) { router.navigate(['/unauthorized']); return false; }
        return true;
      }),
      catchError(() => { router.navigate(['/login']); return of(false); })
    );
  };
};

// app.routes.ts — aplicar en rutas sensibles
export const routes: Routes = [
  {
    path: 'admin/liquidaciones',
    loadComponent: () => import('./liquidaciones/liquidaciones.component'),
    canActivate: [permissionGuard('approve-liquidacion')],  // valida server-side
  },
];
```

```typescript
// auth.service.ts — los permisos SIEMPRE vienen del backend
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);

  // ✅ CORRECTO: revalida contra backend
  checkPermission(permission: string): Observable<boolean> {
    return this.http
      .get<{ allowed: boolean }>(`/api/auth/check-permission/${permission}`)
      .pipe(map(r => r.allowed));
  }

  // ❌ INCORRECTO — NUNCA hacer esto:
  // hasPermission(p: string): boolean {
  //   const token = JSON.parse(atob(localStorage.getItem('token')!.split('.')[1]));
  //   return token.permissions?.includes(p) ?? false;
  // }
}
```

---

## 2. Interceptor de Seguridad HTTP
**Remedia**: QD-01 (token injection), QD-08 (manejo de 429).

```typescript
// security.interceptor.ts
import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';

export const securityInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const token  = sessionStorage.getItem('access_token'); // ← sessionStorage, no localStorage

  const secureReq = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(secureReq).pipe(
    catchError((err: HttpErrorResponse) => {
      if (err.status === 401) {
        sessionStorage.clear();
        router.navigate(['/login']);
      }
      if (err.status === 429) {
        // Mostrar mensaje de rate limit al usuario — no reintentar automáticamente
        console.warn('Rate limited. Retry after:', err.headers.get('Retry-After'), 's');
      }
      if (err.status === 403) {
        router.navigate(['/unauthorized']);
      }
      return throwError(() => err);
    })
  );
};

// app.config.ts — registrar interceptor
export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(withInterceptors([securityInterceptor])),
  ],
};
```

---

## 3. Almacenamiento Seguro del Token
**Remedia**: QD-01 (token en localStorage accesible por XSS).

```typescript
// token-storage.service.ts
@Injectable({ providedIn: 'root' })
export class TokenStorageService {
  // ✅ sessionStorage: se limpia al cerrar el tab y no es accesible entre tabs
  // Para mayor seguridad en producción: usar cookies HttpOnly (requiere cambio en backend)
  private readonly KEY = 'access_token';

  save(token: string): void {
    sessionStorage.setItem(this.KEY, token);
    // ❌ NUNCA: localStorage.setItem('token', token)
  }

  get(): string | null {
    return sessionStorage.getItem(this.KEY);
  }

  clear(): void {
    sessionStorage.clear();
  }
}
```

---

## 4. Rendering Seguro — Prohibición de [innerHTML]
**Remedia**: QD-07 (Stored XSS via innerHTML), QD-11 (HTML injection).

```typescript
// ❌ VULNERABLE — ejecuta cualquier script almacenado en la DB
// <div [innerHTML]="company.name"></div>
// <td [innerHTML]="item.description"></td>

// ✅ SEGURO — usar interpolación de Angular siempre
// <div>{{ company.name }}</div>
// <td>{{ item.description }}</td>

// ✅ Si necesitas renderizar HTML controlado (ej: editor de texto rico):
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { computed, input } from '@angular/core';

@Component({
  template: `<div [innerHTML]="safeContent()"></div>`,
})
export class RichTextViewerComponent {
  readonly content = input.required<string>();
  private readonly sanitizer = inject(DomSanitizer);

  readonly safeContent = computed((): SafeHtml =>
    // bypassSecurityTrustHtml SOLO cuando el contenido viene de un editor controlado
    // NUNCA con datos directos de input de usuario no validado
    this.sanitizer.bypassSecurityTrustHtml(this.content())
  );
}
```

**Script para auditar usos peligrosos en el codebase:**
```bash
echo "=== [innerHTML] sin DomSanitizer ==="
grep -rn "\[innerHTML\]" fuse-starter/src/ --include="*.html" | \
  grep -v "safeContent\|safeHtml\|trustHtml"

echo "=== bypassSecurityTrust sin comentario de justificación ==="
grep -rn "bypassSecurityTrust" fuse-starter/src/ --include="*.ts"

echo "=== JWT en localStorage ==="
grep -rn "localStorage.*token\|localStorage.*jwt" fuse-starter/src/ --include="*.ts"
```

---

## 5. Formulario de Cambio de Email con Verificación
**Remedia**: QD-03 (ATO via email change sin current_password).

```typescript
// email-change.component.ts
import { Component, signal, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

@Component({
  standalone: true,
  imports: [ReactiveFormsModule, /* ... */],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      <input formControlName="email" type="email" placeholder="Nuevo email" />
      <input formControlName="current_password" type="password"
             placeholder="Contraseña actual (requerida)" />
      <button type="submit" [disabled]="form.invalid || isLoading()">
        {{ isLoading() ? 'Actualizando...' : 'Cambiar email' }}
      </button>
      @if (error()) { <p class="error">{{ error() }}</p> }
    </form>
  `,
})
export class EmailChangeComponent {
  private readonly fb      = inject(FormBuilder);
  private readonly profile = inject(ProfileService);

  readonly isLoading = signal(false);
  readonly error     = signal<string | null>(null);

  readonly form = this.fb.group({
    email:            ['', [Validators.required, Validators.email]],
    current_password: ['', [Validators.required, Validators.minLength(8)]],
  });

  submit(): void {
    if (this.form.invalid) return;
    this.isLoading.set(true);
    this.error.set(null);
    this.profile.updateEmail(this.form.getRawValue()).subscribe({
      next:     () => { /* mostrar éxito */ },
      error:    (e) => this.error.set(e.error?.message ?? 'Error al actualizar.'),
      complete: () => this.isLoading.set(false),
    });
  }
}
```

---

## 6. Separación de Portales — Carga Dinámica por Rol
**Remedia**: QD-06 (cross-portal privilege escalation).

El Portal Admin y el Portal Soporte son el mismo frontend Angular 21 pero con componentes
cargados condicionalmente según el rol del usuario autenticado. La validación de qué componentes
están disponibles debe venir del backend, no de una condición local.

```typescript
// portal-router.service.ts — decide la ruta raíz según el scope del token
@Injectable({ providedIn: 'root' })
export class PortalRouterService {
  private readonly auth = inject(AuthService);

  navigateToPortal(): void {
    // El scope viene del backend — no del token decodificado localmente
    this.auth.getPortalScope().subscribe(scope => {
      const route = {
        'admin':   '/admin/dashboard',
        'support': '/support/tickets',
        'client':  '/client/dashboard',
      }[scope] ?? '/unauthorized';
      inject(Router).navigate([route]);
    });
  }
}

// Lazy loading por portal — el backend controla qué APIs puede llamar cada scope
const PORTAL_ROUTES: Routes = [
  {
    path: 'admin',
    loadChildren: () => import('./portals/admin/admin.routes'),
    canActivate: [permissionGuard('portal:admin')],
  },
  {
    path: 'support',
    loadChildren: () => import('./portals/support/support.routes'),
    canActivate: [permissionGuard('portal:support')],
  },
  {
    path: 'client',
    loadChildren: () => import('./portals/client/client.routes'),
    canActivate: [permissionGuard('portal:client')],
  },
];
```

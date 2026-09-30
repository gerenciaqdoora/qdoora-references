---
trigger: model_decision
description: Estándares de ingeniería Frontend — Portal Soporte/Admin Angular 21 (support-portal)
---

# 🏢 SUPPORT_RULES.md — Portal Soporte/Admin (Angular 21 · `support-portal`)

> Lee este archivo antes de escribir o revisar cualquier código del Portal de Soporte y Administración (`support-portal`). Aplica ADEMÁS de los principios generales de `CLIENTE_RULES.md` — este portal tiene diferencias arquitectónicas críticas.

---

## ⚡ DIFERENCIAS VS PORTAL CLIENTE (Resumen Ejecutivo)

| Aspecto | Portal Cliente (Angular 18) | Portal Soporte (Angular 21) |
|---------|-----------------------------|-----------------------------|
| Change Detection | Default + Signals | **Zoneless** — SOLO Signals + APIs nativas |
| Zone.js | Presente | **ELIMINADO** |
| Bundler | Webpack/esbuild | **Vite** (aliases con rutas relativas `./`) |
| Estilos | Tailwind v3 | **Tailwind v4 CSS-first** (sin `tailwind.config.js`) |
| Estructura de módulos | `src/app/modules/` | **`src/modules/`** (`app/` solo core/layout) |
| Interceptores | Clase POO | **Funcionales** con `inject()` |
| Alertas | `NotificationService` + `app-shared-alert` | `NotificationService` + **`QdooraAlertService`** |

---

## 🏛️ ARQUITECTURA ZONELESS (Angular 21)

### Detección de Cambios
ESTÁS OBLIGADO a eliminar `zone.js` completamente. La reactividad es responsabilidad **exclusiva** de:
- **Signals** (`signal()`, `computed()`, `effect()`) para estado local y compartido
- **APIs nativas del framework** para eventos de ciclo de vida

```typescript
// ✅ CORRECTO — reactividad con Signals
export class DashboardComponent {
    protected readonly data = signal<DashboardData | null>(null);
    protected readonly isLoading = signal(false);
    protected readonly total = computed(() => this.data()?.items.length ?? 0);

    loadData(): void {
        this.isLoading.set(true);
        this._service.getData()
            .pipe(finalize(() => this.isLoading.set(false)))
            .subscribe(result => this.data.set(result));
    }
}
```

### Vite — Configuración
- Aliases y tipos de importación DEBEN ser estrictamente relativos (`./`)
- PROHIBIDO usar paths absolutos en la configuración de Vite

### Tailwind v4 — CSS-First
```css
/* ✅ CORRECTO — todo en @theme del CSS principal */
@import "tailwindcss";
@theme {
    --color-primary: #1a1a2e;
    --color-accent: #4f46e5;
    --font-sans: 'Outfit', sans-serif;
}

/* ❌ PROHIBIDO — no crear tailwind.config.js */
```

---

## 🔐 SEGURIDAD IAM — ALTA JERARQUÍA

El Portal de Soporte es el activo de mayor riesgo. La seguridad tiene prioridad absoluta sobre la conveniencia funcional.

### Scopes y Aislamiento
- Inyectar `scope: 'support' | 'admin'` en **cada petición** enviada desde este portal.
- El personal de soporte (`scope: 'support'`) **NUNCA** debe acceder a componentes o rutas `admin`.
- PROHIBIDO confiar en el estado local del cliente para la autorización.

### Guards — Validación Server-Side Obligatoria
```typescript
// Guard funcional — validar contra backend en cada navegación crítica
export const adminGuard: CanActivateFn = () => {
    const authService = inject(AuthService);
    const router = inject(Router);

    return authService.checkPermission('/api/auth/check-permission/').pipe(
        map(allowed => allowed || router.createUrlTree(['/unauthorized']))
    );
};
```

### Tokens de Sesión
- **EXCLUSIVAMENTE `sessionStorage`** — la sesión muere al cerrar la pestaña.
- **TERMINANTEMENTE PROHIBIDO** `localStorage` para tokens o estados de permisos.

---

## 🧩 ESTRUCTURA DE MÓDULOS

```
support-portal/src/
├── app/                        # SOLO configuración central
│   ├── core/                   # guards, interceptors, providers
│   └── layout/                 # shell, sidebar, navbar
└── modules/                    # ← TODOS los módulos de vistas aquí
    ├── admin/
    ├── auth/
    └── shared/                 # componentes compartidos del portal
```
**PROHIBIDO** colocar módulos de vistas en `src/app/modules/`. La carpeta `src/app/` se reserva para configuración central.

---

## ⚙️ PATRONES OPERATIVOS

### Interceptores Funcionales (Obligatorio)
```typescript
// ✅ CORRECTO — interceptor funcional Angular 18+
export const authInterceptor: HttpInterceptorFn = (req, next) => {
    const token = inject(AuthService).getToken();
    const scope = inject(AuthService).getScope(); // 'support' | 'admin'

    const authReq = req.clone({
        headers: req.headers
            .set('Authorization', `Bearer ${token}`)
            .set('X-Scope', scope)
    });
    return next(authReq);
};

// ❌ PROHIBIDO — clase interceptora tradicional POO
@Injectable()
export class AuthInterceptor implements HttpInterceptor { ... }
```

### Route Resolvers — Datos Críticos Pre-render
ESTÁS OBLIGADO a cargar datos complejos (PUC, categorías maestras, variables globales) antes del render. PROHIBIDO que un componente administrativo se muestre en estado vacío.
```typescript
// Resolver funcional — datos listos antes de que el componente cargue
export const accountPlanResolver: ResolveFn<AccountPlan[]> = () =>
    inject(AccountingService).getPUC();

// En las rutas
{
    path: 'plan-de-cuentas',
    component: AccountPlanComponent,
    resolve: { accounts: accountPlanResolver }
}
```

### QdooraAlertService — SOLO para Errores Críticos
```typescript
// ✅ CORRECTO — solo para errores que requieren acción explícita del usuario
this._alertService.showAlert({
    appearance: 'border',
    type: 'error',
    message: 'Error crítico que requiere atención del usuario.',
    name: 'component-unique-name'  // identificador único por componente
});

// OBLIGATORIO en ngOnDestroy — previene estados residuales en re-navegación
ngOnDestroy(): void {
    this._alertService.clearAlert('component-unique-name');
}
```

**`AlertMessage` acepta solo**: `appearance`, `type`, `message`, `name`.
Sin timeouts automáticos. Siempre botón close para descarte manual.
PROHIBIDO `[innerHTML]` en el contenedor de alertas — solo `{{ }}`.

### NotificationService — Feedback Pasivo
Mismo patrón que Portal Cliente — para éxito, información o advertencias no bloqueantes.

---

## 🛑 HARD REJECT — Portal Soporte

Autoridad suprema para rechazar código que:
1. Mezcle scopes (`support` accediendo a recursos `admin`)
2. Confíe en estado local del cliente para autorizar acciones administrativas
3. Almacene tokens o permisos en `localStorage`
4. Use `zone.js` o Class-based interceptors
5. Modifique `tailwind.config.js` en lugar de usar el bloque `@theme` del CSS
6. Coloque módulos de vistas en `src/app/modules/` en lugar de `src/modules/`
7. Renderice un componente en estado vacío sin resolver los datos previos (sin Route Resolver)
8. Deje alertas activas sin limpiarlas en `ngOnDestroy` con `clearAlert()`

---

> **Skills de referencia**: `qdoora-ui-ux-master` (sección Portal Soporte) · `qdoora-security-iam-expert`
> `contratos-api`

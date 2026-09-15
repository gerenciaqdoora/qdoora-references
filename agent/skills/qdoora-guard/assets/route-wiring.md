# Dónde se aplica cada guard

El árbol de rutas tiene dos niveles, y cada guard vive en uno concreto. Mezclarlos duplica
verificaciones o deja huecos.

## Nivel 1 — `app.routes.ts`: el módulo contratado

El guard de módulo se aplica **una sola vez**, en el nodo que hace `loadChildren`:

```typescript
{
    path: 'billing',
    canActivate: [hasModuleGuard(['BILLING'])],
    loadChildren: () => import('app/modules/admin/billing/billing.route'),
},
```

`hasModuleGuard` compara contra `User.active_modules` (lo que el suscriptor contrató, tabla
`subscriber_plan_module`). Es el espejo de `authorizeModuleContracted()` del backend.

No lo repitas en las rutas hijas: ya cubrió toda la rama.

## Nivel 2 — `<módulo>.route.ts`: el submódulo y la empresa

Los guards de contexto y de permiso se aplican **por cada hijo**:

```typescript
import { Routes } from '@angular/router';
import { CompanySelectedRequiredGuard } from 'app/core/guards/company-selected-required.guard';
import { hasSubmodulePermissionGuard } from 'app/core/guards/has-submodule-permission.guard';

export default [
    {
        path: '',
        component: BillingComponent,
        children: [
            { path: '', pathMatch: 'full', redirectTo: 'list' },
            {
                path: 'setting',
                component: BillingSettingComponent,
                canActivate: [
                    CompanySelectedRequiredGuard,
                    hasSubmodulePermissionGuard('BILLING.SETTING', 'review'),
                ],
                data: { breadcrumb: 'Configuración' },
            },
        ],
    },
] as Routes;
```

Orden recomendado: primero el contexto (`CompanySelectedRequiredGuard`), después el permiso.
Sin empresa activa no hay matriz de permisos que consultar.

## Convenciones del archivo de rutas

- `export default [...] as Routes` — no una constante nombrada.
- Lazy-load desde `app.routes.ts` con `loadChildren`.
- `data: { breadcrumb: '...' }` en cada hijo.
- El proyecto usa **solo** `canActivate`/`canActivateChild`. No hay ningún `canMatch`.

## Guards de contexto disponibles

| Guard | Verifica |
|---|---|
| `AuthGuard` | Sesión válida (aplicado en el layout padre, no lo repitas) |
| `CompanySelectedRequiredGuard` | Hay empresa activa seleccionada |
| `CompanyCostCenterRequiredGuard` | La empresa tiene centros de costo habilitados |
| `accountPlanRequireGuard` | La empresa tiene plan de cuentas |
| `categoryAccountRequireGuard` | Asociación de categoría contable (abre diálogo si falta) |

## Cómo fallan los guards

Todos devuelven un `UrlTree` (vía `router.parseUrl(...)`), nunca `false`, acompañado de
`NotificationService.show(mensaje, 'warning', [], titulo)`. Devolver `false` deja al usuario
en una pantalla en blanco sin explicación.

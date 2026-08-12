# Arquitectura del Sistema de Tours Guiados — QdoorA

> Snapshot verificado sobre el repo (agosto 2026). Antes de asumir una firma, `grep` el archivo real.

## 1. Capa de datos (PostgreSQL)

Migración única: `qdoora-api/database/migrations/2026_08_06_220000_create_user_tours_table.php`

```
tour_sections                tours                          user_tours
-------------                -----                          ----------
id                           id                             id
key (unique)                 tour_section_id (FK cascade)   user_id (FK users, cascade)
name                         key (unique)                   tour_id (FK tours, cascade)
description (nullable)       title                          completed_at (default now)
icon (nullable)              description (nullable)         unique(user_id, tour_id)
order (default 0)            order (default 0)
timestamps                   is_active (default true)
                             timestamps
```

**Sin `company_id`**: `tour_sections` y `tours` son catálogo global de producto (mismo contenido para todos los tenants). El aislamiento por usuario está en `user_tours`. La regla HARD REJECT #2 (`company_id` forzoso) **no aplica** a este dominio.

Modelos: `app/Models/System/TourSection.php`, `Tour.php`, `UserTour.php`.
- `TourSection::tours()` → `hasMany(Tour)->orderBy('order')`.
- `Tour::section()` / `Tour::userTours()`.

## 2. Capa API (Laravel 11)

`routes/api.php` (dentro del grupo autenticado):

| Método | Ruta | Controller | Uso |
|--------|------|-----------|-----|
| GET | `/v1/tours/sections` | `TourController@sections` | Sidebar de secciones del Centro de Ayuda |
| GET | `/v1/tours/sections/{section_id}/tours` | `TourController@toursBySection` | Tarjetas de tours + flag `is_completed` |
| GET | `/v1/user-tours` | `UserTourController@index` | `data: { completed: [keys del usuario], active: [keys publicadas] }` |
| POST | `/v1/user-tours/complete` | `UserTourController@complete` | Marca `{ tour_key }` como completado |

Servicios:
- `TourService::getSections()` → `TourSection::orderBy('order')->get()` (sin eager load de tours).
- `TourService::getActiveKeys()` → `Tour::where('is_active', true)->pluck('key')`. Es el **catálogo publicado** que el frontend usa para decidir si un tour puede correr.
- `TourService::getToursBySection($sectionId, $userId)` → filtra `is_active = true`, eager-loadea `userTours` del usuario y calcula `is_completed`.
- `UserTourService::getCompletedTours($userId)` → `pluck('tour.key')`.
- `UserTourService::markAsCompleted($userId, $tourKey)` → busca `Tour` por `key`; **si no existe lanza** `"El tour solicitado no se encuentra registrado en el sistema."`; luego `firstOrCreate` sobre `user_tours`.

FormRequests: `Http/Requests/V1/System/CompleteTourRequest.php`, `Http/Requests/System/ListTourSectionRequest.php`, `ListTourBySectionRequest.php`.

## 3. Seeder — catálogo

`qdoora-api/database/seeders/TourSeeder.php`, registrado en `DataSyncCommand` (último del array, junto a `EmergencyAdminSeeder`).

Estructura repetida por módulo:

```php
$interactive<Modulo>Section = TourSection::updateOrCreate(
    ['key' => 'tours-<modulo>'],
    ['name' => '...', 'description' => '...', 'icon' => '...', 'order' => 10|20|30|40|50]
);
$tours = [ ['key' => '...', 'title' => '...', 'description' => '...', 'order' => 1, 'is_active' => true], ... ];
foreach ($tours as $tourData) {
    Tour::updateOrCreate(['key' => $tourData['key']], array_merge($tourData, ['tour_section_id' => $interactive<Modulo>Section->id]));
}
```

Secciones vigentes:

| `key` | Nombre | `order` | Variable PHP | ¿Tiene tours? |
|-------|--------|---------|--------------|---------------|
| `tours-getting-started` | Primeros Pasos | 10 | `$interactiveGettingStartedSection` | Sí (5) |
| `tours-accounting` | Contabilidad | 20 | `$interactiveAccountingSection` | Sí (3) |
| `tours-remuneration` | Remuneraciones | 30 | `$interactiveRemunerationSection` | No — falta `$tours` + `foreach` |
| `tours-billing` | Facturación | 40 | `$interactiveBillingSection` | No — ídem |
| `tours-customs` | Aduana | 50 | `$interactiveCustomsSection` | No — ídem |

`$tours` se **reasigna** en cada bloque: agregar el array sin su `foreach`, o con la variable de sección equivocada, es un fallo silencioso.

## 4. Frontend — núcleo (`fuse-starter/src/app/core/tour/`)

### `tour.types.ts`

```typescript
export interface TourStep {
    element: string;                      // selector CSS, en la práctica siempre '#tour-*'
    popover: {
        title: string;
        description: string;
        side?: 'top' | 'bottom' | 'left' | 'right';
        align?: 'start' | 'center' | 'end';
    };
    onDeselected?: (element?, step?, options?) => void;
    onHighlightStarted?: (element?, step?, options?) => void;
    actionBeforeNext?: () => void;        // se ejecuta al pulsar "Siguiente"
    delayBeforeNext?: number;             // ms de espera antes de avanzar (default 200)
    actionBeforePrev?: () => void;
    delayBeforePrev?: number;
}

export interface TourDefinition {
    key: string;                  // debe coincidir con tours.key en BD
    title: string;
    description: string;
    requiredPermission?: string;  // ver gotcha: hoy solo resuelve 'account-plan.create'
    route: string;                // destino de forceTour() — debe ser navegable
    steps: TourStep[];
}
```

### `tours-registry.ts`

Array constante `TOURS_REGISTRY: TourDefinition[]`. Es la **única** fuente de los pasos; la BD no almacena pasos, solo el catálogo (título/descripción/orden/activo).

### `tour-manager.service.ts` (`providedIn: 'root'`)

- `init()`: GET `/v1/user-tours` → llena el `BehaviorSubject` `_completedTours`. Se invoca desde `app.resolvers.ts` (`initialDataResolver`, dentro del `forkJoin`), es decir **una vez al entrar al layout autenticado**.
- `completedTours$`: observable consumido por el Centro de Ayuda para refrescar el badge "Completado" sin recargar.
- `getAvailableTours()`: filtra el registry por permiso.
- `isPublished(key)`: consulta el `Set` `_activeTourKeys` cargado por `init()`. **Primera validación de `tryStartTour` y `forceTour`**: `TOURS_REGISTRY` define los pasos, pero la BD decide qué corre.
- `tryStartTour(key)`: **no-op silencioso** si (a) no está publicada en BD, (b) ya está en completados, (c) no está en el registry, (d) no pasa `hasPermission`. Es el disparo automático desde `ngAfterViewInit`.
- `forceTour(key)`: **ignora el estado de completado**; resuelve la ruta con `resolveRoute()`, `navigateByUrl()` → `setTimeout(500)` → arranca. Es el disparo del Centro de Ayuda.
- `resolveRoute(route)`: reemplaza tokens dinámicos de la `route` por valores del usuario actual. Hoy resuelve **solo `:company_id`** (→ `currentUser.company.id`) y retorna `null` si el token existe pero no hay empresa activa, para no navegar a una URL rota. Rutas sin token pasan intactas. **Es el único punto de `tour-manager.service.ts` que se extiende** cuando aparece un token nuevo.
- `startDriverTour(tour)`: configura driver.js con `animate: true`, `showProgress: true`, `allowClose: false`, `smoothScroll: true`, botones en español (`Siguiente`/`Anterior`/`Finalizar`), `popoverClass: 'premium-tour-popover'`. Intercepta `onNextClick`/`onPrevClick` para ejecutar `actionBeforeNext`/`actionBeforePrev` y avanzar tras el delay. `onDestroyStarted` → `markTourAsCompleted(key)` + `destroy()`.
- `markTourAsCompleted(key)`: update optimista del subject + POST `/v1/user-tours/complete`.
- `hasPermission(permission?)`: `true` si no hay permiso declarado; caso especial `'account-plan.create'` (exige módulo CONTABILIDAD en `user.active_modules`); **cualquier otro string retorna `true`**.

### Dependencias ya instaladas

- `driver.js@^1.8.0` en `fuse-starter/package.json`.
- `node_modules/driver.js/dist/driver.css` declarado en `angular.json` → `styles`.
- Overrides visuales en `src/styles/styles.scss`: `.premium-tour-popover`, `.driver-popover-title`, `.driver-popover-description`, `.driver-popover-footer`.
- Existe además `core/services/walkthrough.service.ts` (otro wrapper de driver.js). **No lo uses para tours del Centro de Ayuda** — no persiste completado ni consulta el registry.

## 5. Centro de Ayuda — `/general/help-center/guides`

`modules/admin/general/help-center/guides/guides.component.ts|html`

- `ngOnInit` → `getTourSections()` → llena sidebar y activa la primera sección.
- `setSection(key)` → si la sección ya trae `tours` cacheados los usa; si no, `getToursBySection(section.id)` y luego `syncCompletedTours()` (suscripción a `completedTours$`).
- `onTourClick(tour)` → `_tourManager.forceTour(tour.key)`.
- Render: `app-header-premium` + `mat-drawer-container` + `app-section-card`; cada tour es una tarjeta con ícono play/check, badge "Completado" o botón "Empezar". Sección sin tours activos → bloque **"Próximamente"**.
- Tipos en `help-center.type.ts`: `Tour { id, tour_section_id, key, title, description, is_completed? }`, `TourSection { id, key, name, description?, icon?, tours? }`.

## 6. Consumidores actuales (`tryStartTour`)

| Componente | Key | Estado |
|-----------|-----|--------|
| `general/company/create/create.component.ts` | `company-tour` | OK (seeder + registry + anclas) |
| `general/users/create/create.component.ts` | `user-create-tour` | Registry + seeder OK; `route` apunta a `/general/users/create` y la real es `/general/user/create` |
| `general/roles/edit/edit.component.ts` | `role-create-tour` | OK (`/general/roles/create` es ruta real) |
| `general/users/edit/edit.component.ts` | `user-update-tour` | `route` con `:id` → `forceTour` no navega |
| `shared/account-plan-tree-grid/account-plan-tree-grid.component.ts` | `account-plan-tour` | Huérfano: sin registry ni seeder |

Huérfanos solo en seeder (tarjeta visible, clic sin efecto): `tax-list-tour`, `voucher-tour`, `purchase-tour`, `sale-tour`.

## 7. Secuencia de arranque (resumen)

```
Login → initialDataResolver → TourManagerService.init() → GET /v1/user-tours → completedTours[]
   │
   ├── Usuario entra a la vista X
   │      └── ngAfterViewInit → setTimeout(500) → tryStartTour('x-tour')
   │             └── ¿completado? → no-op | ¿en registry? → no-op | OK → driver.drive()
   │
   └── Usuario abre /general/help-center/guides
          └── clic en tarjeta → forceTour('x-tour') → navigateByUrl(route) → setTimeout(500) → driver.drive()

Fin del tour (Finalizar o destroy) → onDestroyStarted → markTourAsCompleted
   → subject optimista + POST /v1/user-tours/complete → UserTour::firstOrCreate
```

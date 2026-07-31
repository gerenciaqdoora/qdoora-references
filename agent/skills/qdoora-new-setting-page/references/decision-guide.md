# Guía de Decisión: Layout de Páginas de Configuración

## ¿Cuándo uso `mat-drawer-container`?

| Señal | Decisión |
|---|---|
| El dominio tiene 2 o más agrupaciones temáticas claramente distintas (ej. Certificado vs Folios CAF; Legales vs Instituciones vs Ausencias; Datos generales vs Permisos por módulo) | **`mat-drawer-container`** con sidebar de navegación |
| El dominio tiene una sola naturaleza de configuración (ej. una vista que solo administra un parámetro o un único formulario) | **NO** uses el drawer — un `app-section-card` o `<section>` simple bajo `app-header-premium` basta |
| Las áreas son muchas (5+) y cada una tiene decenas de campos que conviene ver todas a la vez con scroll | Evalúa `app-vertical-nav`/`app-horizontal-nav` (patrón scroll-spy de `aduana/din/new-edit`) en vez de este blueprint — son problemas distintos |

## Las 4 referencias reales (julio 2026)

| Página | Áreas | Sabor de filtrado | `isAvailableButton` header | Sidebar |
|---|---|---|---|---|
| `nomina/settings` | Legales y Contrato, Instituciones, Ausencias y Permisos (dinámicas, solo se muestran si hay settings de esa categoría) | `signal`/`computed()` — `activeCategory`/`filteredSettings()` | `false` (cada card tiene su propio botón "Guardar Cambios") | Categorías (`categories` fijo, pero `availableCategories()` las filtra por datos reales) |
| `billing/setting` | Certificado Digital, Folios (CAF) (fijas, siempre 2) | Propiedad simple `activeSection: 'CERTIFICADO' \| 'CAF'` | `false` (cada sección tiene sus propios botones de acción) | Áreas fijas (`sections` array literal) |
| `general/roles/edit` | Un módulo contratado por vez (permisos de submódulos) | Propiedad simple `activeSection: string` (código del módulo) | `true` (botón "Guardar" único, global, en el header) | Módulos contratados de la empresa (`data.modules`) |
| `general/users/edit` | Igual que `roles/edit` (mismo componente de edición de permisos) | Igual que `roles/edit` | `true` | Igual que `roles/edit` |

**Conclusión clave**: el `isAvailableButton` del header es el discriminador entre los dos arquetipos:
- **Arquetipo "Ajustes con muchos toggles independientes"** (Nómina, Facturación): guardado por-card, header sin botón.
- **Arquetipo "Edición de una entidad con secciones por área"** (Roles, Usuarios): guardado único global, header con botón "Guardar".

## Contrato real del layout (Angular Material, `MatSidenavModule`)

```html
<div class="flex flex-auto overflow-hidden">
    <mat-drawer-container class="h-full flex-auto bg-transparent" [hasBackdrop]="false">

        <!-- Contenido del área activa -->
        <mat-drawer-content class="flex flex-col overflow-y-auto">
            ...
        </mat-drawer-content>

        <!-- Sidebar de navegación — SIEMPRE a la derecha -->
        <mat-drawer class="w-72 border-r-0 bg-transparent" [mode]="'side'" [opened]="true" [position]="'end'">
            <div class="flex h-full flex-col p-6 pl-0 sm:p-8">
                <div class="bg-card flex flex-col overflow-hidden rounded-3xl border border-l-4 border-gray-200 border-l-blue-600 shadow-xl backdrop-blur-xl dark:border-gray-800">
                    <div class="p-6">
                        <div class="text-secondary mb-6 text-xs font-bold uppercase tracking-widest opacity-60">
                            Áreas <!-- o "Categorías" / "Módulos Contratados" -->
                        </div>
                        <div class="relative flex flex-col space-y-2">
                            @for (item of sections; track item.id) {
                                <button mat-button
                                    class="group relative flex items-center justify-start rounded-xl px-4 py-3 transition-all duration-300"
                                    [ngClass]="{
                                        'bg-blue-50/50 text-blue-600 dark:bg-blue-900/10': activeSection === item.id,
                                        'text-secondary opacity-60 grayscale hover:bg-gray-100 hover:opacity-100 hover:grayscale-0 dark:hover:bg-gray-800': activeSection !== item.id
                                    }"
                                    (click)="setSection(item.id)">
                                    <mat-icon class="mr-4 transition-transform icon-size-5 group-hover:scale-110"
                                        [ngClass]="{ 'text-blue-600': activeSection === item.id }"
                                        [svgIcon]="item.icon"></mat-icon>
                                    <span class="text-sm font-bold tracking-tight">{{ item.label }}</span>
                                </button>
                            }
                        </div>
                    </div>
                </div>
            </div>
        </mat-drawer>

    </mat-drawer-container>
</div>
```

Módulos Angular requeridos: `MatSidenavModule` (para `mat-drawer-container`/`mat-drawer-content`/`mat-drawer`), `MatButtonModule` (`mat-button`), `MatIconModule` (`mat-icon`).

`[hasBackdrop]="false"` y `[mode]="'side'"` + `[opened]="true"` son constantes en las 4 referencias — el sidebar nunca se cierra ni superpone contenido, es un panel fijo.

## `app-header-premium` en páginas de Configuración

Inputs típicos:
```html
<app-header-premium
    [title]="'Configuración de X'"
    [subtitle]="'Descripción breve del alcance'"
    [icon]="'heroicons_outline:cog-6-tooth'"
    [isLoading]="isLoading"
    [isSearchable]="false"
    [isAvailableButton]="false"
    [alertMessage]="alertName">
</app-header-premium>
```

- `isSearchable` casi siempre `false` (no se busca dentro de una página de ajustes).
- `icon`: `heroicons_outline:cog-6-tooth` es el ícono convencional para "Configuraciones" (usado en `nomina/settings`); usa uno más específico del dominio si aplica (ej. `shield-check` para permisos).
- `isLoading`: expón un getter que combine todos los loaders de sub-secciones (`get isLoading() { return this.loadingA || this.loadingB; }`) — no un solo booleano manual que puedas olvidar actualizar.
- `alertMessage`: siempre define un `alertName` único de la página, aunque no dispares alertas de `FuseAlertService` hoy — es la convención para reservar el slot de `app-shared-alert` embebido en el header.

---
name: qdoora-new-setting-page
description: Blueprint one-shot para crear o estandarizar páginas de configuración/ajustes/parámetros en el Portal Cliente de QdoorA (fuse-starter). Cubre app-header-premium como cabecera obligatoria y mat-drawer-container con sidebar de navegación a la derecha para separar "áreas" o "naturalezas" de configuración (ej. Certificado vs Folios CAF, Legales vs Instituciones vs Ausencias). Documenta los dos sabores reales de backend: registro dinámico de features toggleables (trait feature_key/is_active/config JSON) y agregación de sub-recursos independientes bajo una misma vista. Úsala SIEMPRE que el usuario pida crear una nueva vista de "Configuración"/"Ajustes"/"Parámetros", o migrar una vista de settings "a mano" (HTML crudo, sin cabecera estándar) a los componentes compartidos.
---

# QdoorA New Setting Page: Blueprint de Páginas de Configuración

Eres el especialista en construir (o estandarizar) páginas de **Configuración / Ajustes / Parámetros** del Portal Cliente (`fuse-starter`, Angular 18) en **un solo intento**, replicando el patrón real ya validado en producción (Configuraciones de Nómina, Configuración de Facturación Electrónica SII, edición de Roles/Usuarios). Tu objetivo es que nunca más se construya una página de settings con un `<h1>` artesanal y secciones sin cabecera ni navegación entre áreas.

> Esta skill es la contraparte de `qdoora-new-table-page` para vistas que **no son listados paginados**, sino agrupaciones de formularios/ajustes por área temática. Si la vista es una tabla con paginación server-side, usa `qdoora-new-table-page` en su lugar.

## Capacidades

- Genera `*.component.ts` + `.html` completos usando **`app-header-premium`** (cabecera obligatoria: título, subtítulo, spinner de carga) combinada con **`mat-drawer-container`** cuando existen 2 o más "áreas"/"naturalezas" de configuración distintas.
- Decide si la página necesita `mat-drawer-container` (2+ áreas claramente separables) o si un solo `app-section-card`/`<section>` basta (1 sola área — ver Gotcha de sobre-ingeniería).
- Aplica la convención QdoorA del sidebar de navegación: **siempre a la derecha** (`[position]="'end'"`), con la tarjeta visual "estilo DIN" (`rounded-3xl border-l-4 border-l-blue-600 shadow-xl backdrop-blur-xl`).
- Aplica el patrón de **filtrado** (mostrar solo el área activa) en vez de scroll-spy — ver Gotcha de confusión con `app-vertical-nav`/`app-horizontal-nav`.
- Reconoce y documenta los dos sabores de backend de una página de Configuración (ver `references/backend-flavors.md`):
  1. **Registro de features toggleables** (Nómina: `GlobalXFeature` + `XCompanySettings` con `feature_key`/`is_active`/`config` JSON, endpoints `index`/`toggle`/`updateConfig`).
  2. **Agregación de sub-recursos independientes** (Facturación SII: certificado + CAF, cada uno con sus propios endpoints CRUD, sin abstracción común de "feature").

## Flujo de Trabajo

1. **Verifica antes de asumir** (regla #2 de `CLAUDE.md`): `grep_search` sobre `mat-drawer-container`/`app-header-premium` en 2-3 páginas de settings/edición existentes (`nomina/settings`, `billing/setting`, `general/roles/edit`) para confirmar que la convención descrita aquí sigue vigente. Esta skill es un snapshot verificado en julio 2026.
2. **Cuenta las áreas/naturalezas del dominio.** Si hay 2+ agrupaciones temáticas claramente distintas (ej. Certificado vs CAF, Legales vs Instituciones vs Ausencias, Módulo A vs Módulo B) → usa `mat-drawer-container`. Si hay una sola área → no fuerces el drawer, usa un `app-section-card`/`<section>` simple bajo `app-header-premium` (ver Gotcha de sobre-ingeniería).
3. **Arma el esqueleto de layout** (idéntico en las 3 referencias reales):
   ```html
   <div class="bg-card flex min-w-0 flex-auto flex-col dark:bg-transparent sm:absolute sm:inset-0 sm:overflow-hidden">
     <app-header-premium [title]="..." [subtitle]="..." [icon]="..." [isLoading]="isLoading" [isSearchable]="false" [isAvailableButton]="false|true" [alertMessage]="alertName"></app-header-premium>
     <div class="flex flex-auto overflow-hidden">
       <mat-drawer-container class="h-full flex-auto bg-transparent" [hasBackdrop]="false">
         <mat-drawer-content class="flex flex-col overflow-y-auto">...área activa...</mat-drawer-content>
         <mat-drawer class="w-72 border-r-0 bg-transparent" [mode]="'side'" [opened]="true" [position]="'end'">...nav de áreas...</mat-drawer>
       </mat-drawer-container>
     </div>
   </div>
   ```
4. **Decide el sabor del filtrado de áreas**:
   - Áreas fijas y conocidas de antemano (2-3, no dependen de datos del backend) → array estático `{id, label, icon}[]` + propiedad simple `activeSection` (patrón `billing/setting`).
   - Áreas derivadas de una lista dinámica de settings/features que llega del backend (pueden no existir todas para cada empresa) → `signal`/`computed` que filtra `availableCategories` a partir de los datos reales (patrón `nomina/settings`).
5. **Decide el sabor de backend** (ver `references/backend-flavors.md`): registro de features toggleables (nuevo dominio con muchas configuraciones booleanas + JSON config) vs agregación de sub-recursos (2-3 conceptos independientes que ya tendrían sus propios servicios).
6. **`*.component.ts`**: **OBLIGATORIO** — Decorador `@Component()` DEBE incluir:
   ```typescript
   @Component({
       selector: '...',
       standalone: true,
       imports: [...],
       templateUrl: '...',
       encapsulation: ViewEncapsulation.None,
       changeDetection: ChangeDetectionStrategy.OnPush,
       animations: fuseAnimations,
   })
   ```
   Luego define `sections`/`categories`, `activeSection`/`activeCategory`, un getter `isLoading` que combine los loaders de cada sub-sección, y `alertName` para `app-header-premium`. Plantillas completas en `assets/`.
7. **`*.component.html`**: ensambla `app-header-premium` + `mat-drawer-container`, con el contenido de cada área envuelto en `@if (activeSection === 'X') { <section>...</section> }` (o `@for` + `filteredX()` si son dinámicas).
8. **Verifica antes de cerrar la tarea**: `npx tsc -p tsconfig.app.json --noEmit` en `fuse-starter` (y `php -l` si tocaste backend).
9. **Si estableciste un patrón nuevo**: regístralo en las reglas según `AGENT_BASE.md`, sección 5.

## ⚠️ Gotchas (Errores Reales Encontrados)

- **El sidebar de navegación de áreas SIEMPRE va a la derecha.** A diferencia del `mat-sidenav` por defecto de Angular Material (que suele ir a la izquierda), la convención QdoorA en `nomina/settings`, `billing/setting`, `general/roles/edit` y `general/users/edit` es `[position]="'end'"`. No lo pongas a la izquierda "porque es lo estándar de Material" — verifica siempre contra estas 4 referencias reales.
- **No confundas este patrón con `app-vertical-nav`/`app-horizontal-nav`.** Ese es un componente de scroll-spy (todas las secciones renderizadas a la vez, el nav solo hace `scrollIntoView`) usado en formularios largos de un solo registro con muchos campos (ej. `aduana/din/new-edit`). El patrón de Configuraciones/Ajustes es de **filtrado**: solo el área activa se renderiza en el DOM, las demás ni se instancian. Son dos patrones distintos para dos problemas distintos — no los mezcles.
- **No fuerces `mat-drawer-container` si solo hay una naturaleza de configuración.** Si el dominio tiene una sola área temática (ej. una página que solo configura un parámetro), un simple `app-section-card` o `<section>` bajo `app-header-premium` es suficiente — agregar un drawer con un solo botón de navegación es sobre-ingeniería (viola DRY/KISS de `CLAUDE.md`).
- **`isAvailableButton` del header depende del tipo de página.** Si es una página de "ajustes con muchos toggles", cada tarjeta se guarda de forma independiente (botón "Guardar Cambios" dentro de cada card) y el header casi siempre lleva `[isAvailableButton]="false"` (patrón `nomina/settings`, `billing/setting`). Si es la edición de una sola entidad con datos generales + permisos por área (patrón `general/roles/edit`), el botón "Guardar" SÍ va en el header (`[isAvailableButton]="true"`) porque hay un único submit global. Verifica cuál de los dos escenarios aplica antes de decidir.
- **El `is_mandatory`/feature obligatoria no se puede desactivar.** Si documentas o replicas el patrón de features toggleables de Nómina, recuerda que el backend (`NominaSettingsService::toggleFeature`) lanza excepción si `$globalFeature->is_mandatory && !$isActive` — el frontend debe reflejar esto ocultando el `mat-slide-toggle` cuando `setting.is_mandatory` es true (no solo deshabilitarlo).
- **La tarjeta del sidebar sigue el "estilo DIN"**: `bg-card rounded-3xl border border-l-4 border-gray-200 border-l-blue-600 shadow-xl backdrop-blur-xl dark:border-gray-800`, con un label superior en mayúsculas tenue (`text-xs font-bold uppercase tracking-widest opacity-60`) seguido de botones de navegación. Los botones activos usan `bg-blue-50/50 text-blue-600 dark:bg-blue-900/10`; los inactivos, `text-secondary opacity-60 grayscale hover:bg-gray-100 hover:opacity-100 hover:grayscale-0`. No inventes una paleta nueva — reutiliza estas clases.
- **`app-config-card` NO es el precedente real para las tarjetas de cada área.** El catastro de `qdoora-angular-shared-components-expert` lo lista como "tarjeta para vistas de ajustes", pero ninguna de las 4 páginas de referencia (`nomina/settings`, `billing/setting`, `roles/edit`, `users/edit`) lo usa — es un componente colapsable con toggle de "heredar configuración" (para jerarquías empresa/subcuenta) que además usa `*ngIf`/`*ngFor` (viola HARD REJECT #7 de `CLAUDE.md`). Para las tarjetas de área de esta skill, replica el `<section>` con header manual (icono + título + subtítulo) de las plantillas en `assets/` — solo usa `app-config-card` si el dominio realmente necesita herencia empresa→subcuenta y aceptas corregir sus directivas obsoletas primero.
- **No mezcles `qdoora-new-table-page` con esta skill sin necesidad.** Si dentro de una de las áreas de configuración necesitas listar filas (ej. folios CAF, permisos por submódulo), evalúa si conviene migrar esa tabla a `generic-table`/`app-table-without-pagination` — pero eso es una decisión de la otra skill, no fuerces la migración solo porque estás tocando la página (evita el scope creep; hazlo si el usuario lo pide o si la tabla ya viola reglas HARD REJECT).
- **CRÍTICO: Async sin `detectChanges()` con `OnPush`:** Usamos `ChangeDetectionStrategy.OnPush` en toda QdoorA. Si un callback async (dentro de `subscribe`, `finalize`, etc.) actualiza propiedades del componente sin forzar `ChangeDetectorRef.detectChanges()`, Angular NO dispara un ciclo de CD automáticamente — la UI se actualiza recién cuando un evento externo (clic del usuario, setTimeout) dispara un ciclo. **Síntoma**: datos cargados pero no renderizados hasta interactuar con la página. **Fix**: inyecta `ChangeDetectorRef` y llama `this._cdr.detectChanges()` en todo `finalize()` / callback `next`/`error` que mute estado. Ver ejemplo real en `billing/setting.component.ts` (certificado/CAF/conexión SII).
- **Gotcha de testing: `mat-drawer`/`mat-sidenav` lanza `NG05105: Unexpected synthetic listener @transform.start` en `TestBed` aislado.** El `mat-drawer` de Material usa una animación de host (`@transform`) que requiere `BrowserAnimationsModule` o `NoopAnimationsModule` registrado — sin bootstrap completo de la app (que ya trae `provideAnimations()`), cualquier test que instancie un componente con `mat-drawer-container` truena al primer `detectChanges()`. **Fix**: agregar `provideNoopAnimations()` (de `@angular/platform-browser/animations`) a los `providers` del `TestBed.configureTestingModule`, tanto en el spec del componente con el drawer como en el spec de cualquier padre que lo renderice por defecto (ej. un shell cuyo estado inicial ya muestra el drawer). No confundir con el gotcha de `MatIconRegistry` — son dos providers distintos, ambos necesarios si la vista combina `mat-icon` custom + `mat-drawer`.
- **El wrapper exterior (`sm:absolute sm:inset-0 sm:overflow-hidden`) es lo que hace que el header se vea "estándar" — no solo los inputs del `app-header-premium`.** Si envuelves la página en un contenedor centrado y acotado (`max-w-6xl mx-auto p-6`, típico de una vista de formulario simple) en vez del esqueleto full-bleed del paso 3, el `app-header-premium` queda "encajonado" con padding doble y no se ve igual a las referencias aunque los `@Input()` sean idénticos — la diferencia visual está en el contenedor padre, no en el componente de header. Si la página combina un área con patrón de Configuración (ej. un selector de categorías con `mat-drawer-container`) y otra área que sí necesita ancho de lectura acotado (ej. un formulario largo), el `max-w-*` va **dentro** de esa segunda área específica, nunca en el wrapper que contiene el header — de lo contrario el header hereda el acotamiento. Caso real: `emission.component.html` en `/billing/emission` (paso 1 con drawer + paso 2 formulario) — el fix fue mover `max-w-6xl mx-auto` de la `<div>` raíz a solo el `<div>` interno del paso 2.

## Checklist

- [ ] **OBLIGATORIO**: Decorador `@Component()` incluye `ViewEncapsulation.None`, `ChangeDetectionStrategy.OnPush` y `animations: fuseAnimations`.
- [ ] Confirmé con grep que la convención de `app-header-premium` + `mat-drawer-container` sigue vigente en al menos 2 páginas de referencia.
- [ ] Conté las áreas/naturalezas reales del dominio antes de decidir si el drawer es necesario (2+ → sí, 1 → no).
- [ ] El sidebar de navegación está a la derecha (`[position]="'end'"`), con la tarjeta "estilo DIN".
- [ ] El filtrado de áreas es por ocultar/mostrar (`@if`/`filteredX()`), no scroll-spy.
- [ ] Decidí `isAvailableButton` del header según si el guardado es por-card (false) o global (true).
- [ ] Si el dominio es un registro de features toggleables: las obligatorias (`is_mandatory`) no muestran el toggle de desactivar.
- [ ] Cualquier llamada async (`subscribe`, `finalize`) que actualice estado fuerza `ChangeDetectorRef.detectChanges()` al cerrar (crítico con `OnPush`).
- [ ] `npx tsc -p tsconfig.app.json --noEmit` sin errores (y `php -l` si tocaste backend).

## 🚨 Reglas de Oro

- Toda página de Configuración/Ajustes/Parámetros lleva `app-header-premium` como cabecera — nunca un `<h1>`/`<div>` artesanal.
- El sidebar de navegación entre áreas va siempre a la derecha (`position: 'end'`) — es la convención QdoorA, no la de Material por defecto.
- El patrón es de filtrado (una sola área visible a la vez), nunca de scroll-spy — ese es un problema distinto (`app-vertical-nav`).
- No agregues `mat-drawer-container` para una sola área — DRY/KISS primero.

## Referencias Profundas

- **`references/decision-guide.md`**: contrato completo del layout `mat-drawer-container`/`mat-drawer-content`/`mat-drawer`, las 4 páginas reales de referencia y sus diferencias, y la matriz de decisión "1 área vs 2+ áreas".
- **`references/backend-flavors.md`**: los dos sabores de backend (registro de features toggleables vs agregación de sub-recursos independientes) con los endpoints reales de Nómina y Facturación SII.
- **`assets/`**: plantillas copy-paste de `settings.component.ts`/`.html` para ambos sabores (áreas fijas estáticas y áreas dinámicas por signal/computed).

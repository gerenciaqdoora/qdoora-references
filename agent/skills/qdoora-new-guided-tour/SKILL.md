---
name: qdoora-new-guided-tour
description: Blueprint one-shot para crear, refinar o auditar tours guiados (walkthroughs con driver.js) del Portal Cliente de QdoorA (fuse-starter), los que se listan y disparan desde el Centro de Ayuda en `/general/help-center/guides`. Cubre el ciclo completo de 6 pasos - analizar el flujo real de la ruta, proponer e iterar las secciones con el usuario (HARD STOP), registrar el tour en `TourSeeder.php`, registrarlo en `tours-registry.ts`, anclar los `id="tour-*"` en el HTML y disparar `tryStartTour()` en `ngAfterViewInit`, y entregar el comando `php artisan db:seed --class=TourSeeder`. Úsala SIEMPRE que el usuario pida "crear un tour", "agregar un tour guiado", "hacer un walkthrough/onboarding" de una pantalla, "mejorar/refinar el tour de X", o pregunte por qué un tour no arranca o no aparece en el Centro de Ayuda.
---

# QdoorA New Guided Tour: Blueprint de Tours Guiados

Eres el especialista en construir **tours guiados interactivos** (driver.js) para el Portal Cliente (`fuse-starter`, Angular 18) en un solo intento, replicando el patrón real ya en producción (`company-tour`, `user-create-tour`, `role-create-tour`, `user-update-tour`).

Un tour de QdoorA vive en **cinco lugares simultáneos**. Si falta uno, el tour falla en **silencio** (sin error de consola, sin excepción): no aparece en el Centro de Ayuda, no arranca solo, o arranca y no resalta nada. Tu trabajo es cerrar los cinco.

| # | Lugar | Archivo | Qué aporta | Si falta |
|---|-------|---------|------------|----------|
| 1 | Catálogo BD | `qdoora-api/database/seeders/TourSeeder.php` | **Publica** el tour: sin fila activa en `tours` el tour no existe para el sistema | El tour **no arranca en absoluto** (ni automático ni desde el Centro de Ayuda) y tampoco se lista |
| 2 | Definición de pasos | `fuse-starter/src/app/core/tour/tours-registry.ts` | `route` + array de `steps` | El clic en la tarjeta del Centro de Ayuda no hace **nada** (`forceTour` hace `return` mudo) |
| 3 | Anclas DOM | `<vista>.component.html` | `id="tour-*"` que driver.js resalta | driver.js no encuentra el elemento y el paso se salta/descuadra |
| 4 | Disparo automático | `<vista>.component.ts` → `ngAfterViewInit` | Primera vez que el usuario entra a la pantalla | El tour solo existe en el Centro de Ayuda, nunca es proactivo |
| 5 | Ejecución del seeder | `php artisan db:seed --class=TourSeeder` | Materializa (1) en la BD del entorno | Todo lo anterior compila pero el tour no existe en runtime |

> Contexto arquitectónico completo (tablas, endpoints, servicios, ciclo de vida de `driver.js`) en `references/tour-architecture.md`.
> Cómo redactar los pasos y decidir cuántos son, en `references/step-authoring-guide.md`.

## Capacidades

- Analiza una ruta del Portal Cliente y **deduce las secciones didácticas** reales del flujo (no inventa pasos: los deriva del HTML y del formulario existentes).
- Propone e itera con el usuario las secciones del tour **antes** de escribir una sola línea de código.
- Genera el registro en `TourSeeder.php` (tour nuevo en sección existente, o sección nueva completa).
- Genera la entrada de `TOURS_REGISTRY` con `route` verificada contra las rutas reales de Angular.
- Inserta las anclas `id="tour-*"` en el HTML sin alterar el layout ni las clases Tailwind existentes.
- Cablea `tryStartTour('<key>')` en `ngAfterViewInit` con el `setTimeout(500)` estándar.
- Refina tours existentes (reordenar, reescribir copy, agregar/quitar pasos, arreglar anclas rotas).
- Audita el drift entre seeder ↔ registry ↔ componente (tours huérfanos en cualquiera de los tres lados).

## Flujo de Trabajo — 6 Pasos Obligatorios

### 1. Analizar el tour

Antes de proponer nada, **lee el flujo completo** de la ruta objetivo (regla #2 de `CLAUDE.md` — prohibición de suposiciones):

- Ubica la ruta real: `grep` en `fuse-starter/src/app/app.routes.ts` y en el `*.route.ts` del módulo. **Anota la ruta literal** — la usarás en el paso 4 y es la fuente #1 de tours rotos.
- Lee el `component.html` completo: identifica los contenedores lógicos (`app-section-card`, tarjetas `bg-card rounded-2xl`, sidebars, `mat-drawer`), qué está detrás de un `@if` y qué se renderiza siempre.
- Lee el `component.ts`: `initForm()` (qué campos son obligatorios), resolvers de la ruta (¿la data ya viene precargada?), estado que condiciona bloques (`activeSection`, `sectionType`, `isEdit`).
- Verifica si **ya existe** un tour para esa ruta: `grep` de la ruta en `tours-registry.ts` y `grep` de `tryStartTour` en el componente.
  - **Existe** → modo *refinar*: parte del tour actual, no lo reescribas de cero.
  - **No existe** → modo *crear*.
- Verifica que los `id="tour-*"` que pienses usar no colisionen con otros ya presentes en el DOM (`grep -rn 'id="tour-'` en `fuse-starter/src/app`).

### 2. Proponer secciones — 🛑 HARD STOP

Presenta al usuario la propuesta de secciones **en texto plano, sin escribir código todavía**, con esta tabla:

| # | Sección | Ancla (`id`) | `side` | Qué explica al usuario |
|---|---------|--------------|--------|------------------------|

Cada fila debe declarar: el bloque real del HTML al que se anclará, el título del popover, la idea del copy y por qué ese paso aporta valor. Adjunta las **decisiones abiertas** (ej. "¿incluimos el bloque de Certificado Digital, que solo aparece si el módulo está activo?").

**DETENTE COMPLETAMENTE aquí.** No toques ningún archivo hasta que el usuario apruebe o corrija la propuesta. Itera cuantas veces sea necesario. Criterios de una buena propuesta en `references/step-authoring-guide.md` (regla de 3-6 pasos, orden = flujo de llenado real, copy en español que explique el *por qué*).

### 3. Backend — registrar en `TourSeeder.php`

Archivo: `qdoora-api/database/seeders/TourSeeder.php`. Plantilla: `assets/tour-seeder-entry.php.template`.

- **Sección existente** (`tours-getting-started`, `tours-accounting`, `tours-remuneration`, `tours-billing`, `tours-customs`): agrega un elemento al array `$tours` **del bloque de esa sección** y asigna el `order` siguiente.
- **Sección sin tours aún** (`tours-remuneration`, `tours-billing`, `tours-customs` hoy solo declaran el `TourSection`): debes agregar **tanto** el array `$tours` **como** su `foreach` apuntando a la variable `$interactive<Modulo>Section` correcta.
- **Sección nueva**: `TourSection::updateOrCreate(['key' => 'tours-<modulo>'], [...])` con `icon` (Heroicons `heroicons_outline:*`/`heroicons_solid:*` o ligadura Material como `money`, `receipt_long`) y `order` en múltiplos de 10.
- `key` en **inglés kebab-case** y **idéntica** a la del registry. `title`/`description` en **español** (son texto de usuario final, regla #3 de `CLAUDE.md`).
- El seeder es idempotente por diseño (`updateOrCreate` sobre `key`): re-ejecutarlo actualiza, no duplica. Nunca borres tours existentes ni cambies una `key` ya publicada (rompe los `user_tours` históricos).

### 4. Frontend — registrar en `tours-registry.ts`

Archivo: `fuse-starter/src/app/core/tour/tours-registry.ts`. Plantilla: `assets/tour-registry-entry.ts.template`.

- `key`: **exactamente** la misma del seeder.
- `route`: la ruta **real y navegable** que anotaste en el paso 1. `forceTour()` hace `navigateByUrl(tour.route)` — si la ruta no existe o contiene un placeholder `:id`, la navegación falla y el tour nunca arranca desde el Centro de Ayuda.
- `steps[]`: un objeto por sección aprobada, con `element: '#tour-*'` y `popover { title, description, side }`.
- Si un paso depende de un bloque que solo aparece tras un clic, usa `actionBeforeNext` + `delayBeforeNext` (y su par `actionBeforePrev`/`delayBeforePrev` para que el retroceso también funcione). Patrón real: `user-update-tour`.
- **No declares `requiredPermission`** salvo que extiendas `hasPermission()` en `tour-manager.service.ts`: hoy ese método solo resuelve `'account-plan.create'` y devuelve `true` para cualquier otro valor (falso sentido de seguridad).

### 5. Anclar el HTML y disparar en `ngAfterViewInit`

**5a. Anclas** en `<vista>.component.html`: agrega `id="tour-<dominio>-<bloque>"` al **contenedor** de cada sección, sin tocar clases ni estructura.

```html
<!-- Sobre un componente compartido: el id se aplica al elemento host -->
<app-section-card id="tour-info-basica" [title]="'INFORMACIÓN BÁSICA'" ...>
<!-- Sobre un div contenedor -->
<div id="tour-user-personal" class="w-full">
```

**5b. Disparo** en `<vista>.component.ts` — patrón canónico de `general/users/create/create.component.ts`. Plantilla: `assets/component-afterviewinit.ts.template`.

> **Antes de elegir el hook**, mira de dónde viene la data de la vista: si usa **resolvers de ruta**, `ngAfterViewInit` + `setTimeout(500)` es correcto. Si carga **asíncrono en `ngOnInit`** (`forkJoin`, `subscribe`) y el contenido está tras un `@if`, dispara dentro del `subscribe` con flag `_tourStarted` + condición sobre la data (ver Gotchas).
>
> **Si el componente sirve más de una ruta** (mismo componente en `''` y en `generar/:id`, por ejemplo), el disparo debe elegir la key según el estado que las distingue — reutiliza el getter que ya usa el template:
> ```typescript
> const tourKey = this.is_available_crud ? 'account-plan-tour' : 'account-plan-clone-tour';
> ```

```typescript
import { AfterViewInit, inject } from '@angular/core';
import { TourManagerService } from 'app/core/tour/tour-manager.service';

export class MiVistaComponent implements AfterViewInit {
    private _tourManagerService = inject(TourManagerService);

    ngAfterViewInit(): void {
        // Ejecutamos el tour con un pequeño retraso para asegurar que la vista esté completamente renderizada
        setTimeout(() => {
            this._tourManagerService.tryStartTour('mi-tour-key');
        }, 500);
    }
}
```

Declara `implements AfterViewInit` en la clase (si ya implementa `OnInit`/`OnDestroy`, encadénalos). No cambies la estrategia de detección de cambios ni el resto del componente.

### 6. Sembrar la base de datos

`php artisan db:seed` es un **comando sensible** (`CLAUDE.md` §2): **no lo ejecutes con auto-run**. Entrégalo siempre al cierre bajo el título **"Comandos a ejecutar"**:

```bash
# Comandos a ejecutar (en orden):
# 1. Registrar el nuevo tour en el catálogo del Centro de Ayuda
cd qdoora-api && php artisan db:seed --class=TourSeeder
```

Si el usuario te autoriza explícitamente a ejecutarlo en esa misma conversación, hazlo y reporta la salida real. Si falla (BD abajo, contenedor detenido), reporta el error textual y vuelve a entregar el comando — nunca declares la tarea completa asumiendo que corrió.

### Verificación de cierre

- `cd fuse-starter && npx tsc -p tsconfig.app.json --noEmit`
- `php -l qdoora-api/database/seeders/TourSeeder.php`
- Repasa el checklist de más abajo (los 5 lugares cerrados).

## ⚠️ Gotchas (Errores Reales Verificados en el Repo)

- **🔴 `route` desalineada = tour muerto y mudo.** `forceTour()` navega literal a `tour.route`; si la ruta no existe, la promesa se resuelve sin navegar y el `setTimeout` arranca driver.js sobre la pantalla equivocada (o sobre ninguna ancla). Caso real vigente: el registry declara `/general/users/create` y `/general/users/edit/:id`, pero la ruta real de Angular es **`/general/user/...`** (singular, `app.routes.ts` → `path: 'user'`). **Siempre copia la ruta desde el `*.route.ts`, nunca la deduzcas del nombre de la carpeta.**
- **🔴 Un placeholder en `route` deja la vista sin datos.** Angular **sí matchea** `edit/:id` contra el segmento literal `:id` (un param acepta cualquier segmento), así que la navegación no falla: el componente carga con `id = ':id'`, el `parseInt` da `NaN` y la API responde vacío o 404. El síntoma no es "no pasa nada", es "la pantalla abre en blanco y el tour resalta anclas que no existen". Tres salidas, en orden de preferencia:
  1. **Token soportado**: `:company_id` se resuelve solo — `TourManagerService.resolveRoute()` lo reemplaza por `user.company.id` antes de navegar, y aborta si no hay empresa activa. Úsalo tal cual en el `route` (caso real: `master-account-assignated-tour`).
  2. **Un id estático y siempre válido**, si el dominio tiene uno: `account-plan-clone-tour` apunta a `/accounting/account-plan/generar/0` porque `0` = PUC existe siempre.
  3. **La ruta de listado** del módulo, para que el usuario elija el registro.
  Si necesitas un token nuevo (`:user_id`, etc.), agrégalo a `resolveRoute()` — es el único lugar donde tocar `tour-manager.service.ts` está permitido, porque cierra un hueco estructural en vez de acomodar un tour puntual.
- **🔴 Vista sin resolver = el `setTimeout(500)` puede ganarle a la data.** Si el componente carga con `forkJoin`/`subscribe` dentro de `ngOnInit` (no con resolvers de ruta) y la tabla está tras un `@if`, el disparo estándar de `ngAfterViewInit` corre antes de que existan las anclas y driver.js resalta la nada. En ese caso **dispara dentro del `subscribe`**, después del `markForCheck()`, con dos guardas: un flag `_tourStarted` (los métodos de recarga suelen re-ejecutarse tras cada acción del usuario) y una condición sobre el largo de la data. Caso real: `master-account-assignated-tour` en `master-accounts-review.component.ts`.
- **🔴 Tour en el seeder pero no en el registry → tarjeta fantasma.** Se lista en `/general/help-center/guides` con botón "Empezar", y el clic no hace nada (`forceTour` → `find()` sin match → `return`). Huérfanos vigentes: `tax-list-tour`, `voucher-tour`, `purchase-tour`, `sale-tour`.
- **🔴 La BD publica; el registry solo define los pasos.** `TourManagerService` valida `isPublished(key)` contra el catálogo activo (`tours` con `is_active = true`) que `GET /v1/user-tours` entrega en `data.active`. Un tour declarado en `TOURS_REGISTRY` pero **no sembrado o desactivado no arranca**, ni automático ni desde el Centro de Ayuda. Consecuencia práctica: **el paso 6 (ejecutar el seeder) no es opcional** — hasta que corra, el tour no existe en runtime por más que compile. El guard es **fail-closed**: si `init()` falla por red, `_activeTourKeys` queda vacío y ningún tour corre.
  *(Antes de este guard, un tour no publicado sí arrancaba, el POST de completado fallaba y el tour reaparecía en cada sesión indefinidamente. Si ves ese síntoma en un entorno viejo, el fix es este.)*
- **Elemento tras un `@if` = paso invisible.** driver.js resuelve `document.querySelector` en el momento del paso. Si el bloque está oculto tras estado (`@if (activeModule)`), o lo revelas con `actionBeforeNext` (clic programático + `delayBeforeNext: 250`, patrón de `user-update-tour`), o lo sacas del tour.
- **El tour automático se dispara una sola vez por usuario.** `tryStartTour` corta si la `key` está en `completedTours` (cargado por `TourManagerService.init()` desde el `initialDataResolver`). Para re-probar: borra la fila en `user_tours` o dispáralo desde el Centro de Ayuda (`forceTour` ignora el estado de completado).
- **Cerrar el tour cuenta como completarlo.** `onDestroyStarted` llama a `markTourAsCompleted` siempre. Con `allowClose: false` el usuario debe llegar al final, pero cualquier destrucción del driver marca el tour como visto. No agregues pasos "de relleno": no habrá segunda oportunidad automática.
- **El `id` va en el contenedor, no en el input.** Anclar sobre `<app-input-form>` resalta un control diminuto y descuadra el popover. Ancla el `<div>`/`<app-section-card>` que agrupa el bloque conceptual.
- **`$tours` se reutiliza entre bloques del seeder.** Cada sección redefine `$tours` y corre su propio `foreach` con `$interactive<Modulo>Section`. Agregar el array sin su `foreach` (o con la variable de sección equivocada) inserta cero tours o los inserta en la sección incorrecta — sin error visible.
- **Sección sin tours activos** muestra el bloque "Próximamente" en el Centro de Ayuda. Es el estado esperado de `tours-remuneration`, `tours-billing` y `tours-customs` hoy.
- **`tours` y `tour_sections` son tablas globales, sin `company_id`.** Es intencional (catálogo de producto, no dato de tenant); la regla HARD REJECT #2 de multi-tenancy **no aplica** aquí. El aislamiento por usuario vive en `user_tours` (`user_id` + `tour_id`, único).
- **No toques el CSS.** `driver.css` ya está en `angular.json` y `.premium-tour-popover` / `.driver-popover-*` están definidos en `src/styles/styles.scss`. Un tour nuevo no requiere una sola línea de estilos.
- **`requiredPermission` es casi decorativo.** `hasPermission()` solo tiene lógica para `'account-plan.create'` (valida módulo CONTABILIDAD) y retorna `true` para cualquier otra cadena. Si necesitas gating real, extiende el método explícitamente.

## Checklist

- [ ] Leí la ruta real en `app.routes.ts` + `*.route.ts` y **copié la ruta literal** (no la deduje).
- [ ] Revisé si ya existía un tour para esa vista (refinar en vez de duplicar).
- [ ] Presenté la tabla de secciones y **esperé aprobación explícita** antes de editar archivos.
- [ ] `TourSeeder.php`: entrada agregada en el bloque de la sección correcta, con su `foreach` presente y el `order` siguiente.
- [ ] `tours-registry.ts`: `key` idéntica a la del seeder y `route` navegable (sin `:id`, sin plural inventado).
- [ ] Cada `element` del registry tiene su `id="tour-*"` real y único en el HTML.
- [ ] Los pasos que dependen de bloques `@if` usan `actionBeforeNext`/`delayBeforeNext` (y su par `Prev`).
- [ ] `ngAfterViewInit` + `setTimeout(..., 500)` + `tryStartTour('<key>')`, con `implements AfterViewInit` declarado.
- [ ] Copy en español, `key` en inglés kebab-case.
- [ ] `npx tsc -p tsconfig.app.json --noEmit` y `php -l` sin errores.
- [ ] Comando `php artisan db:seed --class=TourSeeder` entregado bajo **"Comandos a ejecutar"** (o ejecutado con autorización explícita y salida reportada).

## 🚨 Reglas de Oro

- **Nunca cierres la tarea con el tour registrado en menos de los 5 lugares.** Un tour a medias no falla: se queda mudo, y nadie lo nota hasta que un cliente reclama.
- **Nunca escribas código antes de que el usuario apruebe las secciones** (paso 2 es HARD STOP).
- **Nunca ejecutes `php artisan db:seed` con auto-run** (`CLAUDE.md` §2) — entrégalo.
- **Nunca cambies la `key` de un tour ya publicado**: los `user_tours` existentes quedan huérfanos y el tour reaparece para todos.
- **Nunca modifiques `tour-manager.service.ts`, `tour.types.ts` ni el CSS de driver.js** para acomodar un tour puntual: resuelve con anclas, `side` y `actionBefore*`.

## Referencias Profundas

- **`references/tour-architecture.md`**: arquitectura completa (tablas `tour_sections`/`tours`/`user_tours`, endpoints `/v1/tours/*` y `/v1/user-tours/*`, `TourManagerService`, ciclo `tryStartTour` vs `forceTour`, render del Centro de Ayuda).
- **`references/step-authoring-guide.md`**: cómo diseñar y redactar los pasos — cuántos, en qué orden, qué `side`/`align` elegir, cómo escribir el copy y cómo tratar bloques condicionales.
- **`assets/`**: plantillas copy-paste del bloque de seeder, la entrada del registry y el `ngAfterViewInit` del componente.

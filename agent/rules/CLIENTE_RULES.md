---
trigger: model_decision
description: Estándares de ingeniería Frontend — Portal Cliente Angular 18 (fuse-starter)
---

# 🎨 CLIENTE_RULES.md — Portal Cliente (Angular 18 · `fuse-starter`)

> Lee este archivo antes de escribir o revisar cualquier código del Portal Cliente (`fuse-starter`).

---

## ⚡ ARQUITECTURA MODERNA (Non-Negotiable)

- **Standalone Components**: 100% sin NgModules. Cada componente es completamente autosuficiente.
- **Control Flow**: `@if`, `@for`, `@switch` SIEMPRE. **TERMINANTEMENTE PROHIBIDO** `*ngIf`/`*ngFor`.
- **Signals**: Usa Signals para reactividad granular y estados de UI locales.
- **Interceptores**: Funcionales (Angular 18+ style con `inject()`), no clases POO.

### Reutilización — REGLA DE ORO
ANTES de crear cualquier componente, revisar exhaustivamente `/app/modules/shared`.

Componentes clave disponibles:
- `app-input-form` — inputs de formulario
- `app-table` — tablas con paginación
- `app-header-premium` — headers de sección (**USAR SIEMPRE, `app-header` está OBSOLETO**)
- `app-dialog-header` / `app-dialog-footer` — estructura de modales
- `app-shared-alert` — alertas bloqueantes
- `app-period-picker` — selector de periodo

**PROHIBIDO** reinventar componentes existentes.

---

## 💎 DISEÑO PREMIUM QDOORA

Cada pantalla debe generar un impacto visual inmediato. PROHIBIDO entregar diseños genéricos o planos.

- **Tipografía**: Outfit o Space Grotesk. PROHIBIDO fuentes por defecto del navegador.
- **Espacio negativo**: Generoso, composiciones asimétricas limpias.
- **Profundidad**: Gradientes sutiles, `backdrop-blur`, transparencias en capas.
- **Dashboard Bento Grid**:
```css
/* grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 */
/* KPIs → tarjetas individuales */
/* Gráfico principal → col-span-2 row-span-2 */
/* Panel de estado del módulo → columna lateral integrada */
```

---

## 🔐 SEGURIDAD DEL LADO DEL CLIENTE

- **XSS (QD-07)**: **TERMINANTEMENTE PROHIBIDO** `[innerHTML]` con datos dinámicos. Solo `{{ }}`.
- **Sesión**: Token **SOLO en `sessionStorage`**. PROHIBIDO `localStorage`.
- **Contratos**: Sincronizar tipos con Backend usando `api-contract-aligner` antes de escribir interfaces TypeScript.
- **Guards**: Revalidar permisos contra backend en navegaciones críticas. No confiar solo en el JWT decodificado.

---

## ⚙️ PATRONES OPERATIVOS OBLIGATORIOS

### Memory Leaks (RxJS)
```typescript
private _unsubscribeAll: Subject<any> = new Subject<any>();

ngOnInit(): void {
    this._service.getData()
        .pipe(takeUntil(this._unsubscribeAll))
        .subscribe(data => this.data = data);
}

ngOnDestroy(): void {
    this._unsubscribeAll.next(null);
    this._unsubscribeAll.complete();
}
```

### Loading States (determinista)
```typescript
this._service.save(payload)
    .pipe(
        finalize(() => this.isLoading = false) // limpia en éxito Y en error
    )
    .subscribe({ next: () => {...}, error: () => {...} });
```

### Errores HTTP
```typescript
// En servicios — SIEMPRE usar ErrorHandler
return this._http.get<T>(url).pipe(
    catchError((error) => this._errorHandler.handle(error))
);

// En componentes — tipar como JsonResponse<any>, NUNCA HttpErrorResponse
.subscribe({
    error: (err: JsonResponse<any>) => this._notifications.error(err.message)
    // NUNCA: err?.error?.message (frágil ante cambios de estructura)
});
```

### Integridad de Contratos (FormRequest → TypeScript)
Al modificar un FormRequest en Backend:
1. Identifica el endpoint y controlador afectado
2. Busca (`grep_search`) los servicios Angular que consumen ese endpoint
3. Actualiza las Interfaces TypeScript:
   - `required` → campo obligatorio
   - `nullable` → campo `optional?`
   - `numeric` → `number`

### Formularios multi-variante (selección de tipo → sub-bloques por sub-FormGroup)

Patrón descubierto en el rediseño de `billing/emission` (11 tipos de DTE, jul-2026): cuando un formulario cambia de forma según un tipo elegido por el usuario (documento, categoría, etc.), **no** crear un componente por variante duplicando el tronco común. En su lugar:

1. Un **shell único** (el componente orquestador) mantiene el `FormGroup` raíz con TODOS los sub-grupos posibles como controles fijos (`this.form = fb.group({ ..., bloqueA: fb.group({...}), bloqueB: fb.group({...}) })`), nunca añadidos/quitados dinámicamente con `addControl`/`removeControl` — así `form.getRawValue()`/`.value` siempre tiene forma estable y ningún consumidor (payload de submit) se rompe según el tipo activo.
2. Cada bloque variante es un **componente standalone Reactive Forms** que recibe su sub-`FormGroup` por `@Input() group!: FormGroup` (patrón `[formGroup]="group"` + `formControlName` internos) — nunca `ngModel` suelto.
3. El shell decide **qué bloques renderizar** (`@if (isTipoX) { <bloque-x [group]="xGroup" /> }`), pero el control del `FormGroup` siempre existe — el `@if` solo oculta UI, no invalida datos.
4. Al armar el payload final, leer siempre desde los getters del sub-group (`this.xGroup.value`), nunca desde propiedades planas del componente — evita que la migración a Reactive Forms cambie accidentalmente la forma de lo que se envía al backend.
5. Paso 1 (selector de tipo) vive en un componente separado (`@Output() selected` emite el tipo elegido); el shell guarda el tipo en un `signal` y hace `@if (!tipoElegido()) { <selector /> } @else { <shell-paso-2 /> }` en la MISMA ruta — evita duplicar guards/resolvers de ruta solo para un flujo de 2 pasos.

**Gotcha de testing**: `mat-icon` con `[svgIcon]` custom (heroicons_outline/etc.) lanza `"Unable to find icon"` en tests aislados (`TestBed`) porque el registro de iconos solo se puebla en el bootstrap completo de la app. Mockear `MatIconRegistry` en el `TestBed` (`getNamedSvgIcon: () => of(svgElement)`) en vez de tocar config global de test. Además: los spies de Jasmine declarados en el `describe` (no en `beforeEach`) acumulan historial de llamadas entre tests — llamar `spy.calls.reset()` en `beforeEach` antes de aserciones tipo `not.toHaveBeenCalled()`.

**Gotcha de UX — el paso 1 (selector) SIEMPRE necesita estado vacío**: cuando el paso 1 depende de una lista que llega por HTTP (`@Input() documents`), el gating `@if (loading) {...} @else if (!tipoElegido()) { <selector> } @else {...}` oculta silenciosamente cualquier fallo de datos (backend devuelve `[]`, un filtro cliente descarta todo, o la petición falla y el catch solo dispara un toast transitorio) detrás de una pantalla en blanco sin explicación — el diseño previo (formulario único siempre visible) toleraba esto porque el resto del formulario seguía ahí; el shell de 2 pasos no. **Regla**: todo componente selector de paso 1 debe exponer un `@if (hasAnyDocs) {...} @else { <empty-state con mensaje + acción> }` explícito — nunca dejar que un `@for` sobre una lista vacía sea el único fallback visual. Caso real: `emission-type-selector.component.ts` en `/billing/emission` quedaba en blanco cuando `core_documents.can_emit_dte` no estaba poblado en el ambiente (ver [[BACKEND_RULES.md]] sección `can_emit_dte`); el fix fue el empty-state, no un cambio de datos.

**Gotcha crítico — `app-qdoora-smart-select` guarda el OBJETO completo, no el escalar**: a diferencia de un `<select formControlName="x"><option [ngValue]="opt.id">`, `app-qdoora-smart-select` setea el FormControl con el **objeto completo** elegido de `[allOptions]` (confirmado en `crearCabecera.component.ts:273: client: formData.client?.id` — el consumidor real extrae `.id` al armar el payload, nunca asume un escalar). `[primaryKey]`/`[show_atribute_option]` solo controlan comparación y display, NO qué se guarda. Al migrar un `<select>` nativo a este componente:
1. El control retiene su valor inicial (escalar u `null`) hasta que el usuario interactúa; tras eso pasa a ser el objeto — **doble forma posible**, no solo una.
2. En cualquier punto donde se lea `.value` para armar un payload o pasarlo a un servicio, hay que desenvolverlo con un helper tipo `unwrap(val, key) => typeof val === 'object' ? val[key] ?? null : val` — nunca asumir que sigue siendo un escalar. Ver `emission.component.ts::unwrap()` (aplicado en `submit()` y en la suscripción a `valueChanges` de `reference_venta_id` antes de pasarlo a `loadChainPreview`).
3. Los campos derivados de `<option>` estáticos (sin `[allOptions]` previo) necesitan convertirse a un array `readonly` de `{code, label}` — el componente no soporta `<option>` proyectado.
4. Escribe un test que simule la interacción REAL (patch con el objeto completo, no con el escalar) — un test que solo hace `patchValue({ campo: 5 })` nunca ejercita el `unwrap()` y puede dar falso verde mientras el payload real se rompe en producción.

**Patrón "crear entidad inline desde el smart-select" (`needAddItem`)**: para replicar el flujo de creación de cliente/proveedor de `formulario-cabecera.component.ts` (`/accounting/sale/create`) en otro selector de `ThirdCompany`: `[needAddItem]="true"` + `[labelAddItem]="'Crear cliente'"` + `(addItem)="onCreateClient()"` en el smart-select, y en el handler abrir `FormularioEntidadDialogComponent` (`app/dialog/formulario-entidad/`) con un `DialogThirdCompany` — `countries: []` es suficiente, el diálogo se autocarga los países vía `CompanyService.getCountries()` cuando detecta que `data.countries`/`data.identification_documents` no vienen completos (no hace falta prefetch en el componente padre). Al cerrar (`afterClosed()`), si `response?.record` existe: anteponer el nuevo registro a la lista y `setValue()` sobre el control para autoseleccionarlo. Ver `emission.component.ts::onCreateClient()`.

**Extensión (jul-2026) — reutilizar el mismo handler en modo edición**: cuando una validación de negocio bloquea el submit porque el registro YA elegido le falta un campo (ej. Factura sin `giro` en el cliente — ver [[BACKEND_RULES.md]] sección Factura 33), generaliza la firma a `onCreateClient(existing?: ThirdCompany)`: si `existing?.id` viene, pasa `is_new_record: false, info: existing` al `DialogThirdCompany` (el dialog ya soporta modo edición vía `initEditMode()`) y, al cerrar, **reemplaza** el registro en la lista (`map` por id) en vez de anteponerlo. El flujo típico es: `submit()` detecta el campo faltante leyendo el OBJETO completo que ya guarda el smart-select (no un fetch adicional — ver el Gotcha de `unwrap()` arriba), dispara un `NotificationService.warning(...)` y llama `this.onCreateClient(counterpartyObj)` en el mismo click, evitando un viaje de ida y vuelta.

**Eliminación de catálogo/mantenedor de un dialog de captura de línea**: al quitar la dependencia de un catálogo (`app-select-with-filter` + `needAddItem` hacia un dialog "crear producto") de un formulario de captura rápida (ej. `item-emision-dialog`), el único control que normalmente llevaba `Validators.required` apuntando al catálogo debe eliminarse por completo (no dejarlo opcional) — los campos que antes se prellenaban desde el catálogo (nombre, precio) pasan a ser inputs manuales con sus propios validators. El campo `product_id`/`producto_id` que consume el backend se fija en `null` en el resultado, preservando el contrato existente (el backend ya lo trataba como opcional). Ver `item-emision-dialog.component.ts::buildResult()`.

**Actualización (jul-2026) — paso 1 migrado al patrón `qdoora-new-setting-page`**: `emission-type-selector.component.ts` reemplazó el grid de cards agrupadas por familia (apiladas verticalmente) por el estándar `mat-drawer-container` de [[qdoora-new-setting-page]]: categorías fijas (Ventas/Notas/Guía/Exportación) en un `mat-drawer` a la derecha (`[position]="'end'"`), contenido filtrado por categoría activa a la izquierda. Las 4 categorías se muestran **siempre**, incluso con 0 documentos (badge "Próx." en el botón), para que una futura habilitación de `can_emit_dte` aparezca sin tocar UI — y el empty-state ahora es de dos niveles: por-categoría ("todavía no hay documentos en esta categoría") y global (ningún documento habilitado en absoluto). Como el shell (`emission.component.ts`) ya trae su propio `app-header-premium` con título/subtítulo/botón volver, el sub-componente de selección **no duplica el header** — solo implementa `mat-drawer-container`/`mat-drawer`/`mat-drawer-content`, evitando doble cabecera en la misma vista.

---

## 🧩 COMPONENTES DE UI — ESTÁNDARES

### Headers (SIEMPRE `app-header-premium`)
```html
<app-header-premium
    [title]="'Nombre del Módulo'"
    [isSearchable]="true"
    [isAvailableButton]="true"
    [buttonLabel]="'Nueva acción'"
    (action)="onAction()"
    (search)="onSearch($event)">
    <!-- Filtros adicionales alineados a la derecha -->
    <div filters>
        <app-period-picker></app-period-picker>
    </div>
</app-header-premium>
```

### Formateo de Montos Monetarios (SIEMPRE `formatAmount`)
Para renderizar valores monetarios, usar exclusivamente el pipe personalizado `formatAmount` importado desde `app/core/pipes/format-amount.pipe`. Este pipe maneja correctamente los separadores de miles y decimales según la configuración regional para CLP.
**PROHIBIDO** usar el pipe nativo de Angular `number` (ej. `number:'1.0-0'`) o el pipe `currency`.
```html
<!-- Correcto -->
<span>{{ monto | formatAmount }}</span>

<!-- PROHIBIDO -->
<span>{{ monto | number:'1.0-0' }}</span>
```

### Notificaciones Pasivas (`NotificationService`)
Para feedback de éxito, advertencias o errores no bloqueantes. Apila alertas simultáneamente sin destruir las anteriores. **PROHIBIDO** `MatSnackBar` nativo.
```typescript
this._notificationService.success('Registro guardado correctamente.');
this._notificationService.warning('Revisa los campos antes de continuar.');
this._notificationService.error(err.message);
```
El contenedor usa `pointer-events: none` · las alertas usan `pointer-events: auto`.
Inyectar texto SOLO con `{{ }}` — nunca `[innerHTML]` (vector QD-07).

### Alertas Bloqueantes (`app-shared-alert`)
Para decisiones destructivas o advertencias que requieren acción explícita del usuario. Captura el foco e impide continuar sin interactuar.

### Diálogos (`MatDialog`) — Estructura Obligatoria
```html
<div class="standard-dialog-container relative">
    <app-dialog-header
        title="Título del modal"
        subtitle="Descripción opcional"
        [showCloseButton]="true">
    </app-dialog-header>
    <div class="standard-dialog-content">
        <!-- contenido del modal -->
    </div>
    <app-dialog-footer>
        <!-- botones de acción -->
    </app-dialog-footer>
</div>
```
Al abrir el diálogo: `panelClass: 'dialog-panel'` con `padding: 0 !important`.
`.mdc-dialog__surface` debe mantener `overflow: hidden !important` globalmente.
PROHIBIDO aplicar márgenes negativos (`-m-6`) para corregir espacios.

### Descargas y Archivos Asíncronos (`SecureTabService`)
SIEMPRE para abrir/descargar documentos tras peticiones HTTP. Evita el bloqueo de popups en navegadores modernos.
```typescript
// 1. SYNC — en el hilo inmediato del clic del usuario
const tab = this._secureTabService.open(); // inyecta loader animado

// 2. ASYNC — cuando el servidor responde
try {
    const url = await lastValueFrom(this._api.getDocument(id));
    tab.redirect(url);
} catch (err: any) {
    tab.close(); // cierra limpiamente si el backend falla
    this._notificationService.error(err.message);
}
```

---

## 🛑 HARD REJECT — Frontend Cliente

Autoridad suprema para rechazar código que:
1. Cree un componente sin revisar primero `/app/modules/shared`
2. Use `*ngIf`/`*ngFor` en lugar de `@if`/`@for`
3. Use `[innerHTML]` con datos dinámicos del servidor
4. Almacene tokens o estados de sesión en `localStorage`
5. Use `MatSnackBar` nativo en lugar de `NotificationService`
6. Abra descargas asíncronas sin `SecureTabService`
7. Use `<app-header>` obsoleto en lugar de `<app-header-premium>`

---

> **Skills de referencia**: `angular-developer` · `angular-shared-components-expert`
> `qdoora-ui-ux-master` (sección Portal Cliente) · `api-contract-aligner`

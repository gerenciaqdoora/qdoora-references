---
name: qdoora-new-table-page
description: Blueprint one-shot para crear o estandarizar páginas de listado (list.component) en el Portal Cliente de QdoorA (fuse-starter). Cubre app-header-premium como cabecera obligatoria, generic-table para tablas paginadas con server-side (Laravel FormRequest + Service con trait PaginatesResults + Angular BehaviorSubject) y app-table-without-pagination para catálogos acotados sin paginación de backend. Úsala SIEMPRE que el usuario pida crear una nueva vista de tabla/listado, migrar un listado "a mano" (HTML crudo) a los componentes compartidos, o agregar búsqueda/orden server-side a un endpoint de listado existente.
---
# QdoorA New Table Page: Blueprint de Páginas de Listado

Eres el especialista en construir (o estandarizar) páginas de listado del Portal Cliente (`fuse-starter`, Angular 18) en **un solo intento**, replicando el patrón real ya validado en producción (Empleados, Previred, Documentos Electrónicos SII). Tu objetivo es que nunca más se reescriba una tabla HTML cruda ni se invente un `@Input` que no existe.

> Esta skill es la extensión práctica de `angular-shared-components-expert` (que dice QUÉ componentes existen) hacia el CÓMO ensamblarlos en una página real, incluyendo el lado Laravel del server-side.

## Capacidades

- Genera `list.component.ts` + `.html` completos usando **`app-header-premium`** (cabecera obligatoria: título, subtítulo, buscador, botón de acción) combinada con:
  - **`generic-table`** — tablas con paginación **server-side** (datasets que crecen sin límite práctico).
  - **`app-table-without-pagination`** — tablas **sin paginación de backend** (catálogos/configuración acotada).
- Genera el patrón backend Laravel completo para listados paginados: `FormRequest` (page/size/search/sort/order) → `Controller` delgado → `Service` con `trait PaginatesResults` (búsqueda + whitelist de orden).
- Decide el tipo de tabla correcto según la naturaleza del dataset (ver `references/decision-guide.md`).
- Mapea columnas a los tipos ya soportados por los componentes compartidos (`multiline`, `badge`, `salary`, `badges`, pipes `date`/`formatAmount`/`rutFormat`/`capitalizeFormat`) **sin modificar los componentes compartidos**.
- Aplica las reglas HARD REJECT de `CLAUDE.md` al listado (multi-tenant, RUT formateado, sin editar/eliminar registros históricos inmutables).

## Flujo de Trabajo

1. **Verifica antes de asumir** (regla #2 de `CLAUDE.md`): `grep_search` sobre `generic-table`/`app-table-without-pagination` en 2-3 list.component.ts existentes similares al dominio que vas a construir, para confirmar que los `@Input`/`@Output` documentados aquí siguen vigentes. Esta skill es un snapshot verificado en julio 2026 — no un contrato inmutable.
2. **Elige el tipo de tabla** (detalle completo en `references/decision-guide.md`):
   - Dataset que puede crecer sin límite práctico (ventas, DTE, empleados, comprobantes, declaraciones) → **`generic-table`** + paginación server-side.
   - Catálogo o configuración acotada, sin endpoint de paginación real (impuestos de empresa, parámetros, tipos fijos) → **`app-table-without-pagination`**.
3. **Si es `generic-table` y el backend solo soporta `page`/`size`**, extiende el server-side siguiendo `references/generic-table-server-side.md`:
   - `FormRequest`: agrega `search` (`nullable|string`), `sort` (`nullable|string|in:<whitelist>`), `order` (`nullable|string|in:asc,desc`).
   - `Controller`: extrae los 3 query params y los pasa al Service (nunca lógica de negocio en el controlador).
   - `Service`: `use PaginatesResults;` — aplica `search` con `whereRaw('LOWER(col) LIKE ?', ...)` (columnas propias) o `whereHas(...)` (relaciones), y pasa `$sort/$order` + un array `$allowedSorts` a `paginateQuery()`.
4. **Angular Service**: patrón `BehaviorSubject` + Observables (`entities$`, `pagination$`), método `list(page, size, search, sort, order)` con `tap()` que actualiza ambos subjects. Plantilla en `assets/paginated-service.ts.template`.
5. **Api HTTP client**: agrega `search`/`sort`/`order` a los `HttpParams` de la llamada `GET` existente.
6. **`list.component.ts`**: **OBLIGATORIO** — Decorador `@Component()` DEBE incluir:
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
   Luego arma columnas, mapea estados a las etiquetas ya soportadas por el badge estándar (ver Gotcha de paleta de colores), aplana cualquier campo anidado (`client.rut` → `client_rut`) antes de pasarlo a `[lista]`/`[dataSource]`, y define si el dominio permite editar/eliminar. Plantillas completas en `assets/`.
7. **`list.component.html`**: ensambla `app-header-premium` + `generic-table`/`app-table-without-pagination`, agregando `ng-template #customActions` (solo en `generic-table`) o `customTemplates` (solo en `app-table-without-pagination`) si se necesitan celdas o acciones no estándar.
8. **Verifica antes de cerrar la tarea**: `npx tsc -p tsconfig.app.json --noEmit` en `fuse-starter` y `php -l` en cada archivo backend tocado.
9. **Si estableciste un patrón nuevo** (una variante de columna, un nuevo gotcha): invoca `technical-scribe-documentarian` para que lo registre.

## ⚠️ Gotchas (Errores Reales Encontrados)

- **La key de columna del front puede no ser el nombre de columna real en BD.** `generic-table` emite el `sort` literal de `column.key` (o `column.key_column.subkey` si hay `subkey`). Si difieren (ej. columna `folio` en front vs `dte_folio` en BD), crea un diccionario `SORT_KEY_MAP` en el componente y tradúcelo en `onRefreshLista()` **antes** de llamar al Service. No asumas que coinciden.
- **Una columna con `subkey` cambia el `sort_active` emitido** a `key_subkey` (ej. `employee_code_profile`). Evita marcar como "ordenable en serio" una columna con `subkey` salvo que el backend soporte explícitamente ese join — de lo contrario el clic en el header no hace nada (falla silenciosa, no error).
- **El `type: 'badge'` de `generic-table` tiene una paleta FIJA** de literales en español: verde (`COMPLETADO`/`ACTIVO`/`APROBADO`), rojo (`ERROR`/`INACTIVO`/`RECHAZADO`), azul (`PROCESANDO`/`EN_PROCESO`/`ENVIADO`), ámbar (`PENDIENTE`/`BORRADOR`), cualquier otro string cae a gris por defecto. **Traduce tu enum/estado real a una de esas etiquetas en el componente consumidor — nunca modifiques `table.component.html` para inventar un color nuevo.**
- **Ni `generic-table` ni `app-table-without-pagination` acceden a objetos anidados de la misma forma.** `app-table-without-pagination` SÍ soporta dot-notation (`'concept.name'`) vía `getNestedValue()`. `generic-table` NO: `dataRow[column.key]` es acceso directo. Para `generic-table`, aplana los campos anidados (`client.rut` → `client_rut`) en el componente/servicio antes de pasarlos a `[lista]`.
- **`app-table-without-pagination` con `customTemplates` y formularios por fila** necesita una key única por fila (`row._formKey` o similar) para indexar los `FormGroup` — el dataset no tiene paginación que lo proteja de renderizar cientos de forms sueltos, así que úsalo solo para catálogos realmente acotados.
- **Registros históricos inmutables** (Facturación, Contabilidad, Nómina cerrada, Aduana): `[useEdit]="false" [useDelete]="false"` en `generic-table` — nunca ofrezcas editar/eliminar un DTE, comprobante contable confirmado, liquidación pagada o DIN despachado (regla HARD REJECT #6 de `CLAUDE.md`). Usa `customActions` para acciones puntuales de solo-lectura (ej. "Ver PDF").
- **RUT sin formatear**: usa `pipe: 'rutFormat'` (columna directa) o `subkeyPipe: 'rutFormat'` (columna `multiline`) — nunca interpoles el RUT crudo.
- **No inventes props**: `generic-table` NO tiene `[data]`/`[totalItems]`/`(pageChange)` (esos nombres aparecen en documentación vieja/incorrecta en otros assets) — sus inputs reales son `[lista]`/`[pagination]`/`[columns]` y su output de refresco es `(refresh)`. Verifica siempre contra `app/modules/shared/table/table.component.ts`.
- **CRÍTICO: Async sin `detectChanges()` con `OnPush`:** Usamos `ChangeDetectionStrategy.OnPush` en toda QdoorA. Si un callback async (dentro de `subscribe`, `finalize`, etc.) actualiza propiedades del componente sin forzar `ChangeDetectorRef.detectChanges()`, Angular NO dispara un ciclo de CD automáticamente — la UI se actualiza recién cuando un evento externo (clic del usuario, setTimeout) dispara un ciclo. **Síntoma**: datos cargados pero no renderizados hasta interactuar con la página. **Fix**: inyecta `ChangeDetectorRef` y llama `this._cdr.detectChanges()` en todo `finalize()` / callback `next`/`error` que mute estado. Ver ejemplo real en `billing/setting.component.ts` (certificado/CAF/conexión SII).

## Checklist

- [ ] **OBLIGATORIO**: Decorador `@Component()` incluye `ViewEncapsulation.None`, `ChangeDetectionStrategy.OnPush` y `animations: fuseAnimations`.
- [ ] Confirmé con grep los `@Input`/`@Output` reales de `generic-table` o `app-table-without-pagination` antes de escribir código.
- [ ] Elegí el tipo de tabla según si el backend pagina de verdad o es un catálogo acotado.
- [ ] Si extendí el backend: `FormRequest` + `Controller` + `Service` (`PaginatesResults`, `search`, whitelist de `sort`) — filtro `company_id` presente.
- [ ] El Angular Service sigue el patrón `BehaviorSubject`/`tap()` (no un simple `map()` sin estado, salvo que la página no necesite compartir estado).
- [ ] Los campos anidados están aplanados antes de llegar a `generic-table`.
- [ ] Los estados se tradujeron a una etiqueta ya soportada por el badge estándar (o se documentó que cae a gris).
- [ ] La key de columna sorteable coincide con el campo real del backend (o hay un `SORT_KEY_MAP`).
- [ ] `useEdit`/`useDelete` están en `false` si el dominio es un registro histórico inmutable.
- [ ] Cualquier llamada async (`subscribe`, `finalize`) que actualice estado fuerza `ChangeDetectorRef.detectChanges()` al cerrar (crítico con `OnPush`).
- [ ] `npx tsc -p tsconfig.app.json --noEmit` y `php -l` sin errores.

## 🚨 Reglas de Oro

- Nunca inventes un `@Input`/`@Output`: verifica siempre contra el código real de `generic-table` / `app-table-without-pagination` (regla #2 `CLAUDE.md`).
- Nunca modifiques `table.component.ts/html` o `table-without-pagination.component.ts/html` para acomodar un caso puntual — transforma los datos en el componente/servicio consumidor.
- Nunca actives paginación server-side para un catálogo acotado, ni renuncies a ella para un dataset que crece indefinidamente.
- Toda página de listado lleva `app-header-premium` como cabecera — nunca un `<h1>`/`<div>` artesanal.

## Referencias Profundas

- **`references/decision-guide.md`**: cuándo usar `generic-table` vs `app-table-without-pagination`, contrato completo de `@Input`/`@Output` de ambos, paleta de colores del badge estándar.
- **`references/generic-table-server-side.md`**: patrón full-stack completo (Laravel `PaginatesResults` + Angular `BehaviorSubject`) con el caso real de Documentos Electrónicos SII (`/billing/list`).
- **`assets/`**: plantillas copy-paste de `list.component.ts`/`.html` (paginado y sin paginación) y del bloque backend `FormRequest`/`Controller`/`Service`.

# Patrón Full-Stack: `generic-table` con Paginación Server-Side

Caso real documentado: extensión del listado de Documentos Electrónicos SII (`/billing/list`), que originalmente solo soportaba `page`/`size`, para agregar `search`/`sort`/`order` — igual al patrón ya usado en Empleados (`EmployeeService`) y Previred (`PreviredService`).

Todo el ciclo vive en 5 capas. Ninguna capa se salta.

---

## 1. Backend — `FormRequest`

```php
public function rules(): array
{
    return [
        'page' => ['sometimes', 'integer', 'min:0'],
        'size' => ['sometimes', 'integer', 'min:1', 'max:100'],
        'search' => ['sometimes', 'nullable', 'string', 'max:100'],
        'sort' => ['sometimes', 'nullable', 'string', 'in:id,dte_folio,date,total,sii_status'],
        'order' => ['sometimes', 'nullable', 'string', 'in:asc,desc'],
    ];
}
```

La whitelist de `sort` (`in:...`) debe coincidir EXACTAMENTE con el array `$allowedSorts` que le pasarás a `paginateQuery()` en el Service (paso 3). Si no coinciden, un valor pasa la validación pero el Service lo ignora silenciosamente (no es un bug, es el comportamiento esperado de `paginateQuery`, pero mantenlos sincronizados para que la whitelist tenga sentido).

## 2. Backend — `Controller` (ultraligero, sin lógica de negocio)

```php
public function index(DteListRequest $request, int $company_id)
{
    $user = Auth::guard('api')->user();
    try {
        $page = (int) $request->query('page', 0);
        $size = (int) $request->query('size', 15);
        $search = (string) $request->query('search', '');
        $sort = (string) $request->query('sort', 'id');
        $order = (string) $request->query('order', 'desc');

        $data = $this->electronicDocumentService->listEmittedSales($company_id, $page, $size, $search, $sort, $order);

        return jsonResponse(['records' => $data['records'], 'pagination' => $data['pagination']], 200, 'Ok');
    } catch (\Throwable $e) {
        return $this->handleError->logAndResponse($e, $request, LoggerOperation::LISTAR, LoggerEvent::SII_DTE, $user);
    }
}
```

## 3. Backend — `Service` (`trait PaginatesResults`)

```php
use App\Traits\PaginatesResults;

class ElectronicDocumentService
{
    use PaginatesResults;

    public function listEmittedSales(
        int $companyId, int $page, int $size,
        string $search = '', string $sort = 'id', string $order = 'desc'
    ): array {
        $query = Venta::where('company_id', $companyId)   // filtro multi-tenant SIEMPRE primero
            ->whereNotNull('dte_folio')
            ->with(['document', 'client']);

        if ($search !== '') {
            $query->where(function ($q) use ($search) {
                $q->whereRaw('CAST(dte_folio AS TEXT) LIKE ?', ['%'.$search.'%'])   // columna numérica propia: cast a texto
                    ->orWhereHas('client', function ($sub) use ($search) {          // relación: whereHas + whereRaw LOWER+LIKE
                        $sub->whereRaw('LOWER(full_name) LIKE ?', ['%'.strtolower($search).'%'])
                            ->orWhereRaw('LOWER(rut) LIKE ?', ['%'.strtolower($search).'%']);
                    })
                    ->orWhereHas('document', function ($sub) use ($search) {
                        $sub->whereRaw('LOWER(name) LIKE ?', ['%'.strtolower($search).'%']);
                    });
            });
        }

        $result = $this->paginateQuery($query, $page, $size, $sort, $order, ['id', 'dte_folio', 'date', 'total', 'sii_status']);
        $result['records'] = DteDocumentResource::collection($result['records']);

        return $result;
    }
}
```

`PaginatesResults::paginateQuery()` (ubicado en `app/Traits/PaginatesResults.php`) hace `count()` → `orderBy($sort, $order)` SOLO si `$sort` está en `$allowedSorts` → `skip()->take()->get()` → arma `pagination` (`length`, `size`, `page`, `lastPage`, `startIndex`, `endIndex`, todo 0-indexed en `page`/`lastPage`).

**Gotcha de tipos de columna**: si el campo buscable es numérico (`dte_folio` es `unsignedInteger`), Postgres no permite `LOWER()` sobre un entero — castea a texto: `CAST(col AS TEXT) LIKE ?`. Si el campo es texto (`full_name`, `rut`, `name`), usa `LOWER(col) LIKE ?` con el término también en minúsculas (patrón ya usado en `EmployeeService`).

**Alternativa con joins** (cuando necesitas ordenar/buscar por una columna de una relación, ej. `employee_code` de `EmployeeProfile`): revisa `EmployeeService::getEmployeesList()` — usa `leftJoin` + `orderBy` explícito en vez de `paginateQuery()`, porque el whitelist simple no soporta columnas de tablas unidas. Es más código pero es el patrón ya aceptado para ese caso.

## 4. Frontend — Api HTTP client

```ts
public listDte(companyId: number, page = 0, size = 15, search = '', sort = 'id', order = 'desc'): Observable<JsonResponse<any>> {
    let params = new HttpParams().set('page', page).set('size', size).set('sort', sort).set('order', order);
    if (search) {
        params = params.set('search', search);
    }
    return this._httpClient.get<JsonResponse<any>>(this._baseApi.setUrl(`${this.prefix(companyId)}/dte`), {
        headers: this._baseApi.setHeadersJson(), params
    });
}
```

## 5. Frontend — Angular Service (estado compartido con `BehaviorSubject`)

Patrón idéntico a `EmployeeService`/`PreviredService`: el Service guarda el último listado y su paginación como estado observable, no solo los devuelve de paso. Esto permite que el componente se suscriba una vez en `ngOnInit` y no tenga que re-mapear la respuesta cruda cada vez.

```ts
private _documents: BehaviorSubject<DteDocument[] | null> = new BehaviorSubject(null);
private _pagination: BehaviorSubject<Pagination | null> = new BehaviorSubject(null);

get documents$(): Observable<DteDocument[] | null> { return this._documents.asObservable(); }
get pagination$(): Observable<Pagination | null> { return this._pagination.asObservable(); }

listDte(page = 0, size = 15, search = '', sort = 'id', order = 'desc'): Observable<DteDocument[]> {
    return this._siiApi.listDte(this.requireCompany(), page, size, search, sort, order).pipe(
        tap((res) => {
            this._pagination.next(res?.data?.pagination ?? null);
            this._documents.next(res?.data?.records ?? []);
        }),
        map((res) => res?.data?.records ?? [])
    );
}
```

## 6. Frontend — `list.component.ts` (piezas clave, plantilla completa en `assets/`)

- Suscríbete a `pagination$` en `ngOnInit` (actualiza `this.pagination` + `markForCheck()` si usas `OnPush`).
- Expón `documents$` como el `documents$.pipe(map(...))` del Service, aplicando el aplanado de campos anidados + la traducción de estado a etiqueta de badge (ver `decision-guide.md`).
- `onRefreshLista(event)` recibe `{ pagination_pageIndex, pagination_pageSize, sort_active, sort_direction }` de `(refresh)` — aplica el `SORT_KEY_MAP` si la key de columna no coincide con el campo real del backend (Gotcha #1 del `SKILL.md`).
- `buscarEnLista(query)` (conectado al `(search)` de `app-header-premium`) resetea a página 0 y reusa el sort/order actuales.

```ts
onRefreshLista(event: any): void {
    const sortKey = event.sort_active
        ? (BillingListComponent.SORT_KEY_MAP[event.sort_active] ?? event.sort_active)
        : this.currentSort;
    this.loadDocuments(event.pagination_pageIndex, event.pagination_pageSize, this.searchQuery, sortKey, event.sort_direction || this.currentOrder);
}
```

---

## Checklist de verificación de esta capa

- [ ] `FormRequest.rules()['sort']` (`in:...`) coincide con `$allowedSorts` del Service.
- [ ] El filtro `company_id` está en la query ANTES de aplicar `search` (multi-tenant primero, siempre).
- [ ] Los campos numéricos usan `CAST(col AS TEXT)`, los de texto usan `LOWER(col) LIKE ?` con el término en minúsculas.
- [ ] El Angular Service expone `entities$`/`pagination$` reactivos, no solo un método que retorna un array plano.
- [ ] El componente traduce `sort_active` de vuelta al campo real del backend si difieren los nombres.

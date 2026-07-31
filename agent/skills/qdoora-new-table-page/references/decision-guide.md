# Guía de Decisión: generic-table vs app-table-without-pagination

## ¿Cuándo usar cuál?

| Señal | `generic-table` | `app-table-without-pagination` |
|-------|------------------|----------------------------------|
| El dataset puede llegar a cientos/miles de filas | ✅ | ❌ |
| El backend ya pagina (o vale la pena que pague) | ✅ | ❌ |
| Es un catálogo/configuración fija (impuestos de empresa, tipos de documento, parámetros) | ❌ | ✅ |
| Necesitas ordenar por columna (`mat-sort-header`) | ✅ (server-side) | ❌ (no tiene sort integrado) |
| Necesitas un footer con totales/resúmenes | ❌ (no tiene footer) | ✅ (`showFooter`, `footerLeftLabel/Value`, `footerRightLabel/Value`) |
| Necesitas un formulario por fila (auto-save inline) | Posible pero incómodo | ✅ (patrón validado: `company-tax-list`) |

Regla rápida: si dudas, pregúntate *"¿este listado puede crecer sin que nadie lo controle?"* — si sí, `generic-table`. Si es una lista que el propio negocio mantiene acotada (tipos de impuesto, monedas, parámetros), `app-table-without-pagination`.

---

## Contrato real: `generic-table`

Fuente: `fuse-starter/src/app/modules/shared/table/table.component.ts`

```ts
@Input() lista: any[];
@Input() pagination: Pagination;              // app/core/models/common/table
@Input() isLoading: boolean = false;
@Input() notFound: string = 'Sin datos para mostrar';
@Input() columns: Array<{ key: string, label: string }>;
@Input() useEdit: boolean = true;
@Input() useDelete: boolean = true;
@Input() useView: boolean = false;
@Input() useSettings: boolean = false;
@Input() useRefresh: boolean = false;
@Input() useEmail: boolean = false;
@Input() usePdf: boolean = false;              // menú con 2 versiones fijas (Empleador/Trabajador) — específico de Nómina, NO genérico para "ver PDF" simple.

@Output() refresh = new EventEmitter<{ pagination_pageIndex, pagination_pageSize, sort_active, sort_direction }>();
@Output() edit = new EventEmitter<any>();
@Output() delete = new EventEmitter<any>();
@Output() view = new EventEmitter<any>();
@Output() settings = new EventEmitter<any>();
@Output() refreshRow = new EventEmitter<any>();
@Output() email = new EventEmitter<any>();
@Output() pdf = new EventEmitter<{ row, version }>();

@ContentChild('customActions') customActions: TemplateRef<any>;  // <ng-template #customActions let-row> para acciones no estándar
```

Si necesitas una acción puntual que no sea "editar/eliminar/ver/pdf-empleador-trabajador" (ej. "Ver PDF" de un DTE, "Descargar archivo", "Reintentar"), **usa `customActions`**, no fuerces `usePdf`/`useSettings` a significar otra cosa.

### Tipos de columna soportados (`column.type`)

| `type` | Qué hace | Campos relevantes |
|--------|----------|--------------------|
| _(sin type)_ + `pipe` | Columna simple con pipe (`rutFormat`, `capitalizeFormat`, `currency`/`formatAmount`, `date`) | `key`, `pipe` |
| _(sin type, sin pipe)_ | Texto plano, o `subkey` para acceso anidado de 1 nivel (`dataRow[key][subkey]`), o ícono check/x si `key === 'active'` | `key`, `subkey` |
| `multiline` | Dos líneas: principal (`key`, `pipe`) + secundaria (`subkey`, `subkeyPipe`) | `key`, `pipe`, `subkey`, `subkeyPipe` |
| `salary` | Dos líneas fijas "Base: x" / "Liq: y" con `formatAmount` | `key`, `subkey` |
| `badges` | Grupo de badges pequeños clicables (novedades: AU/HE/HB) | `key` (objeto `{clave: cantidad}`) |
| `badge` | Badge de color único, paleta FIJA (ver abajo) | `key` |

### Paleta fija del badge estándar (`type: 'badge'`)

No se puede extender sin tocar el componente compartido (prohibido por esta skill). Traduce tu estado a una de estas etiquetas exactas:

| Color | Literales que lo disparan |
|-------|----------------------------|
| Verde | `COMPLETADO`, `ACTIVO`, `APROBADO` |
| Rojo | `ERROR`, `INACTIVO`, `RECHAZADO` |
| Azul | `PROCESANDO`, `EN_PROCESO`, `ENVIADO` |
| Ámbar | `PENDIENTE`, `BORRADOR` |
| Gris (default) | Cualquier otro string |

Ejemplo real (`DteSiiStatus` → etiqueta del badge), usado en `billing/list/list.component.ts`:

```ts
private statusLabel(status: DteSiiStatus): string {
    const labels: Record<DteSiiStatus, string> = {
        PENDING: 'PENDIENTE',   // ámbar
        SENT: 'ENVIADO',        // azul
        PROCESSING: 'PROCESANDO', // azul
        ACCEPTED: 'APROBADO',   // verde
        REJECTED: 'RECHAZADO',  // rojo
        RECEIVED: 'RECIBIDO',   // gris (no está en la paleta, y está bien así)
        CANCELLED: 'ANULADO',   // gris (coincide con el gris que tenía el diseño original)
    };
    return labels[status] ?? status;
}
```

---

## Contrato real: `app-table-without-pagination`

Fuente: `fuse-starter/src/app/modules/shared/table-without-pagination/table-without-pagination.component.ts`

```ts
export interface TableColumn {
    key: string;
    label: string;
    class?: string;
    headerClass?: string;
    pipe?: 'date' | 'currency' | 'datetime' | 'number' | string;
    transform?: 'uppercase' | 'lowercase' | 'capitalize';
}

@Input() dataSource: any[] = [];
@Input() columns: TableColumn[] = [];
@Input() isLoading: boolean = false;
@Input() notFound: string = 'Sin datos para mostrar';
@Input() maxHeight: string = 'none';
@Input() showFooter: boolean = false;
@Input() footerLeftLabel: string = '';
@Input() footerLeftValue: any = '';
@Input() footerRightLabel: string = '';
@Input() footerRightValue: any = '';
@Input() customTemplates: { [key: string]: TemplateRef<any> } = {};
```

No tiene `@Output` de refresco/paginación — es 100% client-side. `columns[].key` soporta dot-notation (`'concept.name'`) vía `getNestedValue()`. Para una celda que no se resuelve con `pipe`/`transform`, pasa un `TemplateRef` en `customTemplates` indexado por `col.key`.

No confundir con `generic-table`: **no** tiene `pagination`, **no** tiene `useEdit`/`useDelete`/eventos `edit`/`delete` — si necesitas esas acciones, resuélvelas dentro de tu propio `customTemplates` (botones con `(click)` directos al método del componente).

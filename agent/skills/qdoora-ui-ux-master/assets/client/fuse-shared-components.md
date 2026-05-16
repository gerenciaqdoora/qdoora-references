# Componentes Compartidos (Fuse Starter)

> Ubicación: `/app/modules/shared`

## 📊 Tablas

| Tipo | Componente | Selector |
| :--- | :--- | :--- |
| **Con Paginación** | `GenericTableComponent` | `<app-table>` |
| **Sin Paginación** | `TableWithoutPaginationComponent` | `<app-table-without-pagination>` |

### Ejemplo con Paginación
```html
<app-table
  [columns]="columns"
  [data]="data"
  [totalItems]="totalItems"
  (pageChange)="onPageChange($event)">
</app-table>
```

---

## 🔍 Selectores con Filtro (`app-select-with-filter`)

OBLIGATORIO para selectores de datos del backend.

```html
<app-select-with-filter
  [primaryKey]="'id'"
  [show_atribute_option]="'name'"
  [allOptions]="options"
  [controlName]="'user_id'"
  [parentForm]="form">
</app-select-with-filter>
```

---

## 📝 Campos de Formulario

PROHIBIDO usar `<mat-form-field>` directo.

| Campo | Componente |
| :--- | :--- |
| Input de texto | `app-input-form` |
| Selector de fecha | `app-date-picker` |
| Área de texto | `app-textarea` |

### Ejemplo Correcto
```html
<app-input-form
  [label]="'Nombre'"
  [formControl]="form.get('name')"
  [required]="true">
</app-input-form>
```

---

## 📂 Secciones (Cards)

Usa `app-section-card` para agrupar campos con una grid responsiva.

```html
<app-section-card
  [title]="'TÍTULO DE SECCIÓN'"
  [subtitle]="'Descripción de apoyo'"
  [icon]="'heroicons_outline:identification'">
  
  <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
    <app-input-form [label]="'Campo 1'" ...></app-input-form>
    <app-input-form [label]="'Campo 2'" ...></app-input-form>
  </div>
</app-section-card>
```

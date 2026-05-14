# Componentes Compartidos de Fuse (Client)

Usa estos patrones para asegurar la consistencia visual en `fuse-starter`.

### Inputs y Selects
```html
<app-input-form
    [label]="'Nombre de Usuario'"
    [control]="form.get('name')"
    [placeholder]="'Ej: Juan Pérez'">
</app-input-form>

<app-select-with-filter
    [label]="'Empresa'"
    [control]="form.get('company_id')"
    [options]="companies"
    [optionLabel]="'name'"
    [optionValue]="'id'">
</app-select-with-filter>
```

### Botones y Acciones
```html
<button
    mat-flat-button
    [color]="'primary'"
    (click)="save()"
    [disabled]="form.invalid || isLoading">
    <mat-icon [svgIcon]="'heroicons_outline:check'"></mat-icon>
    <span>Guardar Cambios</span>
</button>
```

### Tablas Paginadas vs No Paginadas
- **Tablas Paginadas**: Usa `GenericTableComponent`.
- **Tablas No Paginadas**: Usa `TableWithoutPaginationComponent`.

### Diálogos Estrictos
Todo diálogo debe generarse en `app/dialog` y seguir esta estructura:
```html
<app-dialog-header [title]="'Título del Diálogo'"></app-dialog-header>

<mat-dialog-content class="p-6">
    <!-- Contenido -->
</mat-dialog-content>

<app-dialog-footer>
    <app-dialog-button-cancel (click)="close()"></app-dialog-button-cancel>
    <app-dialog-button-confirm (click)="confirm()"></app-dialog-button-confirm>
</app-dialog-footer>
```

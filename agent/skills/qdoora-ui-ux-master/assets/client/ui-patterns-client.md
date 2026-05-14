# Patrones de Diseño UI: Portal de Clientes

Estructuras y configuraciones extraídas de `fuse-starter` y la referencia estética `fuse-demo`.

### Layout de Página "Classy"
El portal utiliza el layout `classy` de Fuse. Los componentes de página deben seguir esta estructura para coherencia:

```html
<div class="flex flex-col flex-auto min-w-0">
    <!-- Header de Página -->
    <div class="flex flex-col sm:flex-row flex-0 sm:items-center sm:justify-between p-6 sm:py-8 sm:px-10 border-b bg-card">
        <div class="flex-1 min-w-0">
            <div class="flex flex-wrap items-center font-medium">
                <!-- Breadcrumbs -->
            </div>
            <div class="mt-2">
                <h2 class="text-3xl md:text-4xl font-extrabold tracking-tight leading-7 sm:leading-10 truncate">
                    Título de la Vista
                </h2>
            </div>
        </div>
        <!-- Acciones Rápidas (Botones) -->
    </div>

    <!-- Contenido Principal -->
    <div class="flex-auto p-6 sm:p-10">
        <!-- Grid de Secciones -->
    </div>
</div>
```

### Grid de Formulario Estandarizada
Usa `app-section-card` para agrupar campos con una grid responsiva:

```html
<app-section-card
    [title]="'DATOS PRINCIPALES'"
    [icon]="'heroicons_outline:user'">
    
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <app-input-form [label]="'Nombre'" [control]="form.get('name')"></app-input-form>
        <app-select-with-filter [label]="'Categoría'" ...></app-select-with-filter>
        <app-date-picker [label]="'Fecha'" ...></app-date-picker>
    </div>
</app-section-card>
```

### Patrón de Diálogo Premium
Estructura quirúrgica para diálogos normalizados:

```html
<div class="standard-dialog-container">
    <app-dialog-header [title]="'Editar Registro'" [icon]="'heroicons_outline:pencil'"></app-dialog-header>

    <mat-dialog-content class="standard-dialog-content">
        <!-- Alertas de validación siempre arriba -->
        <app-shared-alert name="form-error" appearance="outline"></app-shared-alert>
        
        <!-- Formulario -->
    </mat-dialog-content>

    <app-dialog-footer>
        <app-dialog-button-cancel (click)="close()"></app-dialog-button-cancel>
        <app-dialog-button-confirm (click)="save()"></app-dialog-button-confirm>
    </app-dialog-footer>
</div>
```

### Notificaciones de Operación
Usa `MatSnackBar` con las clases de éxito/error definidas en `styles.scss`:
- `panelClass: 'snackbar-success'`
- `panelClass: 'snackbar-error'`

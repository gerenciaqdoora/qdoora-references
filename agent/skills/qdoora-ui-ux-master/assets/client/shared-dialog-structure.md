# Estructura de Diálogos y Popups

> Ubicación Obligatoria: `app/dialog`

## 🏗️ Componentes de Estructura

| Componente | Uso |
| :--- | :--- |
| `app-dialog-header` | Título e icono del encabezado. |
| `app-dialog-footer` | Contenedor de acciones (derecha). |
| `app-dialog-button-cancel` | Botón estándar de cierre/cancelación. |
| `app-dialog-button-confirm` | Botón de acción principal (con estado loading). |

## 📝 Patrón de Implementación

```html
<div class="dialog-container">
  <!-- Encabezado -->
  <app-dialog-header 
    [title]="'Crear Usuario'"
    [icon]="'heroicons_outline:user-plus'">
  </app-dialog-header>

  <!-- Contenido -->
  <mat-dialog-content>
    <form [formGroup]="form">
        <!-- Campos usando app-input-form -->
    </form>
  </mat-dialog-content>

  <!-- Footer -->
  <app-dialog-footer>
    <app-dialog-button-cancel (click)="onCancel()">
    </app-dialog-button-cancel>
  
    <app-dialog-button-confirm 
      [disabled]="!form.valid"
      [loading]="isLoading"
      (click)="onConfirm()">
    </app-dialog-button-confirm>
  </app-dialog-footer>
</div>
```

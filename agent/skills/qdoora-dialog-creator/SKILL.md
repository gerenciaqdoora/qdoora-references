---
name: qdoora-dialog-creator
description: Blueprint one-shot para la creación de diálogos (modales) en el Portal Cliente (fuse-starter). Aplica la estructura obligatoria de layout (Header/Footer), estilos Tailwind inyectados y encapsulamiento. Activar siempre que el usuario pida crear un nuevo dialog.
---
# QdoorA Dialog Creator Expert

Eres el **arquitecto maestro de modales (Dialogs)** en el Portal Cliente de QdoorA (Angular 18, `fuse-starter`). Tu misión es asegurar que cada nuevo componente modal cumpla con los estándares visuales, arquitectónicos y de rendimiento de la plataforma.

---

## REGLAS OBLIGATORIAS (Hard Rules)

1. **Ubicación Estricta**: Todo diálogo nuevo debe crearse obligatoriamente dentro de la ruta `src/app/dialog/`. Nunca en módulos ni otras rutas.
2. **Consulta de Ancho OBLIGATORIA**: Antes de escribir código, SIEMPRE debes preguntar al usuario qué ancho requiere para el diálogo, para saber si usará la clase por defecto u otra. Debes decir: *"¿Qué ancho deseas para este diálogo? Por defecto se utiliza `.dialog-panel` (w-128 en sm y w-200 en md)."*
3. **Encapsulamiento y Detección de Cambios**: Es OBLIGATORIO utilizar `ViewEncapsulation.None` y `ChangeDetectionStrategy.OnPush` en el decorador `@Component`.
4. **CSS Injectado Obligatorio**: Todos los diálogos deben inyectar el bloque de estilos (Tailwind) estandarizado en la propiedad `styles` del `@Component`.
5. **Estructura HTML Estricta**: Todo modal debe envolverse en `<div class="standard-dialog-container">`, tener un header, un contenedor para el contenido (`standard-dialog-content`) y un footer con botones estándar.

---

## BLUEPRINT: TYPESCRIPT (@Component)

Cada nuevo diálogo debe inicializarse con esta estructura exacta en su decorador:

```typescript
import { Component, ChangeDetectionStrategy, ViewEncapsulation } from '@angular/core';

@Component({
    selector: 'app-nombre-del-dialog',
    templateUrl: './nombre-del-dialog.component.html',
    styles: [
        `
            .dialog-panel {
                @screen sm {
                    @apply w-128; //32rem
                }

                @screen md {
                    @apply w-200; //50rem
                }

                .mat-mdc-dialog-container {
                    .mat-mdc-dialog-surface {
                        padding: 0 !important;
                    }
                }
            }
        `,
    ],
    encapsulation: ViewEncapsulation.None,
    changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NombreDelDialogComponent {
    // La inyección de dependencias debe incluir al menos:
    // @Inject(MAT_DIALOG_DATA) public data: any,
    // public matDialogRef: MatDialogRef<NombreDelDialogComponent>
}
```

---

## BLUEPRINT: HTML ESTRUCTURAL

Todo HTML de diálogo en QdoorA debe armarse siguiendo esta jerarquía exacta:

```html
<div class="standard-dialog-container">

    <!-- Header -->
    <app-dialog-header 
        [title]="data?.title || 'Título por defecto'" 
        [showCloseButton]="!!data?.dismissible"
        (close)="onClose()">
    </app-dialog-header>

    <!-- Content -->
    <div class="standard-dialog-content">
        <!-- AQUÍ VA EL FORMULARIO O CONTENIDO DEL MODAL -->
    </div>

    <!-- Footer -->
    <app-dialog-footer>
        <!-- Botón Cancelar -->
        <app-dialog-button-cancel 
            [label]="data?.actions?.cancel?.label ?? 'Cancelar'" 
            [disabled]="isLoading"
            (cancel)="onClose()">
        </app-dialog-button-cancel>

        <!-- Botón Confirmar (Si amerita) -->
        <app-dialog-button-confirm 
            [label]="data?.actions?.confirm?.label ?? 'Confirmar'" 
            [color]="data?.actions?.confirm?.color ?? 'primary'"
            [isLoading]="isLoading" 
            [disabled]="form?.invalid" 
            (confirm)="onSubmit()">
        </app-dialog-button-confirm>
    </app-dialog-footer>

</div>
```

---

## FLUJO DE TRABAJO (Workflow)

Cuando el usuario pida "Crear un nuevo diálogo para X":

1. **Pausa y Pregunta**: Inmediatamente pregunta por el ancho del diálogo antes de generar el código.
2. **Implementación**: Una vez confirmada la respuesta, genera el `.ts` (con los decoradores exactos mostrados arriba) y el `.html` (envolviendo el contenido con el layout estándar).
3. Asegúrate de inyectar las dependencias comunes en el constructor: `MAT_DIALOG_DATA`, `MatDialogRef`, y si lleva formulario, el `FormBuilder`.

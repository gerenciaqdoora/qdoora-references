# Angular 21: Signals y Zoneless

Patrones modernos para el Portal de Soporte.

### Reactividad con Signals
```typescript
import { signal, computed, effect } from '@angular/core';

export class SupportDashboardComponent {
    // Estado base
    public logs = signal<Log[]>([]);
    public filterText = signal<string>('');

    // Estado derivado (automático)
    public filteredLogs = computed(() => {
        return this.logs().filter(log => 
            log.message.includes(this.filterText())
        );
    });

    constructor() {
        // Efectos secundarios
        effect(() => {
            console.log('Filtro actualizado:', this.filterText());
        });
    }
}
```

### Optimización Angular 21
1.  **Vite Scanning**: Tailwind v4 detecta automáticamente las plantillas `.html` y componentes `.ts` gracias al motor basado en Vite.
2.  **Zoneless Compatibility**: Los estilos de Tailwind no dependen de Zone.js, garantizando un renderizado fluido en modo Zoneless.
3.  **Signals Integration**: Usa clases dinámicas de Tailwind vinculadas a Angular Signals para reactividad máxima.

```typescript
// Ejemplo de clases dinámicas con Signals
public isActive = signal(false);
public statusClasses = computed(() => 
    this.isActive() ? 'bg-success text-white' : 'bg-gray-100 text-gray-500'
);
```

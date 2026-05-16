# Angular 21: Signals & Zoneless

> Estándar de reactividad para el Portal de Soporte/Admin.

## ⚡ Configuración Zoneless

Para habilitar la detección de cambios sin Zone.js, se debe configurar en el `app.config.ts`:

```typescript
import { provideZonelessChangeDetection } from '@angular/core';

export const appConfig: ApplicationConfig = {
    providers: [
        provideZonelessChangeDetection(), // ✅ Estable en Angular 21
        // ... otros proveedores
    ]
};
```

## 📶 Reactividad con Signals

### 1. Inputs como Signals
```typescript
// Componente Standalone
export class UserDetailComponent {
    // Input reactivo
    userId = input.required<string>();
    
    // Derived state con computed
    user$ = computed(() => this.userService.getUserById(this.userId()));
}
```

### 2. Manejo de Estado Local
```typescript
export class TicketListComponent {
    private ticketsSignal = signal<Ticket[]>([]);
    
    // Read-only access
    tickets = this.ticketsSignal.asReadonly();

    loadTickets() {
        this.service.getTickets().subscribe(data => {
            this.ticketsSignal.set(data);
        });
    }
}
```

## 🚨 Reglas de Oro
- PROHIBIDO usar `ChangeDetectorRef.detectChanges()`.
- Priorizar `computed()` sobre métodos que se ejecutan en el template.
- Usar `effect()` con precaución solo para efectos secundarios externos (logging, storage).

# Vitest — Estándares de Testing Angular 21 (Portal Soporte/Admin)

> Usa este archivo para tests del portal Soporte/Admin (`support-portal`, Angular 21 Zoneless).
> Framework: Vitest + @testing-library/angular + Signals
> El portal usa arquitectura Zoneless — NO usar TestBed.detectChanges() de forma imperativa.

---

## Tabla de Contenidos
1. [Configuración Base Vitest + Angular 21](#1-configuración-base)
2. [Tests de Signals y Estado Reactivo](#2-tests-de-signals-y-estado-reactivo)
3. [Tests de Componentes Standalone Zoneless](#3-tests-de-componentes-standalone-zoneless)
4. [Tests de Servicios con inject()](#4-tests-de-servicios-con-inject)
5. [Tests del Sistema de Tickets (Soporte)](#5-tests-del-sistema-de-tickets-soporte)
6. [Tests de Traceabilidad Forense](#6-tests-de-traceabilidad-forense)

---

## 1. Configuración Base

```typescript
// vitest.config.ts (en support-portal/)
import { defineConfig } from 'vitest/config';
import angular from '@analogjs/vite-plugin-angular';

export default defineConfig({
    plugins: [angular()],
    test: {
        globals:     true,
        environment: 'jsdom',
        setupFiles:  ['src/test-setup.ts'],
        include:     ['**/*.spec.ts'],
    },
});

// src/test-setup.ts
import '@angular/core/testing';
import { setupZonelessTestEnv } from 'zone.js/testing'; // Angular 21 Zoneless
setupZonelessTestEnv();
```

```bash
# Comandos
vitest              # modo watch
vitest run          # una sola ejecución (CI/CD)
vitest run --coverage  # con cobertura
```

---

## 2. Tests de Signals y Estado Reactivo

Los Signals son el corazón del estado en Angular 21. Testear que los signals se actualizan
correctamente bajo diferentes escenarios es equivalente a testear el estado en otros frameworks.

```typescript
// src/app/features/tickets/ticket-list.component.spec.ts
import { signal, computed, effect } from '@angular/core';
import { describe, it, expect, vi } from 'vitest';

describe('TicketListComponent — Signals', () => {

    it('el computed de tickets filtrados reacciona al cambio de filtro', () => {
        // Simular los signals del componente de forma aislada
        const tickets = signal([
            { id: 1, status: 'OPEN',   title: 'Error de login' },
            { id: 2, status: 'CLOSED', title: 'PDF no genera' },
            { id: 3, status: 'OPEN',   title: 'Factura duplicada' },
        ]);
        const statusFilter = signal<string | null>('OPEN');

        const filteredTickets = computed(() =>
            statusFilter() === null
                ? tickets()
                : tickets().filter(t => t.status === statusFilter())
        );

        expect(filteredTickets().length).toBe(2);

        statusFilter.set('CLOSED');
        expect(filteredTickets().length).toBe(1);
        expect(filteredTickets()[0].title).toBe('PDF no genera');

        statusFilter.set(null);
        expect(filteredTickets().length).toBe(3);
    });

    it('el signal isLoading vuelve a false después de la carga', async () => {
        const isLoading = signal(true);

        // Simular operación async
        await new Promise(resolve => setTimeout(resolve, 0));
        isLoading.set(false);

        expect(isLoading()).toBe(false);
    });
});
```

---

## 3. Tests de Componentes Standalone Zoneless

```typescript
// src/app/features/tickets/ticket-detail.component.spec.ts
import { render, screen, fireEvent } from '@testing-library/angular';
import { TicketDetailComponent } from './ticket-detail.component';
import { TicketService } from '../services/ticket.service';
import { vi } from 'vitest';

describe('TicketDetailComponent', () => {

    it('muestra el título y estado del ticket', async () => {
        const mockTicket = {
            id: 'uuid-1',
            title: 'Error en liquidación de nómina',
            status: 'OPEN',
            priority: 'HIGH',
        };

        const ticketServiceMock = {
            getById: vi.fn().mockReturnValue(Promise.resolve(mockTicket)),
            updateStatus: vi.fn(),
        };

        await render(TicketDetailComponent, {
            providers: [{ provide: TicketService, useValue: ticketServiceMock }],
            componentInputs: { ticketId: 'uuid-1' },
        });

        expect(screen.getByText('Error en liquidación de nómina')).toBeTruthy();
        expect(screen.getByText('OPEN')).toBeTruthy();
    });

    it('llama a updateStatus al hacer clic en "Cerrar Ticket"', async () => {
        const ticketServiceMock = {
            getById: vi.fn().mockResolvedValue({ id: 'uuid-1', status: 'OPEN', title: 'Test' }),
            updateStatus: vi.fn().mockResolvedValue({ id: 'uuid-1', status: 'CLOSED' }),
        };

        await render(TicketDetailComponent, {
            providers: [{ provide: TicketService, useValue: ticketServiceMock }],
            componentInputs: { ticketId: 'uuid-1' },
        });

        const closeBtn = screen.getByRole('button', { name: /cerrar ticket/i });
        await fireEvent.click(closeBtn);

        expect(ticketServiceMock.updateStatus).toHaveBeenCalledWith('uuid-1', 'CLOSED');
    });
});
```

---

## 4. Tests de Servicios con inject()

```typescript
// src/app/features/tickets/ticket.service.spec.ts
import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TicketService } from './ticket.service';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('TicketService', () => {
    let service: TicketService;
    let httpMock: HttpTestingController;

    beforeEach(() => {
        TestBed.configureTestingModule({
            imports: [HttpClientTestingModule],
        });
        service  = TestBed.inject(TicketService);
        httpMock = TestBed.inject(HttpTestingController);
    });

    afterEach(() => httpMock.verify());

    it('obtiene todos los tickets del usuario autenticado', () => {
        const mockResponse = {
            data: [{ id: 'uuid-1', title: 'Error', status: 'OPEN' }],
        };

        service.getAll().subscribe(res => {
            expect(res.data[0].id).toBe('uuid-1');
        });

        const req = httpMock.expectOne('/api/support/tickets');
        expect(req.request.method).toBe('GET');
        req.flush(mockResponse);
    });

    it('cambia el estado del ticket y retorna el ticket actualizado', () => {
        service.updateStatus('uuid-1', 'CLOSED').subscribe(ticket => {
            expect(ticket.status).toBe('CLOSED');
        });

        const req = httpMock.expectOne('/api/support/tickets/uuid-1/status');
        expect(req.request.method).toBe('PATCH');
        expect(req.request.body).toEqual({ status: 'CLOSED' });
        req.flush({ id: 'uuid-1', status: 'CLOSED' });
    });
});
```

---

## 5. Tests del Sistema de Tickets (Soporte)

```typescript
// Tests de transiciones de estado válidas
import { TicketStatusMachine } from '../state/ticket-status-machine';
import { describe, it, expect } from 'vitest';

describe('TicketStatusMachine', () => {
    it('permite transición OPEN → IN_PROGRESS', () => {
        expect(TicketStatusMachine.canTransition('OPEN', 'IN_PROGRESS')).toBe(true);
    });

    it('no permite transición CLOSED → OPEN (reapertura no permitida)', () => {
        expect(TicketStatusMachine.canTransition('CLOSED', 'OPEN')).toBe(false);
    });

    it('no permite transición OPEN → CLOSED directa (debe pasar por IN_PROGRESS)', () => {
        expect(TicketStatusMachine.canTransition('OPEN', 'CLOSED')).toBe(false);
    });

    it('permite transición IN_PROGRESS → CLOSED', () => {
        expect(TicketStatusMachine.canTransition('IN_PROGRESS', 'CLOSED')).toBe(true);
    });
});
```

---

## 6. Tests de Traceabilidad Forense

La trazabilidad es un requerimiento crítico del portal Soporte. Cada cambio de estado
en un ticket DEBE registrarse. Estos tests verifican que el registro ocurre correctamente.

```typescript
// Verificar que el servicio llama al endpoint de traceabilidad después de un cambio de estado
it('registra la traceabilidad después de cambiar el estado del ticket', async () => {
    const ticketServiceMock = {
        updateStatus: vi.fn().mockResolvedValue({ id: 'uuid-1', status: 'CLOSED' }),
    };
    const traceServiceMock = {
        register: vi.fn().mockResolvedValue({}),
    };

    // El componente debe llamar a ambos servicios en secuencia
    await render(TicketDetailComponent, {
        providers: [
            { provide: TicketService, useValue: ticketServiceMock },
            { provide: TraceabilityService, useValue: traceServiceMock },
        ],
        componentInputs: { ticketId: 'uuid-1' },
    });

    const closeBtn = screen.getByRole('button', { name: /cerrar ticket/i });
    await fireEvent.click(closeBtn);

    // El registro de traceabilidad debe ocurrir DESPUÉS del cambio de estado
    expect(ticketServiceMock.updateStatus).toHaveBeenCalledBefore(traceServiceMock.register as any);
    expect(traceServiceMock.register).toHaveBeenCalledWith({
        ticketId: 'uuid-1',
        action:   'STATUS_CHANGE',
        from:     'OPEN',
        to:       'CLOSED',
    });
});
```

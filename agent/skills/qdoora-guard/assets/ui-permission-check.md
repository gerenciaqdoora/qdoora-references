# Ocultar botones y acciones según permiso

## La convención: método booleano + `@if`

El proyecto **no usa directivas estructurales** para esto. El patrón establecido es exponer
el servicio (o un método del componente) y consultarlo desde el template con `@if`.

### Componente

```typescript
export class BillingSettingComponent {
    constructor(
        private _billingService: BillingService,
        /**
         * Público: el template lo consulta para ocultar acciones que el backend
         * rechazaría igual (ver StoreCafRequest → BILLING.SETTING + create).
         */
        public permissions: PermissionService
    ) {}
}
```

### Template

```html
@if (permissions.can('BILLING.SETTING', 'create')) {
    <button (click)="submitCaf()">Cargar CAF</button>
}
```

Usa `can` (síncrono) y no `can$` aquí: en un template el re-render posterior corrige solo
cuando llega la matriz. La variante asíncrona es exclusiva de los guards, donde una
evaluación prematura sí produce una redirección incorrecta.

## Precedente en el codebase

`emission-type-selector.component.ts` ya resuelve el mismo problema con un método booleano
del componente y `@if`, mostrando además el motivo del bloqueo:

```html
@if (canEmit(doc)) {
    <button (click)="choose(doc)">…</button>
} @else {
    <a routerLink="/billing/setting" [matTooltip]="blockReason(doc)">…</a>
}
```

## Ocultar vs. deshabilitar vs. explicar

| Situación | Qué hacer |
|---|---|
| El usuario **nunca** podrá hacerlo (no tiene el permiso) | Ocultar con `@if` |
| El usuario podría hacerlo pero falta un requisito subsanable (sin folios, sin certificado) | Mostrar deshabilitado + `matTooltip` con el motivo y un link a donde se resuelve |
| Una operación en curso | `[disabled]` con el estado de carga |

No deshabilites por permisos: un botón gris permanente que nunca se explica es peor UX que
no mostrarlo. Reserva el deshabilitado para lo que el usuario **sí** puede desbloquear.

## La operación debe coincidir con el backend

El segundo argumento de `can()` tiene que ser exactamente el que valida el FormRequest del
endpoint que dispara el botón:

| Acción del botón | FormRequest | Chequeo en el template |
|---|---|---|
| Cargar un CAF | `StoreCafRequest` → `BILLING.SETTING` + `CREATE` | `can('BILLING.SETTING', 'create')` |
| Eliminar un registro | `…DeleteRequest` → `<CODE>` + `DELETE` | `can('<CODE>', 'delete')` |

Verifica el `authorize()` real antes de escribir el `@if`. Un chequeo que no corresponde
con el backend oculta acciones permitidas o muestra acciones que fallarán con 403.

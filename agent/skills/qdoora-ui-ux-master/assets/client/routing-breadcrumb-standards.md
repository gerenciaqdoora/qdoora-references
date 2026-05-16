# Routing y Breadcrumbs

## 📍 Configuración de Rutas

Toda ruta debe ser descriptiva y contener metadatos para la navegación.

```typescript
{
  path: 'nomina',
  data: { breadcrumb: 'Nómina' },
  children: [
    {
      path: 'empleados',
      component: EmpleadosComponent,
      data: { breadcrumb: 'Empleados' }
    }
  ]
}
```

## 🛡️ Guards (Protección)

| Guard | Propósito |
| :--- | :--- |
| `CompanySelectedRequiredGuard` | Bloquea si no hay empresa seleccionada. |
| `accountPlanRequireGuard` | Bloquea si la empresa no tiene Plan de Cuentas. |

### Ejemplo de Uso
```typescript
{
  path: 'comprobantes',
  component: ComprobantesComponent,
  canActivate: [
    CompanySelectedRequiredGuard,
    accountPlanRequireGuard
  ],
  data: { breadcrumb: 'Comprobantes' }
}
```

# Routing y Notificaciones (Client)

### Notificaciones y Feedback
- **MatSnackBar**: Úsalo SOLO para confirmaciones pasivas breves (ej: "Registro guardado").
- **app-shared-alert**: OBLIGATORIO para errores de backend, validaciones de formularios y alertas persistentes.
  - Atributos: `appearance: 'outline'`.
  - Atributo: `name` (debe ser ÚNICO por componente).

### Protección de Rutas (Guards)
- Verifica si la ruta requiere:
  - `CompanySelectedRequiredGuard`
  - `accountPlanRequireGuard`
- **Breadcrumbs**: Toda ruta debe incluir `data: { breadcrumb: '...' }`.

### Manejo de Errores (Tipado)
En el bloque `error` de una suscripción, la respuesta debe estar estrictamente tipada:
```typescript
.subscribe({
    error: (response: JsonResponse<any>) => {
        this.errorMessage = response.message;
        this._changeDetectorRef.markForCheck();
    }
});
```

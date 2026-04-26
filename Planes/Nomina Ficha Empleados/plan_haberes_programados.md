# Plan de Desarrollo: Haberes y Descuentos Programados (Ficha Empleado)

## 📋 Descripción del Requerimiento
Implementar una funcionalidad en la Ficha del Empleado que permita programar haberes y descuentos recurrentes. Estos se aplicarán automáticamente en todas las liquidaciones dentro de un rango de fechas definido.

### Lógica de Fechas:
- **Fecha Inicial**: Se seleccionará una fecha, pero el sistema forzará siempre el **día 01** de ese mes como inicio de aplicación.
- **Fecha Final**: Se seleccionará una fecha, pero el sistema forzará siempre el **último día** de ese mes como término de aplicación (si no es indefinido).
- Esto asegura que el movimiento cubra el mes comercial completo para efectos de liquidación.

---

## 🛠️ Backend (Laravel)

### 1. Base de Datos
- **Migración**: Crear tabla `employee_scheduled_movements`.
    - `id`: PK.
    - `employee_id`: FK a `employees`.
    - `haber_descuento_id`: FK a `haberes_descuentos`.
    - `amount`: Decimal (12,2).
    - `start_date`: Date (Forzado al día 1 del mes).
    - `end_date`: Date (Nullable, forzado al último día del mes).
    - `observations`: Text (Nullable).
    - `is_active`: Boolean (Default true).

### 2. Capa de Negocio (Services)
- **Service**: `EmployeeScheduledMovementService` en `app/Services/Nomina`.
    - **Normalización**: El servicio debe asegurar que al guardar, la `start_date` sea el día 1 y la `end_date` sea el último día del mes respectivo.
    - **Logic**: Las liquidaciones buscarán registros donde `current_month` esté contenido entre `start_date` y `end_date`.
    - **Logger**: Implementar `LoggerService` obligatorio.

### 3. API (Controllers & Requests)
- **FormRequest**: `StoreScheduledMovementRequest` con mensajes en español.
- **Controller**: `EmployeeScheduledMovementController` usando `HandlesControllerLogs`.

---

## 🎨 Frontend (Angular)

### 1. Componente de Vista (`create.component.ts`)
- **Pestaña**: "Haberes y Descuentos Programados".
- **Tabla**: `TableWithoutPaginationComponent`.
    - Columnas: Concepto, Tipo, Monto, Fecha Inicio, Fecha Fin, Acciones.

### 2. Diálogo de Gestión
- **Componente**: `ScheduledMovementFormDialogComponent`.
- **UI**:
    - `app-select-with-filter` para el concepto.
    - `app-date-picker`: Aunque se seleccione día/mes/año, el componente o el servicio backend normalizarán a "inicio de mes" y "fin de mes".
    - `app-shared-amount-input` para el monto.

### 3. Integración de Reglas
- Uso de componentes compartidos.
- Prohibición de `mat-form-field` directo.

---

## 🚀 Pasos de Ejecución Suggestion

1.  **Backend Base**: Migración, Modelo y Service con lógica de normalización de fechas.
2.  **API**: Endpoint de guardado y listado por empleado.
3.  **Frontend**: Diálogo de creación y actualización de la pestaña principal.

---
> [!NOTE]
> Se mantiene la integridad histórica: los movimientos programados no se eliminan si el concepto base de la empresa se desactiva.

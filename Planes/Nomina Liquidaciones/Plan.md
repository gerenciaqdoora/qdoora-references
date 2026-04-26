## Plan: Submódulo Liquidaciones (Nómina)

### Visión General del Flujo

Selección de período (mes/año)
       ↓
GET /liquidaciones?period=2026-04
       ↓
Backend genera automáticamente liquidaciones por empleado
  (basado en ficha: salario base, movimientos programados,
   configuraciones de empresa, cargas familiares, AFP/salud)
       ↓
Lista renderizada con columnas:
  Documento | Nombre | Contacto | Salario | Novedades | Acciones
       ↓
Cada novedad (AU/HE/DD/OT) abre diálogo → guarda → refresca automáticamente
Acciones: Refresh manual | Ver PDF | Enviar email (popup)

---

### Modelo de Datos

**Tabla `liquidaciones`**

id | company_id | third_company_id | period (YYYY-MM) |
base_salary | imponible_total | haberes_total |
descuentos_total | liquid_total |
status (BORRADOR | GENERADA | ENVIADA) |
calculated_at | sent_at | softdeletes | timestamps
UNIQUE(company_id, third_company_id, period)

**Tabla `liquidacion_novedades`**

id | liquidacion_id | type (AUSENCIA | HORA_EXTRA | HABER | DESCUENTO) |
haber_descuento_id (nullable) | days (nullable) | hours (nullable) |
amount | description | is_from_ficha (bool) |
softdeletes | timestamps

---



### Backend — Archivos a Crear

| Archivo                                                     | Propósito                                 |
| ----------------------------------------------------------- | ------------------------------------------ |
| `migrations/..._create_liquidaciones_table.php`           | Tabla principal                            |
| `migrations/..._create_liquidacion_novedades_table.php`   | Novedades por liquidación                 |
| `Models/Nomina/Liquidacion.php`                           | Modelo con relaciones: employee, novedades |
| `Models/Nomina/LiquidacionNovedad.php`                    | Modelo novedad                             |
| `Enums/Nomina/EstadoLiquidacion.php`                      | BORRADOR, GENERADA, ENVIADA                |
| `Enums/Nomina/TipoNovedad.php`                            | AUSENCIA, HORA_EXTRA, HABER, DESCUENTO     |
| `Enums/Logger/LoggerEvent.php`                            | Agregar `LIQUIDACION = 'LIQUIDACION'`    |
| `Services/Nomina/LiquidacionService.php`                  | Lógica de negocio (ver abajo)             |
| `Http/Controllers/Nomina/LiquidacionController.php`       | Controlador delgado                        |
| `Http/Requests/Nomina/ReviewLiquidaciones.php`            | authorize + rules de listado/filtros       |
| `Http/Requests/Nomina/StoreLiquidacionRequest.php`        | Generación manual                         |
| `Http/Requests/Nomina/StoreLiquidacionNovedadRequest.php` | Nueva novedad                              |
| `Http/Requests/Nomina/SendLiquidacionEmailRequest.php`    | Envío por correo                          |
| `Http/Resources/Nomina/LiquidacionListResource.php`       | Respuesta lista                            |
| `Http/Resources/Nomina/LiquidacionResource.php`           | Respuesta detalle                          |
| `Http/Resources/Nomina/LiquidacionNovedadResource.php`    | Respuesta novedad                          |
| `routes/api.php`                                          | Nuevas rutas                               |

**`LiquidacionService` — métodos clave:**

// Obtiene lista, genera automáticamente si no existen para el período
getLiquidacionesList(int $companyId, array $params): array

// Genera o actualiza una liquidación calculando:
//   base_salary (de EmployeeRemuneration)
//   + movimientos programados activos del período
//   + novedades manuales ya guardadas
//   + configuraciones empresa (gratificación, APVC, CCAF, mutual)
//   + asignación familiar según tramo
//   - AFP + Salud + impuesto
generateOrRefreshLiquidacion(int $companyId, int $employeeId, string $period): Liquidacion

// CRUD de novedades → llama a generateOrRefreshLiquidacion al final
addNovedad(int $liquidacionId, array $data): LiquidacionNovedad
updateNovedad(int $novedadId, array $data): LiquidacionNovedad
deleteNovedad(int $novedadId): void

// PDF y Email
generatePdf(int $liquidacionId): string  // retorna URL/path
sendByEmail(int $liquidacionId, string $email): void

**Rutas a agregar en `api.php`:**

Route::group(['prefix' => '{company_id}/nomina/liquidaciones'], function () {
    Route::get('/', [LiquidacionController::class, 'index']);
    Route::post('/generate', [LiquidacionController::class, 'generate']);
    Route::get('/{id}', [LiquidacionController::class, 'show']);
    Route::post('/{id}/refresh', [LiquidacionController::class, 'refresh']);
    Route::post('/{id}/novedades', [LiquidacionController::class, 'storeNovedad']);
    Route::put('/{id}/novedades/{novedad_id}', [LiquidacionController::class, 'updateNovedad']);
    Route::delete('/{id}/novedades/{novedad_id}', [LiquidacionController::class, 'destroyNovedad']);
    Route::get('/{id}/pdf', [LiquidacionController::class, 'pdf']);
    Route::post('/{id}/send-email', [LiquidacionController::class, 'sendEmail']);
});

---



### Frontend — Archivos a Crear

| Archivo                                                         | Propósito                                          |
| --------------------------------------------------------------- | --------------------------------------------------- |
| `api/nomina/liquidacion.api.ts`                               | Llamadas HTTP                                       |
| `modules/admin/nomina/liquidaciones/liquidaciones.service.ts` | Estado BehaviorSubject + métodos                   |
| `modules/admin/nomina/liquidaciones/liquidaciones.routes.ts`  | Rutas con guards                                    |
| `modules/admin/nomina/liquidaciones/list/list.component.ts`   | Componente principal                                |
| `modules/admin/nomina/liquidaciones/list/list.component.html` | Template tabla + filtro período                    |
| `dialog/ausencia-novedad-dialog/`                             | Diálogo ausencias (días + descripción)           |
| `dialog/horas-extras-novedad-dialog/`                         | Diálogo horas extras (horas + valor)               |
| `dialog/haberes-descuentos-dialog/`                           | Diálogo haberes/descuentos (ficha + excepcionales) |
| `dialog/email-liquidacion-dialog/`                            | Popup envío correo                                 |
| `app.routes.ts`                                               | Agregar `liquidaciones` bajo `nomina`           |

**Columnas de la tabla:**

| Key                                | Label     | Notas                                 |
| ---------------------------------- | --------- | ------------------------------------- |
| `doc` + `rut`                  | Documento | Dos líneas: tipo doc + número       |
| `full_name`                      | Nombre    | Link a ficha                          |
| `email` + `phone`              | Contacto  | Dos líneas                           |
| `base_salary` + `liquid_total` | Salario   | Base + Total con `FormatAmountPipe` |
| `novedades`                      | Novedades | Badges AU/HE/DD/OT clickeables        |
| `acciones`                       | Acciones  | Refresh, ver detalle, PDF, email      |

**Flujo de refresco automático:**

* Cada diálogo de novedad al guardar/eliminar emite un evento → el componente list llama `refreshLiquidacion(id)` → actualiza el row en el BehaviorSubject sin recargar toda la lista.

**Filtros del header:**

* Selector de período (mes/año) — al cambiar dispara `loadLiquidaciones()`
* Búsqueda por nombre/RUT

---



### Orden de Implementación Sugerido

1. **Migrations** → tablas `liquidaciones` + `liquidacion_novedades`
2. **Models** → `Liquidacion` + `LiquidacionNovedad` con relaciones
3. **Enums** → `EstadoLiquidacion`, `TipoNovedad`, actualizar `LoggerEvent`
4. **LiquidacionService** → lógica de cálculo + CRUD novedades
5. **FormRequests + Resources + Controller** → capa HTTP
6. **Rutas API**
7. **`liquidacion.api.ts`** → llamadas HTTP
8. **`liquidaciones.service.ts`** → estado reactivo
9. **`list.component`** → tabla con filtros + badges novedades + acciones
10. **Diálogos** (4): ausencias, horas extras, haberes/descuentos, email
11. **`app.routes.ts`** → registrar ruta

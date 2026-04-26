# 📘 Development Guidelines

> Guía completa de estándares y mejores prácticas para el desarrollo del proyecto.

---

## 📑 Índice

1. [Reglas Generales de Interacción](#-reglas-generales-de-interacción)
2. [Frontend - Angular](#-frontend---angular)
   - [Componentes Compartidos](#componentes-compartidos)
   - [Diálogos y Popups](#diálogos-y-popups)
   - [Pipes y Formateo](#pipes-y-formateo)
   - [Routing](#routing)
   - [Notificaciones y Alertas](#notificaciones-y-alertas)
   - [Suscripciones a Servicios](#suscripciones-a-servicios)
3. [Backend - Laravel](#-backend---laravel)
   - [Arquitectura](#arquitectura)
   - [Patrones de Implementación](#patrones-de-implementación)
   - [Convenciones de Nombres](#convenciones-de-nombres)

---

## 🤝 Reglas Generales de Interacción

### Ejecución de Comandos

> ⚠️ **IMPORTANTE**: El asistente NO debe ejecutar comandos que requieran instalación de dependencias o modificaciones de base de datos.

**Comandos que deben ser entregados al usuario:**

- Instalación de librerías: `npm install`, `composer install/require`
- Comandos de base de datos: migraciones, seeds, etc.
- Comandos de framework: `php artisan ...`, `ng generate ...`

**Responsabilidad del asistente:**

- [ ] ✅ Listar claramente estos comandos al finalizar la respuesta
- [ ] ✅ Agruparlos en una sección "Comandos a ejecutar"
- [ ] ✅ Proporcionar el orden correcto de ejecución
- [ ] ✅ Explicar brevemente el propósito de cada comando

**Ejemplo de formato de entrega:**

```bash
# 📦 Comandos a ejecutar (en orden):

# 1. Instalar dependencias del backend
composer require vendor/package

# 2. Ejecutar migraciones
php artisan migrate

# 3. Instalar dependencias del frontend
npm install nueva-libreria
```

---

## 🎨 Frontend - Angular

### Resumen Ejecutivo

- ♻️ **Reutilización primero**: Verificar componentes compartidos antes de crear nuevos
- 🚫 **Prohibiciones**: No usar `mat-form-field` directo, no usar `currency` pipe estándar
- 📍 **Ubicación estricta**: Diálogos solo en `app/dialog`
- 🎯 **Consulta obligatoria**: Pedir referencia visual antes de crear vistas
- 🧩 **Arquitectura Standalone**: Cada componente compartido incluido en el HTML **DEBE** ser importado explícitamente en el array `imports` del componente padre.

---

### Componentes Compartidos

> 🔍 **REGLA DE ORO**: Antes de construir cualquier componente nuevo, SIEMPRE revisar `/app/modules/shared`

#### Tablas

| Tipo de Tabla             | Componente Obligatorio              | Ubicación                                                                             |
| ------------------------- | ----------------------------------- | -------------------------------------------------------------------------------------- |
| **Con Paginación** | `GenericTableComponent`           | `/app/modules/shared/table/table.component.ts`                                       |
| **Sin Paginación** | `TableWithoutPaginationComponent` | `/app/modules/shared/table-without-pagination/table-without-pagination.component.ts` |

**Ejemplo de uso:**

```html
<!-- Tabla con paginación -->
<app-table
  [columns]="columns"
  [data]="data"
  [totalItems]="totalItems"
  (pageChange)="onPageChange($event)">
</app-table>
```

---

#### Selectores con Filtro

**🔴 OBLIGATORIO**: Al usar `app-select-with-filter`, SIEMPRE verificar la integridad de:

```html
<app-select-with-filter
  [primaryKey]="'id'"              <!-- ✅ Obligatorio -->
  [show_atribute_option]="'name'"  <!-- ✅ Obligatorio: Atributo a mostrar -->
  [allOptions]="options"           <!-- ✅ Obligatorio: Lista completa de opciones -->
  [controlName]="'user_id'"        <!-- ✅ Obligatorio: Nombre del control en el form -->
  [parentForm]="form">             <!-- ✅ Obligatorio: Instancia del FormGroup -->
</app-select-with-filter>
```

**Propósito:**

- `primaryKey`: Identifica correctamente el ID de la opción seleccionada.
- `show_atribute_option`: Define qué atributo se visualizará en la lista desplegable.
- `allOptions`: Provee el arreglo de datos para el filtrado interno.
- `controlName` & `parentForm`: Aseguran la vinculación reactiva del componente con el formulario padre.
---

#### Campos de Formulario

> 🚫 **PROHIBIDO**: Uso directo de `<mat-form-field>`

**Componentes obligatorios en su lugar:**

| Campo             | Componente                 | Ubicación              |
| ----------------- | -------------------------- | ----------------------- |
| Input de texto    | `app-input-form`         | `/app/modules/shared` |
| Select con filtro | `app-select-with-filter` | `/app/modules/shared` |
| Selector de fecha | `app-date-picker`        | `/app/modules/shared` |
| Área de texto    | `app-textarea`           | `/app/modules/shared` |
| Card de Sección   | `app-section-card`       | `/app/modules/shared` |

> [!IMPORTANT]
> **REGLA DE IMPORTACIÓN (Standalone)**: No basta con usar el componente en el template. Se DEBE importar la clase del componente en el array `imports` del archivo `.ts` del componente padre.

**Razones:**

- ✅ Homogenización de estilos (ej: `reduceMarginLabel`)
- ✅ Actualizaciones globales simplificadas
- ✅ Consistencia visual en toda la aplicación

**Ejemplo correcto:**

```html
<!-- ✅ CORRECTO -->
<app-input-form
  [label]="'Nombre'"
  [formControl]="form.get('name')"
  [required]="true">
</app-input-form>

<!-- ❌ INCORRECTO -->
<mat-form-field>
  <mat-label>Nombre</mat-label>
  <input matInput [formControl]="form.get('name')">
</mat-form-field>
```

---

#### Estandarización de Secciones (Cards)

**OBLIGATORIO**: Para agrupar campos de formulario, se DEBE utilizar el componente `app-section-card` desde `/app/modules/shared`.

**Patrón Responsivo Sugerido:**
```html
<app-section-card
  [title]="'DESPACHADOR DE ADUANA'"
  [subtitle]="'Información obligatoria para trámites aduaneros'"
  [icon]="'heroicons_outline:identification'">
  
  <!-- Grid responsiva estandarizada -->
  <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
    <app-input-form [label]="'Nombre Completo'" ...></app-input-form>
    <app-input-form [label]="'Código Aduana'" ...></app-input-form>
  </div>
</app-section-card>
```

---

### Diálogos y Popups

#### Ubicación Estricta

> 📍 **REGLA**: Todos los diálogos DEBEN estar en `app/dialog`

#### Componentes Obligatorios

**🔴 Estandarización de estructura** - Usar componentes compartidos de `/app/dialog/shared`:

| Componente                    | Uso                     | Obligatorio                          |
| ----------------------------- | ----------------------- | ------------------------------------ |
| `app-dialog-header`         | Encabezado del diálogo | ✅ Siempre                           |
| `app-dialog-footer`         | Pie del diálogo        | ✅ Siempre                           |
| `app-dialog-button-cancel`  | Botón cancelar         | ✅ Siempre                           |
| `app-dialog-button-confirm` | Botón confirmar        | ⚠️ Solo si hay acción de guardado |

**Estructura estándar de un diálogo:**

```html
<div class="dialog-container">
  <!-- Encabezado -->
  <app-dialog-header 
    [title]="'Crear Usuario'"
    [icon]="'heroicons_outline:user-plus'">
  </app-dialog-header>

  <!-- Contenido -->
  <mat-dialog-content>
    <!-- Formulario o contenido -->
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

---

### Pipes y Formateo

> 🎯 **Objetivo**: Consistencia en el formateo de datos en toda la aplicación

#### Monedas

**🚫 PROHIBIDO**: Uso del pipe `currency` estándar de Angular

**✅ OBLIGATORIO**: Usar `FormatAmountPipe`

```typescript
// Ubicación: app/core/pipes/format-amount.pipe.ts

<!-- En template -->
{{ monto | formatAmount }}

// En componente
import { FormatAmountPipe } from '@core/pipes/format-amount.pipe';

constructor(private formatAmount: FormatAmountPipe) {}

formatearMonto(valor: number): string {
  return this.formatAmount.transform(valor);
}
```

**Razón**: Asegura separadores de miles y decimales consistentes según las necesidades del proyecto.

---

#### RUT Chileno

**✅ OBLIGATORIO**: Usar `RutFormatPipe`

```typescript
// Ubicación: app/core/pipes/rut-format.pipe.ts

<!-- En template -->
{{ rut | rutFormat }}

// Ejemplo: 12345678-9 → 12.345.678-9
```

**🚫 Evitar**: Formateos manuales con regex o funciones personalizadas.

---

### Angular 21 (Ecosistema Vite & Zoneless) - Proyecto: support-portal

#### Configuración de Servidor de Desarrollo (Docker)

**Regla Estricta**: En proyectos generados con constructores modernos basados en Vite, el flag `--disable-host-check` está deprecado y causa fallos.
- Para habilitar el live-reload en contenedores de Docker, se DEBE usar: `--host 0.0.0.0 --poll 2000` en el script de package.json (`"start": "ng serve --host 0.0.0.0 --poll 2000"`).

#### Compilador TypeScript y Aliases (TS 5.5+)

**Regla Estricta**: La opción `baseUrl` en `tsconfig.json` está fuertemente deprecada y causa fallos abortivos (TS5101) con el plugin `angular-compiler` de Vite.
- Se DEBE eliminar `"baseUrl": "./"` del archivo.
- Todos los aliases en el nodo `"paths"` DEBEN ser estrictamente relativos usando el prefijo `./`. 
  - ❌ Incorrecto: `"@app/*": ["src/app/*"]`
  - ✅ Correcto: `"@app/*": ["./src/app/*"]`

#### Cambio de Detección (Zoneless)

**Regla Estricta**: Para habilitar Zoneless de forma estable en Angular 21+, se utiliza el API estable `provideZonelessChangeDetection()`. NUNCA usar la versión experimental (`provideExperimentalZonelessChangeDetection`).

#### Control de Flujo (Templates)

**Regla Estricta**: Se prohíbe el uso de directivas estructurales antiguas (`*ngIf`, `*ngFor`) y sintaxis heredadas como `*if`. Todo componente nuevo o refactorizado DEBE utilizar la sintaxis nativa de bloque de control de flujo de Angular.
- ❌ Incorrecto: `<div *if="condicion">` o `<div *ngIf="condicion">`
- ✅ Correcto: `@if (condicion) { <div> }`

#### Integración de Estilos (Tailwind v4)

**Regla Estricta**: Tailwind v4 tiene un nuevo motor de compilación CSS. Si el proyecto Angular tiene configurado `styles.scss` y se declara `@import "tailwindcss";`, el compilador emitirá un warning deprecado de Sass (`[WARNING] Deprecation [plugin angular-sass]`).
- **Solución**: Se debe renombrar el archivo principal de `styles.scss` a `styles.css` (CSS puro) y actualizar la referencia en el array `"styles": ["src/styles.css"]` dentro de `angular.json`.

#### Componentes de Terceros y Strict Templates (TS2322)

**Regla Estricta**: Cuando se utilicen componentes de terceros (como `ng-apexcharts`) que reciban objetos de configuración con propiedades opcionales (`Partial<T>`), pero que en el template exijan validaciones estrictas (donde `undefined` no es asignable), se DEBE forzar el tipado a `any` o castearlo explícitamente en el archivo `.ts` en lugar de saturar el HTML con operadores non-null `!`.
- **Ejemplo ApexCharts**: `public chartOptions: Partial<ApexOptions> | any;` para evitar colisiones del compilador angular.

---

### Routing

#### Guardias (canActivate)

**Checklist de configuración:**

- [ ] ¿La ruta requiere validación de acceso?

  - ✅ Sí → Incluir array `canActivate`
- [ ] **Consulta obligatoria al usuario:**

  - ¿Se requiere plan de cuentas? → `accountPlanRequireGuard`
  - ¿Se requiere empresa seleccionada? → `CompanySelectedRequiredGuard`

**Ejemplo de configuración:**

```typescript
{
  path: 'facturas',
  component: FacturasComponent,
  canActivate: [
    CompanySelectedRequiredGuard,  // Empresa seleccionada
    accountPlanRequireGuard        // Plan de cuentas requerido
  ],
  data: { 
    breadcrumb: 'Facturas'
  }
}
```

---

#### Migas de Pan (Breadcrumb)

**🔴 OBLIGATORIO**: Cada ruta debe tener `data: { breadcrumb: '...' }`

```typescript
const routes: Routes = [
  {
    path: 'nomina',
    data: { breadcrumb: 'Nómina' },
    children: [
      {
        path: 'empleados',
        component: EmpleadosComponent,
        data: { breadcrumb: 'Empleados' }
      },
      {
        path: 'empleados/:id',
        component: EmpleadoDetalleComponent,
        data: { breadcrumb: 'Detalle' }
      }
    ]
  }
];

// Resultado visual: Nómina > Empleados > Detalle
```

---

### Notificaciones y Alertas

#### Resumen de Decisión

```
┌─────────────────────────────────────────────────┐
│  ¿Notificación breve de acción completada?     │
│                                                  │
│  SÍ → MatSnackBar                               │
│  NO → app-shared-alert                          │
│                                                  │
│  ¿Usuario debe leer y entender el mensaje?     │
│                                                  │
│  SÍ → app-shared-alert                          │
│  NO → MatSnackBar                               │
└─────────────────────────────────────────────────┘
```

---

#### 1. Notificaciones de Acciones (MatSnackBar)

**Uso exclusivo para:**

- ✅ Confirmación de operaciones exitosas
- ✅ Feedback breve de operaciones CRUD
- ✅ Mensajes que NO requieren interacción

**Ejemplos correctos:**

```typescript
// ✅ Operación exitosa
this.snackBar.open('Registro guardado correctamente', 'Cerrar', {
  duration: 3000
});

// ✅ Acción CRUD
this.snackBar.open('Elemento eliminado', 'Cerrar', {
  duration: 2000
});

// ✅ Feedback de subida
this.snackBar.open('Archivo subido', 'Cerrar', {
  duration: 2000
});
```

---

#### 2. Alertas Generales (app-shared-alert)

**Uso obligatorio para:**

- ✅ Validaciones de formulario
- ✅ Errores del backend/API
- ✅ Advertencias críticas
- ✅ Mensajes que requieren confirmación
- ✅ Errores de conexión
- ✅ Sesión expirada

**Ejemplos correctos:**

```typescript
// ✅ Error de validación
this.showAlert('error', 'El campo email es requerido');

// ✅ Error del backend
this.showAlert('error', 'Error al procesar la solicitud');

// ✅ Confirmación
this.showAlert('warning', '¿Está seguro de eliminar este registro?');

// ✅ Error de sesión
this.showAlert('error', 'Sesión expirada. Por favor, inicie sesión nuevamente');
```

---

#### 3. Tabla de Decisión

| Característica            | MatSnackBar             | app-shared-alert         |
| -------------------------- | ----------------------- | ------------------------ |
| **Duración**        | Temporal (2-3s)         | Persistente hasta cierre |
| **Interacción**     | Sin acción requerida   | Puede requerir acción   |
| **Propósito**       | Notificación pasiva    | Alerta importante        |
| **Prioridad visual** | Baja                    | Alta                     |
| **Casos de uso**     | "Guardado", "Eliminado" | Errores, validaciones    |

**⚠️ Regla de oro**: En caso de duda, preferir `app-shared-alert` para asegurar que el usuario vea el mensaje.

---

#### 4. Patrón de Implementación (app-shared-alert)

**Estructura obligatoria:**

```typescript
this._fuseAlertService.showAlert({
  type: 'error',              // 'error' | 'success' | 'warning' | 'info'
  appearance: 'outline',      // ✅ SIEMPRE 'outline'
  message: response.message,
  dismissible: true,
  dismissed: false,
  timeout: null,
  name: 'unique-component-alert-name', // ✅ Único por componente
  button_required: false,
  button_label: null,
  action_clicked: null
});
```

**🔴 CRÍTICO**:

- `appearance` debe ser **SIEMPRE** `'outline'`
- `name` debe ser **único por cada componente** para evitar colisiones de estado

**Ejemplos de nombres únicos:**

```typescript
// ✅ Buenos nombres
name: 'employee-form-alert'
name: 'invoice-list-alert'
name: 'user-settings-alert'

// ❌ Malos nombres (genéricos)
name: 'alert'
name: 'error-alert'
name: 'form-alert'
```

---

#### 5. Estándar de Respuesta de Error (JsonResponse)

**Patrón obligatorio para manejo de errores:**

```typescript
// ✅ PATRÓN CORRECTO
this._userService.createUser(userData)
  .pipe(
    takeUntil(this._unsubscribeAll),
    finalize(() => {
      this.isLoading = false;
      this._changeDetectorRef.markForCheck();
    })
  )
  .subscribe({
    next: (res) => {
      this.showAlertMessage('success', 'Usuario creado correctamente');
    },
    error: (response: JsonResponse<any>) => {
      // ✅ Tipado correcto: JsonResponse<any>
      // ✅ Nomenclatura: 'response' (no 'err' ni 'error')
      // ✅ Acceso directo: response.message
      this.showAlertMessage('error', response.message);
    }
  });
```

**Reglas de tipado:**

- ✅ **Tipo**: `JsonResponse<any>`
- ✅ **Nombre del argumento**: `response`
- ✅ **Acceso al mensaje**: `response.message`

**❌ Patrones incorrectos:**

```typescript
// ❌ Tipado incorrecto
error: (err: any) => { ... }

// ❌ Nomenclatura incorrecta
error: (err: JsonResponse<any>) => { ... }

// ❌ Acceso incorrecto
error: (response: JsonResponse<any>) => {
  this.showAlert(response.error.message); // ❌
}
```

---

### Suscripciones a Servicios

#### Diagrama de Decisión

```
┌───────────────────────────────────────────────┐
│  ¿El componente tiene propiedad isLoading?   │
├───────────────────────────────────────────────┤
│                                               │
│  SÍ → Patrón completo                        │
│       ├─ takeUntil(this._unsubscribeAll)     │
│       └─ finalize(() => {                    │
│            this.isLoading = false;           │
│            this._changeDetectorRef           │
│                .markForCheck();              │
│          })                                   │
│                                               │
│  NO → Patrón simplificado                    │
│       ├─ takeUntil(this._unsubscribeAll)     │
│       └─ finalize(() => {                    │
│            this._changeDetectorRef           │
│                .markForCheck();              │
│          })                                   │
└───────────────────────────────────────────────┘
```

---

#### 1. Patrón Completo (con isLoading)

```typescript
guardarDatos(): void {
  this.isLoading = true; // Activar loading

  this._dataService.save(this.formData)
    .pipe(
      takeUntil(this._unsubscribeAll),
      finalize(() => {
        // ✅ Se ejecuta SIEMPRE (éxito, error, cancelación)
        this.isLoading = false;
        this._changeDetectorRef.markForCheck();
      })
    )
    .subscribe({
      next: (res) => {
        this.showAlertMessage('success', 'Datos guardados correctamente');
        this.router.navigate(['/lista']);
      },
      error: (response: JsonResponse<any>) => {
        // ❌ NO duplicar isLoading = false aquí
        // ❌ NO duplicar markForCheck() aquí
        this.showAlertMessage('error', response.message);
      }
    });
}
```

---

#### 2. Patrón Simplificado (sin isLoading)

```typescript
cargarDatos(): void {
  this._dataService.getData()
    .pipe(
      takeUntil(this._unsubscribeAll),
      finalize(() => {
        // ✅ Solo markForCheck cuando no hay isLoading
        this._changeDetectorRef.markForCheck();
      })
    )
    .subscribe({
      next: (res) => {
        this.datos = res.data;
      },
      error: (response: JsonResponse<any>) => {
        this.showAlertMessage('error', response.message);
      }
    });
}
```

---

#### 3. Uso de takeUntil

**¿Cuándo usar `takeUntil(this._unsubscribeAll)`?**

| Escenario                           | Usar takeUntil   | Razón                                   |
| ----------------------------------- | ---------------- | ---------------------------------------- |
| Componente de larga duración       | ✅ SÍ           | Evita memory leaks                       |
| Observable con múltiples emisiones | ✅ SÍ           | Limpia suscripción al destruir          |
| Suscripción manual en componente   | ✅ SÍ           | Necesario para cleanup                   |
| HTTP request única                 | ⚠️ Recomendado | Buena práctica, aunque se completa solo |
| Uso de `async` pipe en template   | ❌ NO            | El pipe maneja la desuscripción         |
| Servicio singleton global           | ❌ NO            | Vive durante toda la app                 |

**Regla de oro**: **En caso de duda, usar `takeUntil`**. Es mejor prevenir memory leaks.

---

#### 4. Configuración Requerida del Componente

**Checklist obligatorio:**

```typescript
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { Component, OnDestroy, ChangeDetectorRef } from '@angular/core';

@Component({
  selector: 'app-mi-componente',
  templateUrl: './mi-componente.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush // ← Si se usa OnPush
})
export class MiComponente implements OnDestroy {
  
  // ✅ Subject para desuscripción
  private _unsubscribeAll: Subject<void> = new Subject<void>();
  
  // ✅ Propiedad isLoading (opcional, según necesidad)
  isLoading: boolean = false;
  
  constructor(
    private _changeDetectorRef: ChangeDetectorRef,
    private _dataService: DataService
  ) {}
  
  // ✅ Implementación obligatoria de OnDestroy
  ngOnDestroy(): void {
    this._unsubscribeAll.next();    // ← Emitir señal
    this._unsubscribeAll.complete(); // ← Completar el Subject
  }
}
```

**🔴 ERRORES COMUNES A EVITAR:**

```typescript
// ❌ ERROR 1: Olvidar .complete()
ngOnDestroy(): void {
  this._unsubscribeAll.next(); // ❌ Falta .complete()
}

// ❌ ERROR 2: Duplicar lógica en error
.subscribe({
  next: (res) => { ... },
  error: (err) => {
    this.isLoading = false;           // ❌ Ya está en finalize
    this._changeDetectorRef.markForCheck(); // ❌ Ya está en finalize
  }
});

// ❌ ERROR 3: No usar takeUntil en componentes
this._service.getData()
  .subscribe(...); // ❌ Falta takeUntil → memory leak
```

---

#### 5. Matriz de Decisión Completa

| Componente tiene isLoading | takeUntil necesario | Contenido de finalize                      |
| -------------------------- | ------------------- | ------------------------------------------ |
| ✅ SÍ                     | ✅ SÍ              | `isLoading = false` + `markForCheck()` |
| ❌ NO                      | ✅ SÍ              | Solo `markForCheck()`                    |
| ✅ SÍ                     | ⚠️ Recomendado    | `isLoading = false` + `markForCheck()` |
| ❌ NO                      | ⚠️ Recomendado    | Solo `markForCheck()`                    |

---

#### 6. Casos Especiales

**Peticiones HTTP únicas:**

```typescript
// Patrón para HttpClient (se completa automáticamente)
consultarApi(): void {
  this.isLoading = true;
  
  this._httpClient.get<ApiResponse>('/api/endpoint')
    .pipe(
      // takeUntil es opcional aquí, pero recomendado
      takeUntil(this._unsubscribeAll),
      finalize(() => {
        this.isLoading = false;
        this._changeDetectorRef.markForCheck();
      })
    )
    .subscribe({
      next: (res) => this.procesarDatos(res),
      error: (response: JsonResponse<any>) => {
        this.showAlertMessage('error', response.message);
      }
    });
}
```

**Observables de larga duración:**

```typescript
// WebSocket, Interval, Stream, etc.
escucharCambios(): void {
  this._websocketService.mensajes$
    .pipe(
      // ✅ takeUntil es OBLIGATORIO aquí
      takeUntil(this._unsubscribeAll),
      finalize(() => {
        this._changeDetectorRef.markForCheck();
      })
    )
    .subscribe({
      next: (mensaje) => this.procesarMensaje(mensaje)
    });
}
```

---

#### 7. Checklist de Validación

Antes de hacer commit, verificar:

- [ ] ¿El componente implementa `OnDestroy`?
- [ ] ¿Existe `_unsubscribeAll: Subject<void>`?
- [ ] ¿Se llama a `_unsubscribeAll.next()` en `ngOnDestroy`?
- [ ] ¿Se llama a `_unsubscribeAll.complete()` en `ngOnDestroy`?
- [ ] ¿La suscripción usa `takeUntil(this._unsubscribeAll)`?
- [ ] ¿Se usa `finalize()` para resetear estados?
- [ ] ¿NO se duplica lógica entre `finalize` y `error`?
- [ ] ¿Se inyectó `ChangeDetectorRef` en el constructor?
- [ ] Si usa `OnPush`: ¿Se llama a `markForCheck()` en `finalize`?

---

### Sincronización de Contratos API

**REGLA DE ORO**: Toda interface de Request en el Frontend (`/app/core/models/request`) debe ser un reflejo exacto de las reglas del `FormRequest` en Laravel.

#### 1. Tipado Estricto de Requests
Al crear o modificar una interface de envío de datos:
- Si el campo es `required` en Laravel → El campo en TS debe ser obligatorio.
- Si el campo es `nullable` en Laravel → El campo en TS debe ser opcional (`field?: type`).
- Si el campo tiene `exists` o `in` → Considerar el uso de `Enums` o tipos literales.

#### 2. Auditoría Cross-Stack
Antes de dar por finalizada la integración con un endpoint:
1. Validar que los nombres de los campos coincidan EXACTAMENTE con los keys en `rules()` del Backend.
2. Asegurar que los tipos de datos (string, number, boolean, array) sean coherentes.
3. Verificar si el cambio en el contrato requiere ajustes en las validaciones de `ReactiveForms` (`Validators.required`, etc).

#### 3. Ubicación de Interfaces
- **Models de Dominio**: `/app/core/models/data`
- **Request Payloads**: `/app/core/models/request`
- **Response Payloads**: `/app/core/models/response`

---

#### Checklist de Integración
- [ ] ¿Inicia sesión el usuario? (Validar vigencia de token)
- [ ] ¿Coincide la interface con el FormRequest?
- [ ] ¿Se manejan todos los posibles errores del backend (response.message)?
- [ ] ¿Se limpian las suscripciones con `_unsubscribeAll`?

---

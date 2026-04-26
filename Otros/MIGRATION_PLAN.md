# Plan Maestro: Migración Angular 18 → 21

## 🛡️ Mandatos del Usuario
1. **Runner**: Cambio obligatorio a **Vitest**.
2. **Arquitectura**: Meta final **Zoneless** en v21. Rigurosidad total.
3. **Estabilidad**: La app debe ser funcional en cada salto de versión (18→19→20→21).
4. **Auditoría**: Revisión de librerías terceras en cada paso.

## 🏗️ Fases de Ejecución

### Fase 0: Preparación
- [NEW] Crear Skill `angular-migration-architect`.
- Rama: `migration/ng18-to-ng21`.

### Fase 1: Angular 18 → 19
- `ng update @angular/core@19 @angular/cli@19`.
- Migración de Control Flow y Signals iniciales.
- Auditoría de dependencias Material.

### Fase 2: Angular 19 → 20
- Cambio de Builder a `@angular/build`.
- Sustitución de Karma por **Vitest**.
- Auditoría de Quill y ApexCharts.

### Fase 3: Angular 20 → 21
- `ng update @angular/core@21 @angular/cli@21`.
- Activación de **Zoneless**.
- Refactorización rigurosa de componentes a Signals.

## 🔍 Verificación
- Suite Vitest completa.
- Verificación visual de gráficos y editores.

¿Me das tu autorización para comenzar con la Fase 0?

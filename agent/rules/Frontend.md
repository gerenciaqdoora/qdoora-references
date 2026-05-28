---
trigger: always_on
---

# 🎨 Estándares de Ingeniería Frontend (Angular)

> Guía maestra de principios, estética y arquitectura para el desarrollo de interfaces. Como asistente, DEBES aplicar estas reglas de forma obligatoria en todo el ecosistema UI/UX de QdoorA.

---

## Filosofía de Desarrollo

El frontend de QdoorA exige una **experiencia premium**. ESTÁS OBLIGADO a construir interfaces reactivas, seguras y visualmente impactantes. TIENES PROHIBIDO entregar diseños genéricos, planos o descuidados.

### 1. Modern Angular (Standalone & Signals)
UTILIZA exclusivamente las capacidades modernas del framework para garantizar el máximo rendimiento y la mantenibilidad del código:
- **Standalone Components**: Diseña bajo una arquitectura 100% libre de módulos (`NgModules`). Cada componente que crees debe ser completamente autosuficiente.
- **Signals**: BASA la reactividad granular y el manejo de estados estrictamente en Signals, especialmente dentro del Portal de Soporte e interfaces reactivas de alta jerarquía.
- **Control Flow**: CONFIGURA de forma mandatoria la nueva sintaxis estructurada (`@if`, `@for`, `@switch`). TIENES TERMINANTEMENTE PROHIBIDO utilizar directivas estructurales heredadas (`*ngIf`, `*ngFor`).

### 2. Reutilización y Consistencia Estricta
> [!IMPORTANT]
> **REGLA DE ORO**: ANTES de escribir un solo elemento de interfaz, ESTÁS OBLIGADO a revisar exhaustivamente el directorio `/app/modules/shared`. TIENES PROHIBIDO reinventar la rueda; debes refinarla y reutilizarla.

- EMPLEA de forma mandatoria los componentes compartidos existentes (`app-input-form`, `app-table`, etc.) para garantizar la consistencia visual y asegurar que cualquier cambio estético se propague inmediatamente a toda la plataforma.

---

## 💎 Estética y Diseño Premium QdoorA

Tus diseños deben generar un impacto visual inmediato de alta fidelidad:
- **Tipografía**: CONFIGURA fuentes con carácter e identidad propio (Outfit, Space Grotesk). TIENES PROHIBIDO dejar las tipografías por defecto del navegador o del framework.
- **Composición**: UTILIZA de forma generosa el espacio negativo y diseña composiciones asimétricas limpias para romper la monotonía de las cuadrículas tradicionales.
- **Profundidad**: APLICA gradientes sutiles, desenfoques de fondo (_backdrop-blur_) y transparencias en capas para construir una jerarquía visual moderna y limpia.

---

## 🔐 Seguridad y Calidad del Lado del Cliente

### 1. Blindaje contra Inyecciones XSS (Vector QD-07)
- **TIENES TERMINANTEMENTE PROHIBIDO el uso de la directiva `[innerHTML]`** para renderizar datos dinámicos provenientes de la API. Si requieres mostrar texto, hazlo exclusivamente mediante interpolación segura `{{ }}`. La seguridad es innegociable.

### 2. Gestión de Sesión Segura
- ALMACENA el token de autenticación estrictamente en `sessionStorage`. TIENES PROHIBIDO utilizar `localStorage` para el portal administrativo y de soporte con el fin de mitigar riesgos de persistencia ante ataques de secuestro de sesión.
- CONFIGURA los Guards para que revaliden activamente los permisos contra el backend en cada salto de navegación crítica; nunca confíes ciegamente en el payload decodificado del JWT en el cliente.

### 3. Integridad Inamovible de Contratos
- ESTÁS OBLIGADO a sincronizar los tipos de datos con el Backend utilizando la lógica del `api-contract-aligner` antes de escribir cualquier interfaz de TypeScript. Las restricciones de Laravel (`required`, `nullable`, tipos de datos) deben verse reflejadas exactamente en tus definiciones de código del Frontend.

---

## ⚙️ Patrones Operativos Obligatorios

### 1. Gestión de Memoria (RxJS)
- EVITA activamente las fugas de memoria (_memory leaks_). Cuando utilices flujos observables de RxJS que no manejen ciclos de vida autocompletables, IMPLEMENTA obligatoriamente el patrón de desuscripción centralizado utilizando una propiedad privada `_unsubscribeAll: Subject<any>` combinada con el operador `takeUntil`.

### 2. Estados de Carga y Feedback
- NUNCA dejes la interfaz de usuario congelada o bloqueada sin feedback visual. ESTÁS OBLIGADO a utilizar el operador `finalize` en tus flujos de peticiones HTTP para asegurar que los estados de carga (`isLoading = false`) se limpien de forma determinista, tanto en escenarios de éxito como de error de red.

### 3. Notificaciones y Alertas Stacked (Simultáneas)
DIFERENCIA estrictamente los casos de uso para alertas dentro del sistema:
- **Feedback Pasivo e Informativo (`NotificationService`)**: Utilízalo para confirmaciones de éxito (ej. "Perfil actualizado"), advertencias o errores no bloqueantes. Estas alertas se deben apilar simultáneamente sin borrar las anteriores y desaparecerán solas de forma reactiva mediante Signals (`notifications()`), configurando el contenedor con `pointer-events: none` y las alertas con `pointer-events: auto` para no interferir con los clics del usuario. Inyecta los textos exclusivamente con `{{ }}` para blindar contra el vector **QD-07**. TIENES PROHIBIDO usar `MatSnackBar` nativo.
- **Alertas Críticas o Bloqueantes (`app-shared-alert`)**: Utilízalas obligatoriamente cuando el sistema requiera una decisión explícita o advertencias destructivas (ej. "Eliminar datos permanentes"). Este patrón debe capturar el foco e impedir que el usuario continúe sin interactuar.

### 4. Apertura Segura de Archivos y Descargas (`SecureTabService`)
Para abrir o descargar documentos (PDFs, planillas, adjuntos) de forma asíncrona tras peticiones HTTP o polling, ESTÁS OBLIGADO a implementar el `SecureTabService` para burlar los bloqueadores de popups de navegadores modernos:
1. ABRE síncronamente una pestaña en blanco (`window.open('', '_blank')`) en el hilo inmediato del clic del usuario e inyecta el loader animado premium de la plataforma.
2. UTILIZA la referencia `SecureTabRef` devuelta para redirigir la pestaña dinámicamente (`redirect(url)`) una vez que el servidor responda de forma asíncrona.
3. CIERRA la pestaña (`close()`) de forma limpia y transparente si el backend llega a fallar, evitando dejar ventanas vacías colgando en el navegador.

### 5. Estándar de Diálogos y Paneles Personalizados (MatDialog)
Para garantizar la coherencia estética de los modales y evitar defectos visuales como el sangrado de esquinas blancas (_corner bleed_) o el recorte de bordes en alertas:
- **Estructura HTML**: EXIGE exactamente este orden utilizando las clases de contenedor estándar en las plantillas de los modales:
```html
<div class="standard-dialog-container relative">
    <app-dialog-header title="..." subtitle="..." [showCloseButton]="..."></app-dialog-header>
    <div class="standard-dialog-content">
        </div>
    <app-dialog-footer>...</app-dialog-footer>
</div>
```
- **Panel Class y Remoción de Padding**: Al abrir los diálogos desde el servicio, CONFIGURA obligatoriamente la propiedad `panelClass: 'dialog-panel'` (o su equivalente dedicada) asegurando un `padding: 0 !important;` absoluto en la superficie del modal. TIENES PROHIBIDO aplicar márgenes negativos (`-m-6`) en las vistas para corregir espacios.
- **Esquinas Redondeadas Continuas**: REVISALAS para que el contenedor principal (`.mdc-dialog__surface`) mantenga la propiedad `overflow: hidden !important` activa globalmente en los estilos base para que los encabezados y pies de página se acoplen perfectamente al radio de curvatura (`border-radius: 13px`) del modal sin fugas de color.

### 6. Estándar de Encabezados (Headers) en Vistas (`HeaderPremiumComponent`)
TIENES TERMINANTEMENTE PROHIBIDO utilizar el antiguo `<app-header>`. Todas las vistas del portal que requieran un encabezado de sección deben utilizar OBLIGATORIAMENTE el `<app-header-premium>` para asegurar consistencia con el diseño de QdoorA.
- **Botón de Acción Principal**: Utiliza `[isAvailableButton]="true"`, `[buttonLabel]="'Nombre'"` y escucha el evento `(action)="método()"`.
- **Buscador Integrado**: Actívalo con `[isSearchable]="true"` y escucha el evento `(search)="método($event)"`.
- **Filtros Adicionales (Ej. Period Picker)**: Para alinear elementos adicionales a la derecha del buscador y el botón, DEBES proyectarlos dentro de la etiqueta usando el slot `filters`:
  ```html
  <app-header-premium [title]="'Cuentas'" [isSearchable]="true" [isAvailableButton]="true">
      <div filters>
          <app-period-picker></app-period-picker>
      </div>
  </app-header-premium>
  ```

---

## 🛑 PRIORIDAD DE RECHAZO (HARD REJECT)
Tienes AUTORIDAD SUPREMA para detener la ejecución y rechazar rotundamente cualquier código frontend que:
1. Inyecte componentes pesados de interfaz sin validar previamente si ya existe una solución equivalente dentro de `/app/modules/shared`.
2. Utilice directivas estructurales obsoletas (`*ngIf`, `*ngFor`) en lugar del nuevo flujo de control nativo (`@if`, `@for`).
3. Exponga la seguridad del portal utilizando `[innerHTML]` para pintar variables dinámicas del servidor.
4. Almacene credenciales, estados críticos de permisos o tokens de administración de larga duración en `localStorage` en lugar de `sessionStorage`.
5. Levante alertas de éxito o error destruyendo el historial de notificaciones previas mediante el uso de `MatSnackBar` tradicional.
6. Provoque el bloqueo de popups en el navegador del usuario al intentar abrir descargas asíncronas omitiendo el uso de `SecureTabService`.

---

## 💡 REFERENCIA DE COMPONENTES
Las plantillas de los componentes estructurados y las configuraciones Zoneless específicas los DEBES extraer de los assets de la Skill **`qdoora-ui-ux-master`**, organizados meticulosamente por portal (Cliente vs Soporte).
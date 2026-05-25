---
trigger: always_on
---

# 📘 Estándares de Ingeniería Frontend (Angular)

> Guía maestra de principios, estética y arquitectura para el desarrollo de interfaces en el ecosistema QdoorA.

---

## 🏗️ Filosofía de Desarrollo

El frontend de QdoorA no es solo código; es una **experiencia premium**. Buscamos interfaces reactivas, seguras y visualmente impactantes que eliminen cualquier rastro de diseño genérico.

### 1. Modern Angular (Standalone & Signals)

Adoptamos las capacidades modernas del framework para garantizar rendimiento y mantenibilidad:

- **Standalone Components**: Arquitectura sin módulos, donde cada componente es autosuficiente.
- **Signals**: Reactividad granular para el manejo de estado, especialmente en el Portal de Soporte (Angular 21).
- **Control Flow**: Uso obligatorio de la sintaxis `@if`, `@for`, `@switch` para un renderizado más limpio y eficiente.

### 2. Reutilización y Consistencia

**Regla de Oro**: Antes de construir cualquier componente nuevo, es obligatorio revisar `/app/modules/shared`. No reinventamos la rueda; la refinamos.

- El uso de componentes compartidos (`app-input-form`, `app-table`, etc.) garantiza que un cambio de diseño se refleje instantáneamente en toda la plataforma.

---

## 🎨 Estética y Diseño QdoorA

Nuestras interfaces deben generar un "Wow factor" inmediato.

- **Tipografía**: Uso de fuentes con carácter (Outfit, Space Grotesk) evitando valores por defecto del navegador.
- **Composición**: Uso generoso del espacio negativo y composiciones asimétricas para romper la monotonía de las cuadrículas tradicionales.
- **Profundidad**: Aplicación de gradientes sutiles y transparencias en capas para crear jerarquía visual.

---

## 🔐 Seguridad y Calidad del Lado del Cliente

### 1. Blindaje contra XSS (QD-07)

Está terminantemente prohibido el uso de `[innerHTML]` para renderizar datos provenientes de la API. La seguridad del usuario es innegociable.

### 2. Gestión de Sesión Segura

- El token de autenticación debe residir en `sessionStorage`. Evitamos `localStorage` para mitigar riesgos de persistencia ante posibles ataques.
- Los Guards deben revalidar permisos contra el backend en navegaciones críticas; no confiamos únicamente en el payload del JWT.

### 3. Integridad de Contratos

Antes de definir interfaces de datos, es obligatorio sincronizar con el Backend mediante el `api-contract-aligner`. Las reglas de validación de Laravel (required, nullable) deben mapearse exactamente a tipos de TypeScript.

---

## 🛠️ Patrones Operativos

### 1. Gestión de Memoria (RxJS)

Para prevenir fugas de memoria (_memory leaks_), implementamos siempre el patrón de desuscripción con `_unsubscribeAll` y el operador `takeUntil`.

### 2. Estados de Carga y Feedback

La UI nunca debe quedar bloqueada sin feedback. Usamos el operador `finalize` para asegurar que los estados de carga (`isLoading`) se limpien correctamente, tanto en éxito como en error.

### 3. Notificaciones y Alertas Stacked (Simultáneas)

Diferenciamos claramente los casos de uso para las alertas dentro del ecosistema:

- **Feedback Pasivo e Informativo (`NotificationService`)**: Reemplaza el uso histórico de `MatSnackBar`. Debe usarse para confirmaciones de éxito (ej. "Perfil actualizado"), advertencias informativas o errores no bloqueantes. Las notificaciones se apilan automáticamente sin bloquear la pantalla y desaparecen tras su duración, no requiriendo interacción obligatoria.
- **Alertas Críticas o Bloqueantes (`app-shared-alert`)**: Debe usarse cuando el sistema requiere una decisión explícita, advertencias críticas (ej. "Estás a punto de eliminar datos permanentes") o atención inmediata y obligatoria. Obliga al usuario a tomar una acción antes de continuar.

El sistema utiliza un mecanismo premium de **Notificaciones Stacked Simultáneas** gestionadas globalmente por el `NotificationService` y visualizadas a través de `NotificationStackComponent`.

- **Bypass de Limitación**: Reemplaza el `MatSnackBar` nativo (el cual descarta alertas anteriores) permitiendo apilar múltiples notificaciones simultáneas sin pérdida de información.
- **Manejo de Estado Reactivo**: Se gestiona mediante Signals (`notifications()`), evitando suscripciones manuales y previniendo fugas de memoria (_memory leaks_).
- **Interactividad Premium**: El contenedor global se define con `pointer-events: none` para no bloquear los clics del usuario en la interfaz del portal, mientras que cada alerta usa `pointer-events: auto`.
- **Prevención de XSS (QD-07)**: La inyección de mensajes se realiza exclusivamente con interpolación de texto plano `{{ }}` en el DOM, blindando el componente contra XSS almacenado o reflejado.

### 4. Apertura Segura de Archivos y Descargas (`SecureTabService`)

Para abrir o descargar documentos (PDFs, planillas Excel, archivos adjuntos) de forma asíncrona (ej: tras peticiones HTTP o polling de generación) sin ser bloqueado por los bloqueadores de popups de navegadores modernos (Safari, Chrome, Firefox), es obligatorio el uso de `SecureTabService`.

- **Bypass de Popup Blocker**: Abre síncronamente una pestaña en blanco (`window.open('', '_blank')`) en el hilo de ejecución inmediato del clic del usuario, inyectando un loader premium animado.
- **Redirección e Interfaz Fluida**: Retorna una referencia `SecureTabRef` que permite realizar la redirección dinámica (`redirect(url)`) asíncronamente una vez generado el archivo, manteniendo el portal principal intacto.
- **Limpieza de Recursos**: Permite cerrar la pestaña (`close()`) de forma transparente ante fallos de servidor para no dejar ventanas vacías colgando.
- **Prevención de XSS (QD-07)**: Sanitiza rigurosamente los textos principales y secundarios inyectados en la nueva pestaña para impedir inyecciones de código HTML/JS reflejadas.


### 5. Estándar de Diálogos y Paneles Personalizados (MatDialog)

Para asegurar la coherencia estética en todos los modales (incluyendo diálogos de cambio de contraseña obligatoria, formularios, etc.) y evitar defectos visuales comunes como el sangrado de esquinas blancas (corner bleed) y el recorte de bordes en alertas:

- **Estructura HTML**: Usa la clase `standard-dialog-container` en el contenedor raíz y `standard-dialog-content` para la sección central del cuerpo del diálogo:
  ```html
  <div class="standard-dialog-container relative">
      <app-dialog-header title="..." subtitle="..." [showCloseButton]="..."></app-dialog-header>
      <div class="standard-dialog-content">
          <!-- Alertas y campos del formulario aquí -->
      </div>
      <app-dialog-footer>...</app-dialog-footer>
  </div>
  ```
- **Panel Class y Remoción de Padding**: Abre los diálogos utilizando `panelClass: 'dialog-panel'` o una clase de panel dedicada configurada para establecer `padding: 0 !important;` en la superficie del diálogo. Evita hacks de márgenes negativos (`-m-6`) en las plantillas.
- **Esquinas Redondeadas Continuas**: El contenedor principal de diálogos de Angular Material (`.mdc-dialog__surface`) debe tener la propiedad `overflow: hidden !important` activa globalmente en el sistema para obligar al renderizado de cabeceras, fondos y pies de página a seguir el `border-radius: 13px` del modal sin sangrados ni bordes blancos visibles.

---

> [!TIP]
> Los patrones de código exactos, ejemplos de componentes y plantillas de implementación para estos principios se encuentran disponibles en los assets de la Skill **`qdoora-ui-ux-master`**, organizados por portal (Cliente vs Soporte).

---
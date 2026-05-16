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
Para prevenir fugas de memoria (*memory leaks*), implementamos siempre el patrón de desuscripción con `_unsubscribeAll` y el operador `takeUntil`.

### 2. Estados de Carga y Feedback
La UI nunca debe quedar bloqueada sin feedback. Usamos el operador `finalize` para asegurar que los estados de carga (`isLoading`) se limpien correctamente, tanto en éxito como en error.

### 3. Notificaciones y Alertas
Diferenciamos claramente entre feedback pasivo (`MatSnackBar`) y alertas que requieren atención o acción del usuario (`app-shared-alert`).

---

> [!TIP]
> Los patrones de código exactos, ejemplos de componentes y plantillas de implementación para estos principios se encuentran disponibles en los assets de la Skill **`qdoora-ui-ux-master`**, organizados por portal (Cliente vs Soporte).

---

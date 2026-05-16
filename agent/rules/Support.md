# 📘 Estándares de Ingeniería: Portal de Soporte y Admin

> Guía maestra de principios, seguridad y arquitectura para el portal de alta jerarquía de QdoorA (Angular 21).

---

## 🏗️ Filosofía Arquitectónica: Alta Performance

El portal administrativo está diseñado bajo el paradigma de **Máxima Eficiencia y Baja Latencia**. Al manejar grandes volúmenes de datos y privilegios críticos, la arquitectura debe ser ligera y altamente reactiva.

### 1. Vanguardia Angular 21 (Zoneless & Signals)
Adoptamos el estado del arte de Angular para eliminar sobrecargas innecesarias:
- **Zoneless**: Operamos sin `zone.js`. La detección de cambios es responsabilidad de las señales y las APIs nativas del framework, lo que reduce el uso de CPU en el navegador.
- **Signals**: Toda la reactividad del portal debe basarse en Signals. Esto permite actualizaciones granulares del DOM y una lógica de estado predecible y síncrona.

### 2. Ecosistema de Compilación (Vite & Tailwind v4)
- **Vite**: Utilizamos el bundler de alto rendimiento. Las configuraciones de aliases y tipos deben ser estrictamente relativas (`./`).
- **Tailwind v4**: La gestión de estilos es CSS-first. No usamos archivos de configuración JS; toda la identidad visual reside en el bloque `@theme` del archivo CSS principal.

---

## 🔐 Seguridad y Acceso Administrativo (IAM)

El Portal de Soporte es el activo de mayor riesgo. La seguridad es la prioridad número uno sobre la funcionalidad.

### 1. Aislamiento de Scopes
- Cada petición enviada desde este portal debe portar el claim de scope correspondiente (`support` o `admin`).
- El acceso está segmentado: el personal de soporte no tiene acceso a herramientas de nivel de administrador del sistema.

### 2. Validación Server-Side Obligatoria
**Mandato de Hierro**: No se confía en el estado local del cliente.
- Los Guards deben revalidar permisos contra el backend (`/api/auth/check-permission/`) en cada salto de navegación crítica.
- Está estrictamente prohibido persistir tokens de administración en `localStorage`. Solo se permite el uso de `sessionStorage` para asegurar que la sesión expire al cerrar la pestaña.

### 3. Blindaje contra Inyecciones (QD-07)
Dado el alto privilegio de los paneles administrativos, el riesgo de XSS es crítico. El uso de `[innerHTML]` está terminantemente prohibido para prevenir cualquier vector de ejecución de scripts maliciosos.

---

## 🛠️ Patrones Operativos de Administración

### 1. Interceptores Funcionales
Adoptamos el patrón funcional de Angular 18+ para la inyección de cabeceras de autenticación y manejo de errores globales, eliminando la complejidad de las clases interceptoras tradicionales.

### 2. Integridad de Datos Críticos
Antes de cualquier modificación en interfaces de administración, es obligatorio realizar una **Auditoría de Impacto** mediante el `api-contract-aligner` para garantizar que la vista de administración refleje fielmente las reglas de negocio del Backend.

---

> [!TIP]
> Los patrones de código exactos, configuraciones Zoneless y plantillas de implementación para el portal administrativo se encuentran disponibles en los assets de la Skill **`qdoora-ui-ux-master`** bajo la sección de **Soporte**.

---

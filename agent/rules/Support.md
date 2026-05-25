---
trigger: always_on
---

# 🏢 Estándares de Ingeniería: Portal de Soporte y Admin

> Guía maestra de principios, seguridad y arquitectura. Como asistente, DEBES aplicar estas reglas de forma obligatoria en el portal de alta jerarquía de QdoorA (Angular 21).

---

## ⚡ Filosofía Arquitectónica: Alta Performance

El portal administrativo exige **Máxima Eficiencia y Baja Latencia**. Al manejar grandes volúmenes de datos y privilegios críticos, TIENES QUE estructurar la arquitectura para que sea ligera y altamente reactiva.

### 1. Vanguardia Angular 21 (Zoneless & Signals)
ESTÁS OBLIGADO a usar el estado del arte de Angular para eliminar sobrecargas:
- **Zoneless**: DEBES operar sin `zone.js`. La detección de cambios es responsabilidad exclusiva de las señales y las APIs nativas del framework.
- **Signals**: BASA toda la reactividad del portal estrictamente en Signals. Esto permite actualizaciones granulares del DOM y una lógica de estado predecible y síncrona.

### 2. Ecosistema de Compilación (Vite & Tailwind v4)
- **Vite**: UTILIZA el bundler nativo. Las configuraciones de aliases y tipos DEBEN ser estrictamente relativas (`./`).
- **Tailwind v4**: APLICA una gestión de estilos CSS-first. TIENES PROHIBIDO generar o modificar archivos de configuración JS para Tailwind; toda la identidad visual DEBE residir en el bloque `@theme` del archivo CSS principal.

---

## 🔐 Seguridad y Acceso Administrativo (IAM)

El Portal de Soporte es nuestro activo de mayor riesgo. TIENES QUE priorizar la seguridad por encima de cualquier conveniencia funcional.

### 1. Aislamiento de Scopes
- INYECTA el claim de scope correspondiente (`support` o `admin`) en cada petición enviada desde este portal.
- RESPETA la segmentación: el personal de soporte NUNCA debe tener acceso a componentes o rutas de nivel administrador del sistema.

### 2. Validación Server-Side Obligatoria
> [!CAUTION]
> **MANDATO DE HIERRO**: TIENES ESTRICTAMENTE PROHIBIDO confiar en el estado local del cliente para la autorización.

- CONFIGURA los Guards para que revaliden los permisos contra el backend (`/api/auth/check-permission/`) en cada salto de navegación crítica.
- **NUNCA** persistas tokens de administración en `localStorage`. DEBES utilizar EXCLUSIVAMENTE `sessionStorage` para asegurar que la sesión muera al cerrar la pestaña.

### 3. Blindaje contra Inyecciones (Vector QD-07)
Dado el alto privilegio, el riesgo de XSS es inaceptable. TIENES TERMINANTEMENTE PROHIBIDO el uso de la directiva `[innerHTML]` bajo cualquier circunstancia para prevenir la ejecución de scripts maliciosos.

---

## ⚙️ Patrones Operativos de Administración

### 1. Interceptores Funcionales
IMPLEMENTA obligatoriamente el patrón funcional (Angular 18+) para la inyección de cabeceras de autenticación y el manejo de errores globales. NO crees clases interceptoras tradicionales basadas en POO.

### 2. Integridad de Datos Críticos
ANTES de escribir código para modificar interfaces de administración, ESTÁS OBLIGADO a realizar una **Auditoría de Impacto** revisando los contratos para garantizar que la vista refleje fielmente las reglas de negocio del Backend.

### 3. Pre-carga de Datos Contables y Maestros (Resolvers)
ESTÁS OBLIGADO a cargar los datos de las vistas complejas (Plan de Cuentas - PUC, categorías maestras o variables globales inmutables) a través de **Route Resolvers funcionales** mediante `inject()`. 
- TIENES PROHIBIDO permitir que un componente se renderice en un estado vacío o inconsistente mientras espera estas estructuras base.

---

> [!TIP]
> **REFERENCIA**: Los patrones de código exactos, configuraciones Zoneless y plantillas de implementación para el portal administrativo los DEBES extraer de los assets de la Skill **`qdoora-ui-ux-master`** bajo la sección de **Soporte**.

---
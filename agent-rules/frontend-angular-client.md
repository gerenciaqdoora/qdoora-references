---
trigger: always_on
globs: fuse-starter/**/*
description: Estándares de Ingeniería Frontend Angular 18 (Área Cliente) - QdoorA
---

# 👤 CONTEXTO FRONTEND: ANGULAR 18 (CLIENTE)
Estás trabajando en el área de Frontend del Cliente (directorio `./fuse-starter`). Prioriza la reactividad moderna y la seguridad del lado del cliente.

## 🛠️ Instrucciones Críticas de Implementación

1. **Arquitectura y Estándares**:
   - Adhiérete estrictamente a las normas en `./qdoora-references/Rules/Frontend.md`.
   - **Modern Angular**: Uso obligatorio de **Standalone Components**, **Signals** para el manejo de estado y el nuevo **Control Flow** (`@if`, `@for`, `@switch`).
   - **Reutilización**: Antes de crear componentes nuevos, verifica y prioriza `./fuse-starter/src/app/modules/shared`.

2. **Seguridad y Acceso (IAM)**:
   - **Validación Server-Side**: Los Guards DEBEN revalidar permisos contra el backend en cada navegación crítica; no confíes en el estado local del JWT para autorizar acciones.
   - **Prohibición de innerHTML**: Queda estrictamente prohibido el uso de `[innerHTML]` para renderizar datos provenientes de la API para prevenir XSS (hallazgo **QD-07**).
   - **Storage**: Usa `sessionStorage` para el token; evita `localStorage` para mitigar riesgos de persistencia ante ataques XSS.

3. **Integridad y Contratos**:
   - **Alineación API**: Antes de definir o modificar una Interface, activa `api-contract-aligner/SKILL.md` para asegurar que coincida exactamente con el `FormRequest` de Laravel.
   - **Pipes Obligatorios**: Usa `FormatAmountPipe` para montos monetarios y `RutFormatPipe` para identificadores legales.

4. **Gestión de Ciclo de Vida y RxJS**:
   - **Desuscripción**: Implementar siempre el patrón de desuscripción con `_unsubscribeAll` y `takeUntil`.
   - **Finalización**: Usa el operador `finalize` para limpiar estados de carga (*loading states*) y asegurar que la UI sea consistente.

## 🚨 Modo de Operación / Refutación
Detén la generación de código si:
- Se intenta manejar lógica de roles o permisos basándose solo en el payload del JWT decodificado (Vector **QD-01**).
- Se crean interfaces manuales que no han sido validadas contra el backend.
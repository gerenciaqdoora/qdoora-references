---
trigger: always_on
globs: support-portal/**/*
description: Estándares de Ingeniería Angular 21 (Portal Soporte/Admin) - QdoorA
---

# 🔑 CONTEXTO FRONTEND: ANGULAR 21 (SOPORTE & ADMIN)
Estás trabajando en el portal de alta jerarquía (directorio `./support-portal`). Este entorno utiliza **Angular 21 Zoneless** y maneja privilegios críticos de administración.

## 🛠️ Instrucciones Críticas de Implementación

1. **Arquitectura de Alta Performance**:
   - Adhiérete estrictamente a `./qdoora-references/Rules/Support.md`.
   - **Zoneless & Signals**: El uso de **Signals** es obligatorio para toda la reactividad del portal; no dependas de Zone.js.
   - **Abstracción de Soporte**: Al implementar lógica compartida con el portal de clientes, asegúrate de que la extensión sea segura y no exponga datos de administración al cliente.

2. **Seguridad y Acceso Administrativo (IAM)**:
   - **Scope: Support/Admin**: Todo request enviado desde este portal debe portar el claim de scope correspondiente (`support` o `admin`).
   - **permissionGuard**: Usa obligatoriamente el Guard basado en Signals que revalida permisos contra el backend (`/api/auth/check-permission/`).
   - **Interceptor Funcional**: Implementar `authInterceptor` mediante funciones (pattern funcional de Angular 18+).

3. **Integridad de Datos Críticos**:
   - **Contract Alignment**: Antes de modificar una interface de administración, activa `api-contract-aligner/SKILL.md` para sincronizar con el backend de Laravel.
   - **Auditoría de Inyección**: Dado el alto riesgo de XSS en paneles administrativos, el uso de `[innerHTML]` está terminantemente prohibido (Vector **QD-07**).

4. **Documentación Proactiva**:
   - Cualquier decisión arquitectónica sobre cómo el portal Admin consume la API Global debe ser documentada por el `technical-scribe-documentarian` en `./qdoora-references/Rules/Support.md`.

## 🚨 Prioridad de Refutación
Detén la generación si:
- Se intenta utilizar `localStorage` para persistir tokens de administración.
- La lógica de navegación depende de una verificación local de roles en lugar de una validación server-side.
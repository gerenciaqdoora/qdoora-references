# CLAUDE.md — Guía Universal QdoorA

Este archivo contiene los estándares técnicos, comandos y reglas de arquitectura para el ecosistema QdoorA. Es la fuente de verdad para Claude Code y Antigravity.

## 📦 Comandos de Construcción y Test

### Backend (Laravel 11)

- **Tests**: `php artisan test` o `vendor/bin/pest`
- **Migraciones**: `php artisan migrate` (Solo en desarrollo local)
- **Cache**: `php artisan optimize:clear`

### Frontend (Angular 18/21)

- **Dev**: `npm run start`
- **Build**: `npm run build`
- **Lint**: `npm run lint`

---

## 🏛️ Mandatos de Arquitectura (Hard Rules)

### 🔴 [Reglas Globales](./qdoora-references/agent/rules/GLOBAL_RULES.md)

1. **Multitenancy**: Todo dato debe estar filtrado por `company_id`.
2. **Layered Architecture**: Lógica de negocio EXCLUSIVA en `Services`. Controladores delgados.
3. **Stateless (AWS)**: Prohibido guardar archivos localmente. Usar S3. Prohibido usar `session()` de PHP.

### 🐘 [Backend](./qdoora-references/agent/rules/Backend.md)

- **Seguridad**: Uso obligatorio de `FormRequest` para validación. No usar `findOrFail`.
- **Endpoints**: Los endpoints administrativos deben ir en el grupo `v1/support`.
- **Integridad**: `softDeletes` requiere discusión obligatoria antes de aplicarse.

### 🅰️ [Frontend](./qdoora-references/agent/rules/Frontend.md)

- **Estética**: Diseño premium, tipografía Outfit/Space Grotesk, micro-interacciones suaves.
- **Seguridad**: Prohibido el uso de `[innerHTML]` (Vector **QD-07**). Tokens en `sessionStorage`.
- **Componentes**: Usar componentes de `shared/` (`app-input-form`, `app-table`) en lugar de Material directo.

### 🎫 [Soporte y Admin](./qdoora-references/agent/rules/Support.md)

- **Angular 21**: Uso de Signals y arquitectura Zoneless.
- **Validación IAM**: Revalidación server-side de permisos en cada salto de navegación.
- **Tailwind v4**: Configuración de estilos mediante `@theme` en CSS.

---

## 🛠️ Guía de Estilo de Código

- **Idioma**: Comentarios y documentación técnica en español. Mensajes de error al usuario en español.
- **Tipado**: TypeScript estricto. Interfaces sincronizadas con el backend mediante `api-contract-aligner`.
- **Git**: Commits descriptivos siguiendo el estándar del proyecto.

---

> [!NOTE]
> Este archivo es mantenido automáticamente por la skill `technical-scribe-documentarian`. No editar manualmente.

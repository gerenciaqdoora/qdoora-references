---
name: qdoora-guard
description: >
  Confección e implementación de guards de ruta y control de acceso client-side en el
  Portal Cliente (fuse-starter, Angular 18). Cubre el espejo frontend del modelo de
  autorización del backend: módulo contratado (hasModuleGuard) y permiso por submódulo
  con operación CRUD (hasSubmodulePermissionGuard), más la convención para ocultar
  botones y acciones en templates según permiso.

  Usar AUTOMÁTICAMENTE cuando el usuario pida: crear o proteger una ruta nueva, ocultar
  un botón según permisos, "que solo vea esto quien tenga permiso", guards de Angular,
  control de acceso en el frontend, o cuando se agregue una página a un módulo existente.
---

# QdoorA Guard — Autorización Client-Side

Construyes el espejo frontend del modelo de autorización que el backend ya aplica en sus
FormRequests. Tu salida son guards de ruta y chequeos de UI que **ocultan** lo que el
usuario no puede hacer.

## ⛔ REGLA CERO — El guard es UX, nunca seguridad

Un guard de Angular **no protege nada**. Cualquiera puede saltárselo con devtools o
llamando la API directo con `curl`. La barrera real es el `authorize()` del FormRequest.

Consecuencia práctica y obligatoria:

> **Nunca escribas un guard sin verificar antes que existe su contraparte en el backend.**
> Si la ruta que proteges consume un endpoint cuyo FormRequest NO valida ese submódulo,
> no estás asegurando: estás decorando. Corrige primero el backend
> (skill `qdoora-laravel-form-requests`), después el guard.

Un `submodule_code` inventado en el frontend bloquea la UI sin que ninguna validación
real lo respalde — el peor de los dos mundos.

## Árbol de decisión

| Lo que necesitas proteger | Guard | Dónde se aplica |
|---|---|---|
| Toda una rama de negocio (módulo contratado por el suscriptor) | `hasModuleGuard(['BILLING'])` | En `app.routes.ts`, en el nodo que hace `loadChildren` |
| Una página concreta dentro del módulo | `hasSubmodulePermissionGuard('BILLING.SETTING', 'review')` | En el `*.route.ts` del módulo, por cada hijo |
| Que exista empresa activa | `CompanySelectedRequiredGuard` | Igual, por cada hijo |
| Un botón o acción dentro de una página | `@if (permissions.can(...))` en el template | Ver `assets/ui-permission-check.md` |

Los tres guards se combinan en el mismo array y se evalúan en orden:

```typescript
canActivate: [
    CompanySelectedRequiredGuard,
    hasSubmodulePermissionGuard('BILLING.SETTING', 'review'),
],
```

## Reglas duras

1. **`can$` en guards, `can` en templates.** La matriz de permisos llega por HTTP después
   del arranque. Un guard que lea el valor de forma síncrona deniega el acceso en un
   deep-link a un usuario que sí tiene permiso. `can$` espera la primera emisión; `can`
   es para templates, donde el re-render posterior corrige solo.

2. **`review` para acceder, la operación real para actuar.** Entrar a una página exige
   `review`. El botón que crea algo exige `create`, el que edita `update`, el que elimina
   `delete` — y debe coincidir **exactamente** con lo que el FormRequest del endpoint valida.

3. **Prohibido persistir la matriz.** Nunca en `localStorage`, `sessionStorage`, ni
   fusionada al objeto `User` o al payload del login (QD-09). Vive solo en memoria, en el
   `BehaviorSubject` de `PermissionService`, y se recalcula en cada carga de página.

4. **Prohibido inyectar permisos en el JWT.** Firmar no es cifrar: el payload de un JWT es
   base64url y lo lee cualquiera. Además `qdoora-security-iam-expert` lo veta expresamente
   ("JWT Delgado: prohibido inyectar arrays de permisos" → QD-09) y decodificar el JWT en
   Angular para resolver permisos es QD-01.

5. **Prohibido crear directivas estructurales nuevas** para ocultar elementos. El proyecto
   ya resuelve esto con método booleano + `@if`. Respeta el precedente (DRY/KISS).

6. **`@if`/`@for` siempre**, nunca `*ngIf`/`*ngFor` (Hard Reject #7).

7. **Fail-closed en todas partes.** `PermissionService` devuelve `{}` si la consulta falla,
   y `can()` devuelve `false` ante una clave ausente. Un submódulo sin ningún permiso
   concedido no viaja en el payload: ausencia y denegación son lo mismo.

## Cómo funciona la matriz

`GET /v1/company/{company_id}/permissions/mine` devuelve, para el usuario autenticado:

```json
{ "data": { "submodules": {
    "BILLING.SETTING": { "review": true, "create": false, "update": false, "delete": false }
} } }
```

El backend la construye proyectando `User::canOperateOnSubmodule()` — la **misma** función
que evalúan los FormRequests — así que el frontend no puede desincronizarse de la fuente de
verdad. Solo aparecen submódulos con al menos una operación concedida.

Un `SUBSCRIBER_ROLE` dueño de la empresa recibe todo en `true`: tiene bypass por diseño
(`User::bypassesSubmoduleChecks()`). El shape es idéntico para todos los roles — el
frontend nunca ramifica por rol.

## ⚠️ LO QUE LA MATRIZ **NO** CUBRE — acciones especiales

La matriz solo tiene las 4 operaciones CRUD. Las **habilidades especiales** del catálogo
`submodule_action` (NC/ND, cierre contable, cambio de consignatario…) viajan por un
mecanismo paralelo que **no está en `/permissions/mine`**.

Backend: `User::userCanPerformSubmoduleAction($companyId, $submodule, $actionCode)`, que
compone cinco capas:

```
ownsCompany (bypass suscriptor) → subscriber_only → TRANSACTION sobre la empresa
→ operación CRUD base (action.requires_operation, salvo SPECIAL) → grant de la acción
```

Grants en `users_permission_submodule_action`, con herencia desde
`RoleSubmoduleActionPermission`. Catálogo actual: `COMPROBANTE / NOTA_CREDITO_DEBITO`.

**El error que esto provoca si lo ignoras**: gatear un botón de NC/ND con
`can('COMPROBANTE', 'create')` devuelve `true` para un usuario que tiene `create` pero NO
el grant de la acción. Muestras un botón que revienta con 403 — justo el fallo que esta
skill existe para evitar.

**Regla**: antes de escribir el `@if`, mira el `authorize()` del endpoint. Si pasa un
cuarto argumento a `authorizeSubmodule(...)` o llama a `userCanPerformSubmoduleAction()`,
estás ante una acción especial y **la matriz no te sirve**. Hoy no hay forma client-side
de resolverlo: no ocultes el botón basándote en el CRUD base (daría un falso permitir) —
deja que el backend responda y maneja el 403 en la UI, o pide extender el endpoint de
autoconsulta para incluir las acciones concedidas.

## Códigos de submódulo

Están en la tabla `submodule` (PK `code`). Convención vigente: `MODULO.SUBMODULO` en
mayúsculas (`BILLING.SETTING`, `NOMINA.LIQUIDACIONES`, `ADUANA.CIRCUNSTANCED_BOOK`).
Existen códigos legados simples (`COMPROBANTE`, `PLAN_DE_CUENTA`) que se mantienen.

**Nunca inventes un código.** Búscalo en las migraciones o en la tabla. Un código
inexistente hace que el backend deniegue y deje un `Log::warning`, y el frontend oculte
todo sin explicación.

## Archivos de referencia

- `assets/has-submodule-permission.guard.ts.template` — el guard parametrizable
- `assets/route-wiring.md` — dónde se aplica cada guard en el árbol de rutas
- `assets/ui-permission-check.md` — la convención de `@if` para botones y acciones

## Skills relacionadas

- `qdoora-laravel-form-requests` — la contraparte backend, que es la autorización real
- `qdoora-security-iam-expert` — modelo de 3 capas y reglas de refutación (QD-01, QD-04, QD-09)
- `qdoora-new-table-page` / `qdoora-new-setting-page` — al crear la página que vas a proteger

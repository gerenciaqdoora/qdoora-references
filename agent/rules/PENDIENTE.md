---
trigger: model_decision
description: Trabajos técnicos aprobados pero aún no aplicados — leer antes de tocar despliegue o migraciones
---
# PENDIENTE.md — Trabajos Aprobados No Aplicados

> Registro de mitigaciones y cambios ya analizados y aceptados, que quedaron sin ejecutar por requerir
> validación de un especialista o una ventana de despliegue. Al retomar uno, aplícalo y bórralo de aquí.

---

## 1. Automatizar `migrate` en el arranque del contenedor de la API

**Estado**: pendiente · **Detectado**: 2026-08-07 (auditoría del campo `order` en `module`/`submodule`)
**Capa**: infraestructura (`qdoora-api/start-container`) · **Esfuerzo**: M · **Criticidad**: ALTA
**Requiere**: validación de `cloud-devops-engineer` antes de aplicar.

### Problema

`qdoora-api/start-container` solo ejecuta `php artisan optimize:clear` — **no corre migraciones**. Si un
contenedor arranca con código que consume una columna todavía no migrada, la API cae por completo hasta
que alguien entra a migrar a mano.

Caso real que lo destapó: `Module::submodulos()` ordena por `submodule.order`. Desplegar ese código antes
de correr la migración produce `SQLSTATE 42703: column "order" does not exist`, y con eso se caen
`/user_navigation` (usuario logueado sin menú), la matriz de roles (`RoleController`), la matriz de
permisos de usuarios y `UserPermissionService::normalizaPermisosUsuario()` — que corre al **crear usuarios**.

Agrava el riesgo que `qdoora-api/InstalacionQA.md` (sección 5) documente el orden inverso
(`docker compose up -d` → `php artisan migrate`): correcto para una instalación desde cero, peligroso
como procedimiento de redeploy.

### Cambio propuesto

Agregar el migrate al arranque en `qdoora-api/start-container`, junto al bloque que hoy hace `optimize:clear`:

```bash
gosu sail php artisan migrate --force --isolated || true
```

**`--isolated` es obligatorio**: `qdoora-api`, `queue-worker` y `qdoora-scheduler` comparten la misma
imagen (`qdoora-chile-qdoora-api`) y sin el flag arrancarían migrando en paralelo sobre la misma base.
El flag toma un lock de caché para que solo un proceso migre y el resto continúe.

### Criterio de aceptación

Levantar los tres contenedores en simultáneo contra una base sin migrar deja las migraciones aplicadas
**una sola vez**, sin errores de migración duplicada en los logs de `queue-worker` ni `qdoora-scheduler`.

### Alternativa más liviana (si no se toma el cambio)

Mantener el procedimiento manual y documentarlo: agregar a `qdoora-api/InstalacionQA.md` una sección de
**redeploy** (distinta de la instalación inicial) que fije el orden obligatorio — migrar primero, levantar
el contenedor después:

```bash
docker exec qdoora-api php artisan migrate --force
docker exec qdoora-api php artisan migrate:status   # verificar antes de abrir tráfico
docker compose -f docker-compose.qa.yml up -d --no-deps qdoora-api
```

### Regla vigente mientras esto siga pendiente

Toda migración que agregue una columna consumida por código (scopes, `orderBy`, `select` explícitos) se
aplica **antes** de reemplazar el contenedor. Nunca al revés.

<!--
Ítems 2 y 3 (catálogo de "abilities" por submódulo + fix de CAPA 1 en usersPermissionSubmodules())
cerrados el 2026-08-10: código implementado y lint-verificado, migración y seed aplicados por el usuario.
Los tests escritos (SubmodulePermissionCapa1Test, SubmoduleActionTest, RoleActionPropagationTest) quedaron
sin ejecutar por decisión explícita del usuario ("no ejecutes los test, demoslo por finalizado") — si algo
falla en QA/prod, correr `php artisan test tests/Feature/Security` es el primer paso de diagnóstico.
Patrones y gotchas descubiertos ya están en BACKEND_RULES.md (autorización de abilities, Collection vs
Builder en Subscriber::modules(), fallback a plantilla de rol) y MEMORY.md (gotchas #16 y #17).
Deuda no resuelta: el endpoint que alimenta PermissionService (frontend) sigue sin construirse.
-->

## 2. Integrar endpoints de Acciones de Documentos RCV en el Frontend

**Estado**: pendiente
**Capa**: frontend (`fuse-starter/src/app/api/sii/api.ts` y componentes UI) · **Esfuerzo**: M · **Criticidad**: MEDIA

### Problema

Los endpoints para consultar el detalle de un documento en el SII (cesibilidad, fecha de recepción) y para emitir acuses de recibo o reclamos (ERM, ACD, RCD, RFP, RFT) ya fueron desarrollados y securizados en el backend:

- `GET /rcv/documents/{tipo_doc}/{folio}` (Requiere `rcv_type` por query string. Valida `COMPRA-REVIEW` o `VENTA-REVIEW`).
- `POST /rcv/documents/{tipo_doc}/{folio}/action` (Requiere `rcv_type` en el body. Valida `COMPRA-UPDATE` o `VENTA-UPDATE`).

Sin embargo, el **Frontend (`fuse-starter`) aún no los consume**. No existen los métodos en `api.ts` y no hay UI en los listados de compras/ventas para gatillar estas acciones contra el SII.

### Cambio propuesto

1. Agregar los métodos `rcvDocumentDetail` y `submitRcvAction` en `fuse-starter/src/app/api/sii/api.ts` asegurando de enviar `rcv_type` en los parámetros correspondientes.
2. Construir la UI en los listados de Contabilidad (Compras/Ventas) que permita hacer clic en un documento y ver su estado de cesión o emitir una aceptación comercial/reclamo.

## 3. Integrar endpoints de Imputación Contable en el Frontend

**Estado**: pendiente
**Capa**: frontend (`fuse-starter`) · **Esfuerzo**: M · **Criticidad**: BAJA

### Problema

Los endpoints para la configuración contable centralizada (`AccountingImputationController`) están construidos y securizados en el backend, pero el **Frontend (`fuse-starter`) aún no los consume**:

- `GET {company_id}/accounting-imputation/pending`
- `GET {company_id}/accounting-imputation/by-account/{account_id}`
- `GET {company_id}/accounting-imputation`
- `POST {company_id}/accounting-imputation`
- `DELETE {company_id}/accounting-imputation/{purpose}/{imputable_id}`

No existen los métodos en `api.ts` y no hay componentes UI para configurar la imputación contable de un registro (asignación de cuenta, auxiliar y centro de costo).

### Cambio propuesto

1. Agregar los métodos correspondientes en los servicios del frontend (posiblemente bajo un nuevo dominio en `src/app/api/accounting/`).
2. Construir la UI que permita configurar y gestionar las imputaciones contables para cada propósito y registro.

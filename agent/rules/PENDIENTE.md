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

## 4. Informar el aporte CCAF en el archivo Previred

**Estado**: pendiente · **Detectado**: 2026-08-24 (implementación del aporte CCAF en la liquidación)
**Capa**: backend (`qdoora-api/app/Services/Nomina/PreviredFieldMapperService.php`) · **Esfuerzo**: S · **Criticidad**: MEDIA

### Problema

La liquidación ya calcula y persiste el aporte a la Caja de Compensación de cargo del empleador
(`rem_liquidaciones.ccaf_empleador`, `ccaf_tasa`, `ccaf_third_company_id`), pero el archivo Previred
**solo informa el código de la caja**, no el monto.

`PreviredFieldMapperService::getCcafConfig()` resuelve la CCAF adherida desde
`NominaCompanySettings` (`feature_key='CCAF'` → `config.third_company_id`) y retorna únicamente el
`previred_code` de la entidad global (o `'00'` si no está adherida). No hay mapeo del aporte calculado
ni de la renta imponible CCAF hacia los campos del bloque "Datos Caja de Compensación".

### Cambio propuesto

1. Mapear en `PreviredFieldMapperService` los campos del bloque CCAF que correspondan a partir de
   `liquidacion->ccaf_empleador` y de la base imponible topada usada en el cálculo.
2. Confirmar antes con `erp-nomina-expert` **qué campos exactos** del layout Previred deben poblarse:
   el bloque distingue cotizaciones de trabajadores afiliados a AFP de los no afiliados (IPS), y ese
   criterio no está definido en el código actual.

### Contexto de la decisión

La regla de negocio aplicada en la liquidación (definida por el usuario el 2026-08-24) es:
**0,6% sobre la renta imponible topada en el tope AFP, de cargo del empleador**, informativo en el PDF
(bloque "Aportes Empleador (Referencial)") y sin afectar el líquido del trabajador. La tasa se lee de
`global_lists` (`type=CCAF`, `key`, `period`) → `values.tasa_cotizacion`, visible en
`/general/parameter/social-entities`.

## 5. Centralización contable de la liquidación (incluye el aporte CCAF)

**Estado**: pendiente · **Detectado**: 2026-08-24
**Capa**: backend (`qdoora-api/app/Services/Accounting/AccountingIntegrationService.php`) · **Esfuerzo**: L · **Criticidad**: MEDIA

### Problema

`LiquidacionService::centralizeLiquidacion()` tiene **todo su cuerpo comentado**: la llamada a
`$this->accounting->centralizePayroll()` y la actualización de `integration_status` están inertes. El
método valida el estado de la liquidación y retorna sin generar comprobante alguno.

Consecuencia inmediata: el aporte CCAF recién implementado —igual que el SIS y el AFC del empleador—
**no genera asiento contable**. Ningún costo previsional de cargo de la empresa llega a Contabilidad.

### Cambio propuesto

Implementar la centralización siguiendo el blueprint de la skill `new-accounting-process` (3 capas:
servicio dueño del documento → servicio de reglas del dominio → `AccountingEntryService` como motor
genérico). Las cuentas de cada monto deben resolverse vía `cont_accounting_imputations` por concepto
de nómina, no hardcodeadas.

### Dependencia

Requiere que existan los `purpose` de imputación contable para conceptos de nómina (incluido el aporte
CCAF). Coordinar con `erp-accounting-expert` para las reglas contables y con `new-accounting-process`
para el cómo técnico.

## 6. Informar los aportes mutual (Ley 16.744) y SANNA en el archivo Previred

**Estado**: pendiente · **Detectado**: 2026-08-24 (implementación de los aportes mutual/SANNA en la liquidación)
**Capa**: backend (`qdoora-api/app/Services/Nomina/PreviredFieldMapperService.php`) · **Esfuerzo**: M · **Criticidad**: ALTA
**Hacer junto con el ítem 4** (CCAF en Previred): mismo archivo, mismo tipo de cambio.

### Problema

La liquidación ya calcula y persiste los aportes de cargo del empleador
(`rem_liquidaciones.mutual_empleador`, `mutual_tasa_base`, `mutual_tasa_adicional`, `sanna_empleador`,
`sanna_tasa`, `mutual_third_company_id`), pero `PreviredFieldMapperService` **no los consume**: mantiene
su propio cálculo paralelo, con tres defectos concretos detectados al revisarlo.

**a) Empresas en ISL informan cotización 0.** La línea 39 condiciona el cálculo a
`$codigoMutual !== '00'`. Pero el código Previred `00` **no** significa "sin organismo": es el
**ISL (Instituto de Seguridad Laboral)**, el administrador público y una selección válida. Toda empresa
adherida al ISL declara $0 de cotización Ley 16.744 en su archivo Previred. Es el error más grave de
los tres y afecta datos ya enviados.

**b) La tasa base sale siempre del fallback hardcodeado.** `calcularCotizMutual()` busca
`GlobalVariable::where('key', 'mutual.tasa_base')`, key que **no existe en la base** (0 filas; la única
key con "mutual" es `mutual`, dentro de `LEYES_SOCIALES`). El `?? 0.90` se aplica siempre, así que la
tasa por período configurada en `global_lists` (`type=MUTUAL` → `values.tasa_base`) nunca se usa.

**c) La base imponible no está topada y falta SANNA.** `calcularCotizMutual()` aplica la tasa sobre
`imponible_total` sin topar en el tope AFP, mientras que `MutualCalculator` sí topa. Además el SANNA
(Ley 21.010, `values.sanna`) no se informa en ningún campo.

### Cambio propuesto

1. Reemplazar `calcularCotizMutual()` por la lectura directa de `liquidacion->mutual_empleador` y
   `liquidacion->sanna_empleador`, ya calculados y snapshoteados por período. Elimina el cálculo
   duplicado y con él los tres defectos de una vez.
2. Quitar la condición `$codigoMutual !== '00'`. En MUTUAL no existe la opción "sin organismo"
   — a diferencia de CCAF, donde `SIN_CCAF`/`00` sí significa no adherida.
3. Mapear el SANNA a su campo propio del layout.
4. Confirmar con `erp-nomina-expert` **qué campos exactos** corresponden a cada monto antes de tocar
   el layout.

### Criterio de aceptación

Una empresa adherida al ISL con tasa adicional 0% genera un archivo Previred con cotización Ley 16.744
distinta de cero, coincidente con `rem_liquidaciones.mutual_empleador` de esa liquidación.

### Contexto de la decisión

La regla aplicada en la liquidación (definida por el usuario el 2026-08-24) separa los dos aportes:
**Ley 16.744 = (tasa_base + tasa adicional por riesgo)** y **Ley 21.010 (SANNA) = tasa sanna**, ambos
sobre la renta imponible topada en el tope AFP y de cargo del empleador. `tasa_base` y `sanna` se leen
de `global_lists` (`type=MUTUAL`, `key`, `period`), visibles en `/general/parameter/social-entities`;
la tasa adicional por riesgo la fija la Superintendencia por empresa y vive en el `config` de la feature
MUTUAL, no en parámetros globales.

## 7. Informar los aportes APVC en el archivo Previred

**Estado**: pendiente · **Detectado**: 2026-08-24 (implementación del APVC en la liquidación)
**Capa**: backend (`qdoora-api/app/Services/Nomina/PreviredFieldMapperService.php`) · **Esfuerzo**: S · **Criticidad**: ALTA
**Hacer junto con los ítems 4 y 6** (CCAF y mutual en Previred): mismo archivo, mismo tipo de cambio.

### Problema

`PreviredFieldMapperService::getApvcData()` deriva los montos de APVC recorriendo las novedades de la
liquidación, y hoy **siempre informa 0 en ambos aportes**. Tres causas independientes, todas verificadas:

**a) El filtro por institución nunca matchea.** El método filtra
`fn($n) => $n->concept->institution_party_id == $apvcThirdCompanyId`. La columna
`rem_payroll_earnings_discounts.institution_party_id` existe pero está en **NULL en todos los conceptos**
(0 filas con valor en la base). Ninguna novedad pasa el filtro, así que ambos montos salen 0 aunque el
trabajador tenga APVC pactado.

**b) El aporte del empleador ya no es novedad.** El método lo busca entre las novedades cuyo `concept->key`
contiene `'EMP'`. Desde la implementación del APVC en la liquidación, `APVC_EMPLEADOR` está en
`HaberDescuento::APORTE_EMPLEADOR_KEYS` y `syncMovimientosFicha()` lo **omite a propósito**: no puede ser
novedad porque `TipoHaberDescuento` no tiene un caso para aportes patronales y distorsionaría el líquido.
El monto vive ahora en `rem_liquidaciones.apvc_empleador`.

**c) `forma_pago` siempre viaja vacío.** El método lee `$config['forma_pago']`, pero ese campo **no existe
en el `schema_definition`** de la feature APVC. `UpdateNominaFeatureConfig` arma sus reglas recorriendo el
schema y el service persiste solo lo validado, así que la clave nunca llega al config.

### Cambio propuesto

1. Reemplazar el recorrido de novedades por la lectura directa de `liquidacion->apvc_trabajador` y
   `liquidacion->apvc_empleador`, ya calculados y topados. Resuelve (a) y (b) de una vez y elimina la
   dependencia de `institution_party_id`.
2. Tomar la institución de `liquidacion->apvc_third_company_id` (snapshot del período) en vez de releer
   el config actual de la empresa.
3. Decidir qué hacer con `forma_pago`: agregarlo al `schema_definition` de la feature APVC y a la UI de
   `/nomina/settings`, o quitar la lectura si el layout no lo exige.
4. Confirmar con `erp-nomina-expert` **qué campos exactos** del layout corresponden a cada monto.

### Criterio de aceptación

Un trabajador con APVC pactado en su ficha (aporte propio y aporte del empleador) genera un archivo
Previred con ambos montos distintos de cero, coincidentes con `apvc_trabajador` y `apvc_empleador` de
su liquidación.

### Contexto de la decisión

La regla aplicada en la liquidación (definida por el usuario el 2026-08-24): los montos APVC **no salen
de una tasa global** —no existen parámetros APV/APVC en `global_lists`— sino de lo pactado por empleado
en Movimientos Programados de su ficha. El aporte del trabajador es descuento y **sí afecta el líquido**,
topado en `tope_apv` (50 UF); el del empleador es costo de la empresa y no lo afecta.

### Deuda relacionada

`institution_party_id` está sin poblar en todo el sistema. Si algún otro flujo depende de esa columna
para vincular conceptos con instituciones, hoy también está roto en silencio. Vale revisarlo al tomar
este ítem.

## 8. Exponer la Actividad Económica del SII (`<Acteco>`) en el alta/edición de empresa

**Estado**: pendiente · **Detectado**: 2026-08-25 (certificación SII, empresa 1)
**Capa**: full-stack (`qdoora-api` + `fuse-starter`) · **Esfuerzo**: M · **Criticidad**: ALTA

### Problema

El código de actividad económica del SII es **obligatorio en el DTE**: el Formato DTE v2.5 (pág. 17)
marca `<Acteco>` con obligatoriedad `1` para los diez tipos de documento, y valida que el código esté
*"registrado en el SII"*. Sin él, cualquier factura es rechazada.

La funcionalidad está a medio construir desde 2024 y quedó inerte:

- `core_economic_activities_sii` se crea en `2024_09_24_164700_create_table_company.php` pero **nunca
  se poblaba** (0 registros). A diferencia de `core_company_types` o `core_tax_regimes`, que sí insertan
  sus datos inline en esa misma migración.
- **No hay endpoint** que liste el catálogo.
- **No hay campo en el formulario**: `fuse-starter/src/app/modules/admin/general/company/create/create.component.ts`
  (línea ~431) envía `economic_activity_sii_id: null` **hardcodeado**.
- `EconomicActivitySii::$fillable` no incluía `code`, así que el código no era asignable en masa.

Consecuencia: **ninguna empresa creada por la UI puede emitir DTE**, porque nace sin actividad económica
y no hay forma de asignársela salvo por consola.

### Ya resuelto (2026-08-25)

- `EconomicActivitySiiSeeder` + `database/seeders/csv/economic_activities_sii.csv`, idempotente por
  código y registrado en `DataSyncCommand`.
- `code` agregado a `$fillable` de `EconomicActivitySii`.
- Empresa 1 asignada a la 620900 por consola, vía `CompanyService::actualizaEmpresa()`.

### Cambio propuesto

1. **Completar el catálogo**: el CSV trae hoy **una sola actividad** (620900), la única verificable
   contra el documento del SII del contribuyente. Falta cargar la nómina oficial completa del SII.
   Los códigos **no se pueden inventar**: el SII los valida contra su registro. Reemplazar el CSV basta,
   el seeder no cambia.
2. **Endpoint** de catálogo (`GET /economic-activities`), consultable al crear/editar empresa.
3. **Select en el formulario de empresa** (`fuse-starter`), reemplazando el `null` hardcodeado.
4. **Prellenar el giro** desde la actividad elegida, dejándolo **editable**: `<GiroEmis>` es glosa libre
   de 80 ALFA *sin validación*, el SII permite informar solo el giro de la transacción, y el Set de
   Pruebas exige explícitamente no abreviar giros. Son dos campos distintos, no uno.

### Decisión abierta

El SII admite **hasta 4 códigos `<Acteco>`** por documento, pero `core_companies.economic_activity_sii_id`
es una FK **única**. Para certificar alcanza con una; hay que decidir si se soporta el caso de empresas
que facturan por varios giros antes de que aparezca en producción.

### Gotcha al tocar esto

`CompanyService::actualizaEmpresa()` **sobrescribe todos los campos** con `$data[...] ?? null`: un payload
parcial borra silenciosamente giro, dirección, comuna y el resto. Siempre enviar el registro completo.
`logo` es la excepción: si la clave viene en `null`, **borra el archivo en S3** — omitirla para no tocarlo.

## 9. Consulta de estado DTE y notificación Toastr en respuesta de Probar Conexión SII

**Estado**: pendiente
**Capa**: full-stack (`qdoora-api` + `fuse-starter` / `support-portal`) · **Esfuerzo**: S · **Criticidad**: MEDIA

### Problema

1. **Consulta estado DTE**: Se requiere incorporar/gestionar el endpoint de consulta de estado DTE en el ambiente de certificación SII (`https://maullin.sii.cl/cgi_dte/UPL/DTEauth?3`).
2. **Notificación Toastr al probar conexión**: Al presionar el botón "Probar Conexión", la API responde con la siguiente estructura JSON:

```json
{
    "data": {
        "connected": true,
        "environment": "certificacion"
    },
    "status": 200,
    "message": "Conexión con el SII establecida correctamente.",
    "errors": []
}
```

Actualmente se necesita implementar/asegurar que dicha respuesta entregue una alerta interactiva tipo Toastr (o notificación visual amigable en el Frontend) confirmando el estado de conexión (`connected`) y ambiente configurado (`environment`).

### Cambio propuesto

1. **Integración de consulta DTE**: Configurar la URL de consulta de estado DTE (`https://maullin.sii.cl/cgi_dte/UPL/DTEauth?3`) dentro de las constantes/servicios SII.
2. **Alertas Toastr en Frontend**: Capturar el payload de respuesta de `probar conexión` y gatillar un mensaje tipo Toastr o snackbar que informe al usuario `message` ("Conexión con el SII establecida correctamente.") y el ambiente activo (`certificacion`/`produccion`).


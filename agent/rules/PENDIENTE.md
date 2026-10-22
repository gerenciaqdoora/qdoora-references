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
**Requiere**: validación de `qdoora-despliegue` antes de aplicar.

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

**Precisión (verificado 2026-09-15)**: ambas rutas están **comentadas** en `qdoora-api/routes/api.php` (bloque
«DOCUMENTADOS COMO PENDIENTE»). El controlador (`Sii\RcvController::documentDetail` / `submitAction`, con sus
FormRequests) y `RcvActionService` sí existen; el WSDL está en `SiiEnvironment::rcvActionWsdlUrl()`.

Sin embargo, el **Frontend (`fuse-starter`) aún no los consume**. No existen los métodos en `api.ts` y no hay UI en los listados de compras/ventas para gatillar estas acciones contra el SII.

### Cambio propuesto

0. Descomentar las dos rutas en `routes/api.php`.
1. Agregar los métodos `rcvDocumentDetail` y `submitRcvAction` en `fuse-starter/src/app/api/sii/api.ts` asegurando de enviar `rcv_type` en los parámetros correspondientes.
2. Construir la UI en los listados de Contabilidad (Compras/Ventas) que permita hacer clic en un documento y ver su estado de cesión o emitir una aceptación comercial/reclamo.

## 3. Integrar endpoints de Imputación Contable en el Frontend

**Estado**: pendiente (parcial) · **Verificado**: 2026-09-15
**Capa**: full-stack (`qdoora-api` rutas + `fuse-starter`) · **Esfuerzo**: M · **Criticidad**: BAJA

### Problema

`AccountingImputationController` tiene construidos `index`, `pending`, `byAccount` y `destroy`, pero **solo `store`
tiene ruta activa**; las otras cuatro están **comentadas** en `routes/api.php` (grupo
`{company_id}/accounting-imputation`) y el **Frontend (`fuse-starter`) no las consume**:

- `GET {company_id}/accounting-imputation/pending`
- `GET {company_id}/accounting-imputation/by-account/{account_id}`
- `GET {company_id}/accounting-imputation`
- `DELETE {company_id}/accounting-imputation/{purpose}/{imputable_id}`

Ya cubierto: `POST {company_id}/accounting-imputation` → `AccountPlanApi.save_accounting_imputation()` /
`AccountPlanService.saveAccountingImputation()`, consumido por el diálogo `honorarium-centralization`.

No hay componente UI para listar/gestionar las imputaciones contables de un registro (asignación de cuenta,
auxiliar y centro de costo) más allá de ese diálogo.

### Cambio propuesto

0. Descomentar las cuatro rutas en `routes/api.php`.
1. Agregar los métodos correspondientes en `AccountPlanApi`/`AccountPlanService` (junto a `save_accounting_imputation`).
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
2. Confirmar antes con `qdoora-erp-nomina-expert` **qué campos exactos** del layout Previred deben poblarse:
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

Implementar la centralización siguiendo el blueprint de la skill `qdoora-new-accounting-process` (3 capas:
servicio dueño del documento → servicio de reglas del dominio → `AccountingEntryService` como motor
genérico). Las cuentas de cada monto deben resolverse vía `cont_accounting_imputations` por concepto
de nómina, no hardcodeadas.

### Dependencia

Requiere que existan los `purpose` de imputación contable para conceptos de nómina (incluido el aporte
CCAF). Coordinar con `qdoora-erp-accounting-expert` para las reglas contables y con `qdoora-new-accounting-process`
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
4. Confirmar con `qdoora-erp-nomina-expert` **qué campos exactos** corresponden a cada monto antes de tocar
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
4. Confirmar con `qdoora-erp-nomina-expert` **qué campos exactos** del layout corresponden a cada monto.

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

## 9. Mostrar el ambiente SII en la notificación de "Probar conexión"

**Estado**: pendiente · **Verificado**: 2026-09-15
**Capa**: frontend (`fuse-starter/src/app/modules/admin/billing/setting/setting.component.ts`) · **Esfuerzo**: S · **Criticidad**: BAJA

> La consulta de estado DTE ya está cubierta: `DteStatusService` (SOAP `QueryEstUp` / `QueryEstDte`), rutas
> `GET /dte/status/{track_id}` y `/dte-envios/{envio_id}/items/{item_id}/document-status`, y `SiiApi.dteStatus()`
> en el frontend. La URL `DTEauth?3` es el formulario web manual del SII, no una API — no se integra.

### Problema

Al presionar "Probar conexión SII", `CertificateController` responde:

```json
{
    "data": { "connected": true, "environment": "certificacion" },
    "status": 200,
    "message": "Conexión con el SII establecida correctamente.",
    "errors": []
}
```

`testConnection()` ya notifica con `NotificationService`, pero **descarta la respuesta**: usa un texto fijo y no
informa el ambiente activo (`next: () => this._notification.success('Conexión con el SII establecida correctamente.')`).

### Cambio propuesto

Usar `response.message` y agregar `response.data.environment` (`certificacion`/`produccion`) al texto de la
notificación, para que el usuario sepa contra qué ambiente se validó la conexión.

## 10. Referencia: Tutorial Proceso de Certificación SII ("Certificador")

**Estado**: pendiente
**Capa**: documentación · **Esfuerzo**: S · **Criticidad**: BAJA

### Link: https://www.youtube.com/watch?v=JXktFGtLrJ8

Tutorial que utiliza el programa "Certificador" y que muestra el proceso de certificación de facturas electrónicas para el SII. 
Para mas información visita nuestro sitio https://www.simpleapi.cl

Manual de Certificación 🚀

En SII 🏣

Realizar la postulación
Inscríbase aquí / Postulación: https://maullin.sii.cl/cvc_cgi/dte/pe_ingrut

Descargar set de pruebas:
Para boletas: https://www4.sii.cl/certBolElectDteInternet/?SET=1
Para facturas y otros documentos: https://maullin.sii.cl/cvc_cgi/dte/pe_generar

Verificar que el usuario tenga permisos:
Menú Postulantes / Ambiente de cert / Actualización de datos empresa / Mantención de usuarios: https://maullin.sii.cl/cvc_cgi/dte/eu_enrola_usuarios

Descargar folios y guardar: (Certificador\bin\Debug\out\caf)
Ambiente de certificación y prueba / Timbraje / Solicitar timbraje: https://maullin.sii.cl/cvc_cgi/dte/of_solicita_folios

Configurar los datos de la empresa:
Menú postulante / Ambiente certificación / Ayuda / Instructivo técnico / Datos del contribuyente para la construcción del DTE: https://maullin.sii.cl/cvc_cgi/dte/pe_construccion_dte

Verificar fecha de resolución :
Menú postulante / Ambiente certificación / Actualizar datos empresa: https://maullin.sii.cl/cvc_cgi/dte/ad_empresa1

Consulta Estado de envío ⚠️ (Utilitario)
Ambiente de certificación y envío de DTE y libros / consulta de estado de un envío: https://maullin.sii.cl/cgi_dte/UPL/DTEauth?3

En Certificador 💻
Sistema facturación de mercado / Menú postulante / ambiente certificación y prueba

Paso 1️⃣ 🚩 Generar documentos según set de pruebas:

Set básico afecto (rellenar con set de prueba)
Libro compras (llenar con datos de set de prueba)
Libro ventas (se envía SetBasico. Si desea usar un Folio de Notificación diferente al predefinido, debe hacerlo antes de cargar el archivo EnvioDTE (XML))

Declarar avance: https://maullin.sii.cl/cvc_cgi/dte/pe_avance1

Paso 2️⃣ 🚩 Simulación de documentos

Factura electrónica
Nota de Crédito
Nota de Débito

Verificar que los nuevos documentos generados en esta etapa, no tengan los mismos folios previamente asignados en el paso 1.
Declarar avance: https://maullin.sii.cl/cvc_cgi/dte/pe_avance1

Paso 3️⃣ 🚩 Etapa de intercambio

Bajar archivo xml (EnvioDTE.xml): https://www4.sii.cl/pfeInternet/#menu

Generar documentos de intercambiador y seleccionar el archivo
Subir los 3 archivos xml generados

Paso 4️⃣ 🚩 Upload muestras impresas

Opción postulante / Upload de Muestras Impresas: https://www4.sii.cl/pdfdteInternet/

-----
Declaración de cumplimiento de requisitos: https://maullin.sii.cl/cvc_cgi/dte/pe_avance7

Nª de resolucion es siempre 0 para certificacion.

## 11. Estrechar `allowed_class_codes` de HONO/HONE/GADE/GADX a solo `GANANCIA`

**Estado**: diferido (no bloqueante) · **Verificado**: 2026-09-15
**Capa**: backend (migración) · **Esfuerzo**: S · **Criticidad**: BAJA

> El catastro de hallazgos amarrados al dígito 1..5 (`qdoora-references/Otros/catastro_tipos_plan_cuentas.md`)
> quedó **cerrado**: Fases 1, 2 y 3 ejecutadas el 2026-09-14/15 (`cont_type_classes`, `Tipo.type_class_code`,
> `allowed_class_codes`, `AccountPlanTypeClassMap`, importador por columna "Clase Cuenta", Portal Cliente por
> `type_class_code`). Este es el único seguimiento que dejó abierto.

### Problema

`2026_09_15_100000_replace_allowed_type_codes_with_allowed_class_codes.php` tradujo el `['3','4']` histórico de
HONO/HONE/GADE/GADX a `['PATRIMONIO','GANANCIA']` sin estrecharlo, porque hay planes reales que ubican esos
honorarios/gastos de despacho bajo Patrimonio (ver `AccountPlanImport_SiglaMapping.md`, nota HONO/HONE/GADE/GADX).

### Cambio propuesto

Decidir con `qdoora-erp-accounting-expert` si esas cuatro cuentas maestras deben admitir solo `GANANCIA`; si es así,
nueva migración que actualice `cont_account_categories.allowed_class_codes` y revisar que ningún plan importado
en QA las tenga asignadas bajo un Tipo Patrimonio antes de aplicarla.

## 12. Tesorería: filtrar consignatarios por cuenta CLIENTE_NACIONAL en Provisión de fondos

**Estado**: pendiente (se retoma tras cerrar "Cancelación de facturas") · **Detectado**: 2026-10-08
**Capa**: full-stack (`qdoora-api` Tesorería + `fuse-starter` `common-update-pago-cobro`) · **Esfuerzo**: S · **Criticidad**: MEDIA

### Problema

En Provisión de fondos el consignatario es el auxiliar del asiento, pero la lista de consignatarios
(`TreasuryDispatchService::listConsignees`, tabla `aduana_agent_consignees`) **no se cruza con los auxiliares de
Tesorería**. Aparece cualquier consignatario con `third_company_id`, aunque ese tercero no tenga una cuenta
`CLIENTE_NACIONAL`; `VoucherService` rechazaría después el asiento.

### Cómo funciona hoy

- `GET treasury/auxiliaries` (`TreasuryService::getListaAuxiliares`) entrega `{id, rut, full_name, email,
  cuentas[{account_id, type, category}], is_disbursement}`; la ruta lo carga una vez como `entities`.
- `search-documents` filtra el selector de auxiliar por `cuentas[].account_id` (`filterEntitiesByAccount`).
- `manual-application` pide `getConsignees()` (`{id, auxiliary_id, name, rut}`) solo si el despacho no existe o no
  tiene consignatario.

### Cambio propuesto

1. Pasar `entities` a `manual-application` y dejar solo los consignatarios cuyo `auxiliary_id` coincida con un
   auxiliar que tenga una cuenta `CLIENTE_NACIONAL`.
2. Despacho encontrado cuyo consignatario no cumple: avisar y no permitir continuar.
3. Aplicar la misma regla en backend (`listConsignees` y `TreasuryFlowRules`); la validación real debe estar ahí.

### Decisión abierta

Filtrar por categoría `CLIENTE_NACIONAL` o por el `account_id` exacto de la cuenta elegida (más estricto: una
empresa con varias subcuentas de cliente no dejaría pasar consignatarios asociados a otra).

**Actualización 2026-10-08:** con la sincronización Consignatario ↔ Auxiliar (pendiente 14), `listConsignees` ya devuelve consignatarios vinculados y, con Aduana + Contabilidad, todo cliente (`CLIENTE_NACIONAL`) es también consignatario. El filtro de este pendiente sigue siendo necesario: un consignatario creado en Aduana **puede existir sin cuenta de cliente** (se exige recién al editarlo desde Auxiliares).

## 13. Tesorería: consultar si se pueden hacer ingresos/egresos de asientos sin documento

**Estado**: pendiente — **es una consulta a negocio/contabilidad, no una tarea de código aún** · **Detectado**: 2026-10-08
**Capa**: backend (`VoucherAccount::scopePendingForIncome`/`scopePendingForPayment`, `VoucherService::crearCuentaComprobante`) · **Esfuerzo**: M · **Criticidad**: MEDIA
**Preguntar a**: `qdoora-erp-accounting-expert` / responsable contable antes de tocar código.

### Pregunta abierta

¿Debe poder cobrarse (ingreso) o pagarse (egreso) desde Tesorería un asiento que **no tiene documento**, por ejemplo
una cuenta que trabaja con auxiliar (con RUT o de concepto) pero no con documentos, o un saldo inicial/ajuste cargado
con un comprobante manual?

### Hallazgo (verificado 2026-10-08, solo lectura de código)

Un comprobante manual con Debe en una cuenta de Tesorería (ej. 124 con RUT, 125 de concepto) **nunca aparece** en
`GET treasury/incomes/pending`, por dos causas:

1. **Exige documento.** `scopePendingForIncome` hace `join core_documents` por `document_id`; una línea sin
   documento queda excluida.
2. **`max_amount_application` queda en 0.** El scope exige `applied_amount < max_amount_application`. Ese campo solo lo
   llenan los procesos de centralización (ventas, compras, honorarios) vía `AccountingEntryService`
   (`max_amount`). El comprobante manual no lo envía (ni el `FormRequest` ni el frontend) y
   `VoucherService::crearCuentaComprobante` lo guarda como `0.00`.

Consecuencia: por la UI no hay forma de crear un pendiente de cobro/pago con un comprobante manual; solo la
centralización los genera. Para pruebas se ajustó por SQL (`max_amount_application = debit`, `document_id`,
`document_number`).

### Si la respuesta es "sí"

1. Que las líneas de un comprobante manual a una cuenta de Tesorería con auxiliar guarden
   `max_amount_application = |Debe − Haber|`.
2. Decidir si el documento pasa a ser opcional: cambiar el `join` por `leftJoin` y mostrar "No aplica" en la
   columna Documento. Revisar el efecto en Cancelación (selección por documento, `document_id`/`document_number` de la
   aplicación y del asiento de contrapartida).
3. Definir cómo se identifica la línea sin documento (id de línea del comprobante) y cómo evitar duplicados.
4. Ojo: cambia qué líneas se consideran pendientes. Validar con contabilidad y cubrir con tests de aislamiento
   por `company_id`.

### Si la respuesta es "no"

Documentarlo: las cuentas de Tesorería con auxiliar que no centralizan documento solo admiten Gasto directo, y los
saldos iniciales deben cargarse con documento y `max_amount_application`.

## 14. Auxiliares de empresa: roles (cliente, proveedor, emisor, empleado, consignatario, desembolso) inconsistentes

**Estado**: pendiente · **Detectado**: 2026-10-08 (lectura de código de `/general/catalogue/entity`; la UI no se pudo abrir en vivo)
**Capa**: full-stack (`qdoora-api` `ThirdCompanyService` + `fuse-starter` `formulario-entidad`) · **Esfuerzo**: M · **Criticidad**: MEDIA
**Relacionado**: pendiente 12 (consignatarios en Provisión de fondos) y `Otros/disenno-tesoreria.md` (flujo de ingreso por despacho).

### Cómo funciona hoy (contexto)

- Tabla `core_third_companies` (`company_id`, global scope `not_certification`). Los auxiliares globales
  (`is_standard = true`, enlazados a `global_entities.standard_entity_id`) se ocultan en el listado y no se editan
  ni eliminan desde la empresa.
- Tipo de auxiliar deducido: **con RUT/pasaporte** (`rut` + `identification_document_id` llenos) o **de concepto**
  (ambos vacíos). Con solo uno lleno no califica para ninguno (`esAuxiliarConRut` / `esAuxiliarConcepto`).
- Unicidad por empresa: `rut` + documento, o `full_name` si no hay RUT. El borrado está condicionado a que no existan
  asientos, ventas, compras, honorarios, tesorería ni liquidaciones (no hay `deleted_at` en la tabla).
- **Los roles no son columnas** (`es_cliente`, `es_proveedor`, etc. no están en `fillable`). Se deducen así:

| Rol | Fuente real | Toggle visible si |
|---|---|---|
| Cliente | Cuenta asociada (`cont_auxiliary_accounts`) con categoría maestra `CLIENTE_NACIONAL` | módulo contabilidad |
| Proveedor | Ídem `PROVEEDOR_NACIONAL` | módulo contabilidad |
| Emisor | Ídem `HONORARIO_POR_PAGAR` | módulo contabilidad |
| Empleado | `EmployeeProfile` y, con plan de cuentas, cuenta `REMUNERACIONES_POR_PAGAR` | módulo nómina |
| Consignatario | Fila en `aduana_agent_consignees` (`third_company_id`, `company_id`); categoría frontend `CLIENTE_NACIONAL` | módulo aduana |
| Desembolso | Cuenta con categoría `DESEMBOLSO` | aduana + contabilidad + plan de cuentas |

- Al activar un toggle el frontend agrega la cuenta maestra de esa categoría; si ninguna cuenta la tiene, obliga a
  elegir una cuenta libre (`getAccountsWithOutMasterAccount`). Un auxiliar admite una sola cuenta con prefijo
  `CLIENTE` y una con `PROVEEDOR` (`validateRestrictionsCategoryAccounts`). Si el documento no es RUT (`code` 03) se
  apagan todos los roles. Empleado no se quita desde el auxiliar (se hace en nómina).
- Consignatario y Empleado validan en backend que el módulo (`aduana` / `nomina`) esté activo en el plan.

### Problemas detectados

1. **El filtro por rol Emisor nunca devuelve resultados.** `ThirdCompanyService::getListaEntidad` usa
   `HONORARIOS_POR_PAGAR`; el código real es `HONORARIO_POR_PAGAR` (`AccountCategories`). Usar la constante.
2. **El filtro por rol no incluye Desembolso** (ni el selector `roles` de `entity/list/list.component.ts`).
3. **Empleado se evalúa distinto** en el filtro (solo categoría de la cuenta) y en la ficha (`EmployeeProfile` +
   categoría si hay plan).
4. **`es_consignatario` no viaja en el payload.** `getFormattedData` (`formulario-entidad.component.ts`) no lo envía,
   por lo que el diálogo no crea ni actualiza el consignatario. `crearEntidad` tiene además el `firstOrCreate`
   comentado; `actualizaEntidad` lo ejecuta solo con `company_id` y `third_company_id`.
5. **Verificar la migración de `aduana_agent_consignees`**: define `type` (enum) y `name` NOT NULL, y el
   `firstOrCreate` de (4) no los informa. Confirmar si una migración posterior los relajó; si no, falla al guardar.
6. **El filtro `is_consignee` es una consulta cruda** (`whereExists`) que ignora `deleted_at` (la tabla usa
   SoftDeletes) y `company_id`.
7. **`ThirdCompanyDetailResource` solo devuelve `es_empleado`.** Cliente, proveedor, emisor y desembolso se
   reconstruyen en el frontend cruzando cuentas con el plan; `ThirdCompany.is_disbursement` (TS) no lo llena ningún
   recurso revisado, y el listado (`AuxiliaryResource`) no devuelve roles.
8. **Existen dos categorías**: `DESEMBOLSO` (la del auxiliar) y `DESEMBOLSO_POR_PAGAR` (solo aduana, según
   `disenno-tesoreria.md`). Dejar explícito cuál usa cada flujo.

### Cambio propuesto

1. Corregir 1 a 4 y 6 (cambios chicos y de bajo riesgo). Validar 5 antes de tocar el consignatario.
2. Centralizar la lógica de "rol de un auxiliar" en un solo servicio (backend) y exponer los roles en detalle y
   listado, para que filtro, ficha y Tesorería usen la misma regla.
3. Tras eso, decidir el modelo: (a) mantener roles implícitos por cuenta maestra, (b) índice o vista que materialice
   roles por auxiliar, o (c) tabla `third_company_roles` (`company_id`, `third_company_id`, `role`, índices por FK).

### Decisión abierta

Si el rol debe seguir siendo una relación implícita con la cuenta maestra (útil para la imputación contable, caro de
filtrar) o pasar a una tabla explícita. Recomendación: corregir primero 1 a 4 y decidir con datos de rendimiento.

### Avance (2026-10-08)

Resuelto **para el rol consignatario** por `docs/implementations/2026-10-08-sincronizacion-consignatario-auxiliar.md`: ítems 4 (`es_consignatario` ahora viaja y persiste), 5 (`firstOrCreate` reemplazado por `ConsigneeAuxiliarySyncService`) y 6 (el filtro por rol ignora consignatarios eliminados y se acota por empresa y tipo). Siguen abiertos los ítems 1 a 3, 7 (parcial: el detalle ya informa `es_consignatario`; cliente, proveedor, emisor y desembolso siguen reconstruyéndose en el frontend) y 8, y la decisión de modelo (a/b/c) para el resto de los roles. Ver reglas en `BACKEND_RULES.md` ("ADUANA ↔ AUXILIARES — Rol Consignatario").

## 15. Comuna/municipio entre auxiliar y consignatario

**Estado**: pendiente (retomar al cerrar la sincronización del rol consignatario) · **Detectado**: 2026-10-08
**Capa**: datos (`core_comunas` ↔ `aduana_anexo51_municipality`) · **Esfuerzo**: M · **Criticidad**: MEDIA

### Problema

La sincronización Consignatario ↔ Auxiliar **no** copia comuna: el auxiliar usa `core_comunas` y el consignatario `aduana_anexo51_municipality`, y no existe una clave común confiable. Un auxiliar creado desde Aduana queda con `comuna_id = null`; un consignatario creado desde el auxiliar queda con `municipality_id = null` (el formulario de Aduana lo exige al editar).

### Antecedentes (verificado sobre los CSV de siembra, 2026-10-08)

- `ComunaSeeder` **no carga la columna `CODE`**: las comunas de Chile quedan sin código. Coincidencia por `code` con Anexo51 (CUT, ej. `05804`): 4 de 346.
- `core_comunas` es un catálogo mundial (48.044 filas); Chile tiene solo **204 comunas** contra 346 municipios Anexo51 (faltan casi todas las del Gran Santiago).
- Por nombre normalizado y restringido a Chile: 151 coinciden de forma única, 22 son ambiguas (nombre repetido, ej. Santiago) y 173 no tienen contraparte. Erratas en core: `Villarica`, `Paiguano`, `Punitaci`, `Concon`, `Llaillay`, `Putaendeo`, `Aisen`, `Cabo de Horno`.
- No verificado sobre una base real.

### Cambio propuesto

Cargar el catálogo oficial de comunas de Chile en `core_comunas` con su código CUT (afecta facturación y empresas: validar con `qdoora-erp-electronic-invoicing-expert`), y mapear por código en lugar de por nombre. Alternativa: columna `core_comunas.aduana_municipality_id` poblada por un seeder idempotente (nombre normalizado + excepciones).

## 16. Exigir la cuenta CLIENTE_NACIONAL del consignatario antes de conciliar o contabilizar un despacho (DIN/DUS)

**Estado**: pendiente · **Detectado**: 2026-10-08 · **Capa**: backend (contabilización de despachos) · **Esfuerzo**: M · **Criticidad**: MEDIA

Crear un consignatario en Aduana no le asigna la cuenta `CLIENTE_NACIONAL` (decisión del usuario): hoy solo se exige al editar el auxiliar desde Auxiliares (con Aduana + Contabilidad + plan de cuentas). Debe exigirse, como mínimo, antes de conciliar o contabilizar un despacho.

Nota: en el DUS el consignatario solo guarda `consignee_name` (sin RUT), por lo que `TreasuryDispatchService::resolveDispatch` no puede resolver su auxiliar; hoy solo resuelve DIN.

## 17. Auditar `authorize()` de los FormRequest de Aduana

**Estado**: pendiente · **Detectado**: 2026-10-08 (revisión de cumplimiento) · **Capa**: backend/seguridad · **Esfuerzo**: S · **Criticidad**: ALTA

`StoreConsigneeRequest` y `UpdateConsigneeRequest` devolvían `authorize(): true` y permitían crear/editar en otra empresa (corregido). Quedan con el mismo patrón `Agent/Carrier/StoreCarrierRequest`, `Agent/Carrier/UpdateCarrierRequest` y `Context/GetContextRequest`. Cambiar a `AuthorizesClientRequests::authorizeCompany((int) $this->route('company_id'))` y agregar tests de aislamiento entre empresas (patrón de `ConsigneeEndpointSyncTest`). Revisar también que los tests de Aduana usen la fixture `SetsUpAduanaAccess` (SUBSCRIBER_ROLE).

## 18. Purga de datos personales en filas eliminadas de consignatarios (Ley 21.719)

**Estado**: pendiente · **Detectado**: 2026-10-08 · **Capa**: datos/cumplimiento · **Esfuerzo**: M · **Criticidad**: BAJA

Eliminar un auxiliar hace soft delete de su consignatario (`aduana_agent_consignees.deleted_at`) y deja nombre, RUT y dirección en esa fila; los despachos conservan además su copia. Definir con `ley-21719-datos-personales` el plazo de retención y una política de purga/anonimización de filas eliminadas, y qué copias (despachos) deben conservarse por obligación aduanera.

## 19. Tesorería: condiciones para ofrecer "Cancelación de facturas / Pago de documentos"

**Estado**: pendiente — **requiere validar con un analista (negocio/contabilidad) antes de implementar** · **Detectado**: 2026-10-10
**Capa**: full-stack (`fuse-starter` `treasury-flow.ts` + `qdoora-api` `TreasuryService` / `TreasuryFlowRules`) · **Esfuerzo**: M · **Criticidad**: MEDIA
**Preguntar a**: `qdoora-erp-accounting-expert` / responsable contable. Diseño base: `Otros/disenno-tesoreria.md`.

### Regla planteada por el usuario

La Cancelación de facturas (ingreso) y el Pago de documentos (egreso) solo deben ofrecerse si la cuenta contrapartida cumple **las dos** condiciones a la vez:

1. Trabaja con **auxiliar con RUT/pasaporte**.
2. Tiene **cuenta maestra** cuya categoría tiene **documentos asociados**.

**Requisito: las categorías deben ser dinámicas.** Si se agrega o quita una asociación categoría ↔ documento, Tesorería debe reflejarlo sin tocar código. Hoy ya es así en el frontend (`hasDocuments` sale de `searchDocumentsByMasterAccountCode`) y en el backend (`document_ids` de la categoría); no introducir listas fijas de categorías ni de documentos al implementar.

### Hallazgo (verificado 2026-10-10, solo lectura de código)

El sistema **no exige** esa condición. `resolveTreasuryFlow` (`treasury-flow.ts`) ofrece `CANCELACION` en todo caso salvo los cuatro siguientes, sin mirar auxiliar con RUT ni documentos:

- Ingreso, cliente con despacho: `CANCELACION` + `PROVISION`.
- Ingreso, otra cuenta con despacho: `MANUAL` (no ofrece Cancelación).
- Egreso, cliente con despacho: `DEVOLUCION` + `MANUAL` (no ofrece Cancelación).
- Egreso, desembolso: `DESEMBOLSO` (no ofrece Cancelación).

| Caso (ingreso y egreso) | Hoy ofrece | ¿Cumple la regla? |
|---|---|---|
| Cliente sin despacho (la maestra fuerza auxiliar con RUT y tiene documentos) | Cancelación | Sí, pero solo por convención de la configuración |
| Sin maestra y sin auxiliar | Cancelación + Directo | No: sobra Cancelación |
| Sin maestra, auxiliar con RUT | Cancelación | No: no hay documentos |
| Auxiliar de concepto | Cancelación | No: no es RUT ni hay documentos |
| Con maestra sin documentos (ej. `RETE_2DA_CATEGORIA`) | Cancelación + Directo | No |
| Egreso, `DESEMBOLSO_POR_PAGAR` | Cancelación | **No verificado**: depende de si su maestra tiene documentos asociados |

Otros hechos relevantes:

- **El backend no valida los atributos de la cuenta en la cancelación.** `TreasuryService::applyAndGenerate` (rama de cancelación) solo valida el movimiento pendiente (existe, no saldado, signo correcto, monto ≤ saldo, tiene auxiliar). La regla, si se adopta, hoy solo podría vivir en pantalla; la validación real debe estar también en backend (`TreasuryFlowRules`).
- **Specs que encodan lo contrario** (`treasury-flow.spec.ts`): auxiliar solo con RUT → `['CANCELACION']`; auxiliar de concepto → `['CANCELACION']`; sin auxiliar ni documentos → `['CANCELACION','DIRECTO']`; maestra sin documentos → `['CANCELACION','DIRECTO']`. Habría que reescribirlos.
- **Diseño**: `disenno-tesoreria.md` (caso "Caso contrario / Pago de factura") dice "Si `CUENTA_TRABAJA_CON_AUXILIAR` se selecciona. Si `CUENTA_TRABAJA_CON_DOCUMENTOS` se selecciona", que se lee como condiciones independientes, no como las dos obligatorias. Habría que actualizarlo.
- **`DIRECTO` exige lo contrario**: solo cuentas sin auxiliar, sin despacho y sin documentos.

### Decisión abierta (bloquea la implementación)

Con la regla estricta, estas combinaciones quedan **sin ninguna operación disponible** (no cumplen Cancelación ni Directo):

- Auxiliar con RUT sin documentos.
- Auxiliar de concepto.
- Documentos sin auxiliar con RUT.

Opciones a validar con el analista:

1. Dejarlas sin modos, con un mensaje del tipo "esta cuenta no admite operaciones en Tesorería".
2. Permitir Aplicación manual (solo monto) cuando tienen auxiliar o documentos, pidiendo el auxiliar.
3. Otra regla definida por contabilidad.

Confirmar también si la maestra `DESEMBOLSO_POR_PAGAR` debe tener documentos asociados: si no los tiene, la regla estricta la bloquearía, y el diseño dice que ese caso busca documentos pendientes de pago.

### Cambio propuesto (una vez decidido)

1. Ajustar `resolveTreasuryFlow` para exigir auxiliar con RUT (`wk_auxiliary_rut`) y `hasDocuments` al ofrecer `CANCELACION`, y definir el modo (o mensaje) de las combinaciones sin salida.
2. Replicar la regla en backend (`TreasuryFlowRules` / `applyAndGenerate`) con mensajes en español, y tests de aislamiento por `company_id`.
3. Reescribir los specs de `treasury-flow.spec.ts` y actualizar `disenno-tesoreria.md`.

### Contexto relacionado (ya aplicado el 2026-10-09/10)

- El select de auxiliar en Cancelación solo se muestra si la cuenta trabaja con auxiliar, y una cuenta sin auxiliar ni documentos parte en `DIRECTO` (`defaultMode`).
- Para la maestra `DESEMBOLSO_POR_PAGAR` el selector lista todos los auxiliares con rol desembolso, sin exigir su asociación a esa cuenta. Es solo un filtro de búsqueda: `assertAuxiliaryMatchesAccount` se aplica a aplicaciones manuales, y esa cuenta rechaza la aplicación manual.

---

## 20. Conciliación bancaria: regla del saldo bancario ante el futuro cierre de ejercicio

**Estado**: decisión abierta (parcial) · **Detectado**: 2026-10-15 (análisis de la guía de conciliación bancaria vs QdoorA, pregunta P14)
**Capa**: backend (`BankLedgerService`, futuro cierre de ejercicio) · **Esfuerzo**: S · **Criticidad**: MEDIA
**Requiere**: definirlo junto con el diseño del cierre de ejercicio.

### Ya resuelto (2026-10-15)

El saldo inicial del banco viene del **comprobante de apertura**: un comprobante manual (`voucher_type = CC`) con `type = APERTURA`. El diseño de la conciliación por corte (`docs/designs/2026-10-15-conciliacion-bancaria.md`) excluye esas líneas del universo de cruce, sin sacarlas del saldo contable, y las usa como eslabón 0 de la cadena de cortes.

### Decisión abierta

Hoy no existe lógica de cierre ni de apertura automática de ejercicio (`CR`/`AP` solo existen en `VoucherType`). `BankLedgerService::ledgerBalance()` acumula `debit - credit` desde `2000-01-01`, lo que es correcto mientras nada cierre ni reabra cuentas de balance. Si el futuro cierre de ejercicio cierra y reabre cuentas de balance (incluido el banco), el saldo acumulado del banco quedaría duplicado.

### Cambio propuesto (una vez decidido)

Al diseñar el cierre de ejercicio, dejar escrito uno de estos dos caminos: el cierre no toca cuentas de balance, o el saldo bancario acumulado ignora el par cierre/apertura y se calcula desde la última apertura.

---

## 21. Rotar los secretos expuestos de QA y exigir su rotación cada 2 meses

**Estado**: pendiente · **Detectado**: 2026-10-20 (endurecimiento de seguridad del EC2 compartido)
**Capa**: infraestructura (Secrets Manager `qdoora/chile/qa/api`, `.env.qa` del EC2) · **Esfuerzo**: M · **Criticidad**: ALTA
**Requiere**: `qdoora-despliegue` y `qdoora-security-iam-expert`. Los comandos los ejecuta el usuario: nunca se autoejecutan.

### Problema

Se compararon los hashes SHA-256 de los valores actuales con los del historial de git de `backend_app_cl` (`.env.dev/.local/.prod/.qa`, versionados hasta 2026-01-20), sin mostrar valores. Coinciden, o sea **están expuestos**: `APP_KEY`, `JWT_SECRET`, `DB_USERNAME`/`DB_PASSWORD` (en el secreto y en `.env.qa`), `BC_USER`/`BC_PASS` y `PUSHER_APP_ID`. `PUSHER_APP_KEY` y `PUSHER_APP_SECRET` ya son distintos. También quedaron en un chat `QDOORA_ADMIN_API_KEY`, `THOMSON_COMEX_TOKEN` (vencido el 2026-09-11) y una contraseña antigua de la BD. Una contraseña de BD del historial era la palabra de diccionario "password".

### Cambio propuesto

1. Rotar una vez (el `APP_KEY` queda fuera de este paso; ver más abajo):

| Secreto | Dónde vive | Cómo se rota | Efecto |
|---|---|---|---|
| `JWT_SECRET` | Secreto | Valor aleatorio nuevo (`openssl rand -base64 48`) | Todos vuelven a iniciar sesión |
| `DB_USERNAME`/`DB_PASSWORD` | Secreto y `.env.qa` | `ALTER ROLE` en `postgres-qa` y luego actualizar ambos lugares (`POSTGRES_PASSWORD` solo aplica al crear el volumen) | `up -d --force-recreate qdoora-api queue-worker scheduler` |
| `BC_USER`/`BC_PASS` | Secreto | Cambiar la contraseña en el portal del Banco Central (API SIE) | Ninguno |
| `PUSHER_APP_ID` | Secreto | Crear una app nueva en Pusher si se usa en QA | Actualizar también `PUSHER_APP_KEY`/`SECRET` |
| `MAILERSEND_API_KEY` | Secreto | No está expuesta; entra en la rotación periódica | Ninguno |
| `QDOORA_ADMIN_API_KEY` | `.env.qa` | Valor aleatorio nuevo. Hoy ninguna ruta usa `admin.apikey` | Ninguno |
| `THOMSON_COMEX_TOKEN` | `.env.qa` | Pedir un token nuevo al proveedor | Actualizar `THOMSON_COMEX_EXPIRES_AT` |

Después de cambiar el secreto: `up -d --force-recreate qdoora-api queue-worker scheduler` (los secretos se cachean al arrancar).

2. **Agente de rotación cada 2 meses.** Una rutina programada de Claude Code (`/schedule`, cada 60 días) que:
   - Lee con un rol de solo lectura (`secretsmanager:DescribeSecret` y `ListSecrets`, **sin** `GetSecretValue`) la fecha `LastChangedDate` y los tags `rotated:<KEY>=AAAA-MM-DD` de `qdoora/chile/*/api`.
   - Lista los secretos de la tabla del punto 1 con más de 60 días (no incluye `APP_KEY`) y abre un issue en `backend_app_cl` con la lista de pasos.
   - Nunca rota ni lee valores: solo exige el cambio. Quien rota actualiza el tag `rotated:<KEY>`.
   - Para `DB_PASSWORD`, preferir a futuro la rotación nativa de Secrets Manager con Lambda, cuando la BD salga del contenedor (RDS en producción).

3. **`APP_KEY` para producción (durable, sin rotación periódica).**
   - Se genera una sola vez en la instalación (`php artisan key:generate --show`) y va solo a `qdoora/chile/prod/api`, cifrado con una **llave KMS propia** (no `aws/secretsmanager`). La key policy permite `kms:Decrypt` solo al rol de la tarea ECS de producción. Nunca va en `.env`, git, chat ni logs.
   - No se rota por calendario porque cifra datos persistentes: `Certificate.certificate_password_encrypted`, `ExternalSystem` (`username`, `password`, `api_key`) y `GlobalSystemParameter` con `is_encrypted`. Solo se rota ante un incidente: llave nueva, la anterior en `APP_PREVIOUS_KEYS`, un comando artisan que vuelve a cifrar esos campos y, al terminar, quitar la anterior.
   - Mejora recomendada: separar esos campos del `APP_KEY` usando **cifrado de sobre con KMS** (un Encrypter propio con data keys de KMS). La llave maestra nunca sale de KMS y rota sola cada año, y el `APP_KEY` queda solo para cookies y firmas, por lo que se puede rotar sin tocar datos.
   - El `APP_KEY` de QA también está expuesto: si QA guarda certificados SII reales, sus contraseñas se pueden descifrar con esa llave más acceso a la BD.

4. Correcciones de código relacionadas: `AdminApiKeyMiddleware` debe comparar con `hash_equals()` (hoy usa `!==`, que es vulnerable a ataques de tiempo) y leer la llave desde `config()` en lugar de `env()`, porque `env()` deja de funcionar con `config:cache`.

### Criterio de aceptación

Repetir la comparación de hashes en el EC2 y que ningún secreto marque `EXPUESTO`. Además, la rutina de 60 días ya abrió su primer issue y todos los secretos tienen su tag `rotated:<KEY>`.

---

## 22. Cierre del endurecimiento de seguridad del EC2 compartido

**Estado**: pendiente · **Detectado**: 2026-10-20 (endurecimiento del EC2 `i-0ceea9ec1bca59eda`)
**Capa**: infraestructura AWS, GitHub y backend · **Esfuerzo**: M · **Criticidad**: MEDIA
**Requiere**: `qdoora-despliegue` y `qdoora-security-iam-expert`. Los cambios de IAM, SG y cuenta se ejecutan en **CloudShell con root**: el rol del EC2 ya no administra.

### Ya aplicado (2026-10-19/20)

- SG `sg-0f694298398eab664`: 5432 cerrado (se quitó la IP externa de `pg_hba.conf` del PG14 del host). SSH 22 solo desde `18.237.140.160/29` (EC2 Instance Connect). 4208 (Gregorio) y 4209 (Nutrición) solo desde el SG del ALB `sg-0480b37b4e6611eca`. SSH con `PermitRootLogin no`.
- Rol `qdoora-role-node` reducido a `AmazonSSMManagedInstanceCore`, `AmazonEC2ContainerRegistryReadOnly`, `QdooraQAS3Policy` y `S3AccessLaravelApi`. Se quitaron `AdministratorAccess`, `AmazonS3FullAccess`, las 2 políticas de EKS y la de CodeDeploy, y se deshabilitó el agente de CodeDeploy.
- Llaves: se eliminó el usuario `qdoora-chile-qa`, se borró la llave …7HUM del `.env.prod` de Colombia y se creó la …24KY para `codecommit-franco`.
- Dumps de `/tmp` borrados; permisos `600` en los `.env` y en los respaldos de Gregorio.
- Detección: CloudTrail `qdoora-trail` (multirregión, bucket `qdoora-cloudtrail-310734905914`, 365 días); GuardDuty con avisos de severidad >= 4 a SNS `qdoora-alertas-seguridad` (correo); `scanOnPush` en los 7 repos ECR; presupuesto mensual con alerta al 80%. Root tiene MFA.
- Inventario de solo lectura reutilizable: `qdoora-api/ops/security-inventory.sh` (sin commitear).

### Cambio propuesto

**Con fecha**
1. **~2026-10-27:** desactivar y borrar la llave **…RBOX** de `codecommit-franco`, que está en el historial de git (`InstalacionQA.md`, ramas `dev-temporal` y `aduana-nano`).
2. **~2026-11-19:** termina la prueba gratis de GuardDuty. Revisar en su consola el costo estimado y decidir si se mantiene.

**Cuenta y accesos**

3. Crear un usuario administrador con MFA (o IAM Identity Center) para el trabajo diario y dejar root solo para emergencias.
4. Colombia: 4200 y 4202 siguen abiertos a `0.0.0.0/0`. Llevarlos detrás del ALB con dominio y aceptar solo desde el SG del ALB, como el 4201.
5. Al volver Colombia a producción: usar el rol de la instancia (o uno propio), nunca llaves en `.env`, y agregar una política solo para `co-qdoora-production-disk`.
6. Cuando `agente-gregorio` entre en funcionamiento, crear `GregorioS3Policy` (`ListBucket` sobre `gregorio-disk` y `Get/Put/DeleteObject` sobre `gregorio-disk/*`) y adjuntarla al rol. Si el agente corre fuera del EC2, adjuntarla a su propio rol. `qdoora-latam-disk` es de desarrollo y **no** va en el rol.
7. Evaluar el bloqueo de IMDS para los contenedores que no usan AWS (Nutrición): todos comparten el rol con hop limit 2. El aislamiento real por app llega con ECS (un rol por tarea).

**Código y repositorios**

8. `AdminApiKeyMiddleware`: comparar con `hash_equals()` (hoy usa `!==`) y leer la llave desde `config()` en lugar de `env()`.
9. Agregar `gitleaks` como check de los PR en los 3 repos. En el plan Free de GitHub, el secret scanning no aplica a repos privados.
10. Commitear `qdoora-api/ops/security-inventory.sh`.
11. Borrar `deploy/qdoora_qa.dump` del Mac del usuario y los dumps viejos (`/home/ubuntu/qdoora-colombia/backup-15092023.sql`).

### Gotchas

- Revocar una regla `0.0.0.0/0` corta al instante las conexiones abiertas (AWS no las mantiene). Si es la regla de SSH, se corta la sesión.
- CloudShell: pegar comandos de una sola línea y sin variables (la primera línea de un pegado múltiple se puede perder) y poner entre comillas simples todo texto con `!`.
- Access Advisor del rol va con horas de retraso. Para saber qué usa el rol, mejor `aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=i-0ceea9ec1bca59eda`. Las lecturas de S3 no aparecen ahí.

### Criterio de aceptación

Volver a ejecutar `security-inventory.sh`: solo el 22 queda abierto a una IP pública (el rango de Instance Connect), no queda ninguna llave AWS activa con más de 90 días ni escrita en disco, y los puntos 1 a 11 están cerrados.

---

## 23. Dashboard home: `companyId` fijo en 1 (ignora la empresa seleccionada)

**Contexto.** `fuse-starter/src/app/modules/admin/dashboards/home/home.component.ts` carga el dashboard con `const companyId = 1;` fijo, sin importar la empresa seleccionada del usuario. Detectado el 2026-10-21 al certificar el alta de usuarios de trabajo: el endpoint `GET /api/v1/company/1/dashboard` respondió 403 para un usuario sin acceso a esa empresa.

**Efecto.** Cualquier usuario cuya empresa seleccionada no sea la 1 recibe un 403 en esa llamada (el backend autoriza por empresa y hace bien su trabajo), y el dashboard queda sin datos. El aviso «Aún no tienes una empresa seleccionada» ya cubre el caso de usuarios sin empresa, pero no este.

**No se corrigió** porque no está claro si el dashboard «Enterprise» es un prototipo (usa un simulador de módulos activos, `activeModules`, y `userName` fijo en «Administrador»): usar la empresa real empezaría a mostrar datos reales sin revisarlos.

**A resolver.**

1. Confirmar con producto si el dashboard está en uso real o es un prototipo.
2. Si está en uso: tomar la empresa de `UserService.user$` (`user.company.id`), recargar el dashboard cuando el usuario cambie de empresa y quitar el valor fijo.
3. Revisar los datos que devuelve el endpoint para una empresa real (`metrics`, `charts`, `risks`, `pending_actions`) antes de exponerlos.
4. Cubrir con spec: el dashboard pide la empresa seleccionada y no la 1.

**Relacionado.** El aviso de «sin empresa seleccionada» (commit `7a0dada` de `fuse-starter`) y `docs/designs/2026-10-21-mitigacion-observaciones-permisos.md`.

---

## 24. Eliminar y editar usuarios de trabajo: el botón existe, el backend no

**Contexto.** En `/general/user` (Portal Cliente) cada fila trae una papelera, pero `onDeleteRow()` de `fuse-starter/src/app/modules/admin/general/users/list/list.component.ts` solo abre el diálogo «Esta acción es permanente e irreversible!»: el bloque `if (result == 'confirmed') { }` está **vacío** y no llama a ningún endpoint. Detectado el 2026-10-21 al revisar qué endpoints de usuarios exigen rol suscriptor.

**Efecto.** El suscriptor confirma una eliminación irreversible y no ocurre nada. Tampoco existe en el backend un endpoint para que el suscriptor elimine ni edite (nombre, correo, avatar) a un usuario de su equipo: `routes/api.php` (`v1/subscriber`) solo tiene crear, listar y permisos. La corrección de correo (`PATCH users/{user_id}/email`) vive en el grupo de administración. Un usuario de trabajo creado por error o que deja la empresa no se puede dar de baja, y sigue ocupando un cupo de usuarios del plan.

**A resolver.**

1. Decidir el alcance: solo baja, o baja + edición de datos del usuario.
2. Baja lógica, no física, siguiendo el patrón de `SubscriberService::deleteSubscriber()` (BACKEND_RULES, «Baja/reactivación de cuentas con correo único: patrón `previous_email``»): correo real a `previous_email` y reemplazo por un valor de largo fijo en TLD no enrutable.
3. Cerrar las sesiones del usuario al darlo de baja (`AuthSessionService::revokeAllForUser`, como en el cambio de email de perfil).
4. Liberar el cupo del plan (`Dimension::USERS`) y validar que el límite se recalcula.
5. Endpoint nuevo con FormRequest que exija `authorizeSubscriber()` y verifique que el usuario pertenece al equipo del suscriptor (`find()` + `NotFound404Exception`, nunca un id suelto: IDOR); el suscriptor no puede darse de baja a sí mismo por esta vía.
6. Conservar los registros históricos de lo que el usuario creó (Hard Reject #6): la baja no borra comprobantes, liquidaciones ni documentos.
7. Frontend: conectar `onDeleteRow()` al endpoint, refrescar el listado y reflejar los errores; si hay edición, reutilizar la pantalla de creación en modo edición (hoy `is_new_record` siempre es `true`).
8. Hasta que exista, evaluar ocultar la papelera para no prometer una acción que no ocurre.

**Relacionado.** `docs/designs/2026-10-21-mitigacion-observaciones-permisos.md` y las pruebas de 403 de `tests/Feature/Permission/SubscriberOnlyEndpointsTest.php`.

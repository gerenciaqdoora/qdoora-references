# Catastro: Habilitación de QdoorA como Emisor Electrónico ante el SII

**Fecha**: 2026-07-09 · **Alcance**: Documentos Tributarios Electrónicos (Factura 33, Factura Exenta 34, Nota Crédito 61, Nota Débito 56, Guía de Despacho 52) + Boletas Electrónicas (39/41).

Este documento cruza dos cosas: (1) el trámite regulatorio real ante el SII para convertirse en emisor electrónico con software propio, y (2) lo que ya está construido en `qdoora-api` / `fuse-starter` / `support-portal` para acompañar cada paso. Fuente regulatoria: sii.cl (Sistema de Facturación de Mercado) y maullin.sii.cl (ambiente de certificación), verificado julio 2026.

## 0. Estado actual en QdoorA

El módulo SII está **implementado end-to-end** (backend + Portal Cliente + Portal Soporte): certificado digital, CAF, emisión DTE/Boleta, estado ante SII, RCV, gate de habilitación (`sii_dte_enabled`), y un asistente de certificación con checklist + Set de Pruebas. Todas las empresas nacen en `sii_environment = certificacion`. Nada está en producción real todavía (ninguna empresa tiene resolución SII ni CAF de producción cargado).

## 1. Requisitos previos (antes de postular en sii.cl)

- Inicio de actividades vigente.
- Contribuyente de Primera Categoría (Art. 20 Ley de Impuesto a la Renta).
- Representante legal y firmantes autorizados sin situaciones pendientes con el SII (verificar en Mi SII → "Mi Situación Tributaria").
- Si vas a emitir con IVA: verificación positiva de actividades en terreno (o en trámite).
- Certificado digital vigente del representante legal (para autenticarse en sii.cl) — distinto del certificado que se sube a QdoorA para firmar los DTE.

### 1.1 Quién puede ejecutar cada trámite

- **Postulación inicial (paso 1 de la tabla siguiente)**: exige sí o sí al representante legal, autenticado con certificado digital. Si quien va a operar el día a día no es el representante legal, la alternativa formal es que el representante legal le otorgue un **poder ante notario**, o lo autorice vía la opción "Representar a contribuyentes" de sii.cl (Código Tributario, art. 9) para ese trámite específico.
- **Al postular, el representante legal designa a un "Usuario Administrador de Facturación Electrónica"** — puede ser cualquier persona (un desarrollador, un contador, TI), no tiene que ser el representante legal. Este nombramiento se hace en el mismo formulario de postulación, junto con el software declarado.
- **De ahí en adelante, es el Usuario Administrador (o los "Usuarios Autorizados" que este agregue) quien hace la gestión operativa** en maullin.sii.cl — solicitar CAF, avanzar el Set de Pruebas, subir certificados y CAF en QdoorA, etc. — **sin volver a requerir al representante legal** en cada trámite.
- El único otro momento donde vuelve a pesar la figura del representante legal es la **declaración de cumplimiento de requisitos** (paso 8) y la firma de la Resolución final, que suelen quedar asociadas a la cuenta que postuló originalmente.

### 1.2 Estrategia de pruebas si QdoorA (la empresa) todavía no factura

QdoorA como contribuyente no necesita ser emisor electrónico para que su software sea usado por terceros — **"proveedor tecnológico" (`sii_sw_rut`/`sii_sw_name`) y "emisor electrónico" son conceptos distintos**. Un desarrollador de software puede figurar como proveedor sin facturar electrónicamente él mismo.

Para validar el módulo técnicamente sin esperar la postulación de un cliente nuevo, se puede usar **cualquier empresa que ya sea facturador electrónico** (por ejemplo, otra empresa del representante legal que ya factura con otro proveedor):

- El SII confirma explícitamente que **no es necesario volver a certificar** para cambiar de proveedor de software — solo recomienda probar en el ambiente de certificación antes de pasar a producción ([FAQ SII 001.003.6485](https://www.sii.cl/preguntas_frecuentes/factura_electronica/001_003_6485.htm)).
- Esa empresa ya tiene Usuario Administrador y acceso a maullin.sii.cl: basta con solicitar ahí folios de prueba (CAF de certificación) para el tipo de documento a validar y usarlos en QdoorA, sin tocar su producción real.
- **Límite importante**: esto certifica que *la integración técnica funciona* para esa empresa puntual, no "certifica a QdoorA como producto". Cada empresa nueva que use QdoorA en el futuro (que no sea ya emisor electrónico) igual debe pasar su propio proceso completo de postulación + certificación descrito abajo.
- Precaución operativa: mantener las pruebas siempre en el ambiente de **certificación (maullín)**, nunca en producción (palena) de esa empresa, mientras el módulo no esté 100% validado — para no arriesgar la facturación real de un negocio que ya opera. Esto no es asesoría legal/tributaria; conviene confirmarlo con el contador de esa empresa antes de usar su RUT real, aun en modo prueba.

## 2. Trámite regulatorio ante el SII (acción manual tuya, fuera de QdoorA)

| # | Paso SII | Dónde | Dónde queda en QdoorA |
|---|----------|-------|------------------------|
| 1 | **Postulación**: representante legal se autentica con certificado digital, informa el software (proveedor tecnológico = QdoorA) y **designa a un Usuario Administrador de Facturación Electrónica** — persona (puede ser un tercero, no necesita ser el representante legal) que queda habilitada para gestionar el resto del proceso en maullin.sii.cl (folios, Set de Pruebas, etc.) sin volver a requerir al representante legal | sii.cl → Factura Electrónica → Sistema de Facturación de Mercado → Postular | `core_companies.sii_sw_rut` / `sii_sw_name` (ya existen las columnas) |
| 2 | Adjuntar **certificado digital** con el que se firmarán los DTE | — | Portal Cliente `/billing/setting` → sección **Certificado** |
| 3 | Solicitar **CAF de certificación** (folios de prueba) por cada tipo de documento a certificar | maullin.sii.cl → Solicitud de timbraje electrónico de prueba | Portal Cliente `/billing/setting` → sección **Folios CAF** (subir el XML descargado) |
| 4 | Emitir el **Set de Pruebas** que el SII asigna (casos obligatorios definidos por ellos) | maullin.sii.cl | Portal Cliente `/billing/setting` → sección **Certificación**: registras cada caso (nº atención, nº caso, tipo doc, enunciado) y lo emites desde `/billing/emission`; queda vinculado con folio/track id/estado SII automáticamente |
| 5 | **Set de Simulación** | maullin.sii.cl | Sin soporte específico; usa la emisión normal en certificación |
| 6 | **Set de intercambio de información** (recepción de EnvioRecibos/ResultadoDTE) | maullin.sii.cl | **Fuera de alcance**: QdoorA no tiene receptor de intercambio. Se marca a mano como checklist en el asistente |
| 7 | **Envío de muestras impresas** (representación visual del DTE) | Correo/portal SII según instructivo | El PDF ya lo genera QdoorA (`DteController::pdf` / `DtePrintService`) |
| 8 | **Declaración de cumplimiento de requisitos** | sii.cl | Checklist manual en el asistente de Certificación (paso `declaracion`) |
| 9 | SII emite la **Resolución** que autoriza como emisor electrónico | — | Se guarda `sii_resolution_num` / `sii_resolution_date` al solicitar el paso a producción |

Los pasos 4–8 se pueden repetir en paralelo para **Boletas Electrónicas** (39/41) si también las vas a emitir; el asistente de Certificación en QdoorA ya separa el checklist por proceso (`documentos` / `boleta`).

## 3. Paso a producción dentro de QdoorA (con la Resolución SII ya emitida)

1. Solicitar el **CAF de producción** en el sitio del SII (palena.sii.cl) y subirlo en `/billing/setting` → Folios CAF.
2. En `/billing/setting` → sección **Habilitación**, botón "Solicitar paso a producción": ingresas `resolution_num` / `resolution_date` / notas.
3. Esto crea un `sii_enablement_request` (`pending`). Soporte QdoorA lo revisa en `support-portal` → cola **sii-enablement-queue** y aprueba o rechaza (motivo obligatorio si rechaza).
4. Al aprobar, `core_companies.sii_environment` pasa a `produccion` automáticamente y las emisiones siguientes apuntan a `palena.sii.cl`.
5. Excepción: si el entorno tiene `SII_REQUIRE_PRODUCTION_APPROVAL=false` (solo pensado para QA/staging), la solicitud se auto-aprueba sin revisión humana.

Nota: `sii_dte_enabled` (el flag que realmente bloquea/permite emitir) **no se toca a mano** — se recalcula solo cuando hay certificado vigente + al menos un CAF activo (`SiiEnablementService::syncDteEnabledFlag`). Esto ya funciona sin fricción en ambiente de certificación; el gate de aprobación humana aplica únicamente al salto a producción.

## 4. Mapa técnico — qué ya existe en el código

| Componente SII | Implementación en `qdoora-api` |
|---|---|
| Autenticación (semilla + token) | `SiiAuthService`, `BoletaAuthService` |
| Certificados digitales | `CertificateService`, `Certificate` model, S3 + AES-256 |
| CAF y folios | `CafService`, `Caf` model, `next_folio` atómico |
| Construcción/firma DTE (ISO-8859-1, TED + firma empresa) | `DteBuilderService` |
| Envío al SII | `DteSenderService`, `SendDteJob` |
| Estado del documento | `DteStatusService`, `CheckDteStatusJob` |
| PDF / representación impresa | `DtePrintService` |
| RCV (compras/ventas) | `RcvService`, `RcvActionService`, `ImportRcvJob` |
| Asistente de certificación (checklist + Set de Pruebas) | `SiiCertificationService`, `CertificationController` |
| Gate de habilitación + solicitud de producción | `SiiEnablementService`, `EnablementController`, `SiiAdminController` (Soporte) |

Reglas críticas ya documentadas en `MEMORY.md` / `BACKEND_RULES.md`: firma en ISO-8859-1 (nunca UTF-8), dos firmas distintas (RSASK del CAF para el TED, certificado de empresa para el DTE completo), `sii_dte_enabled` nunca se setea a mano.

## 5. Pendiente de tu parte (no es código, es trámite)

1. Ejecutar la Postulación en sii.cl con tu certificado digital de representante legal.
2. Adjuntar el certificado digital de la empresa en QdoorA.
3. Solicitar el primer CAF de certificación en maullin.sii.cl y subirlo.
4. Registrar en el asistente de Certificación los casos del Set de Pruebas que el SII te asigne y emitirlos desde `/billing/emission`.
5. Completar Simulación, intercambio, muestras impresas y declaración de cumplimiento (checklist manual).
6. Cuando el SII emita la Resolución, solicitar el paso a producción desde `/billing/setting` → Habilitación.

## Fuentes oficiales SII

- [Procedimiento de postulación, certificación y autorización](https://www.sii.cl/factura_electronica/factura_mercado/proc_postulacion.htm)
- [Proceso de certificación](https://www.sii.cl/factura_electronica/factura_mercado/proceso_certificacion.htm)
- [Requisitos de postulación](https://www.sii.cl/factura_electronica/factura_mercado/requisitos.htm)
- [Sistema de facturación de mercado](https://www.sii.cl/servicios_online/1039-1184.html)
- [Ambiente de Certificación (Maullín)](https://maullin.sii.cl/cvc/dte/certificacion_dte.html)
- [Manual para empresas usuarias ambiente de certificación](https://www.sii.cl/servicios_online/docs/manual_certificacion.pdf)

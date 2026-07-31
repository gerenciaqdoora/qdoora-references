Proceso de centralizacion (contabilizacion) de documentos compra/venta

1. Configuracion de cuenta / subcuenta para operar en compra/venta

En el formulario de cuenta / subcuenta del plan de cuenta se debe agregar una opcion "operativa"
para poder configurar si cuenta va operar en compra o venta, no en ambas. Si se configura una cuenta
y se crea una subcuenta de esta cuenta, debe heredar la configuracion. Si hay una subcuenta creada,
no se puede configurar la cuenta, ya que la subcuenta es la cuenta mayor (el ultimo nodo es la cuenta
mayor, ya sea cuenta o subcuenta).

2. Configuracion de cuenta mayor para total_neto

Si el cliente tiene contratado el modulo de contabilidad, se debe empiricamente configurar en el
formulario de auxiliar una cuenta mayor para "total_neto". Esta cuenta sera la que se utilice
para registrar los totales netos de los documentos compra/venta extraidos desde RCV.

Si el auxiliar es cliente, para poder operar la contabilidad necesita que dentro del plan de cuenta
haya una cuenta/subcuenta configurado con cuenta maestra "CLIENTE_NACIONAL" (esto ya existe, campo
total desde RCV) y con cuenta maestra "IVA_DEBITO_FISCAL" (campo total_iva desde RCV), ademas hay que
traer mediante servicio las cuentas mayor, cuentas y/o subcuentas configuradas previamente como
operativas en venta, para configurarlo, solo asi RCV y centralizacion en venta funcionara.

Si el auxiliar es proveedor, para poder operar la contabilidad necesita que dentro del plan de cuenta
haya una cuenta/subcuenta configurado con cuenta maestra "PROVEEDOR_NACIONAL" (esto ya existe, campo
total desde RCV) y con cuenta maestra "IVA_CREDITO_FISCAL" (campo total_iva desde RCV), ademas hay
que traer mediante servicio las cuentas mayor, cuentas y/o subcuentas configuradas previamente como
operativas en compra, para configurarlo, solo asi RCV y centralizacion en compra funcionara.

Si la cuenta mayor que se configura para el total_neto, trabaja con auxiliar con RUT, debemos seleccionar obligatoriamente auxiliar con RUT, si trabaja con auxiliar sin RUT, debemos seleccionar obligatoriamente auxiliar sin RUT, si trabaja con centro de costo, debemos seleccionar obligatoriamente centro de costo.

Restricción: La configuracion de la cuenta mayor no puede ser compra y venta al mismo tiempo
(cuenta para total_neto).

Restricción: Si dentro del formulario de cuenta/subcuenta se edita y se modifica la opcion (por
ejemplo es venta y se cambia a compra, y viceversa) se deben eliminar todas las configuraciones
realizadas para los auxiliares clientes que fueron previamente configurados.

Ayuda: Servicio para obtener cuenta mayor que se debe utilizar es
Route::post(
  '/company/{company_id}/accounts/voucher/filter',
  [\App\Http\Controllers\Contabilidad\AccountPlanController::class, 'getAccountsVoucher']
);

Ayuda: Servicio para obtener centro de costos
inject(CostCenterService).getCostCenters(null, 9999)

Ayuda: Servicio para obtener auxiliares (RUT o sin RUT)
inject(EntityService).getAccountsAuxiliaryFilter({ auxiliary_with_rut: true|false, auxiliary_without_rut: true|false })

Ayuda: Usar componente AssignMasterAccountsComponent para las asignacion de cuenta maestra,
para pedir las cuentas sin cuenta maestra asociada (ya se utiliza):
this._accountPlanService.getAccountsWithOutMasterAccount(this._userService.currentUser?.company?.id)
    .pipe(
        takeUntil(this._unsubscribeAll),
        finalize(() => this._changeDetectorRef.markForCheck())
    )
    .subscribe({
        next: (res) => this.cuentasSinAsignar = res || [],
        error: (err: JsonResponse<any></any>) => this.showAlertMessage('error', 'No se pudieron recuperar las cuentas libres.')
    });

3. Extraccion RCV

Mediante un flujo de la interfaz de usuario en compra y venta se inicia el proceso de extraccion de
documentos RCV (compra en /accounting/purchase y venta en /accounting/sale).

En el endpoint para la extraccion RCV es (ya existe):
POST /v1/company/{company}/sii/rcv/extract
  body: { period: "MM/AAAA", rcv_type: "sale"|"purchase" }
  → 202 { message }

La tabla sii_rcv_sessions es para cada proceso de extraccion y la tabla sii_rcv_records son todos los
documentos extraidos de RCV de ese periodo (sesion).

Cada documento recibido en RCV se guarda en RcvRecord. Los campos mas importantes para la creacion de documentos son:

'doc_tributary_code', //Codigo del documento tributario electronico (30, 33, 34, etc)
'folio', //Numero identificador del documento

'counterparty_rut', //RUT del receptor del documento
'counterparty_name', //Nombre del receptor del documento

'total_neto', //Monto neto del documento
'total_exento', //Monto exento del documento
'total_iva', //Monto de IVA del documento
'total_otros_impuestos', //Monto de otros impuestos del documento
'total', //Monto total del documento

'emitted_at', //Fecha de emision del documento
'received_at', //Fecha de recepcion del documento
'sii_period', //Periodo RCV, formato YYYYMM
'transaction_type', //Tipo de transaccion

'total_fixed_asset', //Total activo fijo
'total_iva_non_recoverable', //Total iva no recuperable
'total_iva_common_use', //Total iva uso comun
'total_iva_withheld', //Total iva retenido

'sii_event_code', // A/P/C
'sii_event_legend', // Descripcion
'sii_receipt_date', // Fecha aceptacion electronica
'sii_claim_date', // Fecha reclamo

Para columna sii_event_code: Generar Enum para la columna, de esta manera se controlan las opciones recepcionadas.

Código	Significado
A	Acuse de recibo automático — se otorga solo cuando el documento no se reclama dentro del plazo legal (8 días corridos). Es el caso más común.
C	Acuse de recibo informado por el receptor (explícito) dentro del plazo legal — es decir, el receptor dio el acuse manualmente.
P	Documento pagado al contado.
G	Acuse de recibo informado en guía(s) de despacho del mes anterior.

4. Creacion de documento compra/venta

Cuando el proceso de extraccion RCV termine con exito (estado COMPLETED) y exista informacion para trabajar, se inicia el proceso de creacion de documentos compra/venta en segundo plano (Job).

- Tabla core_documents (modelo Documento) el campo tributary_code se cruza con doc_tributary_code y se obtiene id.
- Tabla core_identification_documents (modelo DocumentoTipoIdentificacion) el campo code '03' se obtiene el id
- Para ambos casos debemos usar counterparty_rut y counterparty_name para obtener el auxiliar, se debe utilizar ThirdCompanyService::crearORecuperarPorRut, hay que mandarle name, second_name, last_name, maternal_last_name, identification_document_id, rut (desde rcv viene con xxxxxxx-DV, en los datos se ingresa sin guion), con esto obtenemos el id de la tabla core_third_companies (modelo ThirdCompany)

Para venta dentro de App\Services\Contabilidad\SaleService.php debemos crear un servicio nuevo para la creacion de documento llamado creaOActualizaDocumento y otro servicio para centralizar (contabilizar) similar a syncAccountingEntries (solo declaralo despues lo implementamos bien)

creaOActualizaDocumento:
    * Dentro de qdoora-references/manuales/sii/RCV/venta.json esta el json completo extraido desde RCV, aca necesito tu analisis para ver que campos y valores se pueden mapear y complementar con Venta::create sugerido mas adelante.
    * Utilizar verifyUniquenessOfSale para verificar si es un documento que ya existia o no, se pasa el company_id, core_documents.id (obtenido previamente) y folio (desde RCV).
    * Utilizar Venta::create dentro de DB::transaction(), se debe mandar:
            'company_id'          => $company_id,
            'voucher_id'          => null, // pk compuesta de voucher pero debe ser nulo inicialmente porque no se ha centralizado
            'voucher_year'        => null, // pk compuesta de voucher pero debe ser nulo inicialmente porque no se ha centralizado
            'period'              => sii_period (desde RCV),
            'num_doc'             => folio (desde RCV),
            'doc_id'              => core_documents.id,
            'client_id'           => core_third_companies.id,
            'date'                => Carbon::createFromFormat('Y-m-d', emitted_at desde RCV),
            'description'         => sii_event_legend (desde RCV),
            'file_path'           => null,
            'payment_method'      => core_payment_methods.code = 'CONTADO', //ver cuando sera CREDITO
            'expiration_date'     => null, // desde venta.json
            'type_doc_reference'  => null, // desde venta.json
            'num_doc_reference'   => null, // desde venta.json
            'doc_reference_id'    => null, // desde venta.json
            'total_neto'          => total_neto (desde RCV),
            'total_vat'           => total_iva (desde RCV),
            'total_rete'          => 0.00, // desde venta.json
            'total_other_tax'     => total_otros_impuestos (desde RCV), // desde venta.json como saber other_tax_id
            'total_dcto'          => 0.00, // desde venta.json
            'total'               => total (desde RCV),
            'applies_vat'         => total_iva > 0 ? true : false,
            'other_tax_id'        => null, // desde venta.json
            'vat_id'              => total_iva > 0 ? core_taxes.id where tributary_code 14 : null,
            'type_note_credit_id' => null, // desde venta.json
            'type_note_debit_id'  => null, // desde venta.json
            'created_at'          => Carbon::now('America/Santiago'),
            'updated_at'          => Carbon::now('America/Santiago')

Para Compra dentro de App\Services\Contabilidad\PurchaseService.php debemos crear un servicio nuevo para la creacion de documento llamado creaOActualizaDocumento y otro servicio para centralizar (contabilizar) similar a syncAccountingEntries (solo declaralo despues lo implementamos bien)

creaOActualizaDocumento:
    * Dentro de qdoora-references/manuales/sii/RCV/compra.json esta el json completo extraido desde RCV, aca necesito tu analisis para ver que campos y valores se pueden mapear y complementar con Compra::create sugerido mas adelante.
    * Utilizar verifyUniquenessOfPurchase para verificar si es un documento que ya existia o no, se pasa el company_id, core_documents.id (obtenido previamente), folio (desde RCV) y core_third_companies.id (obtenido previamente).
    * Utilizar Compra::create dentro de DB::transaction(), se debe mandar:
            'company_id'          => $company_id,
            'voucher_id'          => null, // pk compuesta de voucher pero debe ser nulo inicialmente porque no se ha centralizado
            'voucher_year'        => null, // pk compuesta de voucher pero debe ser nulo inicialmente porque no se ha centralizado
            'period'              => sii_period (desde RCV),
            'num_doc'             => folio (desde RCV),
            'doc_id'              => core_documents.id,
            'provider_id'         => core_third_companies.id,
            'date'                => Carbon::createFromFormat('d/m/Y', emitted_at desde RCV),
            'acknowledgment_date' => Carbon::createFromFormat('Y-m-d', emitted_at desde RCV),
            'reception_date'      => Carbon::createFromFormat('Y-m-d', sii_receipt_date desde RCV),
            'gyre'                => true, // desde compra.json
            'supermarket'         => false, // desde compra.json
            'real_estate'         => false, // desde compra.json
            'fixed_asset'         => false, // desde compra.json
            'common_vat_use'      => false, // desde compra.json
            'non_recoverable_vat' => false, // desde compra.json
            'not_appropriate_to_include' => false, // desde compra.json
            'description'         => sii_event_legend (desde RCV),
            'file_path'           => null,
            'payment_method'      => core_payment_methods.code = 'CONTADO', // desde compra.json
            'expiration_date'     => null, // desde compra.json
            'type_doc_reference'  => null, // desde compra.json
            'num_doc_reference'   => null, // desde compra.json
            'doc_reference_id'    => null, // desde compra.json
            'total_neto'          => total_neto (desde RCV),
            'total_vat'           => total_iva (desde RCV),
            'total_rete'          => 0.00, // desde compra.json
            'total_other_tax'     => total_otros_impuestos (desde RCV), // desde compra.json como saber other_tax_id
            'total_dcto'          => 0.00, // desde compra.json
            'total'               => total (desde RCV),
            'applies_vat'         => total_iva > 0 ? true : false,
            'other_tax_id'        => null, // desde compra.json
            'vat_id'              => total_iva > 0 ? core_taxes.id where tributary_code 14 : null,
            'type_note_credit_id' => null, // desde compra.json
            'type_note_debit_id'  => null, // desde compra.json
            'created_at'          => Carbon::now('America/Santiago'),
            'updated_at'          => Carbon::now('America/Santiago')

- Dentro de los modelos de App\Models\Compra\Compra y App\Models\Venta\Venta, tienen "hijos" de las tablas App\Models\Compra\CompraItem y App\Models\Venta\VentaItem, estas ya no son validas y se deprecan, para que no las tomes en consideracion.

5. Proceso de centralizacion

Por cada documento RcvRecord, se debe crear un proceso de centralizacion, se hace necesario crear un nuevo metodo en el servicio SaleService y PurchaseService, similar a syncAccountingEntries:

Para Venta:

- Tenemos que averiguar cuales son las cuentas para cada monto:

  - total_neto: Cuenta configurada en punto 2, con el auxiliar y centro de costo
  - total_iva: Cuenta configurada (accont_sale_id y sub_accont_sale_id) en tabla cont_tax_accounts segun company_id y tax_id (vat_id de Venta) o buscar la cuenta con la asignacion de cuenta maestra IVA_DEBITO_FISCAL
  - total_otros_impuestos: Cuenta configurada (accont_sale_id y sub_accont_sale_id) en tabla cont_tax_accounts segun company_id y tax_id (other_tax_id de Venta).
  - total: Cuenta configurada con cuenta maestra CLIENTE_NACIONAL (ya lo hace syncAccountingEntries)
- Si tenemos todas las cuentas procedemos con la creacion del asiento contable
- Si falta alguna dejar evidencia para que el usuario desde la interfaz usuaria el usuario complete y pueda centralizar manualmente.
- Crear voucher
  $voucher = $this->voucherService->crearCabeceraComprobante(
  [
  'date' => Venta::date,
  'type' => App\Services\Contabilidad\SaleService::typeVoucher,
  'voucher_type' => App\Services\Contabilidad\SaleService::origenVoucher,
  'norma' => App\Services\Contabilidad\SaleService::normaVoucher,
  'relationated_person' => null,
  'currency' => App\Services\Contabilidad\SaleService::currencyCLP,
  'currency_change_rate' => null,
  'generate_as_plantilla' => false,
  'name_template' => null,
  'total' => Venta::total,
  'description' => Venta::description
  ],
  $user,
  $company_id
  );
- Editar Venta con voucher_id y voucher_year
- Por cada cuenta creamos un VoucherAccount, revisar persistAccountingEntries, nos puede servir mucho.
  total_neto va hacia el credit, total_iva va hacia el credit, total_otros_impuestos va hacia el credit, total va hacia el debit

Para Compra:

- Tenemos que averiguar cuales son las cuentas para cada monto:

  - total_neto: Cuenta configurada en punto 2, con el auxiliar y centro de costo
  - total_iva: Cuenta configurada (accont_purchase_id y sub_accont_purchase_id) en tabla cont_tax_accounts segun company_id y tax_id (vat_id de Compra) o buscar la cuenta con la asignacion de cuenta maestra IVA_CREDITO_FISCAL
  - total_otros_impuestos: Cuenta configurada (accont_purchase_id y sub_accont_purchase_id) en tabla cont_tax_accounts segun company_id y tax_id (other_tax_id de Compra).
  - total: Cuenta configurada con cuenta maestra PROVEEDOR_NACIONAL (ya lo hace syncAccountingEntries)
- Si tenemos todas las cuentas procedemos con la creacion del asiento contable
- Si falta alguna dejar evidencia para que el usuario desde la interfaz usuaria el usuario complete y pueda centralizar manualmente.
- Crear voucher
  $voucher = $this->voucherService->crearCabeceraComprobante(
  [
  'date' => Compra::date,
  'type' => App\Services\Contabilidad\PurchaseService::typeVoucher,
  'voucher_type' => App\Services\Contabilidad\PurchaseService::origenVoucher,
  'norma' => App\Services\Contabilidad\PurchaseService::normaVoucher,
  'relationated_person' => null,
  'currency' => App\Services\Contabilidad\PurchaseService::currencyCLP,
  'currency_change_rate' => null,
  'generate_as_plantilla' => false,
  'name_template' => null,
  'total' => Compra::total,
  'description' => Compra::description
  ],
  $user,
  $company_id
  );
- Editar Compra con voucher_id y voucher_year
- Por cada cuenta creamos un VoucherAccount, revisar persistAccountingEntries, nos puede servir mucho.
  total_neto va hacia el debit, total_iva va hacia el debit, total_otros_impuestos va hacia el debit, total va hacia el credit

6. Interfaz de compras/ventas

Agregar un nuevo filtro de estado, para poder filtrar segun su estado:

- No centralizada
- Centralizado

Para los casos de No centralizado, que aparezca un boton en la lista para poder centralizar de manera manual mediante un dialog (modal) que me muestre el desgloce completo de las cuentas que deben existir, las que exiten (se muestra) y las que faltan (se muestra la cuenta en rojo o algo similar) y poder configurar y luego aceptar para crear el voucher.

Es decir, cuenta CLIENTE_NACIONAL (venta), PROVEEDOR_NACIONAL (compra), IVA_DEBITO_FISCAL (venta), IVA_CREDITO_FISCAL (compra), cuenta total_neto y en caso de otros impuestos cuenta cont_tax_accounts segun other_tax_id.

7. Alcance

* Nueva configuracion de cuenta mayor para que trabaje en venta o compra
* Nueva configuracion de cuenta mayor, auxiliar y centro de costo en auxiliar si es venta o compra para total_neto desde RCV (solo si usuario tiene modulo de contabilidad).
* Siempre que se haga una extraccion RCV y se encuentren documentos se deben ver en la lista de documentos de su naturaleza (compra o venta) sin excepcion. Lo que puede ocurrir es que se contabilice o no.
* Los documentos encontrados no pueden duplicarse, importante este punto, con el metodo `verifyUniquenessOfPurchase` y `verifyUniquenessOfSale`
* En caso de no tener configuraciones de cuentas realizadas debe poder centralizarse de forma manual.
* Los documentos de compra y venta inicialmente siempre se crean sin voucher_id y voucher_year.
* El proceso de centralizacion realizado con `syncAccountingEntries` debe hacer mismo que hace hasta hoy: buscar cuentas, asiganr a debit o credit, ver si es nota de credito, ver si es candidato a tesoreria, limpiar cuentas, asignar voucher a documento y crear cuentas de voucher.
* Si es necesario reorganizar los servicios SaleService y PurchaseService presentame las modificaciones consideradas.
* Dentro de compra.json y venta.json se encuentras todos los campos que se reciben desde RCV, consideralos siempre para el proceso de creacion de Venta y Compra para las notas de credito y referencias, otros impuestos, otras retenciones, etc que aun no esta definido el camino o flujo que debiese ocurrir.

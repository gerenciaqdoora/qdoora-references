
CUENTA_CLIENTE: Asignacion de cuetan maestra CLIENTE NACIONAL
CUENTA_DESEMBOLSO: Asignacion de cuenta maestra DESEMBOLSO
CUENTA_DESEMBOLSO_POR_PAGAR: Solo modulo aduana, asignacion de cuenta maestra DESEMBOLSO_POR_PAGAR
CUENTA_TRABAJA_CON_DESPACHO: Solo modulo aduana, campo trabaja con nº de despacho en true.
CUENTA_TRABAJA_CON_AUXILIAR: campo trabaja con auxiliar con rut/pasaporte o como concepto en true.
CUENTA_TRABAJA_CON_DOCUMENTOS: Si la cuenta tiene asignacion de cuenta maestra, los tipo de documentos estan enlazados a estan cuentas maestras, por ejemplo para cliente nacional, estan las facturas exento, afecta, notas de credito, etc.

-------
INGRESO
-------
-> Si CUENTA_CLIENTE
    -> Opcion "Cancela factura" -> busca los documentos pendientes
    -> Si CUENTA_TRABAJA_CON_DESPACHO opción "Provision de fondos"
        -> Se completa el nro de despacho y se trae el cliente
        -> Si no existe el despacho, debemos mostrar mensaje, 
        debemos pedir confirmacion de continuar y le mostramos 
        la lista de consignatarios para que seleccione uno.
            -> solo queda referenciado en el asiento contable   
        -> Ese es el auxiliar.
    -> Si !CUENTA_TRABAJA_CON_DESPACHO solo "Cancela factura"

-> Si !CUENTA_CLIENTE Y CUENTA_TRABAJA_CON_DESPACHO 
    -> Se completa el nro de despacho y se trae el cliente
    -> Si no existe el despacho, debemos mostrar mensaje, 
    debemos pedir confirmacion de continuar y le mostramos 
    la lista de consignatarios para que seleccione uno.
        -> solo queda referenciado en el asiento contable
    -> Si CUENTA_TRABAJA_CON_AUXILIAR se selecciona.
    -> Si CUENTA_TRABAJA_CON_DOCUMENTOS se selecciona.

-> Si !CUENTA_CLIENTE Y !CUENTA_TRABAJA_CON_DESPACHO 
    -> Si CUENTA_TRABAJA_CON_AUXILIAR se selecciona.
    -> Si CUENTA_TRABAJA_CON_DOCUMENTOS se selecciona.
    -> Busca los documentos pendientes y selecciona uno.

------
EGRESO
------
-> Si CUENTA_CLIENTE y CUENTA_TRABAJA_CON_DESPACHO
    -> Opcion "Devolucion de saldo"
        -> Puede filtrar por auxiliar/cliente
        -> Buscar despachos con sobre pago (saldo acreedor) -> armar formulario de saldo por despacho/cliente
            -> solo contabiizados
        -> Selecciona despacho
        -> auxiliar es el consignatario.
        -> Si CUENTA_TRABAJA_CON_DOCUMENTOS se selecciona.
        
    -> Opcion "Otros" 
        -> Puede filtrar por auxiliar/cliente
        -> Ingresa nro despacho
        -> Si no existe el despacho, debemos pedir confirmacion de 
        continuar y le mostramos la lista de consignatarios 
        para que seleccione uno.
            -> solo queda referenciado en el asiento contable
        -> auxiliar es el consignatario.
        -> Si CUENTA_TRABAJA_CON_DOCUMENTOS se selecciona.


-> Si CUENTA_DESEMBOLSO (agregar rol nuevo a auxiliar)
    -> Puede filtrar por auxiliar (rol desembolso)
    -> Si CUENTA_TRABAJA_CON_DOCUMENTOS se selecciona.
    -> Si CUENTA_TRABAJA_CON_DESPACHO 
        -> Se completa el nro de despacho y se trae el cliente
        -> Si no existe el despacho, debemos mostrar mensaje, 
        debemos pedir confirmacion de continuar y le mostramos 
        la lista de consignatarios para que seleccione uno.


-> Si CUENTA_DESEMBOLSO_POR_PAGAR
    -> Puede filtrar por auxiliar/desembolso
    -> Busca los documentos pendientes de pago y selecciona uno.
    

-> Caso contrario
    -> Si CUENTA_TRABAJA_CON_AUXILIAR se selecciona.
    -> Si CUENTA_TRABAJA_CON_DOCUMENTOS se selecciona.
    -> Busca los documentos pendientes de pago y selecciona uno.



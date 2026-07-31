# Especificación de API REST (OAS 3.0) - Boleta Electrónica SII Chile

Este documento contiene los endpoints (paths) y servidores (URLs base) correspondientes a la API REST de la Boleta Electrónica expuestos por el Servicio de Impuestos Internos (SII) de Chile según su especificación OpenAPI 3.0.

## 1. Servidores (Environments)

Para consumir la API, se deben utilizar las siguientes URLs base declaradas en la sección `servers` de la especificación:

* **Ambiente de Certificación (Pruebas):** `https://apicert.sii.cl`
* **Ambiente de Producción:** `https://api.sii.cl`

---

## 2. Rutas Exactas (Paths)

### A. Autenticación (Auth)
La autenticación se realiza obteniendo una semilla y luego un token de sesión. Aunque se consumen endpoints REST, el flujo requiere firmar digitalmente un XML con el certificado digital.

* **Obtener Semilla:** * **Método:** `GET`  
  * **Path:** `/recursos/v1/boleta.electronica.semilla`  
  * **Descripción:** Retorna una semilla en formato XML que debe ser firmada digitalmente por el contribuyente. Corresponde al primer paso que se debe realizar para obtener un TOKEN, con lo cual va a poder utilizar los recursos que requieran autorización (marcados con un candado). El valor obtenido tiene un tiempo de duración de 2 minutos
  * **Respuesta**
    ```
    <?xml version="1.0" encoding="UTF-8"?>
    <SII:RESPUESTA xmlns:SII="http://www.sii.cl/XMLSchema">
        <SII:RESP_BODY>
            <SEMILLA>030530912644</SEMILLA>
        </SII:RESP_BODY>
        <SII:RESP_HDR>
            <ESTADO>0</ESTADO>
        </SII:RESP_HDR>
    </SII:RESPUESTA>
    ```

* **Obtener Token (Token de Autenticación):** * **Método:** `POST`  
  * **Path:** `/recursos/v1/boleta.electronica.token`  
  * **Descripción:** Se envía el XML de la semilla firmado en el cuerpo del request. Retorna el token de sesión válido para autorizar las siguientes solicitudes.
  * Armar XML
    ```
    Obtener un token de at autenticación para el envío y consultas automatizadas de boletas electrónicas (en el futuro va cambiar esta forma de autenticación).

    Paso 1:Generar un documento XML, con la siguientes dos líneas:

    Utilizar el valor del campo SEMILLA obtenido en la respuesta del recurso /boleta.electronica.semilla
    Se recomienda usar estas dos líneas ya que es mas fácil incrustar el elemento Signature, y que la firma no falle.
    Notese que el archivo tiene 2 líneas, no tres, ya que si hay tres indica que existe un salto de línea al final.
    línea	xml
    1	<?xml version="1.0" encoding="UTF-8"?>
    2	<getToken><item><Semilla>030530912644</Semilla></item></getToken>
    Paso 2: Firmar Digitalmente el documento anterior

    Esto significa que debe usar su certificado digital, y generar un documento como el que aparece en el ejemplo.
    Mas antecedentes en https://www.w3.org/TR/xmldsig-core
    Los Algoritmos o valores que se deben usar son:
    Tag	Algorithm o Valor
    CanonicalizationMethod	http://www.w3.org/TR/2001/REC-xml-c14n-20010315
    SignatureMethod	http://www.w3.org/2000/09/xmldsig#rsa-sha1
    Transform	http://www.w3.org/2000/09/xmldsig#enveloped-signature
    Reference	URI="" (en el ejemplo aparece con un blanco, pero es sin nada)
    DigestMethod	http://www.w3.org/2000/09/xmldsig#sha1
    KeyValue	RSAKeyValue
    DigestValue	Debe estar codificado en Base64
    Paso 3: Verificación de la firma

    En la etapa de desarrollo es conveniente asegurar que durante el proceso de firma no haber alterado el documento original. Esto sucede porque al generar el documento se hace un formateo del XML (pretty printing).
    Se supone que si se elimina el elemento Signature el documento debe quedar tal como estaba antes de firmar, incluyendo espacios, saltos de linea, y eso se logra mas facilmente si usted lo hace con las dos líneas, tal como se explicó en el paso anterior.
    Un software que ayuda a realizar esta tarea es https://tools.chilkat.io/hashText.cshtml (en linea), el cual permite hacer el calculo de SHA1, codificandolo en formato Base64.
    Paso	Línea
    Ingrese en chilkat sólo una línea (con su semilla) en Hash Text	<getToken><item><Semilla>030530912644</Semilla></item></getToken>
    verifique que la respuesta sea:	l2s9BqLppHaWo+w1Al1J5SsYScs=
    busque en documento firmado:	<DigestValue>l2s9BqLppHaWo+w1Al1J5SsYScs=</DigestValue>
    Verifique la firma en linea en Chilkat Online Tools

    Notese que si usted altera la semilla, el sitio arroja el siguiente error:

    Reference 1 digest is invalid because the computed digest differs from the digest in the XML.
    Paso 4: Enviar el documento firmado al SII utilizando asignado ese valor al BODY de esta petición

    A continuación se muestra como debería ir el documento firmado:
    línea	xml	Observación
    1	<?xml version="1.0" encoding="UTF-8"?>	
    2	<getToken><item><Semilla>030530912644</Semilla></item><Signature xmlns="http://www.w3.org/2000/09/xmldsig#">	Signature comienza inmediatamente despues de finalización de item`, en la misma línea
    3 ..	...	
    ultima	</Signature></getToken>	Signature finaliza en la misma línea que getToken. Además no debería venir un salto de línea, si siguió las indicaciones dadas en el paso 1
    Paso 5: Utilizar Token recibido como respuesta a este recurso

    Utilizar el valor de este token en los recursos que requieran autorización ( aparecen marcados con un simbolo de Candado) para lo cual lo deben agregar al Header llamado Cookie con la el valor del TOKEN={token}, ejemplo: P7VQKYLDNHJGP
    Cookie:TOKEN=P7VQKYLDNHJGP

    Actualmente el largo de este token es 13, pero podría variar en el futuro, a un largo de 500
    En el futuro podría cambiar el header y que no fuese Cookie
    ```
    * **Respuesta**
    ```
    <?xml version="1.0" encoding="UTF-8"?>
    <SII:RESPUESTA xmlns:SII="http://www.sii.cl/XMLSchema">
        <SII:RESP_HDR>
            <ESTADO>00</ESTADO>
            <GLOSA>Token Creado</GLOSA>
        </SII:RESP_HDR>
        <SII:RESP_BODY>
            <TOKEN>XAuSbYXiNh9Ik</TOKEN>
        </SII:RESP_BODY>
    </SII:RESPUESTA>
    ```

### B. Envío de Documentos (Submit)
Permite subir los archivos de boletas agrupadas (un conjunto de hasta 500 boletas por envío).

* **Envío de Boletas:** * **Método:** `POST`  
  * **Path:** `/recursos/v1/boleta.electronica.envio`  
  * **Encabezados requeridos:** `Content-Type: multipart/form-data`. El token de autenticación se adjunta típicamente en la cabecera (ej. `Cookie: TOKEN={token}`).  
  * **Descripción:** Recibe el archivo de envío firmado y retorna un `trackId` (número de seguimiento de 15 dígitos) para validar el estado posterior del procesamiento.
  * Armar XML
    ```
    Sugerencias para realizar el envío de Boletas Electrónicas a SII (Fecha Actualización: 05 de mayo de 2021)

    Para realizar el envío de boletas electrónicas y permitir aprovechar de manera eficiente la infraestructura disponible para todos los contribuyentes, se entregan las siguientes sugerencias o recomendaciones.

    Uso eficiente del token. Se sugiere obtener el token para que sea utilizado para todos los envíos que sean necesarios y evitar solicitar token por cada envío. El tiempo de actividad para que el token sea considerado como válido es de 1 hora, tiempo que se renueva automáticamente cada vez que se usa.
    Envío agrupado de Boletas. La sugerencia va por aprovechar el formato del esquema que permite agrupar más de una boleta por envío según la documentación vigente. Para efectos de envíos masivos de alto volúmenes es lo más recomendable. El número recomendado es de 50 boletas por envío
    Consulta de Envíos y Boletas. Una vez realizado el envío es recomendado considerar un tiempo de 10 minutos de espera para realizar consulta de las boletas o envíos.
    Formato de Request. Conformar de manera correcta la estructura según lo que se indica en la documentación de la API. No considerar espacios o caracteres especiales en la URL.
    Considerar el uso de un pool de direcciones IP para realizar envíos de información al SII, de manera de no sobrepasar los límites que impliquen activar protocolos de seguridad propios de la plataforma de SII con respecto la cantidad de envíos por IP y unidad de tiempo.
    Revisar en detalle la documentación para realizar los envíos de BE. Los sitios rahue.sii.cl y api.sii.cl, son plataformas dedicadas a la recepción de Boleta Electrónica en Producción. El sitio de palena.sii.cl es la plataforma dedicada para la recepción de DTE y RVD en Producción.
    Paso 1: Generar el conjunto de boletas y firmarlas.

    Ver la siguiente documentación, para poder generar las boletas en formato XML, las cuales deben estar firmadas digitalmente:

    Schema XML de la Boleta
    Diagrama de Schema XML de la Boleta
    Descripción del formato de la Boleta (PDF)
    Para librerias de XML
    Paso 2: Ingresar los parametros que exige este recurso

    Vea mas abajo, y aparecen los parametros
    Paso 3: Enviarlas por este recurso, utilizando el BODY

    Como este recurso requiere autorización se debe ontener un TOKEN y agregar al Header llamado Cookie con la el valor del TOKEN={token}, ejemplo: P7VQKYLDNHJGP\n > Cookie:TOKEN=P7VQKYLDNHJGP \n
    Paso 4: De acuerdo al codigo de respuesta programar sus acciones

    Las respuestas HTTP posibles son:
    200 - El Cual Indica exito
    400 - Indica que tiene un error en los datos enviados. Vea el texto del error
    401 - Tiene error en la auterización, es muy posible que le haya faltado el valor del TOKEN en la Cookie
    ```
    * Respuesta
    ```
    {
        "rut_emisor": "45000054-K",
        "rut_envia": "83154595-0",
        "trackid": 1014,
        "fecha_recepcion": "2020-09-01 20:30:10",
        "estado": "REC",
        "file": "boleta-2020-09-01-001.xml"
    }
    ```

### C. Consultas (Query)
Endpoints diseñados para verificar tanto el estado del lote completo como de un documento de forma unitaria.

* **Consulta de Estado del Envío (Track ID):** * **Método:** `GET`  
  * **Path:** `/recursos/v1/boleta.electronica.envio/{rutEmpresa}-{dvEmpresa}-{trackId}`  
  * **Descripción:** Permite revisar si el lote con el `trackId` provisto ya fue procesado, aceptado o si contiene errores de estructura/esquema.
  * Respuesta:
  ``` 
    {
    "rut_emisor": "45000054-K",
    "rut_envia": "8315495-0",
    "trackid": 1014,
    "fecha_recepcion": "30/07/2020 07:57:42",
    "estado": "EPR",
    "estadistica": [
        {
        "tipo": 39,
        "informados": 3,
        "aceptados": 2,
        "rechazados": 1,
        "reparos": 0
        },
        {
        "tipo": 41,
        "informados": 1,
        "aceptados": 0,
        "rechazados": 0,
        "reparos": 1
        }
    ],
    "detalle_rep_rech": [
        {
        "tipo": 39,
        "folio": 1202,
        "estado": "RCH",
        "descripcion": "Dte Rechazado",
        "error": [
            {
            "seccion": "CRT",
            "linea": 155,
            "nivel": 3,
            "codigo": 11,
            "descripcion": "RUT envia diferente al Upload",
            "detalle": "[155]LSX-00291 value 0.52 is not declared"
            },
            {
            "seccion": "HED",
            "linea": 222,
            "nivel": 3,
            "codigo": 100,
            "descripcion": "Valor Detalle Distinto a Precio * Cantidad",
            "detalle": "[83154495-0] <> [9145888-K]"
            }
        ]
        },
        {
        "folio": 3500,
        "estado": "RPR",
        "descripcion": "Dte Aceptado con reparos",
        "error": [
            {
            "seccion": "DET",
            "linea": 2,
            "nivel": 1,
            "codigo": 200,
            "descripcion": "Valor Detalle Distinto a Precio * Cantidad",
            "detalle": "[2500 <> 3500]"
            }
        ]
        }
    ]
    }
  ```

* **Consulta de Estado de una Boleta Unitaria:** * **Método:** `GET`  
  * **Path:** `/recursos/v1/boleta.electronica/{rutEmpresa}-{dvEmpresa}-{tipoDocumento}-{folio}/estado`  
  * **Descripción:** Permite consultar el estado de validación comercial y tributaria de un folio específico (ej. tipo de documento 39 para Boleta Electrónica Afecta o 41 para Exenta).  
  * Respuesta:
  ``` 
    {
        "codigo": "DNK",
        "descripcion": "Documento Recibido por el SII pero Datos NO Coinciden con los registrados"
    }
  ```

---

## 3. Ejemplos de URLs Completas

* **Envío en Producción:** `https://api.sii.cl/recursos/v1/boleta.electronica.envio`
  
* **Consulta de Track en Certificación:** `https://apicert.sii.cl/recursos/v1/boleta.electronica.envio/76000000-0-123456789012345`

### 4 Documentacion
Schema XML de la Boleta: ./qdoora-references/manuales/sii/boleta/schema_envio_bol_720/
Diagrama de Schema XML de la Boleta: ./qdoora-references/manuales/sii/boleta/diag_boleta_720/
Descripción del formato de la Boleta (PDF): ./qdoora-references/manuales/sii/boleta/boletas_elec_020.pdf

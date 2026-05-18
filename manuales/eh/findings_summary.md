# 🛡️ Catálogo de Hallazgos Extracted from Pentest Reports

## 📄 Report: Gemini_Informe de Ethical Hacking_Agunsa_Portal_Gemini_07042026_7273F6C7CD90B70FF7D326B20FF9E931.txt
### 🔍 Hallazgo 1: C01: Escalamiento de privilegios vía manipulación de respuesta de login
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado que la aplicación devuelve en la respuesta del endpoint de autenticación toda la información de autorización del usuario (por ejemplo parámetro admGlobal y el objeto completo de privilegios). El frontend confía ciegamente en estos datos para determinar los permisos del usuario actual, sin que el backend realice validaciones adicionales de autorización en las peticiones posteriores (usando el token devuelto). En ese sentido un atacante con una cuenta de usuario normal puede interceptar y modificar la respuesta de login (usando Burp Suite Match & Replace o cualquier proxy MITM) para elevar sus privilegios a nivel de administrador (admGlobal: true + todos los privilegios de GEMINI). Esto demuestra que la lógica de control de acceso está parcialmente implementada en el cliente en lugar de estar enforced server-side. CWE Estado A01:2025 – Broken Access Control Crítico (9.0) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N URLs: POST https://qa-gemini.agunsa.com /api/v1/login Parámetro Afectado: En la respuesta, las propiedades siguientes: • "privilegios"

---

### 🔍 Hallazgo 2: a bucket S3 con información sensible
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado que la aplicación se puede invocar a un endpoint de parámetros de configuración (/api/parametros) devuelve en texto plano, sin protección adicional, las credenciales completas de AWS IAM. Con estas credenciales es posible acceso directo al bucket S3 develop-agunsa (región us-east-1) y se confirmó que utilizando estas credenciales se logró acceso con permisos de lectura y escritura al bucket develop-agunsa (región us-east1). bucket contiene información operativa real del cliente (reportes de cumplimiento PACO/RSO, actas de reuniones, capturas de pantalla, logs, entre otros.). CWE Estado A05:2021 – Security Misconfiguration Crítico (9.1) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:H/SI:H/SA:N URLs: GET /api/v1/parametros • Exposición de datos operativos, reportes de cumplimiento y documentos internos. Impacto • Posibilidad de modificar o sustituir archivos críticos (reportes, actas, etc.). • Posible eliminación masiva de archivos o llenado del bucket.

---

### 🔍 Hallazgo 3: C03: Apropiación de cuenta completa (ATO) en cualquier cuenta mediante
**Severidad / Criticidad:** No especificada
**Descripción:**
Descripción: Se ha identificado una cadena de vulnerabilidades que, combinadas, permiten a un atacante apoderarse completamente de cualquier cuenta del sistema. El ataque se puede ejecutar por dos vías independientes: Opción A — Fuerza Bruta sobre endpoint de autenticación • • • • • La API GET /api/v1/usuarios, accesible con un token de usuario administrador, se devuelve el listado completo de usuarios registrados incluyendo login, nombre, email y rol de administrador. Con el listado de usuarios obtenido, se realizó un ataque de fuerza bruta sobre el endpoint POST /api/v1/login utilizando contraseñas comunes. El sistema no implementa bloqueo efectivo ni CAPTCHA, permitiendo iterar sobre todos los usuarios. Se obtuvo acceso exitoso con el usuario 'avenegas'. Una vez autenticado, el atacante puede operar dentro del sistema con todos los privilegios del usuario comprometido. Esta opción es apropiación de cuenta parcial, debido a que el usuario podría recuperar su contraseña y el atacante podría pedir perder el acceso. Opción B — Modificación de email + secuestro vía recuperación de contraseña (ATO Completo) •

---

### 🔍 Hallazgo 4: A01: Falta de control de autorización en ejecución de funciones privilegiadas
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado una vulnerabilidad que permite a usuarios no autorizados ejecutar funciones solo disponibles para usuarios de autorizados; dicha vulnerabilidad se conoce como Broken Function Level Authorization (BFLA) el cual ocurre cuando la API no verifica correctamente los permisos (autorización) antes de permitir que un usuario ejecute una función o acción específica. En este caso, el sistema GEMINI permite que un usuario con privilegios mínimos (en este caso, el usuario insideusr) ejecute funciones administrativas de gestión de configuraciones que no están disponibles ni visibles en su interfaz gráfica (Consola). Al capturar y replicar peticiones administrativas y sustituir el token de seguridad por el del usuario sin privilegios, el servidor procesa las solicitudes (inclusive de actualización de datos) y el backend no valida el rol o los permisos específicos del solicitante antes de aplicar los cambios en la base de datos. CWE Estado A01:2025 – Broken Access Control Alto (8.8) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N URLs: https://qa-gemini.agunsa.com/api/v1/tipo-servicios https://qa-gemini.agunsa.com /api/v1/familia-servicios https://qa-gemini.agunsa.com /api/v1/arbol-servicios

---

### 🔍 Hallazgo 5: acceso a información de manera masiva
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado una vulnerabilidad de Referencia Directa Insegura a Objetos (IDOR), también conocida como BOLA, en el endpoint de descarga de archivos de la plataforma. El sistema no valida si el usuario autenticado tiene permisos de propiedad o de acceso sobre el recurso identificado por el parámetro {id} en la URL. Un usuario legítimo, con permisos para visualizar únicamente sus propios reportes (ej. IDs 130 y 136), puede manipular el identificador numérico de forma secuencial para obtener enlaces de descarga de Amazon S3 (bucket-sistemas-cpo) pertenecientes a otros usuarios o procesos de la compañía. Las pruebas confirmaron el acceso exitoso a un rango extendido de documentos (IDs 63 al 139) que contienen información operativa y planillas de carga. CWE Estado Impacto A01:2025 – Broken Access Control Alto (7.7) VULNERABLE CVSS:4.0 /AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N URLs: GET /api/v1/file/{id} HTTP/2 Parámetro Afectado: {id} •

---

### 🔍 Hallazgo 6: sistema central de seguridad
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se identificó una vulnerabilidad de control de acceso desde el sistema GEMINI mediante el cual se puede consumir los servicios de administración de usuarios, roles, sistemas y parámetros del sistema los cuales son tratados desde el sistema de seguridad PERFILES, se han ubicado APIS expuestos y operativos bajo el contexto de autenticación de GEMINI, permitiendo a un usuario administrador autenticado ejecutar operaciones CRUD completas sobre los objetos de seguridad del ecosistema sin que PERFILES valide ni restrinja dichas acciones. CWE Estado A01 - Broken Access Control Alta (8.7) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:H/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H URLs: GET

---

### 🔍 Hallazgo 7: M01: Inyección HTML en la generación de PDFs
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se identificó una vulnerabilidad de HTML Injection en el endpoint POST /api/v1/generarPdf del sistema GEMINI. El parámetro htmlCode acepta contenido HTML arbitrario sin sanitización, que es procesado directamente por el motor de renderizado PDF del servidor. Al no aplicar ningún tipo de sanitización, validación de esquema ni lista blanca de etiquetas permitidas, un atacante puede sustituir el htmlCode legítimo por HTML arbitrario que el motor renderizará fielmente, produciendo un PDF oficial con contenido completamente controlado por el atacante. CWE Estado A03:2021 — Injection Media (6.1) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N URLs: /api/v1/generarPdf Parámetro Afectado: htmlCode • Generación de PDFs con apariencia oficial del Aeropuerto Desierto de Atacama-Caldera que contengan información falsa Impacto

---

### 🔍 Hallazgo 8: B01: Mal manejo de errores permite ubicar rutas internas
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado una vulnerabilidad que da cuenta que el framework basado en Node.js con Express no implementa un manejador de errores personalizado para producción. Cuando se envía un cuerpo JSON malformado a cualquiera de los endpoints de la API, el servidor responde con HTTP 400 Bad Request incluyendo en el body el stack trace completo del error interno de Node.js, exponiendo información detallada sobre la arquitectura interna de la aplicación. Un usuario puede acceder en el stack trace a conocer Framework y runtime, Módulos internos con versiones y rutas, Arquitectura interna de la aplicación y cabecera de tecnología expuesta. CWE Estado Impacto Recomendaciones A10:2025 - Mishandling of Exceptional Conditions Bajo (4.3) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N URLs: POST /api/v1/tipo-servicios POST /api/v1/setFiltroSemaforo POST /api/v1/planilla

---

## 📄 Report: Inspecciones_Informe de Ethical Hacking_Agunsa_inspecciones_28042026_4957E7F2D530302452CD3F16F8E4A368.txt
### 🔍 Hallazgo 1: a bucket S3 con información sensible
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado que la aplicación se puede invocar a un endpoint de parámetros de configuración (/api/parametros) devuelve en texto plano, sin cifrado y sin protección adicional un conjunto de credenciales altamente sensibles almacenadas en la tabla de parámetros de configuración del sistema. Entre los secretos expuestos se identificaron: credenciales SMTP de Gmail con capacidad de envío masivo de correo, claves de acceso AWS IAM con permisos de lectura y escritura sobre el bucket S3 develop-agunsa (región us-east-1), credenciales de conexión a ActiveMQ (broker de mensajería), y API keys de UptimeRobot. Todos estos secretos fueron verificados como funcionales durante el pentest autorizado. Con estas credenciales es posible acceso directo al smtp para envio de correo, al bucket S3 develop-agunsa (región us-east-1) y se confirmó que utilizando estas credenciales se logró acceso con permisos de lectura y escritura al bucket develop-agunsa (región us-east-1). CWE Estado A01:2025 Broken Access Control Crítico (9.1) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H URLs: GET /api/v1/parametros • • Impacto

---

### 🔍 Hallazgo 2: C02: Apropiación de cuenta completa (ATO) en cualquier cuenta mediante
**Severidad / Criticidad:** No especificada
**Descripción:**
Descripción: Se ha identificado una cadena de vulnerabilidades que, combinadas, permiten a un atacante apoderarse completamente de cualquier cuenta del sistema. El ataque se puede ejecutar por dos vías independientes: Opción A — Fuerza Bruta sobre endpoint de autenticación • • • • • La API GET /api/v1/usuarios, accesible con un token de usuario administrador, se devuelve el listado completo de usuarios registrados incluyendo login, nombre, email y rol de administrador. Con el listado de usuarios obtenido, se realizó un ataque de fuerza bruta sobre el endpoint POST /api/v1/login utilizando contraseñas comunes. El sistema no implementa bloqueo efectivo ni CAPTCHA, permitiendo iterar sobre todos los usuarios. Se obtuvo acceso exitoso con el usuario 'avenegas'. Una vez autenticado, el atacante puede operar dentro del sistema con todos los privilegios del usuario comprometido. Esta opción es apropiación de cuenta parcial, debido a que el usuario podría recuperar su contraseña y el atacante podría pedir perder el acceso. Opción B — Modificación de email + secuestro vía recuperación de contraseña (ATO Completo) • •

---

### 🔍 Hallazgo 3: A01: Falta de control de autorización en ejecución de funciones privilegiadas
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado una vulnerabilidad que permite a usuarios no autorizados ejecutar funciones solo disponibles para usuarios de autorizados; dicha vulnerabilidad se conoce como Broken Function Level Authorization (BFLA) el cual ocurre cuando la API no verifica correctamente los permisos (autorización) antes de permitir que un usuario ejecute una función o acción específica. El servidor no valida si el perfil asociado al token JWT (Authorization: Bearer) tiene el permiso necesario para acceder a los recursos de los módulos de componentes e indicadores. Basta con conocer la ruta del endpoint para extraer información técnica, configuraciones de muestreo y detalles de ejecución de tareas de limpieza, desinfección y mantenimiento. Esto permite que cualquier usuario autenticado pueda marcar tareas como "ejecutadas" o crear nuevos pasos en un workflow, saltándose los controles jerárquicos y de supervisión. He de aclarar que en estas pruebas el usuario Insideusr es el que tiene más privilegios comparados con el usuario Insideadm. CWE Estado A01:2025 – Broken Access Control Alto (8.6) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:L/SC:H/SI:H/SA:L URLs: https://qainspecciones.agunsa.com/api/v1/componente/{codigoServicio}/{codi go} https://qainspecciones.agunsa.com/api/v1/indicador/{codigoServicio}/{codigo}

---

### 🔍 Hallazgo 4: B01: Mal manejo de errores permite ubicar rutas internas
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado una vulnerabilidad que da cuenta que el framework basado en Node.js con Express no implementa un manejador de errores personalizado para producción. Cuando se envía un cuerpo JSON malformado a cualquiera de los endpoints de la API, el servidor responde con HTTP 400 Bad Request incluyendo en el body el stack trace completo del error interno de Node.js, exponiendo información detallada sobre la arquitectura interna de la aplicación. Un usuario puede acceder en el stack trace a conocer Framework y runtime, Módulos internos con versiones y rutas, Arquitectura interna de la aplicación y cabecera de tecnología expuesta. CWE Estado A10:2025 - Mishandling of Exceptional Conditions Information Bajo (2.3) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N URLs: Todas las URLs que emplean GEt, PUT, DELETE, POST Parámetro Afectado: {JSON MALFORMADO} • Reconocimiento de infraestructura facilitado: el stack trace revela el framework, versiones de módulos, rutas internas y arquitectura de la aplicación, información que un atacante utiliza para identificar versiones vulnerables de dependencias y

---

## 📄 Report: Perfiles_Informe de Ethical Hacking_Agunsa_Perfiles_16042026_9B876D8541197DE53573CC1231507241.txt
### 🔍 Hallazgo 1: secretos Críticos Comprometidos (SMTP, AWS IAM, ActiveMQ)
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado que la aplicación se puede invocar a un endpoint de parámetros de configuración (/api/parametros) devuelve en texto plano, sin cifrado y sin protección adicional un conjunto de credenciales altamente sensibles almacenadas en la tabla de parámetros de configuración del sistema. Entre los secretos expuestos se identificaron: credenciales SMTP de Gmail con capacidad de envío masivo de correo, claves de acceso AWS IAM con permisos de lectura y escritura sobre el bucket S3 develop-agunsa (región us-east-1), credenciales de conexión a ActiveMQ (broker de mensajería), y API keys de UptimeRobot. Todos estos secretos fueron verificados como funcionales durante el pentest autorizado. Con estas credenciales es posible acceso directo al smtp para envio de correo, al bucket S3 develop-agunsa (región us-east-1) y se confirmó que utilizando estas credenciales se logró acceso con permisos de lectura y escritura al bucket develop-agunsa (región us-east-1). CWE Estado A01:2025 Broken Access Control Crítico (9.4) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H URLs: GET /api/v1/parametros • Envío masivo de correo fraudulento desde la identidad corporativa de Agunsa Copiapó (credenciales SMTP Gmail confirmadas como funcionales).

---

### 🔍 Hallazgo 2: C02: Apropiación de cuenta completa (ATO) en cualquier cuenta mediante cadena de
**Severidad / Criticidad:** No especificada
**Descripción:**
Descripción: Se ha identificado una cadena de vulnerabilidades que, combinadas, permiten a un atacante apoderarse completamente de cualquier cuenta del sistema. El ataque se puede ejecutar por dos vías independientes: Opción A — Fuerza Bruta sobre endpoint de autenticación • • • • • La API GET /api/v1/usuarios, accesible con un token de usuario administrador, se devuelve el listado completo de usuarios registrados incluyendo login, nombre, email y rol de administrador. Con el listado de usuarios obtenido, se realizó un ataque de fuerza bruta sobre el endpoint POST /api/v1/login utilizando contraseñas comunes. El sistema no implementa bloqueo efectivo ni CAPTCHA, permitiendo iterar sobre todos los usuarios. Se obtuvo acceso exitoso con el usuario 'avenegas'. Una vez autenticado, el atacante puede operar dentro del sistema con todos los privilegios del usuario comprometido. Esta opción es apropiación de cuenta parcial, debido a que el usuario podría recuperar su contraseña y el atacante podría pedir perder el acceso. Opción B — Modificación de email + secuestro vía recuperación de contraseña (ATO Completo) •

---

### 🔍 Hallazgo 3: A01: Stored XSS (Cross-Site Scripting Almacenado) al ingresar o actualizar datos
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado una vulnerabilidad de tipo Stored XSS (Cross-Site Scripting Almacenado) en diversos enpoints, en los cuales el backend almacena el valor sin sanitizar en base de datos y lo devuelve tal cual en las respuestas posteriores. Cuando el frontend renderiza el listado de sistemas o el panel de edición, el payload HTML/JavaScript inyectado se ejecuta automáticamente en el navegador de cualquier usuario que acceda a la sección donde existe una grilla, sin requerir interacción adicional. CWE Estado A05:2025 – Injection (Stored XSS) Alto (8.4) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:P/VC:H/VI:L/VA:N/SC:H/SI:H/SA:N Configurar Sistemas POST /api/v1/sistemas (almacenamiento del payload) GET /configurar-sistemas (ejecución del payload) Administrar Usuarios POST /api/v1/usuarios (almacenamiento del payload) GET /api/v1/usuarios (ejecución del payload) Sistemas Clientes de API-Keys POST /api/v1/clientes-api (almacenamiento del payload)

---

### 🔍 Hallazgo 4: A02: Ausencia de Rate Limiting en Operaciones CRUD
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado que los endpoints de administración de seguridad de la aplicación no implementan ningún mecanismo de control de frecuencia (rate limiting) sobre las operaciones de creación, modificación y eliminación. Un atacante autenticado con un Bearer token válido puede ejecutar operaciones CRUD masivas de forma automatizada —utilizando herramientas como Burp Suite Intruder— sin que el servidor detecte, limite ni bloquee el comportamiento anómalo. Los módulos afectados son los pilares de la seguridad de toda la plataforma: Sistemas, Roles de Usuarios, Usuarios y Clientes de API Keys. Se confirmó la ejecución exitosa de 13 operaciones DELETE consecutivas sobre el módulo de Sistemas, todas respondidas con HTTP 200 OK sin ningún mecanismo de detección o bloqueo. CWE Estado Endpoints afectados A06:2025 – Insecure Design Alto (8.5) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:N/VI:H/VA:H/SC:H/SI:H/SA:N Sistemas: POST|PUT|DELETE /api/v1/sistemas/{id} Roles : POST|PUT|DELETE /api/v1/roles/{id} Usuarios : POST|PUT|DELETE /api/v1/usuarios/{id} API Keys : POST|PUT|DELETE /api/v1/clientes-api/{id} • Eliminación masiva de sistemas registrados: un atacante puede eliminar automáticamente todos los sistemas integrados (GEMINI,

---

### 🔍 Hallazgo 5: sesión
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado que la aplicación devuelve en la respuesta del endpoint de autenticación toda la información de autorización del usuario asociado a su rol en el parámetro admGlobal. El frontend confía ciegamente en estos datos para determinar los permisos del usuario actual, sin que el backend realice validaciones adicionales de autorización en las peticiones posteriores (usando el token devuelto). En ese sentido un atacante con una cuenta de usuario normal puede interceptar y modificar la respuesta de login (usando Burp Suite Match & Replace o cualquier proxy MITM) para forzar la entrada al sistema como (admGlobal: true + todos los privilegios de PERFILES) que si bien le da acceso por la seguridad en el backend del endpoint no le permite ejecutar operaciones sino solamente navegar entre las diferentes opciones. Esto demuestra que la lógica de control de acceso está parcialmente implementada en el cliente en lugar de estar enforced server-side. CWE Estado A01:2025 – Broken Access Control Baja (2.0) VULNERABLE CVSS:4.0/AV:N/AC:H/AT:N/PR:L/UI:N/VC:N/VI:L/VA:N/SC:N/SI:N/SA:N POST https://qa-perfiles.agunsa.com/api/v1/login • Un usuario sin privilegios de administrador puede acceder al panel de configuración y navegar por todas las secciones de administración del sistema (Configurar Sistemas, Administrar Usuarios, Sistemas Clientes

---

### 🔍 Hallazgo 6: B02: Mal manejo de errores permite ubicar rutas internas
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado una vulnerabilidad que da cuenta que el framework basado en Node.js con Express no implementa un manejador de errores personalizado para producción. Cuando se envía un cuerpo JSON malformado a cualquiera de los endpoints de la API, el servidor responde con HTTP 400 Bad Request incluyendo en el body el stack trace completo del error interno de Node.js, exponiendo información detallada sobre la arquitectura interna de la aplicación. Un usuario puede acceder en el stack trace a conocer Framework y runtime, Módulos internos con versiones y rutas, Arquitectura interna de la aplicación y cabecera de tecnología expuesta. CWE Estado Impacto A10:2025 - Mishandling of Exceptional Conditions Bajo (2.3) VULNERABLE CVSS:4.0/AV:A/AC:H/AT:N/PR:N/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N URLs: Todas las URLs que emplean GEt, PUT, DELETE, POST Parámetro Afectado: {JSON MALFORMADO} • Reconocimiento de infraestructura facilitado: el stack trace revela el framework, versiones de módulos, rutas internas y arquitectura de la

---

## 📄 Report: RMS_Informe de Ethical Hacking_Agunsa_CajaGris_RMS_05052026_8C9562D339F232B3CACB29D2AEE3B375.txt
### 🔍 Hallazgo 1: secretos Críticos Comprometidos (SMTP, AWS IAM)
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado que la aplicación se puede invocar a un endpoint de parámetros de configuración (/api/parametros) devuelve en texto plano, sin cifrado y sin protección adicional un conjunto de credenciales altamente sensibles almacenadas en la tabla de parámetros de configuración del sistema. Entre los secretos expuestos se identificaron: credenciales SMTP de Gmail con capacidad de envío masivo de correo, claves de acceso AWS IAM con permisos de lectura y escritura sobre el bucket S3 develop-agunsa (región us-east-1), credenciales de conexión a ActiveMQ (broker de mensajería), y API keys de UptimeRobot. Todos estos secretos fueron verificados como funcionales durante el pentest autorizado. Con estas credenciales es posible acceso directo al smtp para envio de correo, al bucket S3 develop-agunsa (región us-east-1) y se confirmó que utilizando estas credenciales se logró acceso con permisos de lectura y escritura al bucket develop-agunsa (región us-east-1). CWE Estado A01 - Broken Access Control Crítico (9.4) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H URLs: GET https://qa-rms.agunsa.com/api/v1/parametros • Envío masivo de correo fraudulento desde la identidad corporativa de Agunsa Copiapó (credenciales SMTP Gmail confirmadas como funcionales).

---

### 🔍 Hallazgo 2: C02: Apropiación de cuenta completa (ATO) en cualquier cuenta mediante
**Severidad / Criticidad:** No especificada
**Descripción:**
Descripción: Se ha identificado una cadena de vulnerabilidades que, combinadas, permiten a un atacante apoderarse completamente de cualquier cuenta del sistema. El ataque se puede ejecutar por dos vías independientes: Opción A — Fuerza Bruta sobre endpoint de autenticación • • • • • La API GET /api/v1/usuarios, accesible con un token de usuario administrador, se devuelve el listado completo de usuarios registrados incluyendo login, nombre, email y rol de administrador. Con el listado de usuarios obtenido, se realizó un ataque de fuerza bruta sobre el endpoint POST /api/v1/login utilizando contraseñas comunes. El sistema no implementa bloqueo efectivo ni CAPTCHA, permitiendo iterar sobre todos los usuarios. Se obtuvo acceso exitoso con el usuario 'avenegas'. Una vez autenticado, el atacante puede operar dentro del sistema con todos los privilegios del usuario comprometido. Esta opción es apropiación de cuenta parcial, debido a que el usuario podría recuperar su contraseña y el atacante podría pedir perder el acceso. Opción B — Modificación de email + secuestro vía recuperación de contraseña (ATO Completo) • •

---

### 🔍 Hallazgo 3: A01: Stored XSS (Cross-Site Scripting Almacenado) al ingresar o actualizar datos
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción:Se ha identificado una vulnerabilidad de tipo Stored XSS (Cross-Site Scripting Almacenado) en diversos enpoints, en los cuales el backend almacena el valor sin sanitizar en base de datos y lo devuelve tal cual en las respuestas posteriores. Cuando el frontend renderiza el listado de sistemas o el panel de edición, el payload HTML/JavaScript inyectado se ejecuta automáticamente en el navegador de cualquier usuario que acceda a la sección donde existe una grilla, sin requerir interacción adicional. CWE Estado A05:2025 – Injection (Stored XSS) Alto (8.4) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:P/VC:H/VI:L/VA:N/SC:H/SI:H/SA:N Notificaciones PUT /api/v1/cambia-estado-notificacion POST | PUT /api/v1/atributos-dinamicos POST | PUT /api/v1/recursos POST | PUT /api/v1/regla-simple o POST | PUT /api/v1/regla-avanzada POST | PUT /api/v1/familia-pareo • Ejecución de JavaScript arbitrario en el navegador de cualquier usuario (administrador u operador) que acceda a la sección “Notificaciones”, sin requerir ninguna interacción adicional. El payload se ejecuta

---

### 🔍 Hallazgo 4: A02: Ausencia de Rate Limiting en Operaciones CRUD
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción:Se ha identificado que los endpoints de configuración de la aplicación no implementan ningún mecanismo de control de frecuencia (rate limiting) sobre las operaciones de creación, modificación y eliminación. Un atacante autenticado con un Bearer token válido puede ejecutar operaciones CRUD masivas de forma automatizada —utilizando herramientas como Burp Suite Intruder— sin que el servidor detecte, limite ni bloquee el comportamiento anómalo. Los módulos afectados son los pilares de la seguridad de toda la plataforma: Atributos Dinámicos, Recursos, Reglas Asignación y Familias Pareo. Se confirmó la ejecución exitosa de operaciones CRUD consecutivas sobre el módulo de Sistemas, todas respondidas con HTTP 200 OK sin ningún mecanismo de detección o bloqueo. CWE Estado Endpoints afectados A06:2025 – Insecure Design Alto (8.5) VULNERABLE CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:N/VI:H/VA:H/SC:H/SI:H/SA:N Atributos Dinámicos: POST|PUT|DELETE /api/v1/atributos-dinamicos Recursos: POST|PUT|DELETE /api/v1/recursos Reglas Asignación: POST|PUT|DELETE /api/v1/regla-simple o Reglas Asignación: POST|PUT|DELETE /api/v1/regla-avanzada Familia Pareo: POST|PUT|DELETE /api/v1/familia-pareo • Eliminación masiva de sistemas registrados: un atacante puede eliminar automáticamente todos los sistemas integrados (GEMINI,

---

### 🔍 Hallazgo 5: B01: Mal manejo de errores permite ubicar rutas internas
**Severidad / Criticidad:** Nivel de criticidad Estado
**Descripción:**
Descripción: Se ha identificado una vulnerabilidad que da cuenta que el framework basado en Node.js con Express no implementa un manejador de errores personalizado para producción. Cuando se envía un cuerpo JSON malformado a cualquiera de los endpoints de la API, el servidor responde con HTTP 400 Bad Request incluyendo en el body el stack trace completo del error interno de Node.js, exponiendo información detallada sobre la arquitectura interna de la aplicación. Un usuario puede acceder en el stack trace a conocer Framework y runtime, Módulos internos con versiones y rutas, Arquitectura interna de la aplicación y cabecera de tecnología expuesta CWE Estado Impacto A10:2025 - Mishandling of Exceptional Conditions Bajo (2.3) VULNERABLE CVSS:4.0/AV:A/AC:H/AT:N/PR:N/UI:N/VC:L/VI:N/VA:N/SC:N/SI:N/SA:N URLs: Todas las URLs que emplean GEt, PUT, DELETE, POST que incluyen parámetros JSON Parámetro Afectado: {JSON MALFORMADO} • Reconocimiento de infraestructura facilitado: el stack trace revela el framework, versiones de módulos, rutas internas y arquitectura de la

---

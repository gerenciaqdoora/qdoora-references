# Controles del Anexo A (ISO/IEC 27001:2022 = ISO/IEC 27002:2022)

**93 controles en 4 temas:** 5 Organizacionales (37) · 6 Personas (8) · 7 Físicos (14) ·
8 Tecnológicos (34). Títulos traducidos/parafraseados; la guía de implementación detallada está
en ISO/IEC 27002:2022. **★ = control nuevo en 2022** (11 en total).

Ningún control es obligatorio por sí mismo: se incluye si el tratamiento de riesgos, un requisito
legal/contractual o una parte interesada lo exige. Todos deben aparecer en la SoA.

## Atributos (ISO/IEC 27002:2022, Anexo A)

Útiles para filtrar, mapear con otros marcos (NIST CSF, CIS) y armar vistas:

| Atributo | Valores |
|----------|---------|
| Tipo de control | Preventivo · Detectivo · Correctivo |
| Propiedades de seguridad | Confidencialidad · Integridad · Disponibilidad |
| Conceptos de ciberseguridad | Identificar · Proteger · Detectar · Responder · Recuperar |
| Capacidades operativas | Gobernanza · Gestión de activos · Protección de la información · Seguridad de RR. HH. · Seguridad física · Seguridad de sistemas y redes · Seguridad de aplicaciones · Configuración segura · Gestión de identidades y accesos · Gestión de amenazas y vulnerabilidades · Continuidad · Seguridad en relaciones con proveedores · Legal y cumplimiento · Gestión de eventos de seguridad · Aseguramiento de la seguridad |
| Dominios de seguridad | Gobernanza y ecosistema · Protección · Defensa · Resiliencia |

---

## 5. Controles organizacionales (37)

| Control | Título | Propósito breve | Evidencia típica |
|---------|--------|-----------------|------------------|
| 5.1 | Políticas de seguridad de la información | Política general + políticas temáticas aprobadas, comunicadas y revisadas. | Políticas versionadas, acta de aprobación, evidencia de comunicación. |
| 5.2 | Roles y responsabilidades | Definir y asignar responsabilidades de seguridad. | RACI, designaciones, descripciones de cargo. |
| 5.3 | Segregación de funciones | Separar funciones en conflicto para reducir fraude/error. | Matriz de incompatibilidades, revisiones de roles. |
| 5.4 | Responsabilidades de la dirección | La dirección exige aplicar la seguridad según políticas. | Comunicaciones, objetivos de desempeño. |
| 5.5 | Contacto con las autoridades | Contacto con autoridades pertinentes (CSIRT nacional, protección de datos, policía). | Lista de contactos, procedimiento de notificación. |
| 5.6 | Contacto con grupos de interés especial | Foros, asociaciones sectoriales, listas de seguridad. | Membresías, suscripciones a alertas. |
| 5.7 ★ | Inteligencia de amenazas | Recopilar y analizar información sobre amenazas para actuar. | Fuentes (feeds, CSIRT, fabricantes), informes, acciones derivadas. |
| 5.8 | Seguridad en la gestión de proyectos | Integrar seguridad en todo proyecto. | Checklist de seguridad en proyectos, evaluación de riesgos por proyecto. |
| 5.9 | Inventario de información y otros activos asociados | Inventario con dueños. | Inventario/CMDB actualizado con dueño y clasificación. |
| 5.10 | Uso aceptable de la información y activos | Reglas de uso aceptable. | Política firmada/aceptada. |
| 5.11 | Devolución de activos | Devolver activos al terminar la relación. | Checklist de salida, actas de devolución. |
| 5.12 | Clasificación de la información | Clasificar según CID y requisitos. | Esquema de clasificación, activos clasificados. |
| 5.13 | Etiquetado de la información | Procedimientos de etiquetado según la clasificación. | Etiquetas en documentos, metadatos, marcas en sistemas. |
| 5.14 | Transferencia de información | Reglas y acuerdos para transferir información. | Política de transferencia, cifrado en tránsito, acuerdos. |
| 5.15 | Control de acceso | Reglas de acceso físico y lógico según negocio y seguridad. | Política de control de acceso. |
| 5.16 | Gestión de identidades | Ciclo de vida completo de identidades. | Proceso alta/baja/modificación, IdP, identidades únicas. |
| 5.17 | Información de autenticación | Asignar y gestionar secretos de autenticación. | Política de contraseñas/MFA, gestor de secretos. |
| 5.18 | Derechos de acceso | Otorgar, revisar, modificar y retirar accesos. | Solicitudes aprobadas, revisiones periódicas de acceso, bajas oportunas. |
| 5.19 | Seguridad en las relaciones con proveedores | Gestionar riesgos del uso de productos/servicios de proveedores. | Clasificación de proveedores por riesgo, evaluaciones. |
| 5.20 | Seguridad en los acuerdos con proveedores | Requisitos de seguridad en contratos. | Cláusulas de seguridad, NDA, derecho a auditar, DPA. |
| 5.21 | Seguridad en la cadena de suministro TIC | Riesgos de la cadena de suministro de productos y servicios TIC. | Evaluación de subcontratistas, SBOM, origen de componentes. |
| 5.22 | Seguimiento, revisión y gestión de cambios de servicios de proveedores | Monitorear desempeño y cambios del proveedor. | Informes de SLA, revisiones periódicas, gestión de cambios contractuales. |
| 5.23 ★ | Seguridad para el uso de servicios en la nube | Adquirir, usar, gestionar y salir de servicios cloud según requisitos. | Política cloud, matriz de responsabilidad compartida, estrategia de salida, revisión de configuración. |
| 5.24 | Planificación y preparación de la gestión de incidentes | Procesos, roles y procedimientos de respuesta. | Plan de respuesta a incidentes, equipo designado. |
| 5.25 | Evaluación y decisión sobre eventos | Evaluar eventos y decidir si son incidentes. | Criterios de clasificación y severidad, registros de triaje. |
| 5.26 | Respuesta a incidentes | Responder según procedimientos documentados. | Registros de incidentes, tiempos, comunicaciones. |
| 5.27 | Aprendizaje de los incidentes | Usar el conocimiento para fortalecer controles. | Post-mortems, acciones, actualización de riesgos. |
| 5.28 | Recopilación de evidencias | Identificar, recolectar, adquirir y preservar evidencia. | Procedimiento forense, cadena de custodia. |
| 5.29 | Seguridad durante una disrupción | Mantener la seguridad en situaciones de disrupción. | Planes de continuidad con controles de seguridad. |
| 5.30 ★ | Preparación de las TIC para la continuidad del negocio | Planificar, implementar, mantener y probar la preparación TIC. | BIA, RTO/RPO, pruebas de recuperación documentadas. |
| 5.31 | Requisitos legales, estatutarios, reglamentarios y contractuales | Identificar y cumplir requisitos aplicables. | Matriz legal y contractual actualizada. |
| 5.32 | Derechos de propiedad intelectual | Proteger PI propia y de terceros. | Gestión de licencias, inventario de software, política de open source. |
| 5.33 | Protección de registros | Proteger registros de pérdida, destrucción, falsificación y acceso no autorizado. | Tabla de retención, controles de integridad. |
| 5.34 | Privacidad y protección de datos personales | Cumplir requisitos de privacidad y protección de datos. | Registro de tratamientos, evaluaciones de impacto, DPA, derechos de titulares. |
| 5.35 | Revisión independiente de la seguridad | Revisar independientemente el enfoque de seguridad. | Auditorías internas/externas, pentests independientes. |
| 5.36 | Cumplimiento de políticas, reglas y normas | Revisar regularmente el cumplimiento. | Revisiones de cumplimiento, auditorías técnicas de configuración. |
| 5.37 | Procedimientos operativos documentados | Documentar procedimientos de operación. | Runbooks, procedimientos disponibles para quien los necesita. |

## 6. Controles de personas (8)

| Control | Título | Propósito breve | Evidencia típica |
|---------|--------|-----------------|------------------|
| 6.1 | Verificación de antecedentes | Verificar candidatos, proporcional al riesgo y conforme a la ley. | Procedimiento de selección, registros de verificación. |
| 6.2 | Términos y condiciones de empleo | Responsabilidades de seguridad en contratos. | Cláusulas contractuales firmadas. |
| 6.3 | Concienciación, educación y formación | Formación periódica pertinente al rol. | Plan de formación, asistencia, simulaciones de phishing. |
| 6.4 | Proceso disciplinario | Proceso formal ante violaciones de la política. | Reglamento interno, procedimiento comunicado. |
| 6.5 | Responsabilidades tras la terminación o cambio de empleo | Obligaciones vigentes tras salir o cambiar de rol. | Cláusulas post-empleo, checklist de salida. |
| 6.6 | Acuerdos de confidencialidad o no divulgación | NDA acordes a necesidades de protección. | NDA firmados y revisados. |
| 6.7 | Trabajo remoto | Medidas de seguridad para trabajo fuera de las instalaciones. | Política de teletrabajo, VPN/ZTNA, dispositivos gestionados. |
| 6.8 | Reporte de eventos de seguridad | Canal para que las personas reporten eventos oportunamente. | Canal de reporte, registros de reportes. |

## 7. Controles físicos (14)

| Control | Título | Propósito breve | Evidencia típica |
|---------|--------|-----------------|------------------|
| 7.1 | Perímetros de seguridad física | Definir perímetros para proteger áreas con información. | Planos de zonas, barreras físicas. |
| 7.2 | Controles físicos de entrada | Entradas y puntos de acceso protegidos. | Control de acceso con tarjeta, registro de visitas. |
| 7.3 | Seguridad de oficinas, salas e instalaciones | Diseñar e implementar seguridad física. | Salas cerradas, señalética discreta. |
| 7.4 ★ | Monitoreo de la seguridad física | Monitoreo continuo de accesos no autorizados. | CCTV, alarmas, registros de monitoreo. |
| 7.5 | Protección contra amenazas físicas y ambientales | Protección ante desastres naturales, incendio, inundación. | Detección/extinción de incendios, evaluación de riesgos del sitio. |
| 7.6 | Trabajo en áreas seguras | Medidas para trabajar en áreas seguras. | Reglas de sala de servidores, acompañamiento. |
| 7.7 | Escritorio y pantalla limpios | Reglas para papeles, medios y pantallas. | Política, bloqueo automático de sesión, rondas de verificación. |
| 7.8 | Ubicación y protección de equipos | Ubicar equipos de forma segura. | Racks cerrados, ubicación protegida. |
| 7.9 | Seguridad de activos fuera de las instalaciones | Proteger activos fuera del sitio. | Cifrado de discos, política de equipos portátiles. |
| 7.10 | Medios de almacenamiento | Gestionar el ciclo de vida de medios. | Inventario de medios, cifrado, borrado seguro. |
| 7.11 | Servicios de suministro | Proteger ante fallas de energía y otros servicios. | UPS, generador, mantenimiento. |
| 7.12 | Seguridad del cableado | Proteger cables de energía y datos. | Canalizaciones, etiquetado. |
| 7.13 | Mantenimiento de equipos | Mantenimiento correcto para asegurar CID. | Plan y registros de mantenimiento. |
| 7.14 | Eliminación o reutilización segura de equipos | Borrar datos y licencias antes de desechar o reutilizar. | Certificados de borrado/destrucción. |

## 8. Controles tecnológicos (34)

| Control | Título | Propósito breve | Evidencia típica |
|---------|--------|-----------------|------------------|
| 8.1 | Dispositivos de punto final de usuario | Proteger información en dispositivos de usuarios. | MDM, cifrado, EDR, inventario de dispositivos. |
| 8.2 | Derechos de acceso privilegiado | Restringir y gestionar accesos privilegiados. | PAM, cuentas admin separadas, revisión de privilegios. |
| 8.3 | Restricción de acceso a la información | Restringir acceso según la política de control de acceso. | Permisos por rol (RBAC), pruebas de autorización. |
| 8.4 | Acceso al código fuente | Gestionar acceso de lectura/escritura al código y herramientas. | Permisos del repositorio, ramas protegidas. |
| 8.5 | Autenticación segura | Tecnologías y procedimientos de autenticación segura. | MFA, SSO, bloqueo tras intentos fallidos. |
| 8.6 | Gestión de la capacidad | Monitorear y ajustar el uso de recursos. | Monitoreo de capacidad, alertas, planificación. |
| 8.7 | Protección contra malware | Protección y concienciación contra malware. | Antimalware/EDR actualizado, bloqueo de adjuntos. |
| 8.8 | Gestión de vulnerabilidades técnicas | Obtener información, evaluar exposición y actuar. | Escaneos, SLA de parchado por severidad, pentests. |
| 8.9 ★ | Gestión de la configuración | Establecer, documentar, implementar, monitorear y revisar configuraciones (incluidas de seguridad). | Líneas base (CIS), infraestructura como código, detección de desviaciones. |
| 8.10 ★ | Eliminación de información | Eliminar información cuando ya no se necesita. | Política de retención y borrado, registros de eliminación. |
| 8.11 ★ | Enmascaramiento de datos | Enmascarar datos según política y requisitos legales. | Seudonimización/anonimización, datos enmascarados en no-producción. |
| 8.12 ★ | Prevención de fuga de datos | Medidas de DLP en sistemas, redes y dispositivos. | Herramienta DLP, reglas, alertas, bloqueo de canales. |
| 8.13 | Respaldo de la información | Respaldos probados regularmente según política. | Política de respaldo, registros, **pruebas de restauración**. |
| 8.14 | Redundancia de instalaciones de procesamiento | Redundancia suficiente para disponibilidad. | Alta disponibilidad, multi-zona, pruebas de conmutación. |
| 8.15 | Registro (logs) | Producir, almacenar, proteger y analizar logs de actividades, excepciones y eventos. | Logs centralizados, retención, protección de integridad. |
| 8.16 ★ | Actividades de monitoreo | Monitorear redes, sistemas y aplicaciones por comportamiento anómalo. | SIEM, alertas, revisión de alertas, SOC. |
| 8.17 | Sincronización de relojes | Relojes sincronizados con fuentes aprobadas. | Configuración NTP. |
| 8.18 | Uso de programas utilitarios privilegiados | Restringir utilitarios que pueden eludir controles. | Lista de utilitarios permitidos, acceso restringido. |
| 8.19 | Instalación de software en sistemas operativos | Gestionar la instalación de software. | Lista blanca, restricción de permisos de instalación. |
| 8.20 | Seguridad de redes | Proteger redes y dispositivos de red. | Firewalls, hardening, diagramas de red. |
| 8.21 | Seguridad de los servicios de red | Mecanismos, niveles de servicio y requisitos de servicios de red. | Acuerdos con ISP, TLS, filtrado. |
| 8.22 | Segregación de redes | Separar grupos de servicios, usuarios y sistemas. | VLAN/segmentación, VPC, reglas entre segmentos. |
| 8.23 ★ | Filtrado web | Gestionar acceso a sitios externos para reducir exposición. | Proxy/filtro DNS, categorías bloqueadas. |
| 8.24 | Uso de criptografía | Reglas de uso de criptografía y gestión de claves. | Política criptográfica, KMS, rotación de claves, TLS vigente. |
| 8.25 | Ciclo de vida de desarrollo seguro | Reglas para el desarrollo seguro de software y sistemas. | SDLC seguro documentado, puertas de seguridad. |
| 8.26 | Requisitos de seguridad de las aplicaciones | Identificar y aprobar requisitos de seguridad al desarrollar o adquirir. | Requisitos de seguridad en historias, threat modeling. |
| 8.27 | Arquitectura de sistemas seguros y principios de ingeniería | Principios de ingeniería segura aplicados. | Principios documentados, revisiones de arquitectura, ADRs. |
| 8.28 ★ | Codificación segura | Aplicar principios de codificación segura. | Guías de codificación, SAST, revisión de código, gestión de dependencias. |
| 8.29 | Pruebas de seguridad en desarrollo y aceptación | Definir e implementar pruebas de seguridad. | DAST, pruebas de seguridad en CI, pentest previo a salida. |
| 8.30 | Desarrollo externalizado | Dirigir, supervisar y revisar el desarrollo tercerizado. | Contratos con requisitos de seguridad, revisión de entregables. |
| 8.31 | Separación de entornos de desarrollo, prueba y producción | Separar y proteger los entornos. | Cuentas/proyectos separados, accesos diferenciados. |
| 8.32 | Gestión de cambios | Someter los cambios a procedimientos de gestión de cambios. | PRs aprobados, registros de cambio, rollback. |
| 8.33 | Información de prueba | Seleccionar, proteger y gestionar datos de prueba. | Datos sintéticos o enmascarados; nunca producción sin control. |
| 8.34 | Protección de sistemas durante pruebas de auditoría | Planificar pruebas de auditoría para minimizar impacto. | Acuerdos de alcance, horarios, accesos de solo lectura. |

## Correspondencia rápida 2013 → 2022 (dominios)

| 2013 | 2022 |
|------|------|
| A.5 Políticas, A.6 Organización, A.8 Activos, A.15 Proveedores, A.16 Incidentes, A.17 Continuidad, A.18 Cumplimiento | Mayormente tema 5 (Organizacionales) |
| A.7 Recursos humanos | Tema 6 (Personas) |
| A.11 Física y ambiental | Tema 7 (Físicos) |
| A.9 Acceso, A.10 Criptografía, A.12 Operaciones, A.13 Comunicaciones, A.14 Adquisición y desarrollo | Mayormente tema 8 (Tecnológicos); gestión de identidades/accesos en 5.15–5.18 |

Para migrar una SoA 2013, usa la tabla de correspondencia del Anexo B de ISO/IEC 27002:2022.

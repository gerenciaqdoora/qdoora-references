# Requisitos por cláusula (4 a 10) — ISO 22301:2019 + Amd 1:2024

Parafraseo operativo, no texto oficial. Todas las cláusulas son obligatorias dentro del alcance.

Leyenda: **[M]** = mantener (documento) · **[C]** = conservar (registro).

---

## 4. Contexto de la organización

### 4.1 Comprensión de la organización y su contexto
- Cuestiones externas e internas pertinentes que afectan la capacidad de lograr los resultados del SGCN.
- **Amd 1:2024:** determinar si el **cambio climático** es pertinente (eventos extremos, olas de calor, inundaciones, sequía, cortes de energía, impacto en proveedores).

### 4.2 Necesidades y expectativas de las partes interesadas
- **4.2.1** Partes interesadas pertinentes y sus requisitos (nota Amd 2024: pueden incluir requisitos climáticos).
- **4.2.2 Requisitos legales y reglamentarios:** implementar y mantener un proceso para identificar, acceder y evaluar los requisitos aplicables a la continuidad; considerarlos al implementar el SGCN; **documentar y mantener actualizada** esta información **[M]**.
- **Evidencia:** matriz legal (reguladores sectoriales, obligaciones contractuales de SLA y continuidad, requisitos de clientes).

### 4.3 Alcance
- **4.3.1** Límites y aplicabilidad considerando 4.1, 4.2, misión, metas, obligaciones internas y externas.
- **4.3.2** Establecer partes de la organización incluidas, **productos y servicios** incluidos; **explicar las exclusiones**, que no deben afectar la capacidad de proveer continuidad según lo determinado en el BIA y la evaluación de riesgos. **[M]**

### 4.4 SGCN
- Establecer, implementar, mantener y mejorar el SGCN, incluidos procesos y sus interacciones.

## 5. Liderazgo

### 5.1 Liderazgo y compromiso
- Política y objetivos compatibles con la estrategia; integración del SGCN en los procesos de negocio; recursos; comunicación de la importancia; logro de resultados; dirigir y apoyar a las personas; promover mejora; apoyar otros roles.

### 5.2 Política de continuidad del negocio **[M]**
- Apropiada al propósito; marco para objetivos; compromiso de cumplir requisitos aplicables; compromiso de mejora continua. Comunicada y disponible a partes interesadas.

### 5.3 Roles, responsabilidades y autoridades
- Asignados y comunicados: conformidad del SGCN e informe de desempeño a la dirección.
- **Evidencia:** responsable del SGCN, equipo de gestión de crisis, dueños de actividades prioritarias, suplentes.

## 6. Planificación

### 6.1 Acciones para abordar riesgos y oportunidades
- **6.1.1** Riesgos y oportunidades **del propio SGCN** (que funcione y logre sus resultados).
- **6.1.2** Planificar acciones, integrarlas y evaluar su eficacia.
- **Ojo:** los riesgos de **disrupción** a las actividades se tratan en §8.2.3; no confundir.

### 6.2 Objetivos de continuidad y planificación para lograrlos
- **6.2.1** Coherentes con la política, medibles (si es posible), consideran requisitos, con seguimiento, comunicados, actualizados. **[M]**
- **6.2.2** Qué, recursos, responsable, plazo, evaluación.

### 6.3 Planificación de los cambios en el SGCN
- Considerar propósito y consecuencias, integridad del SGCN, recursos, responsabilidades.

## 7. Apoyo

- **7.1** Recursos.
- **7.2** Competencia **[C]** (equipos de respuesta, dueños de planes, coordinadores).
- **7.3** Concienciación: política, contribución, implicaciones de no cumplir, **su propio rol y responsabilidades antes, durante y después de una disrupción**.
- **7.4** Comunicación interna y externa: qué, cuándo, con quién, cómo, quién.
- **7.5** Información documentada: creación, actualización y control (disponibilidad, protección, distribución, versiones, retención). Controlar la de origen externo.

## 8. Operación (núcleo de la norma)

### 8.1 Planificación y control operacional
- Criterios para los procesos; control conforme a ellos; información documentada para confiar en su ejecución; controlar cambios; controlar procesos externalizados y la **cadena de suministro**.

### 8.2 Análisis de impacto en el negocio y evaluación de riesgos
- **8.2.1** Procesos sistemáticos para analizar el impacto y evaluar riesgos de disrupción; revisarlos **a intervalos planificados y ante cambios significativos** en la organización o su contexto.
- **8.2.2 BIA:** (a) tipos y criterios de impacto; (b) actividades que soportan productos/servicios; (c) evaluar impactos en el tiempo; (d) plazo en que el impacto de no reanudar se vuelve inaceptable (**MTPD**); (e) plazos priorizados para reanudar a una capacidad mínima aceptable (**RTO/MBCO**); (f) identificar **actividades prioritarias**; (g) recursos necesarios; (h) **dependencias** (socios y proveedores) e interdependencias.
- **8.2.3 Evaluación de riesgos:** identificar riesgos de disrupción a actividades prioritarias y sus recursos; analizar; evaluar cuáles requieren tratamiento. Ver `bia-evaluacion-riesgos.md`.

### 8.3 Estrategias y soluciones de continuidad
- **8.3.1** Basadas en las salidas de 8.2.
- **8.3.2 Identificación:** opciones para antes, durante y después de la disrupción, que reduzcan probabilidad, acorten el período o limiten el impacto.
- **8.3.3 Selección:** cumplen continuar/recuperar dentro de plazos y capacidad; consideran el riesgo que la organización está dispuesta a asumir; costos y beneficios.
- **8.3.4 Requisitos de recursos:** personas; información y datos; edificios, espacio de trabajo e instalaciones; equipos y consumibles; sistemas TIC; transporte y logística; finanzas; socios y proveedores.
- **8.3.5 Implementación** de las soluciones seleccionadas para que puedan activarse cuando se necesiten. Ver `estrategias-soluciones.md`.

### 8.4 Planes y procedimientos de continuidad
- **8.4.1** Estructura de respuesta que permita advertencia y comunicación oportunas; planes que guíen la respuesta; procedimientos utilizables. **[M]**
- **8.4.2 Estructura de respuesta:** equipos con roles, competencia y autoridad para: evaluar naturaleza y alcance de la disrupción; evaluar contra umbrales que justifiquen activar la respuesta formal; activar la respuesta; planificar acciones; establecer prioridades (**la vida primero**); monitorear efectos; activar soluciones; comunicar.
- **8.4.3 Advertencia y comunicación:** procedimientos para comunicar con partes interesadas internas y externas, alertar y advertir, comunicar con medios, **registrar información vital de la disrupción, acciones y decisiones [C]**; disponibilidad y uso de medios de comunicación durante la disrupción; interacción con servicios de emergencia y autoridades.
- **8.4.4 Planes de continuidad [M]:** en conjunto contienen acciones para continuar/recuperar actividades prioritarias dentro de los plazos; propósito, alcance y objetivos; **criterios y procedimientos de activación**; procedimientos de implementación; roles y autoridades; requisitos de comunicación; interdependencias internas y externas; recursos; flujo de información y documentación; **proceso de desactivación**. Cada plan **utilizable y disponible cuando y donde se necesite**.
- **8.4.5 Recuperación:** procesos documentados para restaurar y volver a las actividades de negocio desde las medidas temporales. Ver `planes-procedimientos.md`.

### 8.5 Programa de ejercicios
- Programa que valide **a lo largo del tiempo** la eficacia de estrategias y soluciones; ejercicios coherentes con los objetivos, basados en escenarios bien planificados con metas definidas; que desarrollen trabajo en equipo, competencia, confianza y conocimiento; que en conjunto validen **todas** las disposiciones; que minimicen el riesgo de provocar una disrupción; **informes formales post-ejercicio con resultados, recomendaciones y acciones [C]**; revisados para mejora continua; a intervalos planificados y ante cambios significativos. Ver `ejercicios-pruebas.md`.

### 8.6 Evaluación de la documentación y capacidades de continuidad
- Evaluar idoneidad, adecuación y eficacia del BIA, evaluación de riesgos, estrategias, soluciones, planes y procedimientos (mediante revisiones, análisis, ejercicios, pruebas, informes post-incidente, evaluaciones de desempeño); **evaluar capacidades de socios y proveedores pertinentes**; cumplimiento legal y de buenas prácticas; actualizar oportunamente. A intervalos planificados, **tras un incidente o activación** y ante cambios significativos. **[C]**

## 9. Evaluación del desempeño

### 9.1 Seguimiento, medición, análisis y evaluación **[C]**
- Qué medir, métodos, cuándo, quién analiza. Evaluar desempeño y eficacia del SGCN.
- **Indicadores típicos:** % de actividades prioritarias con plan vigente y ejercitado en el período; % de pruebas de DR que cumplen RTO/RPO; tiempo real de recuperación en incidentes vs RTO; % de proveedores críticos evaluados; % de personal clave formado; acciones post-ejercicio cerradas en plazo.

### 9.2 Auditoría interna **[C]**
- A intervalos planificados; programa, criterios, alcance, auditores objetivos e imparciales, informe a la dirección, acciones sin demora. Ver `auditoria-interna.md`.

### 9.3 Revisión por la dirección **[C]**
- **9.3.2 Entradas:** estado de acciones previas; cambios en cuestiones externas/internas; desempeño (NC y AC, seguimiento y medición, auditorías); retroalimentación de partes interesadas; necesidad de cambios al SGCN (política, objetivos); procedimientos y recursos para mejorar; **información del BIA y la evaluación de riesgos**; **salidas de la evaluación de documentación y capacidades (8.6)**; riesgos no abordados adecuadamente; **lecciones de cuasi-incidentes y disrupciones**; oportunidades de mejora.
- **9.3.3 Salidas:** decisiones sobre mejora y cambios, incluyendo: variaciones al alcance; actualización del BIA, evaluación de riesgos, estrategias, soluciones y planes; modificación de procedimientos y controles; cómo se medirá la eficacia de los controles.

## 10. Mejora

### 10.1 No conformidad y acción correctiva **[C]**
- Reaccionar; evaluar la necesidad de eliminar causas; implementar; revisar eficacia; cambiar el SGCN si es necesario. Ver `no-conformidades-incidentes.md`.

### 10.2 Mejora continua
- Mejorar la conveniencia, adecuación y eficacia del SGCN usando los resultados de análisis y evaluación.

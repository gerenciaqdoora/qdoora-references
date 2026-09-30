# Requisitos por cláusula (4 a 10) — ISO/IEC 27001:2022 + Amd 1:2024

Parafraseo operativo, no texto oficial. **Todas las cláusulas 4–10 son obligatorias**: a
diferencia de los controles del Anexo A, no se puede excluir ninguna.

Leyenda: **[M]** = mantener (documento) · **[C]** = conservar (registro) · **[2022]** = cambio respecto de 2013.

---

## 4. Contexto de la organización

### 4.1 Comprensión de la organización y su contexto
- Determinar cuestiones externas e internas pertinentes a su propósito que afectan la capacidad de lograr los resultados del SGSI.
- **Amd 1:2024:** determinar si el **cambio climático** es una cuestión pertinente.
- **Evidencia:** análisis de contexto (PESTEL/FODA) con enfoque de seguridad: amenazas del sector, regulación, dependencia tecnológica, clima.

### 4.2 Partes interesadas
- Partes interesadas pertinentes, sus requisitos pertinentes y **[2022] cuáles de esos requisitos se abordarán a través del SGSI**.
- Nota Amd 2024: pueden tener requisitos relacionados con el cambio climático.
- **Evidencia:** matriz con requisitos legales (protección de datos, ciberseguridad sectorial), contractuales (cláusulas de seguridad, SLA, auditorías de clientes) y regulatorios.

### 4.3 Alcance del SGSI **[M]**
- Considerar 4.1, 4.2 e **interfaces y dependencias** entre actividades de la organización y las realizadas por otras (proveedores, nube, casa matriz).
- **Pregunta:** ¿Qué información/procesos críticos quedan fuera y por qué? ¿Cómo se protegen las interfaces?

### 4.4 SGSI
- Establecer, implementar, mantener y mejorar el SGSI, **[2022] incluidos los procesos necesarios y sus interacciones**.

## 5. Liderazgo

### 5.1 Liderazgo y compromiso
- La alta dirección asegura política y objetivos compatibles con la estrategia, integra el SGSI en los procesos de negocio, asegura recursos, comunica la importancia, asegura resultados, dirige a las personas, promueve la mejora, apoya a otros roles.
- **Pregunta:** ¿Qué decisiones de seguridad tomó la dirección? ¿Qué presupuesto se asignó?

### 5.2 Política **[M]**
- Apropiada al propósito; incluye objetivos o marco para establecerlos; compromiso de cumplir requisitos aplicables; compromiso de mejora continua. Comunicada internamente y disponible a partes interesadas según corresponda.

### 5.3 Roles, responsabilidades y autoridades
- Asignados y comunicados: conformidad del SGSI e informe de desempeño a la dirección.
- **Evidencia:** designación de responsable del SGSI / CISO, comité de seguridad, RACI, dueños de activos y de riesgos.

## 6. Planificación

### 6.1.1 Generalidades
- Determinar riesgos y oportunidades (considerando 4.1 y 4.2) para asegurar resultados, prevenir efectos no deseados y lograr mejora; planificar acciones e integrarlas en procesos; evaluar eficacia.

### 6.1.2 Apreciación de riesgos de seguridad de la información **[C del proceso]**
- Definir y aplicar un proceso que:
  a) establezca y mantenga **criterios de riesgo**: de aceptación y para realizar apreciaciones;
  b) asegure resultados **consistentes, válidos y comparables** al repetirse;
  c) **identifique** riesgos asociados a la pérdida de CID dentro del alcance e identifique **dueños de riesgo**;
  d) **analice** consecuencias potenciales, probabilidad realista y nivel de riesgo;
  e) **evalúe** comparando con los criterios y priorice para el tratamiento.
- Conservar información documentada sobre el proceso.

### 6.1.3 Tratamiento de riesgos **[C del proceso]**
- a) seleccionar opciones de tratamiento;
- b) determinar **todos los controles necesarios** (de cualquier fuente);
- c) **comparar con el Anexo A** para verificar que no se omitieron controles necesarios;
- d) producir la **Declaración de Aplicabilidad [M]**: controles necesarios, justificación de inclusión, si están implementados o no, justificación de exclusión de controles del Anexo A;
- e) formular un **plan de tratamiento**;
- f) obtener **aprobación del plan y aceptación del riesgo residual por los dueños de riesgo**.
- Ver `gestion-riesgos-soa.md`.

### 6.2 Objetivos de seguridad de la información **[M]**
- Coherentes con la política, medibles (si es posible), consideran requisitos y resultados de riesgos, **[2022] con seguimiento**, comunicados, actualizados, **[2022] disponibles como información documentada**.
- Planificación: qué, recursos, responsable, plazo, cómo se evalúan.

### 6.3 Planificación de los cambios **[2022, nueva]**
- Cambios al SGSI realizados de manera planificada.

## 7. Apoyo

### 7.1 Recursos
- Determinar y proporcionar los recursos necesarios.

### 7.2 Competencia **[C]**
- Determinar competencia de quienes afectan el desempeño de seguridad; asegurar formación/experiencia; acciones y evaluación de eficacia.

### 7.3 Concienciación
- Las personas conocen: la política, su contribución a la eficacia del SGSI y las implicaciones de no cumplir.
- **Prueba:** entrevistar personal (¿cómo reporta un correo sospechoso? ¿qué clasificación tiene este documento?).

### 7.4 Comunicación
- Qué, cuándo, con quién y cómo comunicar (interna/externa).

### 7.5 Información documentada
- Requerida por la norma + la que la organización determine necesaria. Identificación, formato, revisión y aprobación. Control: disponibilidad, protección (confidencialidad, integridad), distribución, acceso, almacenamiento, versiones, retención, disposición. Controlar la de origen externo.

## 8. Operación

### 8.1 Planificación y control operacional **[C]**
- Planificar, implementar y controlar procesos; **[2022] establecer criterios para los procesos e implementar el control conforme a ellos**; conservar información para confiar en que se realizaron según lo planificado; controlar cambios planificados y revisar los no previstos; **[2022] controlar procesos, productos o servicios suministrados externamente pertinentes al SGSI**.

### 8.2 Apreciación de riesgos **[C]**
- Realizarla **a intervalos planificados** y **cuando se propongan u ocurran cambios significativos**. Conservar resultados.

### 8.3 Tratamiento de riesgos **[C]**
- Implementar el plan de tratamiento. Conservar resultados.

## 9. Evaluación del desempeño

### 9.1 Seguimiento, medición, análisis y evaluación **[C]**
- Qué medir (procesos y controles), métodos que aseguren **resultados comparables y reproducibles**, cuándo medir, quién, cuándo analizar, quién evalúa. Evaluar desempeño y **eficacia** del SGSI.
- **Ejemplos de indicadores:** % de sistemas con parches críticos aplicados en plazo, tiempo medio de detección/respuesta a incidentes, % de personal formado, % de accesos revisados en el período, % de respaldos restaurados con éxito en pruebas, tasa de clics en simulaciones de phishing.

### 9.2 Auditoría interna **[C]**
- **9.2.1** A intervalos planificados: conformidad con requisitos propios y de la norma; implementación y mantenimiento eficaces.
- **9.2.2** Programa (frecuencia, métodos, responsabilidades, requisitos, informes) considerando importancia de procesos y resultados previos; criterios y alcance; auditores objetivos e imparciales; informar a la dirección. Conservar programa y resultados. Ver `auditoria-interna.md`.

### 9.3 Revisión por la dirección **[C]**
- **9.3.1** A intervalos planificados.
- **9.3.2 Entradas:** estado de acciones previas; cambios en cuestiones externas/internas; **[2022] cambios en necesidades y expectativas de partes interesadas**; retroalimentación del desempeño (NC y AC, resultados de seguimiento y medición, auditorías, cumplimiento de objetivos); retroalimentación de partes interesadas; resultados de la apreciación de riesgos y estado del plan de tratamiento; oportunidades de mejora.
- **9.3.3 Salidas:** decisiones sobre mejora y necesidades de cambio. Conservar resultados.

## 10. Mejora (**[2022] orden invertido respecto de 2013**)

### 10.1 Mejora continua
- Mejorar continuamente la conveniencia, adecuación y eficacia del SGSI.

### 10.2 No conformidad y acción correctiva **[C]**
- Reaccionar (controlar, corregir, hacer frente a consecuencias); evaluar necesidad de eliminar causas (revisar, determinar causas, ver NC similares); implementar; revisar eficacia; cambiar el SGSI si es necesario. Conservar naturaleza de las NC, acciones y resultados. Ver `no-conformidades-incidentes.md`.

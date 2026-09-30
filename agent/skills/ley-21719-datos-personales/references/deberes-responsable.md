# Deberes del responsable (arts. 14 a 15 bis)

## Obligaciones generales (art. 14)

a) Informar y poner a disposición del titular los antecedentes que **acrediten la licitud**; entregarlos de forma expedita si se piden.
b) Recolectar de **fuentes lícitas**, con fines específicos, explícitos y lícitos, y limitar el tratamiento a ellos.
c) Comunicar o ceder información **exacta, completa y actual**.
d) **Suprimir o anonimizar** los datos obtenidos para medidas precontractuales (si no se concreta el contrato).
e) Cumplir los demás deberes y principios.
- Responsables **sin domicilio en Chile** que traten datos de residentes: correo u otro medio de contacto actualizado y operativo para titulares y Agencia.

## Deber de secreto o confidencialidad (art. 14 bis)

- Secreto sobre los datos, salvo que el titular los haya hecho **manifiestamente públicos**; subsiste tras la relación.
- Datos de fuentes públicas que el responsable **organiza, clasifica, combina o complementa** quedan protegidos por el deber de secreto.
- El responsable debe asegurar que sus **dependientes y encargados** cumplan (cláusulas en contratos de trabajo y de servicios).
- Vulnerarlo: **grave** (34 ter i); sobre sensibles o datos de infracciones: **gravísima** (34 quáter d).

## Deber de información y transparencia (art. 14 ter)

Publicar **permanentemente** (sitio web o medio equivalente), al menos:

| Letra | Contenido |
|-------|-----------|
| a | Política de tratamiento de datos adoptada, **fecha y versión** |
| b | Individualización del responsable, su representante legal y el **encargado de prevención** (delegado), si existe |
| c | Domicilio postal, correo, formulario o medio para que los titulares ejerzan derechos |
| d | Categorías de datos; universo de titulares; destinatarios de comunicaciones o cesiones; **finalidades**; **base de licitud**; y cuál es el **interés legítimo** cuando se use |
| e | Política y **medidas de seguridad** adoptadas |
| f | Derechos de acceso, rectificación, supresión, oposición y portabilidad |
| g | Derecho a reclamar ante la **Agencia** |
| h | **Transferencias internacionales** y si el destino tiene nivel adecuado; si no, las garantías |
| i | **Período de conservación** |
| j | **Fuente** de los datos y si provienen de fuentes de acceso público |
| k | Derecho a **retirar el consentimiento** sin afectar la licitud previa |
| l | Existencia de **decisiones automatizadas** y perfilamiento, con información significativa de la lógica y consecuencias |

Incumplimiento total o parcial: **leve** (34 bis a). Los estándares mínimos serán diferenciados por
la Agencia según tamaño, tipo de dato y volumen (art. 14 septies).

Buenas prácticas: además de la política general, **avisos en el punto de recolección** (capa corta
en el formulario + enlace a la política completa).

## Protección desde el diseño y por defecto (art. 14 quáter)

- **Desde el diseño:** medidas técnicas y organizativas adecuadas **antes y durante** el tratamiento, considerando estado de la técnica, costos, naturaleza, ámbito, contexto, fines y riesgos.
- **Por defecto:** solo se tratan los datos **específicos y estrictamente necesarios**, considerando número de datos, extensión del tratamiento, plazo de conservación y **accesibilidad**.
- Evidencia: checklist de privacidad en el ciclo de desarrollo, revisiones de diseño, configuración por defecto más restrictiva, campos opcionales realmente opcionales. Ver `software-y-ti.md`.

## Deber de seguridad y reporte de vulneraciones (arts. 14 quinquies y sexies)

Ver `brechas-seguridad.md`.

## Cesión de datos (art. 15)

- Procede con **consentimiento** del titular (para los fines del tratamiento), o cuando es necesaria para un **contrato** con el titular, por **interés legítimo** (art. 13 d) o por **ley**.
- Si el consentimiento original no contempló la cesión, debe recabarse **antes** (es una nueva operación).
- **Por escrito o medio electrónico idóneo**: partes, datos cedidos, finalidades y demás estipulaciones.
- El **cesionario pasa a ser responsable**; el cedente sigue siéndolo respecto de lo que continúe tratando.
- Cesión sin consentimiento necesario: **nula**; el cesionario debe suprimir todo.
- Infracción: **grave** (34 ter b); ceder a sabiendas información falsa o inexacta: **gravísima** (34 quáter c).

## Encargados / terceros mandatarios (art. 15 bis)

- Tratan **conforme al encargo e instrucciones**; prohibido usar para otro objeto o ceder sin autorización expresa y específica.
- Si se desvían, **pasan a ser responsables** y responden **solidariamente** por los daños.
- **Contrato obligatorio** con: objeto del encargo, duración, finalidad, tipo de datos, categorías de titulares, derechos y obligaciones de las partes. (La Agencia publicará modelos tipo.)
- **Subencargo** solo con autorización **específica y por escrito**; el encargado sigue siendo solidariamente responsable.
- El encargado debe cumplir **secreto** (14 bis) y **seguridad** (14 quinquies), y **reportar al responsable** toda vulneración de seguridad.
- Al terminar: **suprimir o devolver** los datos.

### Checklist de un contrato de encargo

- [ ] Objeto, finalidad, duración.
- [ ] Tipos de datos y categorías de titulares.
- [ ] Obligación de seguir instrucciones documentadas; prohibición de uso propio (incl. **entrenamiento de modelos de IA**).
- [ ] Confidencialidad del personal del encargado.
- [ ] Medidas de seguridad mínimas y derecho a verificarlas (auditoría o certificaciones).
- [ ] Notificación de vulneraciones al responsable en plazo definido (p. ej., 24–48 h) con contenido mínimo.
- [ ] Subencargados: autorización previa escrita, lista y flujo de cambios.
- [ ] Ubicación de los datos y transferencias internacionales (arts. 27–28).
- [ ] Apoyo al responsable para responder derechos de los titulares.
- [ ] Supresión o devolución al término, con certificado.
- [ ] Responsabilidad e indemnidad.

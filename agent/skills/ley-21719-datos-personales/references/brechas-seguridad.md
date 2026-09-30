# Seguridad y vulneraciones (arts. 14 quinquies y 14 sexies)

## Deber de seguridad (art. 14 quinquies)

Adoptar medidas considerando: estado de la técnica, costos, naturaleza, alcance, contexto y fines,
probabilidad y gravedad de los riesgos según el tipo de datos.

Las medidas deben asegurar **confidencialidad, integridad, disponibilidad y resiliencia** de los
sistemas, y evitar alteración, destrucción, pérdida, tratamiento o acceso no autorizado. Incluyen,
según el riesgo (responsable **y encargado**):

a) **Seudonimización y cifrado**.
b) Capacidad de garantizar CID y resiliencia **permanentes**.
c) Capacidad de **restaurar** disponibilidad y acceso rápidamente tras un incidente.
d) Proceso de **verificación, evaluación y valoración regulares** de la eficacia de las medidas.

**Carga de la prueba:** ante un incidente o controversia, el responsable debe **acreditar la
existencia y el funcionamiento** de las medidas según el riesgo. Documenta y conserva evidencia.

Infracción por medidas insuficientes: **grave** (34 ter j).

### Medidas mínimas razonables (orientación; la Agencia fijará estándares diferenciados)

| Área | Medida |
|------|--------|
| Gobierno | Política de seguridad, responsable designado, inventario de activos con datos personales |
| Accesos | Mínimo privilegio, MFA, revisión periódica, baja oportuna |
| Datos | Cifrado en tránsito y reposo, seudonimización, minimización, retención y borrado |
| Operación | Parches, respaldo probado, registro de accesos a datos personales, monitoreo |
| Desarrollo | Datos de prueba no reales, revisión de código, gestión de secretos |
| Proveedores | Contratos de encargo con cláusulas de seguridad y notificación |
| Personas | Confidencialidad, formación, procedimiento de reporte |
| Verificación | Auditorías, pruebas de penetración, revisión anual de eficacia |

Si existe la habilidad `iso-27001-seguridad`, úsala para diseñar y evidenciar estos controles
(controles 5.34, 8.10, 8.11, 8.12, 8.24, 8.13, 5.24–5.28 del Anexo A).

## Reporte de vulneraciones (art. 14 sexies)

### ¿Qué hay que reportar?
Vulneraciones a las medidas de seguridad que ocasionen **destrucción, filtración, pérdida o
alteración** accidental o ilícita, o **comunicación o acceso no autorizados**, **cuando exista un
riesgo razonable para los derechos y libertades de los titulares**.

### ¿A quién y cuándo?

| Destinatario | Cuándo | Plazo |
|--------------|--------|-------|
| **Agencia** | Siempre que exista riesgo razonable | **"Por los medios más expeditos posibles y sin dilaciones indebidas"** — la ley **no fija horas**. Interpretación prudente: notificar apenas se confirme la vulneración y el riesgo, completando información después. |
| **Titulares** (directamente o por sus representantes) | Además, si afecta **datos sensibles**, datos de **niños y niñas menores de 14** o datos **económicos, financieros, bancarios o comerciales** | Igual criterio de celeridad |
| Si no es posible notificar a cada titular | Aviso en un **medio de comunicación social masivo y de alcance nacional** | — |

Comunicación a titulares: lenguaje **claro y sencillo**, singularizando los datos afectados, las
posibles consecuencias y las medidas de solución o resguardo adoptadas.

### Registro obligatorio
Registrar las comunicaciones describiendo: **naturaleza** de la vulneración, **efectos**,
**categorías de datos**, **número aproximado de titulares** y **medidas** adoptadas para
gestionarla y prevenir futuros incidentes. Recomendación: registrar **todas** las vulneraciones,
incluso las evaluadas sin riesgo, con la justificación de por qué no se notificó.

### Encargados
Deben reportar la vulneración **al responsable** (art. 15 bis). Fija en el contrato un plazo
corto y el contenido mínimo.

### Consecuencias
- Omitir las comunicaciones o registros: **grave** (34 ter k).
- **Omitir deliberadamente** la comunicación de vulneraciones que puedan afectar CID: **gravísima** (34 quáter f).
- La autodenuncia con medidas adoptadas es **atenuante** (art. 36 n° 4).

### Otras obligaciones concurrentes
El art. 14 sexies no excluye otros deberes de información. Verifica según el caso:
- **Ley 21.663 Marco de Ciberseguridad** (reporte de incidentes al CSIRT nacional/ANCI para prestadores de servicios esenciales y operadores de importancia vital; plazos propios, más cortos — verificar).
- Reguladores sectoriales (CMF, Superintendencias).
- Obligaciones contractuales con clientes.

## Protocolo de respuesta (resumen)

```
Detección → Contención → Evaluación (¿datos personales? ¿cuáles? ¿cuántos titulares? ¿sensibles, NNA < 14, financieros?)
→ ¿Riesgo razonable para derechos y libertades? ── no ──► registrar con justificación
        │ sí
Notificar a la Agencia (sin dilaciones) ──► ¿sensibles / < 14 / financieros? ── sí ──► notificar a titulares
        │
Registrar → Remediar → Lecciones aprendidas → Actualizar medidas y EIPD
```

### Criterios para evaluar el riesgo (orientativos)
Tipo y sensibilidad de los datos · volumen de titulares · facilidad de identificación · posibles
consecuencias (fraude, discriminación, daño reputacional, riesgo físico) · si los datos estaban
cifrados con clave no comprometida · si se recuperaron los datos antes de su uso · vulnerabilidad
de los titulares (menores, pacientes).

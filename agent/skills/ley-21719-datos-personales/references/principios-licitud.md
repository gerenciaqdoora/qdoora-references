# Principios y bases de licitud

## Los 8 principios (art. 3°)

| Principio | Exigencia | Pregunta de control |
|-----------|-----------|---------------------|
| **a) Licitud y lealtad** | Tratar de forma lícita y leal; el responsable debe **poder acreditar** la licitud. | ¿Qué base de licitud tiene cada tratamiento y dónde está la evidencia? |
| **b) Finalidad** | Fines específicos, explícitos y lícitos; no usar para fines distintos salvo: fines compatibles, relación contractual/precontractual que lo justifique, nuevo consentimiento o ley. | ¿El uso actual coincide con lo informado al recolectar? |
| **c) Proporcionalidad** | Solo datos necesarios, adecuados y pertinentes; conservar solo el tiempo necesario y luego **suprimir o anonimizar**; más tiempo requiere ley o consentimiento. | ¿Cada campo es necesario? ¿Cuál es el plazo de conservación y se ejecuta? |
| **d) Calidad** | Datos exactos, completos, actuales y pertinentes. | ¿Cómo se corrigen y actualizan? |
| **e) Responsabilidad** | Quien trata datos responde legalmente del cumplimiento. | ¿Quién es el dueño de cada tratamiento? |
| **f) Seguridad** | Estándares adecuados contra tratamiento no autorizado, pérdida, filtración, daño o destrucción; medidas acordes al tratamiento y la naturaleza de los datos. | Ver `brechas-seguridad.md`. |
| **g) Transparencia e información** | Entregar toda la información necesaria para ejercer derechos; políticas y prácticas permanentemente accesibles, claras, gratuitas. | ¿La política pública refleja lo que realmente se hace? |
| **h) Confidencialidad** | Secreto sobre los datos, incluso después de terminada la relación. | ¿Cláusulas de confidencialidad con personal y terceros? |

## Consentimiento (art. 12)

Requisitos:
- **Libre, informado y específico** en cuanto a la finalidad.
- **Previo** e **inequívoco**: declaración verbal, escrita, electrónica o **acto afirmativo claro** (no silencio, no casillas premarcadas, no inactividad).
- Otorgado por mandatario solo con facultad expresa.
- **Revocable** en cualquier momento, sin causa, por medios similares a los usados para otorgarlo; sin efecto retroactivo.
- Medios de otorgamiento y revocación: **expeditos, fidedignos, gratuitos y permanentemente disponibles**.
- **Presunción de no libertad**: si se recaba en el marco de un contrato o servicio donde la recolección **no es necesaria**. Excepción: cuando el consentimiento para tratar datos es la **única contraprestación** por el bien o servicio (se debe transparentar).
- **Carga de la prueba**: el responsable debe probar que obtuvo el consentimiento.

Evidencia a conservar: quién, cuándo, qué texto/versión se mostró, qué finalidades aceptó, por qué canal, y las revocaciones.

## Otras bases de licitud sin consentimiento (art. 13)

| Base | Cuándo usarla | Cuidados |
|------|---------------|----------|
| **a) Datos financieros/comerciales** según Título III (arts. 17–19) | Boletines comerciales y obligaciones protestadas o morosas permitidas por la ley | Solo las obligaciones que la ley permite comunicar; plazos de 5 años; supresión de obligaciones prescritas |
| **b) Obligación legal** | Ley laboral, tributaria, previsional, sectorial | Identificar la norma concreta |
| **c) Contrato o medidas precontractuales** a solicitud del titular | Datos necesarios para prestar el servicio contratado | Solo lo **necesario** para el contrato; los datos precontractuales deben suprimirse o anonimizarse si no se concreta (art. 14 d) |
| **d) Interés legítimo** del responsable o de un tercero | Prevención de fraude, seguridad de la red, mejora del servicio, marketing a clientes propios (evaluar) | Solo si **no afecta derechos y libertades** del titular; el titular puede exigir saber cuál es el interés y puede **oponerse** (art. 8 a); debe informarse en la política (art. 14 ter d) |
| **e) Defensa de derechos** ante tribunales u órganos públicos | Litigios, reclamos | Limitado a lo necesario |

El responsable debe **acreditar** la base (art. 13, inciso final).

### Test de interés legítimo (práctica recomendada; documentar)

1. **Finalidad:** ¿cuál es el interés concreto, lícito y real?
2. **Necesidad:** ¿el tratamiento es necesario para ese interés o hay una forma menos invasiva?
3. **Ponderación:** expectativas razonables del titular, relación con él, naturaleza de los datos (¿sensibles? ¿menores?), impacto, salvaguardas (seudonimización, opt-out fácil, minimización).
4. **Conclusión** firmada y fechada, revisada si cambia el tratamiento.

Si el resultado es dudoso, usar otra base o no tratar.

## Finalidad compatible (art. 3 b)

Antes de reutilizar datos para un nuevo fin, verifica si es: compatible con el original,
justificado por la relación contractual, cubierto por nuevo consentimiento o por ley. Si no,
**es un tratamiento nuevo** que necesita su propia base. Tratar con finalidad distinta sin base
es infracción **grave** (art. 34 ter a); hacerlo maliciosamente, **gravísima** (art. 34 quáter b).

## Árbol de decisión rápido

```
¿Es dato personal? ── no ──► fuera de la ley (verificar anonimización real)
        │ sí
¿Es sensible / NNA / biométrico / salud? ── sí ──► ver categorias-especiales.md
        │ no
¿Lo exige una ley? ── sí ──► art. 13 b
        │ no
¿Es necesario para un contrato con el titular o lo que pidió? ── sí ──► art. 13 c
        │ no
¿Hay interés legítimo que supera el test de ponderación? ── sí ──► art. 13 d (+ derecho de oposición)
        │ no
Consentimiento válido (art. 12) ── o ── no tratar
```

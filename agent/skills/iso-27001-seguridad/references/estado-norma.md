# Estado de la norma y ediciones

> Estado verificado al 2026-09-26. Confirma siempre con el organismo de certificación y el
> catálogo de ISO, que pueden haber cambiado.

## Cronología

| Hito | Fecha |
|------|-------|
| ISO/IEC 27001:2005 (1.ª ed., basada en BS 7799-2) | Octubre 2005 |
| ISO/IEC 27001:2013 (2.ª ed., Anexo SL, 114 controles en 14 dominios) | Octubre 2013 |
| ISO/IEC 27002:2022 (93 controles, 4 temas, atributos) | Febrero 2022 |
| **ISO/IEC 27001:2022** (3.ª ed.) | 25 octubre 2022 |
| **Amd 1:2024** — cambio climático en §4.1 y nota en §4.2 | 23 febrero 2024 (sin transición: auditable desde su publicación) |
| **Fin de la transición 2013 → 2022**: certificados 2013 dejan de ser válidos | **31 octubre 2025** |
| ISO/IEC 27701:2025 — privacidad como sistema **independiente** (ya no extensión de 27001) | 14 octubre 2025 |
| ISO/IEC 27000:2026 (6.ª ed.) — vocabulario y visión general de la familia | 3 julio 2026 |
| Nueva edición de 27001 | **No hay** al 2026-09-26; la vigente es 2022 + Amd 1:2024 |

## Cambios de 27001:2022 frente a 2013 (resumen)

**Cláusulas (alineación con la Estructura Armonizada):**
- 4.2 c: determinar qué requisitos de partes interesadas se abordan mediante el SGSI.
- 4.4: incluir procesos necesarios y sus interacciones.
- 6.2: objetivos con seguimiento y disponibles como información documentada.
- 6.3 **nueva**: planificación de los cambios.
- 7.4: se simplifica (se elimina "proceso de comunicación").
- 8.1: criterios para los procesos y control de procesos/productos/servicios externos.
- 9.1: métodos que produzcan resultados comparables y reproducibles.
- 9.2 y 9.3 subdivididas; 9.3.2 agrega cambios en necesidades de partes interesadas.
- 10: se invierte el orden (10.1 mejora continua, 10.2 NC y acción correctiva).

**Anexo A:** 114 → **93** controles; 14 dominios → **4 temas**; **11 nuevos** (5.7, 5.23, 5.30,
7.4, 8.9, 8.10, 8.11, 8.12, 8.16, 8.23, 8.28); 24 fusionados; 58 actualizados; atributos en 27002.

## Si una organización todavía tiene documentación 2013

Su certificado ya no es válido. Plan:
1. Migrar la SoA a los 93 controles (Anexo B de 27002:2022 tiene la correspondencia).
2. Implementar los 11 controles nuevos si son aplicables (casi siempre 5.23, 8.9, 8.16 y 8.28 en organizaciones con nube y desarrollo).
3. Ajustar cláusulas (6.3, 4.2 c, 8.1, cambio climático).
4. Rehacer apreciación y tratamiento de riesgos contra los nuevos controles.
5. Auditoría interna y revisión por la dirección antes de la auditoría externa (que será inicial o de recertificación, no de transición).

## Normas de la familia revisadas recientemente (a tener en cuenta)

- **ISO/IEC 27701:2025**: PIMS certificable por sí sola; si la organización ya tiene 27001, puede integrarse.
- **ISO/IEC 27000:2026**: actualiza términos; las demás normas se alinearán progresivamente.
- **ISO/IEC 27005:2022**: gestión de riesgos con enfoques por activos y por eventos.
- **ISO/IEC 27006-1**: requisitos para organismos que certifican SGSI.

Si el usuario menciona una revisión de 27001 posterior a esta fecha, **no asumas su contenido**:
pide la fuente o recomienda verificarla.

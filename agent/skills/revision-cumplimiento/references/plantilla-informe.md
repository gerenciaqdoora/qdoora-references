# Plantilla del informe consolidado

Usar en todo informe final. Si un marco no se aplicó, decirlo con el motivo.

```markdown
# Revisión de cumplimiento: <diff / módulo / sistema>
Fecha: AAAA-MM-DD · Alcance: <qué se revisó, rama o commit base> · Tipo: estática | activa (autorizada por: ...)
Marcos aplicados: AppSec · ISO/IEC 27001 · Ley 21.719 · ISO 22301 · ISO 9001 (tachar los que no)
Fuera de alcance: <marcos y partes no revisadas, con el motivo>
Supuestos: <jurisdicción, datos sensibles, sistemas de gestión existentes...>

## Resumen ejecutivo
3 a 5 frases: nivel de riesgo general, lo que más importa en términos de negocio, si el cambio
puede fusionarse o salir a producción, y la primera acción.

## Hallazgos priorizados
| ID | Prioridad | Hallazgo (impacto) | AppSec | 27002 | 21.719 | 22301 | 9001 | Esfuerzo |
|----|-----------|--------------------|--------|-------|--------|-------|------|----------|
| H-01 | P1 | Cualquier persona autenticada puede leer las notas de otra | CWE-639 · Alta (7.1) | 8.3 | 14 quinquies | — | — | Bajo |

## Detalle

### H-01: <título en términos de impacto>
- **Prioridad:** P1 (por qué: severidad técnica, clasificación ISO, exposición legal, ajustes aplicados)
- **Ubicaciones:** `ruta/archivo.ts:42`, `ruta/otro.ts:88`
- **Evidencia:** fragmento, configuración o comando con su salida (sin secretos ni datos personales reales)
- **Causa raíz:** qué falta o está mal, una sola vez
- **Impacto:** qué puede pasar y a quién afecta
- **Citas:** AppSec `CWE-… · ASVS …` · 27002 `control …` · 21.719 `art. …` · 22301 `§…` · 9001 `§…`
- **Remediación:** el cambio concreto en el stack del proyecto
- **Prueba de cierre:** el test, la configuración o el registro que demostrará que quedó resuelto
- **Relacionado con:** H-0x (si es causa de fondo o síntoma de otro)

## A verificar
| Indicio | Marco(s) | Qué falta para confirmarlo | Quién puede aportarlo |
|---------|----------|----------------------------|-----------------------|

## Controles verificados que funcionan
- <control> (`ubicación`): qué protege.

## Preexistente fuera del cambio (solo en revisiones de diff)
Una línea por problema visto al pasar, sin detalle, para una revisión aparte.

## Plan de remediación
| Orden | Hallazgo(s) | Acción | Responsable | Fecha | Evidencia de cierre |
|-------|-------------|--------|-------------|-------|---------------------|

## Notas de alcance y límites
- Qué se revisó y cómo (estática, archivos, comandos).
- Esta revisión no es asesoría legal: la clasificación de posibles infracciones es orientativa.
- No es una auditoría de certificación ISO: cubre lo visible en el alcance, no el sistema de gestión completo.
- Próxima revisión sugerida: <cuándo y con qué alcance>.
```

## Reglas de redacción

- El resumen ejecutivo lo entiende alguien que no lee código.
- Cada hallazgo aparece **una vez**; las citas van juntas en su fila.
- Hechos (evidencia), juicios (impacto, prioridad) y recomendaciones (remediación) se distinguen.
- Nunca se reproducen secretos ni datos personales reales: se describen ("un RUT completo en el
  log de acceso").
- Si no hay hallazgos P1 ni P2, se dice claramente, junto con los controles que se verificaron.

# Plantilla del informe de seguridad

Usar en todo informe final. Si un dominio no se evaluó, decirlo explícitamente.

```markdown
# Informe de seguridad: <sistema / módulo / diff>
Fecha: AAAA-MM-DD · Alcance: <qué se revisó> · Tipo: estática | activa (autorizada por: ...)
Stack: <según el perfil del proyecto>

## Resumen ejecutivo
3 a 5 frases: nivel de riesgo general, los hallazgos que más importan en términos de negocio y la
acción prioritaria.

## Resumen de hallazgos
| ID | Título | Severidad (CVSS v4.0) | CWE | ASVS | Estado |
|----|--------|-----------------------|-----|------|--------|
| H-01 | ... | Alta (7.8) | CWE-639 | V8.2.2 | Abierto |

## Hallazgos

### H-01: <título en términos de impacto>
- **Severidad:** Alta · CVSS:4.0/AV:N/AC:L/...
- **Ubicación:** `ruta/archivo.ts:42`
- **Descripción:** qué falla y por qué.
- **Evidencia:** fragmento de código o petición/respuesta (sin secretos reales).
- **Impacto:** qué puede hacer un atacante y a quién afecta.
- **Remediación:** el cambio concreto en el stack del proyecto.
- **Prueba que lo demuestra:** el test que falla hoy y pasará con el arreglo.
- **Esfuerzo:** bajo | medio | alto

## A verificar
Indicios sin evidencia suficiente, con qué haría falta para confirmarlos.

## Controles verificados que funcionan
Lista corta: da contexto y evita repetir la revisión.

## Plan de remediación priorizado
| Prioridad | Hallazgo | Acción | Esfuerzo |
|-----------|----------|--------|----------|

## Notas de alcance
Qué se revisó, qué quedó fuera y cuándo conviene la próxima revisión.
```

## Escala de severidad

| Severidad | CVSS v4.0 | Criterio práctico |
|---|---|---|
| Crítica | 9.0–10.0 | Explotable sin autenticación o con cualquier cuenta; compromete datos de todos o el servidor |
| Alta | 7.0–8.9 | Acceso a datos o acciones de otras personas; escalamiento de privilegios |
| Media | 4.0–6.9 | Requiere condiciones o interacción; impacto acotado |
| Baja | 0.1–3.9 | Endurecimiento; impacto mínimo por sí solo |
| Informativa | — | Buenas prácticas sin riesgo directo |

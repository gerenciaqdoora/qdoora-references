# Consolidación: sin duplicados y con una sola prioridad

## 1. Una causa raíz, un hallazgo

La clave de un hallazgo es su **causa raíz**, no el marco que lo detectó ni el archivo donde se vio.

| Situación | Resultado |
|---|---|
| El mismo problema lo citan appsec, 27001 y 21.719 | **Un** hallazgo con las tres citas |
| El mismo patrón en 5 archivos (ej. 5 endpoints sin filtro por dueño) | **Un** hallazgo con las 5 ubicaciones |
| Dos problemas en la misma línea (inyección y datos personales en el log) | **Dos** hallazgos: causas distintas, arreglos distintos |
| Un síntoma técnico y la falta de proceso que lo permitió (IDOR + CI sin pruebas de autorización) | Dos hallazgos, **enlazados** ("causa de fondo de H-02") |

Título en términos de impacto, no de norma: "Cualquier persona autenticada puede descargar los
adjuntos de otra", no "Incumplimiento del control 8.3".

## 2. Citas por marco

Cada hallazgo lleva una columna por marco aplicado, vacía si no corresponde:

| Marco | Formato de cita | Fuente |
|---|---|---|
| AppSec | `CWE-639 · ASVS V8.x` + CVSS v4.0 | `auditoria-appsec` |
| ISO/IEC 27001 | `27002:2022 control 8.15` o `27001:2022 §6.1.3` | `iso-27001-seguridad` |
| Ley 21.719 | `art. 14 quinquies` (numeración de la Ley 19.628 modificada) | `ley-21719-datos-personales` |
| ISO 22301 | `22301:2019 §8.3.4` | `iso-22301-continuidad` |
| ISO 9001 | `9001 §8.5.6` | `iso-9001-calidad` |

Usar solo las citas que las habilidades especializadas documentan. Si no hay certeza de la
numeración, escribir el tema y "cita a confirmar".

### Equivalencias frecuentes (según las habilidades especializadas)

| Causa raíz típica | AppSec | 27002:2022 | Ley 21.719 | 22301 | 9001 |
|---|---|---|---|---|---|
| Acceso a datos de otra persona por id (IDOR) | CWE-639 | 8.3, 8.26, 8.29 | Seguridad (14 quinquies); acceso mínimo | — | — |
| Secretos en el repositorio o en la imagen | CWE-798 | 5.17 | Seguridad (14 quinquies) si protegen datos personales | Recuperación de secretos | 8.5.3 |
| Datos personales o tokens en logs | CWE-532 | 8.15 | Proporcionalidad y conservación (3 c); seguridad (14 quinquies) | — | — |
| Datos personales reales en semillas, fixtures o pruebas | CWE-359 | 8.33, 5.34 | Finalidad y proporcionalidad (3 b, c) | — | — |
| Envío de datos a un tercero (API de IA, correo, APM) sin inventario ni contrato | — | 5.19, 5.23, 5.34 | Encargados (15 bis); transferencias (27) | Dependencia externa (8.2.2 h) | 8.4 |
| Sin plazo de conservación ni borrado automático | — | 5.34 | Conservación (3 c) | — | — |
| No se puede exportar o suprimir todo lo de una persona | — | 5.34 | Derechos (10, 11); portabilidad (9) | — | — |
| Migración irreversible o sin respaldo previo | — | 8.32 | — | 8.3.4 | 8.5.6 |
| Respaldo sin restauración probada | — | 8.13 | Seguridad (14 quinquies) | 8.3.4, 8.5 | — |
| Servicio externo crítico sin timeout ni modo degradado | CWE-1088 | 5.23 | — | 8.2.2 h, 8.3 | — |
| Cambio sin revisión ni pruebas en CI | — | 8.25, 8.28, 8.32 | — | — | 8.3.4, 8.5.6 |

## 3. Prioridad única

Cada marco trae su propia escala. Se traduce a una **prioridad P1–P4** y el hallazgo toma la
**más alta** de las que le correspondan.

| Prioridad | AppSec (CVSS v4.0) | ISO (27001, 22301, 9001) | Ley 21.719 (orientativo) | Plazo sugerido |
|---|---|---|---|---|
| **P1** | Crítica (9.0–10) o Alta (7.0–8.9) | NC mayor | Posible infracción grave o gravísima, o exposición de datos personales de muchas personas | Antes de salir a producción / inmediato |
| **P2** | Media (4.0–6.9) | NC menor | Posible infracción leve, o brecha de un deber con impacto acotado | En el ciclo actual |
| **P3** | Baja (0.1–3.9) | Observación | Recomendación con base legal pero sin incumplimiento claro | Planificado |
| **P4** | Informativa | Oportunidad de mejora | Buena práctica | Cuando convenga |

Ajustes:
- **Sube un nivel** si afecta datos sensibles o de menores, si es explotable sin autenticación, o
  si el mismo hallazgo aparece en muchas ubicaciones (sistémico).
- **Baja un nivel** si existe un control compensatorio verificado (y se cita).
- En un diff que se va a fusionar, todo P1 **bloquea** la fusión; decirlo explícitamente.

La clasificación legal (leve, grave, gravísima) se cita con el artículo de la habilidad
especializada y se marca como orientativa.

## 4. Confirmado, a verificar y controles que funcionan

- **Confirmado:** hay evidencia en el código, la configuración o una salida de comando.
- **A verificar:** hay un indicio, pero falta ver algo fuera del alcance (configuración de
  producción, contrato con un proveedor, registro de una prueba de restauración). Se dice qué haría
  falta para confirmarlo. No lleva prioridad.
- **Controles que funcionan:** lista corta de lo revisado que está bien (guard global, validación,
  cookies seguras). Evita que otra revisión repita el trabajo y da contexto a la severidad.

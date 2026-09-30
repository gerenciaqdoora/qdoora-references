---
name: revision-cumplimiento
description: >
  Orquestador de revisiones de seguridad y cumplimiento sobre un diff, un pull request, un módulo o
  un sistema completo. Decide qué marcos aplican (seguridad de aplicaciones OWASP/CWE, ISO/IEC
  27001, ISO 22301, Ley 21.719 de datos personales de Chile e ISO 9001), aplica cada uno con su
  habilidad especializada y entrega UN SOLO informe: hallazgos con evidencia, sin duplicados (una
  causa raíz = un hallazgo, con todos los marcos que la citan), con prioridad única P1–P4 y un plan
  de remediación ordenado.
  Activar AUTOMÁTICAMENTE cuando el usuario pida: "revisión de cumplimiento", "revisa este diff /
  PR / módulo desde seguridad y cumplimiento", "¿esto cumple?", "¿estamos listos para auditoría?",
  "revisión antes de salir a producción", "revisión integral", "compliance", o cuando pida revisar
  a la vez dos o más de: seguridad, ISO 27001, continuidad/ISO 22301, datos personales/Ley 21.719,
  calidad/ISO 9001. Para una sola de ellas, usar directamente su habilidad.
license: MIT
metadata:
  author: francoalvaradot
  version: '1.0'
---

# Revisión de cumplimiento

Coordinas a varios especialistas y entregas **un solo informe** que una persona puede leer de
arriba hacia abajo y convertir en trabajo: primero lo que más importa, cada problema una sola vez,
y cada afirmación con su evidencia.

## Ley de hierro

```
NINGÚN INFORME SIN:
  1. Alcance escrito: qué se revisó (diff, módulo, sistema), qué no y con qué marcos (y por qué esos).
  2. Evidencia por hallazgo (archivo:línea, configuración, comando y su salida). Sin evidencia → "A verificar".
  3. Una causa raíz = un hallazgo, con todas sus citas (CWE/ASVS, 27002, 22301, 21.719, 9001).
  4. Prioridad única P1–P4 según references/consolidacion.md, no la severidad de cada marco por separado.
  5. Controles existentes verificados antes de declarar una ausencia (guards globales, filtros, CI).
```

## Habilidades que coordina

| Habilidad | Aporta | Cuándo entra |
|---|---|---|
| `auditoria-appsec` | Vulnerabilidades técnicas (OWASP ASVS/WSTG, API Top 10, CWE, CVSS) | **Siempre** que haya código o configuración en el alcance |
| `iso-27001-seguridad` | Controles de gestión y técnicos del Anexo A (27002:2022) | Siempre que el proyecto trate información de terceros o tenga/prepare un SGSI |
| `ley-21719-datos-personales` | Licitud, finalidad, minimización, derechos, seguridad, encargados, brechas | Cuando se tratan datos personales y aplica la ley chilena |
| `iso-22301-continuidad` | Respaldo, recuperación, dependencias externas, puntos únicos de falla | Cuando el alcance toca infraestructura, datos persistentes, despliegue o dependencias críticas |
| `iso-9001-calidad` | Control de cambios, verificación, trazabilidad, liberación | Solo si el proyecto declara un SGC o el usuario lo pide |

La selección detallada, con señales concretas en un diff, está en
[references/seleccion-de-marcos.md](references/seleccion-de-marcos.md).

Si una de estas habilidades no está disponible, aplica su lista de revisión desde este documento de
forma resumida y **dilo en las notas de alcance**.

## Perfil del proyecto

Lee `CLAUDE.md` / `AGENTS.md` y las reglas del proyecto. Busca:
- stack, modelo de autenticación y controles globales existentes;
- qué datos son personales y de quiénes (y si hay datos sensibles o de menores);
- jurisdicción (¿personas en Chile? ¿responsable establecido en Chile? ¿otra ley aplicable?);
- si existe un SGSI, SGCN o SGC, y qué documentos tiene (riesgos, SoA, BIA, políticas);
- proveedores externos que reciben datos (nube, correo, IdP, APIs de IA).

Lo que no esté, pregúntalo en un solo mensaje con tu supuesto por defecto; si el usuario pide
avanzar, deja los supuestos explícitos en el informe.

## Flujo de trabajo

### Paso 1: Delimitar el alcance

| Alcance | Cómo se obtiene | Qué se reporta |
|---|---|---|
| Diff / PR | `git diff <base>...HEAD` (o el PR) y los archivos que tocan esas líneas | Lo que el cambio **introduce o empeora**. Lo preexistente que se ve al pasar va aparte, en una línea |
| Módulo | La carpeta indicada y sus puntos de entrada (rutas, jobs, consumidores) | Todo lo del módulo |
| Sistema | Repositorio completo + infraestructura como código + CI | Todo, con muestreo declarado si es grande |

Escribe el alcance antes de revisar. Revisión **estática** por defecto; pruebas activas solo con
autorización explícita (ver `auditoria-appsec`).

### Paso 2: Elegir los marcos

Con [references/seleccion-de-marcos.md](references/seleccion-de-marcos.md). Anota por qué entra o
queda fuera cada uno: "22301: fuera, el diff no toca infraestructura ni datos persistentes".

### Paso 3: Mapear la superficie una sola vez

Antes de aplicar cualquier marco: rutas y su credencial, datos que entran y salen (y cuáles son
personales), tablas nuevas o modificadas, dependencias y servicios externos nuevos, cambios de
infraestructura, CI y despliegue. Todos los marcos trabajan sobre este mapa; así no se lee tres
veces el mismo archivo ni se describe tres veces el mismo problema.

### Paso 4: Aplicar cada marco

Por cada marco elegido, carga su habilidad y recorre **su lista de revisión técnica**
(`references/software-y-ti.md` en las normas; la lista de revisión en `auditoria-appsec`) sobre el
mapa del paso 3. Anota hallazgos provisionales con: ubicación, evidencia, causa raíz y la cita del
marco.

Orden recomendado: `auditoria-appsec` → `ley-21719-datos-personales` → `iso-27001-seguridad` →
`iso-22301-continuidad` → `iso-9001-calidad`. Los técnicos primero: los de gestión suelen citar los
mismos problemas y solo agregan su referencia.

Por defecto se ejecuta en esta misma conversación. Si el usuario pide paralelizar, cada marco puede
ir a un subagente (`desarrollo-con-subagentes`) que devuelve hallazgos provisionales en el formato
de arriba; la consolidación siempre la haces tú.

### Paso 5: Consolidar

Con [references/consolidacion.md](references/consolidacion.md):
1. Agrupar por causa raíz: un hallazgo con todas sus ubicaciones y todas sus citas.
2. Asignar la prioridad única P1–P4.
3. Separar lo confirmado de lo que queda "A verificar".
4. Registrar los controles que sí funcionan.

### Paso 6: Entregar

Con [references/plantilla-informe.md](references/plantilla-informe.md). El informe se escribe para
quien tiene que decidir y actuar: resumen ejecutivo corto, tabla priorizada, detalle por hallazgo y
plan. Si el informe se compartirá, ofrece publicarlo o guardarlo como archivo.

## Límites (decirlos una vez en el informe, no en cada hallazgo)

- **No es asesoría legal**: la clasificación de una posible infracción de la Ley 21.719 es
  orientativa; las decisiones de alto impacto se validan con un abogado.
- **No es una auditoría de certificación**: los hallazgos ISO describen brechas en lo revisado, no
  el estado del sistema de gestión completo, que exige entrevistas y registros fuera del código.
- Una revisión de un diff no certifica el resto del sistema.

## Señales de alarma (detente y revisa)

- El mismo problema aparece dos veces con nombres distintos ("logs con RUT" y "control 8.15
  incumplido").
- Un hallazgo sin archivo:línea ni comando que lo muestre.
- Un hallazgo "falta X" cuando X existe de forma global (guard, pipe, middleware, política de CI).
- Una cita de artículo, cláusula o control que no está en la habilidad especializada: no inventar
  numeración; si hay duda, "cita a confirmar".
- Prioridades copiadas de cada marco sin unificar (una "NC menor" que en realidad expone datos de
  todos los usuarios).
- Un informe de diff lleno de problemas preexistentes que no tienen relación con el cambio.
- Datos personales reales o secretos reproducidos en el informe: se describen, no se copian.

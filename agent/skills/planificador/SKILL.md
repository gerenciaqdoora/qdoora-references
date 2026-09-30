---
name: planificador
description: >
  Planificador de implementación para cualquier proyecto de software. Genera SOLO el plan de
  implementación (con TDD, contexto acotado y tareas pequeñas con código real) y se detiene a
  esperar aprobación. Incluye la lista de chequeo de punta a punta (contrato → backend → cliente →
  UI → pruebas) y la puerta de cumplimiento (datos personales, seguridad, continuidad).
  Activar cuando haya un requerimiento claro o un diseño aprobado y el usuario diga: "planifica",
  "haz el plan", "cómo lo implementamos", "arma el plan de implementación", o al aprobar un
  documento de diseño de `brainstorming`. NO activar para ideas difusas (usar
  `brainstorming`) ni para corregir un bug puntual (usar `debugging-sistematico`).
license: MIT
metadata:
  author: francoalvaradot
  version: '2.0'
---

# Planificador

Tu trabajo en esta etapa es **solo planificar**. El plan debe ser tan concreto que otro agente sin
tu contexto pueda ejecutarlo copiando y pegando.

## Estado: ESPERANDO_APROBACIÓN

- **Sí** puedes leer código, buscar y ejecutar comandos de solo lectura para delimitar el contexto.
- **No** modificas archivos del proyecto, salvo el propio documento del plan.
- Al terminar, tu última línea es exactamente:
  `PLAN GENERADO. Esperando aprobación para ejecutar.`

## Perfil del proyecto

Lee primero `CLAUDE.md` / `AGENTS.md` y los archivos de reglas que referencien. De ahí salen el
stack, las capas, los comandos de prueba, el idioma y la carpeta de planes. Si el perfil no define
la carpeta, guarda el plan en `docs/planes/AAAA-MM-DD-<tema>.md`. Las reglas del perfil mandan
sobre cualquier ejemplo de esta habilidad.

## Estructura obligatoria del plan

```markdown
# Plan: <tema>
Fecha · Diseño de origen (si existe)

## Objetivo
Una o dos frases.

## Habilidades a activar
Solo las estrictamente necesarias (ej. arquitectura de backend, base de datos, UI, cumplimiento).

## Contexto acotado (whitelist)
Rutas EXPLÍCITAS de archivos que el ejecutor puede leer o modificar. Nunca directorios completos.

## Advertencias (gotchas)
Restricciones tácticas: qué no tocar, qué patrón existente copiar, trampas conocidas.

## Chequeo de punta a punta
(ver sección siguiente; marcar cada capa como "aplica" o "no aplica, porque...")

## Puerta de cumplimiento
(ver sección siguiente)

## Tareas (TDD)
- [ ] Tarea 1: <nombre> — archivo(s)
  1. Test que falla (código completo)
  2. Comando para verlo fallar y el fallo esperado
  3. Implementación mínima (código completo)
  4. Comando para verlo pasar
- [ ] Tarea 2: ...

## Cierre
Pruebas completas a correr, documentación a actualizar, y revisión final.
```

## Chequeo de punta a punta

Para cada funcionalidad, recorre las capas y declara si aplican. Una capa omitida sin razón es una
falla del plan.

1. **Contrato:** DTO de entrada y salida, códigos de estado, formato de error, paginación.
   Si el proyecto genera tipos desde OpenAPI, incluir el paso de regenerarlos.
2. **Datos:** entidad, restricciones, índices y migración con reversa (apoyarse en la habilidad de
   base de datos si existe).
3. **Backend:** controlador delgado (solo enruta, valida y delega) → servicio con una sola
   responsabilidad → repositorio. Autorización en el servidor: rol y regla por recurso.
4. **Cliente HTTP del frontend:** servicio de la funcionalidad + adaptador que mapea la respuesta al
   modelo de UI. Los componentes nunca llaman HTTP directo.
5. **UI:** estados de carga, vacío y error; qué ve cada rol; accesibilidad.
6. **Pruebas:** unitarias de servicio, E2E del endpoint (incluido el caso sin permiso), pruebas del
   componente.
7. **Operación:** variables de entorno, registros (sin datos personales en claro), métricas.

## Puerta de cumplimiento

Responde tres preguntas. Por cada "sí", agrega al plan los requisitos que entregue la habilidad
indicada (si está instalada) y una tarea que los verifique:

| Pregunta | Habilidad |
|---|---|
| ¿Recolecta, muestra, exporta o registra datos de personas? | `ley-21719-datos-personales` (u otra ley de datos aplicable) |
| ¿Cambia autenticación, permisos, secretos, entradas no confiables o superficie expuesta? | `auditoria-appsec` e `iso-27001-seguridad` |
| ¿Afecta un servicio crítico, sus respaldos, su despliegue o su recuperación? | `iso-22301-continuidad` |

Si las tres respuestas son "no", escríbelo explícitamente en el plan.

## Reglas contra el plan vago

- Prohibidos los marcadores: "implementar la lógica aquí", "TODO", "manejar errores". Cada paso
  lleva el código real.
- Tareas de 2 a 5 minutos. Si una tarea toca más de 3 archivos, divídela.
- Cada tarea nombra el comando exacto de prueba del perfil del proyecto.

## Autoevaluación antes de pausar

- ¿Están todas las secciones obligatorias?
- ¿Cada capa del chequeo de punta a punta está marcada?
- ¿La puerta de cumplimiento está respondida?
- ¿Cada tarea tiene test, comando y código?

Si algo falta, corrígelo antes de presentar el plan.

> **Siguiente paso:** cuando el usuario apruebe, se invoca `ejecutor-plan`. Si hay 3 o más tareas
> independientes, `ejecutor-plan` puede apoyarse en `desarrollo-con-subagentes`.

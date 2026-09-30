---
name: desarrollo-con-subagentes
description: >
  Ejecuta un plan de implementación aprobado delegando cada tarea independiente en un subagente
  nuevo, con revisión por tarea (cumplimiento del plan + calidad) y una revisión final de todo el
  cambio. Genérica para cualquier proyecto. Usar cuando `ejecutor-plan` tenga 3 o más tareas
  mayormente independientes, o cuando el usuario pida paralelizar o usar subagentes. NO usar si las
  tareas están muy acopladas o si el plan no está aprobado.
license: MIT
metadata:
  author: francoalvaradot
  version: '2.0'
---

# Desarrollo con subagentes

**Principio:** un subagente nuevo por tarea + revisión por tarea + revisión final. Tú coordinas y
conservas tu contexto; los subagentes implementan.

## Cuándo sí y cuándo no

- **Sí:** tareas que tocan archivos distintos y no dependen del resultado de otra.
- **No:** tareas encadenadas (la 2 usa lo que crea la 1) o que tocan los mismos archivos. En ese
  caso, ejecútalas en secuencia, o paraleliza solo las ramas independientes.
- Tareas que se pueden paralelizar sin conflicto: aíslalas en worktrees si el entorno lo permite.

## Proceso

1. **Leer el plan** y agrupar las tareas en olas: cada ola contiene solo tareas independientes.
2. **Despachar cada tarea** con un encargo autosuficiente. El subagente no comparte tu memoria,
   así que el encargo debe incluir:
   - el objetivo de la tarea y su criterio de terminado;
   - la whitelist de archivos;
   - las advertencias del plan y las reglas del perfil del proyecto que apliquen (idioma, estilo,
     capas);
   - el ciclo TDD obligatorio y el comando exacto de prueba;
   - qué debe reportar: archivos cambiados, comando ejecutado y su salida, y desviaciones.
3. **Revisar cada resultado:** ¿cumple el plan?, ¿el test falló antes y pasa ahora?, ¿respeta la
   whitelist? Para cambios complejos, despacha un subagente revisor. Si no cumple, se devuelve con
   observaciones concretas, no se arregla "por encima".
4. **Marcar la tarea completada** solo con evidencia de pruebas en verde.
5. **Revisión final** (tú, no un subagente): pruebas completas, compilación y linter de todo lo
   tocado; luego el cierre de `ejecutor-plan` (contratos, seguridad y cumplimiento, documentación).

## Elección de modelo

Usa el modelo más económico que resuelva bien el rol: tareas mecánicas (renombrar, mover, tests
repetitivos) con uno rápido; diseño, seguridad y revisión final con el más capaz.

## Reglas

- Nunca aceptes "listo" sin la salida real de las pruebas.
- Nunca dejes que dos subagentes modifiquen el mismo archivo en la misma ola.
- Si un subagente falla dos veces en la misma tarea, tómala tú con `debugging-sistematico`.

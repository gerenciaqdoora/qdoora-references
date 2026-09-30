---
name: ejecutor-plan
description: >
  Ejecutor de planes aprobados para cualquier proyecto de software. Implementa el plan generado
  por `planificador` tarea por tarea con TDD, respetando el contexto acotado, y cierra con
  verificación completa: pruebas, alineación de contratos, revisión de seguridad y cumplimiento,
  y documentación.
  Activar cuando el usuario apruebe un plan ("aprobado", "dale", "ejecuta el plan", "procede con
  la implementación"). NO activar sin un plan aprobado: en ese caso usar `planificador`.
license: MIT
metadata:
  author: francoalvaradot
  version: '2.0'
---

# Ejecutor de planes

## Estado: EJECUTANDO_PLAN_APROBADO

Solo entras en este estado si existe un plan aprobado. Tu prioridad es implementar exactamente lo
que dice el plan, con pruebas en verde, sin desvíos.

## Reglas de ejecución

1. **Leer el plan primero** y trasladar sus tareas a la lista de tareas de la sesión.
2. **Contexto acotado:** lee y modifica solo los archivos de la whitelist. Si necesitas otro
   (un import, un tipo compartido), puedes leerlo, pero **declara la desviación** en el reporte
   final. Si necesitas *modificar* un archivo fuera de la whitelist, detente y pregunta.
3. **Advertencias primero:** lee y respeta cada advertencia (gotcha) del plan antes de escribir código.
4. **TDD estricto por tarea** (ver `desarrollo-guiado-por-pruebas`): test → verlo fallar por la razón correcta → código
   mínimo → verlo pasar → refactor. Marca cada tarea en progreso y luego completada.
5. **Si el plan está mal** (un test no puede fallar como se describe, una API no existe), no
   improvises un rediseño: detente, explica la discrepancia y propone el ajuste.
6. **Si un test falla y no sabes por qué**, cambia a `debugging-sistematico`. No intentes arreglos
   al azar.
7. **Varias tareas independientes:** puedes delegarlas con `desarrollo-con-subagentes`.

## Cierre obligatorio

Cuando todas las tareas estén completas, en este orden:

1. **Verificación completa:** corre la suite de pruebas, el linter y la compilación de cada parte
   tocada, con los comandos del perfil del proyecto. Reporta el resultado real; si algo falla, dilo.
2. **Alineación de contratos:** los DTO del backend, el documento OpenAPI y los tipos o modelos
   del frontend coinciden. Si el proyecto genera tipos desde OpenAPI, regenéralos y verifica que
   no quede diferencia.
3. **Revisión de seguridad y cumplimiento:** si está instalada, invoca `revision-cumplimiento`
   sobre el diff. Si no, aplica `auditoria-appsec` al diff y los requisitos que haya fijado la
   puerta de cumplimiento del plan.
4. **Documentación viva:** actualiza la memoria o las reglas del proyecto solo si cambiaron
   patrones, decisiones o la arquitectura.

## Reporte final

```markdown
## Resultado
- Tareas: N/N completadas
- Pruebas: <comando> → <resultado>
- Contratos: alineados | diferencias: ...
- Seguridad y cumplimiento: sin hallazgos | hallazgos: ...
- Desviaciones de la whitelist: ninguna | <archivo> (motivo)
- Documentación actualizada: ...
```

Última línea, exacta:
`IMPLEMENTACIÓN COMPLETADA. Esperando revisión.`

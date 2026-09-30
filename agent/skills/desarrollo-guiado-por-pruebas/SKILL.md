---
name: desarrollo-guiado-por-pruebas
description: >
  Desarrollo guiado por pruebas (TDD) para cualquier stack: escribir el test primero, verlo fallar
  por la razón correcta, escribir el código mínimo, verlo pasar y refactorizar. Usar al implementar
  cualquier funcionalidad, corrección de bug, refactor o cambio de comportamiento, ANTES de escribir
  el código de producción. Lo invocan `ejecutor-plan`, `desarrollo-con-subagentes` y
  `debugging-sistematico`.
license: MIT
metadata:
  author: francoalvaradot
  version: '2.0'
---

# Desarrollo guiado por pruebas (TDD)

**Ley de hierro:** `NINGÚN CÓDIGO DE PRODUCCIÓN SIN UN TEST QUE HAYA FALLADO PRIMERO`

Si el código se escribió antes que el test, se borra y se empieza de nuevo. Si no viste el test
fallar por la razón correcta, no sabes si prueba lo que crees.

## Perfil del proyecto

El framework de pruebas, la ubicación de los archivos y los comandos exactos salen del perfil del
proyecto (`CLAUDE.md` / `AGENTS.md` y los archivos de reglas). Referencia rápida si el perfil no
los define:

| Stack | Convención | Un solo archivo |
|---|---|---|
| NestJS (Vitest/Jest) | `*.spec.ts` junto al código; E2E en `test/*.e2e-spec.ts` | `npx vitest run ruta/archivo.spec.ts` |
| Angular (Vitest/Jasmine) | `*.spec.ts` junto al componente | `ng test --include ruta/archivo.spec.ts --watch=false` |
| Python (pytest) | `test_*.py` | `pytest ruta/test_archivo.py -v` |
| Laravel (Pest/PHPUnit) | `tests/Feature`, `tests/Unit` | `php artisan test --filter NombreTest` |

## Ciclo

1. **ROJO:** un test mínimo que describa un comportamiento. Uno a la vez.
2. **Verificar ROJO (obligatorio):** ejecutarlo y confirmar que falla **por la aserción**, no por
   un error de sintaxis, un import o una configuración.
3. **VERDE:** el código más simple que lo haga pasar. Nada "por si acaso".
4. **Verificar VERDE (obligatorio):** el mismo comando, más las pruebas vecinas.
5. **REFACTOR:** eliminar duplicación y mejorar nombres, con las pruebas en verde. Sin
   comportamiento nuevo.

## Qué probar

- **Comportamiento, no implementación:** la interfaz pública, no métodos privados.
- **Casos límite y de error**, no solo el camino feliz: entrada inválida, recurso inexistente,
  **usuario sin permiso**, recurso de otra persona.
- **Endpoints:** al menos un E2E por endpoint nuevo que cubra el éxito, la validación y la
  autorización.
- **Bugs:** el test reproduce el bug antes del arreglo.

## Calidad de los tests

- Nombres descriptivos en el idioma del proyecto: `it('responde 403 si la persona no es dueña de la nota')`.
- Un motivo de falla por test.
- Mocks solo en los bordes (red, reloj, servicios externos). No mockear lo que se está probando.
- Datos de prueba mínimos y explícitos dentro del test.
- Las pruebas nunca tocan bases o servicios reales de desarrollo o producción.

## Señales de alerta

| Pensamiento | Realidad |
|---|---|
| "Es trivial, no necesita test" | Lo trivial también se rompe |
| "Escribo el test después" | Un test escrito después confirma el código, no el requisito |
| "El test pasó a la primera" | Sospechoso: verifica que realmente pueda fallar |
| "Mockeo todo para que sea rápido" | Pruebas que no pueden fallar no sirven |

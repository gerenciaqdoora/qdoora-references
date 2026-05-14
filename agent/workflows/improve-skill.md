# Workflow: Mejora y Evaluación de Skill

Este flujo guía el proceso de auditoría y optimización de una habilidad existente.

## Pasos

- [ ] **Auditoría**: Utilizar `skill-master` para revisar la skill actual contra las mejores prácticas.
- [ ] **Inicialización de Workspace**: Crear el espacio de evaluación para la iteración actual.
  ```bash
  npx ts-node .agents/skills/skill-master/scripts/init-eval-workspace.ts --skill=nombre-skill --iter=1
  ```
- [ ] **Línea Base (Baseline)**: Ejecutar los prompts de `evals/evals.json` SIN la skill y guardar en `without_skill/`.
- [ ] **Evaluación con Skill**: Ejecutar los mismos prompts CON la skill y guardar en `with_skill/`.
- [ ] **Calificación y Benchmarking**: Evaluar aserciones, capturar tokens/tiempo y calcular el **Delta** de mejora.
- [ ] **Plan de Mejora**: Proponer cambios en `SKILL.md` basados en los fallos y la comparativa de métricas.
- [ ] **Ejecución y Re-evaluación**: Aplicar cambios y ejecutar una nueva iteración para validar la mejora del Delta.
- [ ] **Sincronización**: Una vez validada la mejora, actualizar los activos en el entorno operativo.
  ```bash
  bash qdoora-references/agent/scripts/update-agent-assets.sh
  ```

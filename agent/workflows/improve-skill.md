# Workflow: Mejora y Evaluación de Skill

Las skills de `agent/skills/` se publican desde suite-agents: **no se editan en `qdoora-references`** (el siguiente publicado se detiene o las sobrescribe).

## Si trabajas con suite-agents

- [ ] **Auditoría**: Revisar la skill en `suite-agents/qdoora/` o `suite-agents/universales/` con `skill-creator`.
- [ ] **Línea Base**: Ejecutar sus evals antes del cambio:
  ```bash
  scripts/evals.py correr <skill>
  ```
- [ ] **Plan de Mejora**: Proponer cambios en `SKILL.md` a partir de los casos que fallan.
- [ ] **Re-evaluación**: Aplicar los cambios y volver a correr los evals; agregar un caso si la mejora cubre algo nuevo.
- [ ] **Commit y publicación**: Commitear en suite-agents, ejecutar `scripts/publicar-qdoora.sh` y commitear el resultado en `qdoora-references`.
- [ ] **Sincronización**:
  ```bash
  bash qdoora-references/agent/scripts/update-agent-assets.sh
  ```

## Si no trabajas con suite-agents

- [ ] Describir el problema (prompt, respuesta obtenida y respuesta esperada) en un issue o PR de `qdoora-references`; se corrige en el origen y se republica.

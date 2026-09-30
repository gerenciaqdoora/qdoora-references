# Workflow: Creación de Nueva Skill

Las skills de QdoorA **no se crean en `qdoora-references`**: todas se publican desde la biblioteca suite-agents (ver `agent/ORIGEN.md` y `AGENT_BASE.md`, "SKILLS PUBLICADAS").

## Si trabajas con suite-agents

- [ ] **Investigación Inicial**: Revisar `rules/SKILLS.md` y buscar con `find-skills` para evitar duplicidad.
- [ ] **Ubicación**: Skill de negocio de QdoorA → `suite-agents/qdoora/qdoora-<nombre>/`. Skill sin dependencia de proyecto → `suite-agents/universales/<nombre>/`.
- [ ] **Desarrollo**: Crear `SKILL.md` y sus evals (`evals/evals.json`, mínimo 3 casos) con `skill-creator`.
- [ ] **Validación**: En suite-agents, `scripts/evals.py validar`.
- [ ] **Commit y publicación**: Commitear en suite-agents y ejecutar `scripts/publicar-qdoora.sh`; luego commitear el resultado en `qdoora-references`.
- [ ] **Catastro**: Registrar la skill en `rules/SKILLS.md` (esto sí se edita en `qdoora-references`).
- [ ] **Sincronización**:
  ```bash
  bash qdoora-references/agent/scripts/update-agent-assets.sh
  ```

## Si no trabajas con suite-agents

- [ ] Proponer la skill (propósito, disparadores y ejemplos de uso) en un issue o PR de `qdoora-references`; se crea en el origen y se publica.

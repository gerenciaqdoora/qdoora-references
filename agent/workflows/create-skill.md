# Workflow: Creación de Nueva Skill

Este flujo guía el proceso de creación de una nueva habilidad siguiendo los estándares de arquitectura de QdoorA.

## Pasos

- [ ] **Investigación Inicial**: Buscar coincidencias con la habilidad global `find-skills` para evitar duplicidad.
- [ ] **Conceptualización**: Utilizar `skill-creator` para definir la lógica base y el propósito.
- [ ] **Scaffolding**: Utilizar `skill-master` para generar la estructura de carpetas en `qdoora-references/agent/skills`.
  ```bash
  npx ts-node .agents/skills/skill-master/scripts/scaffold-skill.ts --name mi-nueva-skill
  ```
- [ ] **Desarrollo**: Escribir las instrucciones en `SKILL.md` y crear scripts/assets necesarios.
- [ ] **Validación Técnica**: Validar que la skill cumpla con los estándares técnicos y el frontmatter.
  ```bash
  npx ts-node .agents/skills/skill-master/scripts/validate-skill.ts --path .agents/skills/mi-nueva-skill
  ```
- [ ] **Refinamiento**: Corregir hallazgos y repetir validación si es necesario.
- [ ] **Sincronización**: Desplegar los cambios al entorno operativo del agente.
  ```bash
  bash qdoora-references/agent/scripts/update-agent-assets.sh
  ```

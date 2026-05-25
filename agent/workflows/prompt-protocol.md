---
trigger: always_on
glob: "**/*"
description: Protocolo de Secuencia Obligatoria Agunsa (Refinamiento -> Ejecución -> Auditoría)
---

# 🔄 AGUNSA SEQUENCE WORKFLOW PROTOCOL

**REGLA INQUEBRANTABLE:** Nunca debes escribir código fuente ni realizar modificaciones inmediatamente después del primer mensaje del usuario. Debes seguir este diagrama de secuencia de forma estricta.

# 🛑 BLOQUEO DE EJECUCIÓN (ANTI-TOOL DIRECTIVE) 🛑
ESTÁ ESTRICTAMENTE PROHIBIDO ejecutar comandos de terminal (bash, find, ls, grep), escribir archivos o realizar búsquedas en el workspace ANTES de completar la Fase 1.

Cuando recibas un requerimiento del usuario, DEBES:
1. BLOQUEAR el uso de herramientas de ejecución/exploración.
2. Consultar silenciosamente la skill `prompt-architect-master`.
3. Imprimir el **Master Prompt Refinado** (Objetivo, Skills, Plan, Sincronización, Auditoría).
4. **DETENERTE** y esperar a que el usuario escriba "Aprobado".

---

## Fase 1: Refinamiento (Pausa Obligatoria)
1. Recibes el requerimiento o idea (Draft).
2. Activas la skill [prompt-architect-master](../skills/prompt-architect-master/SKILL.md).
3. Entregas el **Master Prompt Refinado** siguiendo el formato estricto de la skill.
4. **TE DETIENES** y preguntas al usuario: *"¿Apruebas este Master Prompt para comenzar la ejecución?"*.

## Fase 2: Ejecución y Blindaje (Solo tras la aprobación)
1. **Orquestación de Expertos**: Invocas a las skills de dominio necesarias (ej. `gemini-system-expert`, `inspecciones-expert`, `rms-system-expert`).
2. **Alineación de Contratos**: Usas la skill [api-contract-aligner](../skills/api-contract-aligner/SKILL.md) para asegurar que el `requestBody` y los schemas en `SchemaRegistry` sean íntegros.
3. **Auditoría (Guardián)**: Antes de dar por terminada la tarea, pasas el código por la skill [security-remediation-expert](../skills/security-remediation-expert/SKILL.md) para verificar:
    - Aplicación de middleware de seguridad (Defensa en Profundidad).
    - Prevención de vectores QD (BFLA, IDOR, XSS).
    - Paridad con el despliegue en AWS ECS (Modo bridge).

## Fase 3: Entrega y Documentación
- Entregas el código validado.
- Actualizas el `walkthrough.md` y `task.md`.
- Propones puntos de control para la próxima sesión de auditoría.

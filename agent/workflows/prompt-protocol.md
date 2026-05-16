---
trigger: always_on
glob: '**/*'
description: Protocolo de Secuencia Obligatoria (Refinamiento -> Ejecución -> Auditoría)
---

# 🔄 QDOORA SEQUENCE WORKFLOW PROTOCOL

**REGLA INQUEBRANTABLE:** Nunca debes escribir código fuente inmediatamente después del primer mensaje del usuario (a menos que sea una corrección menor). Debes seguir este diagrama de secuencia:

# 🛑 BLOQUEO DE EJECUCIÓN (ANTI-TOOL DIRECTIVE) 🛑

ESTÁ ESTRICTAMENTE PROHIBIDO ejecutar comandos de terminal (bash, find, ls, grep), leer archivos o buscar en el workspace ANTES de completar la Fase 1.

Cuando recibas un prompt del usuario, DEBES:

1. BLOQUEAR el uso de cualquier herramienta de exploración de código.
2. Leer silenciosamente la skill `prompt-architect-master`.
3. Imprimir en pantalla el "Master Prompt Refinado" (Objetivo, Skills, Plan, Seguridad).
4. DETENERTE y esperar a que el usuario escriba "Aprobado".

## Fase 1: Refinamiento (Pausa Obligatoria)

1. Recibes la idea del usuario.
2. Activas silenciosamente `prompt-architect-master/SKILL.md`.
3. Entregas el **Master Prompt Refinado** (Plan de acción).
4. **TE DETIENES** y preguntas al usuario: _"¿Apruebas este Master Prompt para comenzar la ejecución?"_.

## Fase 2: Ejecución y Blindaje (Solo tras la aprobación del usuario)

1. **Orquestación:** Activas el `erp-skills-orchestrator.md` para invocar a los constructores (ej: `erp-accounting-expert`).
2. **Construcción:** Generas el código asegurando la alineación de interfaces con `api-contract-aligner`.
3. **Auditoría (Guardián):** Antes de entregar la respuesta final, pasas el código internamente por `qdoora-quality-security-guardian.md` para asegurar que no hay vulnerabilidades QD-XX, ni violaciones a la arquitectura stateless (AWS).

## Fase 3: Entrega

- Entregas el código validado.
- Invocas al `technical-scribe-logic.md` proponiendo qué registrar en la documentación.

## Fase 4: Documentación de Conocimiento (Cierre)

1. **Detección**: El Scribe analiza la sesión y genera el bloque de conocimiento (Draft).
2. **Autorización**: El usuario aprueba con un comando simple ("Ok", "Aprobado").
3. **Persistencia**: El Scribe actualiza los archivos `rules/*.md` inmediatamente.

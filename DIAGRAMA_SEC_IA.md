# Evolución de la Interacción con IA en QdoorA

Este documento detalla la transición desde el uso básico de IA hasta el **Ecosistema Agentico** de QdoorA, basado en el uso de **Rules, Skills y Workflows**.

---

### 🔴 Nivel 1: Desarrollo Ad-hoc (Caos sin Estructura)

En este nivel, la IA funciona de manera genérica. No hay conocimiento del proyecto, estándares de seguridad ni arquitectura. Por lo general es el uso que se le da cuando se conoce la herramienta.

```mermaid
sequenceDiagram
    autonumber
    actor U as 👤 Usuario (Developer)
    participant IA as 🤖 IA Genérica (LLM)
    U->>IA: Prompt Crudo (ej: "Haz un endpoint de facturación")
    IA-->>U: Propuesta de Plan / Enfoque Inicial
    Note over U: Usuario revisa o pide ajustes (Iteración básica)
    IA-->>U: Código Genérico (Boilerplate)
    Note over U: Resultado: Código "huérfano", sin multitenant,<br/>vulnerable y fuera de estándares.
    U->>U: Debugging manual e iteración por ensayo y error.
```

---

### 🟡 Nivel 2: Chat Convencional (Contexto Manual)

La IA actúa como "Copiloto". El desarrollador intenta inyectar contexto copiando y pegando archivos o reglas. Es un proceso frágil y dependiente del humano. Practicamente es un prompt refinado por otro modelo de IA con algo de contexto que es lo que nosotros le entregamos.

```mermaid
sequenceDiagram
    autonumber
    actor U as 👤 Usuario (Developer)
    participant IA as 🤖 IA con Contexto (Manual)
    U->>IA: Prompt + Código copiado/pegado manualmente
    IA-->>U: Plan de Implementación (Basado en contexto manual)
    Note over U: Usuario itera o aprueba el plan de la IA
    IA-->>U: Código adaptado al estilo visible
    Note over U: Resultado: Mejor calidad, pero lento y propenso a<br/>errores humanos de omisión técnica.
    U->>U: Revisión manual exhaustiva de seguridad y arquitectura.
```

---

### 🔵 Nivel 3: Ejecución Protocolizada (Sin Refinamiento)

El usuario utiliza las herramientas de QdoorA (**Workflows, Rules y Skills**) directamente. Se incluye el hito de validación del plan técnico y el ciclo de aprendizaje al finalizar la tarea.

```mermaid
sequenceDiagram
    autonumber
    actor U as 👤 Usuario (Developer)
    participant W as 🚥 Workflow (Protocolo)
    participant R as 📜 Reglas (Contexto)
    participant S as 🧠 Skills (Expertos)
    participant G as 🛡️ Guardián (Seguridad)

    U->>W: Dispara Comando / Workflow Directo
    W->>R: Inyecta Contexto (.md Rules)
    W->>S: Activa Skills Expertas (Back/Front)
    
    W-->>U: Propone Plan de Implementación Técnico
    Note over U: El usuario revisa, comenta o itera el plan
    U->>W: Aprobación Humana para Ejecutar

    rect rgb(245, 245, 245)
        Note over S: Ejecución y Sincronización
        S->>S: Aligner: Sincronización API Contract
    end

    S->>G: Entrega para Auditoría Final
    G->>G: Validación de Vectores QD-01 a QD-11
    G-->>W: Visto Bueno (Certificación de Seguridad)
    
    W-->>U: Entrega de Código + Walkthrough
    
    U->>S: Activa Scribe (Technical Documentarian)
    S-->>R: Evoluciona las Reglas (Feedback Loop)
    Note over R: Living Documentation: Actualización del conocimiento
```

---

### 🟢 Nivel 4: Ecosistema Agentico (Ciclo Completo)

Es el nivel de madurez absoluta. El sistema activa el protocolo `/qdoora-workflow-protocol` desde el inicio, asegurando que la estrategia sea perfecta antes de la ejecución.

```mermaid
sequenceDiagram
    autonumber
    actor U as 👤 Usuario (Estrategia)
    participant W as 🚥 Workflow (Protocolo)
    participant PA as 📐 Prompt Architect (Skill)
    participant R as 📜 Reglas (Contexto)
    participant S as 🧠 Skills (Expertos)
    participant G as 🛡️ Guardián (Seguridad)

    U->>W: Idea Inicial (Dispara /qdoora-workflow-protocol)
    
    rect rgb(240, 248, 255)
        Note over W, PA: Fase 1: Refinamiento (Pausa Obligatoria)
        W->>PA: Activa Prompt Architect Master
        PA->>R: Consulta Reglas y Estándares de Arquitectura
        PA-->>U: Entrega "Master Prompt" Refinado + Plan Estratégico
        Note over U: Usuario revisa, ajusta o aprueba (Hito Crítico)
    end

    U->>W: "Aprobado" (Inicia Fase 2: Ejecución)

    W->>S: Orquesta Skills Expertas y Reglas de Dominio
    
    W-->>U: Propone Plan de Implementación Técnico
    Note over U: Validación de archivos y cambios específicos
    U->>W: Aprobación Humana de Ejecución Final

    rect rgb(245, 245, 245)
        Note over S: Construcción y Alineación
        S->>S: Sincronización de Contratos API (Laravel <=> Angular)
    end

    S->>G: Entrega para Auditoría (Fase 2: Blindaje)
    G->>G: Validación de Vectores QD-01 a QD-11 (Hacking/IAM)
    G-->>W: Visto Bueno (Certificación de Seguridad OK)

    Note over W, U: Fase 3: Entrega
    W-->>U: Entrega Final de Código + Walkthrough

    U->>S: Activa Scribe (Technical Documentarian)
    S-->>R: Evoluciona las Reglas (Learning Loop)
    Note over R: Living Documentation: El sistema aprende y se fortalece
```

---

### 🚀 ¿Por qué el Nivel 4 es superior?

La diferencia fundamental radica en el **Doble Check Humano** y la **Prevención**:
*   **Planificación Estratégica**: Mientras que en el Nivel 1 y 2 el plan es una "sugerencia" de la IA, en el Nivel 4 el plan es el resultado de auditar las **Rules** de QdoorA, lo que garantiza que el enfoque sea el correcto antes de escribir una sola línea.
*   **Orquestación desde el Inicio**: En el Nivel 4, el **Workflow** es quien manda, asegurando que se cumplan todas las fases (Refinamiento, Ejecución, Blindaje).
*   **Fases Estancas**: Separa el "Pensar" (Fase 1) del "Hacer" (Fase 2), eliminando errores por impulsividad de la IA.

---

### 📈 Mejora por Fases de Implementación (Workflow Protocol)

| Fase              | Beneficio del Protocolo QdoorA                    | Impacto en el Modelo de IA                                           |
| :---------------- | :------------------------------------------------ | :------------------------------------------------------------------- |
| **Refinamiento**  | Activación de **Prompt Architect** vía Workflow.  | Bloquea la ejecución prematura y refina la intención estratégica.    |
| **Validación**    | **Hito de Aprobación Obligatorio** (Fase 1).      | Asegura alineación total entre humano e IA antes de gastar recursos. |
| **Ejecución**     | Orquestación de **Skills** especializadas.        | Genera código de alta calidad basado en el Master Prompt aprobado.   |
| **Blindaje**      | Auditoría ofensiva del **Guardián** (Fase 2).     | Garantiza inmunidad ante vectores QD-01 a QD-11.                     |
| **Entrega**       | Documentación técnica vía **Scribe** (Fase 3).     | Cierra el círculo con aprendizaje automático de patrones nuevos.      |

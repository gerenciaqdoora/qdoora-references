# Principios y conceptos fundamentales

Fuentes conceptuales: ISO 22301 (requisitos), ISO 22313 (guía), ISO 22300 (vocabulario),
ISO 22316 (resiliencia organizacional).

## Propósito del SGCN

Proteger contra, reducir la probabilidad de, prepararse para, responder a y recuperarse de
**disrupciones**, para que la organización siga entregando sus productos y servicios en
**plazos y capacidades aceptables** durante y después de una disrupción.

## Ciclo de vida de la continuidad del negocio

```
         ┌────────── Programa: política, alcance, roles, recursos (4–7) ──────────┐
         │                                                                        │
  1. Análisis ──► 2. Diseño ──► 3. Implementación ──► 4. Validación ──┐           │
  BIA + riesgos    estrategias     planes y            ejercicios y     │           │
  (8.2)            y soluciones    estructura de       evaluación       │           │
                   (8.3)           respuesta (8.4)     (8.5, 8.6)       │           │
         ▲                                                              │           │
         └──────────── mejora (9, 10) ◄─────────────────────────────────┘           │
         └────────────────────────── integrado en la organización ──────────────────┘
```

## Métricas de tiempo y capacidad (ISO 22300 / 22313 / 22317)

| Término | Pregunta que responde | Ejemplo |
|---------|----------------------|---------|
| **MTPD** — Período máximo tolerable de interrupción | ¿Después de cuánto tiempo sin la actividad el impacto se vuelve **inaceptable**? | Facturación: 5 días hábiles. |
| **RTO** — Objetivo de tiempo de recuperación | ¿En cuánto tiempo **debemos** reanudar la actividad (a capacidad mínima)? Debe ser **< MTPD** con margen. | Facturación: 2 días. |
| **MBCO** — Objetivo mínimo de continuidad del negocio | ¿Qué **capacidad mínima** aceptable debemos entregar durante la disrupción? | 60% del volumen, solo clientes críticos. |
| **RPO** — Objetivo de punto de recuperación | ¿Cuántos **datos** (medidos en tiempo) podemos perder? | 1 hora de transacciones. |
| **Actividades prioritarias** | Actividades a las que se da prioridad tras un incidente para mitigar impactos. | Soporte a clientes críticos, nómina. |
| **Plazo priorizado** (22301:2019 §8.2.2 e) | Término de la norma que operativamente corresponde al RTO. | — |

Regla: `RTO (proceso) ≤ MTPD` y `RTO (sistema TIC que lo soporta) ≤ RTO (proceso)`. El RPO de un
sistema debe cumplir el del proceso más exigente que lo usa.

## Tipos de planes (vocabulario práctico)

| Plan | Propósito | Horizonte |
|------|-----------|-----------|
| Respuesta a emergencias | Proteger vidas y bienes (evacuación, primeros auxilios). | Minutos |
| Gestión de incidentes / crisis | Evaluar, escalar, decidir, comunicar a nivel estratégico. | Horas–días |
| Continuidad del negocio (BCP) | Mantener/reanudar actividades prioritarias con soluciones alternas. | Horas–semanas |
| Recuperación ante desastres TIC (DRP) | Restaurar sistemas e información dentro de RTO/RPO. | Horas–días |
| Recuperación / retorno a la normalidad | Volver de las medidas temporales a la operación habitual. | Días–meses |

ISO 22301 no exige estos nombres; exige que **en conjunto** los planes cubran lo de §8.4.

## Principios de diseño

- **Seguridad de las personas primero.**
- **Basado en el impacto, no en la causa:** planificar por *pérdida de recursos* (personas, sitio, TIC, proveedor, información) cubre muchos escenarios con pocas soluciones.
- **Proporcionalidad:** la solución cuesta en proporción al impacto que evita.
- **Simplicidad bajo estrés:** planes cortos, listas de verificación, roles claros.
- **Disponibilidad del plan:** accesible sin los sistemas afectados.
- **Validación continua:** lo no ejercitado no se considera capacidad.
- **Resiliencia** (ISO 22316): la continuidad es parte de la capacidad más amplia de absorber y adaptarse.

## Vocabulario clave (ISO 22300)

| Término | Significado operativo |
|---------|----------------------|
| **Disrupción** | Incidente, previsto o no, que causa una desviación negativa no planificada de la entrega esperada. |
| **Incidente** | Evento que puede ser, o conducir a, una disrupción, pérdida, emergencia o crisis. |
| **Crisis** | Situación inestable con alto nivel de incertidumbre que afecta objetivos centrales y requiere acción urgente. |
| **BIA** | Proceso de analizar el impacto de una disrupción en la organización a lo largo del tiempo. |
| **Estrategia** | Enfoque para asegurar la recuperación y continuidad ante una disrupción. |
| **Solución** | Medio concreto que implementa la estrategia (sitio alterno, acuerdo con proveedor, réplica). |
| **Ejercicio** | Proceso para entrenar, evaluar, practicar y mejorar el desempeño. |
| **Prueba** | Ejercicio con criterio de aprobación/fallo (p. ej., restauración dentro de RPO). |
| **Parte interesada** | Persona u organización que puede afectar, verse afectada o percibirse afectada. |

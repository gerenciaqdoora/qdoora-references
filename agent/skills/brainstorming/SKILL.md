---
name: brainstorming
description: >
  Diseño colaborativo antes de implementar. Explora la intención del usuario, los
  requerimientos y las alternativas de diseño ANTES de tocar código o invocar
  `prompt-architect-master`. Activa cuando el usuario tiene una idea no formada,
  un requerimiento ambiguo, o necesita explorar opciones antes de comprometerse
  con un enfoque.

  Activar cuando el usuario diga: "quiero hacer...", "tengo una idea para...",
  "necesito pensar en...", "no sé cómo enfocar...", "¿cómo deberíamos...?",
  "ayúdame a diseñar...", o cualquier petición donde NO está claro aún QUÉ
  construir exactamente. NO activar cuando el requerimiento ya es específico y
  claro — en ese caso ir directo a `prompt-architect-master`.
---

# Brainstorming — QdoorA Edition

Conviertes ideas en diseños concretos a través de diálogo colaborativo. Tu salida es un documento de diseño aprobado que sirve como entrada para `prompt-architect-master`.

## ⛔ HARD GATE

**NO invoques ninguna skill de implementación, no escribas código, no crees archivos de código, no ejecutes comandos** hasta que hayas presentado un diseño y el usuario lo haya aprobado explícitamente. Sin excepción, sin importar cuán simple parezca el requerimiento.

---

## Checklist Obligatorio (en orden)

- [ ] **1. Explorar contexto del proyecto** — Leer archivos relevantes, últimos commits, módulos relacionados en QdoorA
- [ ] **2. Preguntas de clarificación** — Una a la vez, entender propósito, restricciones, criterios de éxito
- [ ] **3. Proponer 2-3 enfoques** — Con trade-offs y recomendación fundamentada
- [ ] **4. Presentar diseño** — Por secciones, obtener aprobación de cada sección
- [ ] **5. Escribir documento de diseño** — Guardar en `docs/designs/YYYY-MM-DD-<tema>.md`
- [ ] **6. Auto-revisión del spec** — Verificar placeholders, contradicciones, ambigüedad
- [ ] **7. Revisión del usuario** — Esperar aprobación explícita antes de continuar
- [ ] **8. Transición** — Invocar `prompt-architect-master` para generar el plan de implementación

**El estado terminal es invocar `prompt-architect-master`.** No invoques ninguna otra skill de construcción.

---

## Proceso

### Entendiendo la idea

Antes de preguntar detalles, evaluar el alcance general:
- ¿El requerimiento describe múltiples subsistemas independientes? Flagear inmediatamente y ayudar a descomponer en sub-proyectos secuenciales.
- ¿Hay módulos QdoorA ya existentes que resolver esto? Buscar en el codebase antes de proponer algo nuevo.
- ¿Cuál es el dominio de negocio? (Nómina, Contabilidad, Aduana, Facturación, etc.) — invocar el expert de dominio si es necesario para validar las reglas de negocio.

Preguntas: de a una. Preferir opciones múltiples cuando es posible. Enfocarse en:
- **Propósito**: ¿Qué problema de negocio resuelve?
- **Restricciones**: ¿Multitenant? ¿Inmutabilidad histórica? ¿Portal Cliente o Soporte?
- **Criterio de éxito**: ¿Cómo se sabe que está bien implementado?

### Explorando enfoques

Proponer 2-3 alternativas con:
- Trade-offs reales (tokens, mantenibilidad, riesgo multi-tenant)
- Recomendación propia con justificación
- Señalar si algún enfoque viola las Hard Reject rules del AGENT_BASE.md

### Presentando el diseño

Una vez entendido el requerimiento, presentar el diseño por secciones:
- **Arquitectura**: ¿Qué capas se tocan? (Servicio, FormRequest, Controller, Resource, Migraciones, Angular)
- **Flujo de datos**: Request → Validación → Servicio → BD → Resource → Frontend
- **Contrato API**: Endpoints, payloads, respuestas (para `api-contract-aligner`)
- **Consideraciones de seguridad**: Multitenancy, permisos, vectores QD afectados
- **Tests**: Qué debe cubrirse con Pest/Vitest antes de entregar

Pedir aprobación después de cada sección: *"¿Esto tiene sentido hasta acá?"*

---

## Documento de Diseño

Guardar el diseño aprobado en `docs/designs/YYYY-MM-DD-<tema>.md` con esta estructura:

```markdown
# Diseño: [Nombre del Feature]
**Fecha**: YYYY-MM-DD | **Portal**: [Cliente/Soporte/API/Full-Stack]

## Problema de Negocio
[Qué resuelve y por qué importa]

## Enfoque Seleccionado
[Cuál de los 3 enfoques se eligió y por qué]

## Arquitectura
[Capas afectadas, componentes nuevos, componentes modificados]

## Contrato API
[Endpoints, FormRequest fields, Resource shape]

## Consideraciones de Seguridad
[Multitenancy, permisos, vectores QD relevantes]

## Criterios de Aceptación
[Lista de comportamientos verificables]
```

### Auto-revisión del spec antes de presentarlo

1. ¿Hay algún "TBD", "TODO" o sección incompleta? → Completar.
2. ¿Alguna sección contradice otra? → Resolver.
3. ¿El alcance es manejable para un solo plan de implementación? → Si no, descomponer.
4. ¿Algún requerimiento puede interpretarse de dos formas? → Elegir uno y explicitarlo.

---

## Transición a Implementación

Una vez que el usuario aprueba el documento de diseño:

```
"Documento guardado en docs/designs/YYYY-MM-DD-<tema>.md.
¿Lo revisas y me confirmas que podemos proceder?
Una vez aprobado, invocaré prompt-architect-master para generar el plan de implementación."
```

Esperar respuesta. Solo tras aprobación explícita: **invocar `prompt-architect-master`**.

---

## Principios

- **Una pregunta a la vez** — No abrumar con listas de preguntas
- **YAGNI sin piedad** — Eliminar de los diseños todo lo que no sea estrictamente necesario
- **Respetar los dominios de negocio** — Siempre validar con el expert de dominio relevante (erp-nomina-expert, erp-accounting-expert, etc.) antes de proponer lógica de negocio
- **Separación de portales** — Siempre identificar si el feature es para Portal Cliente (Angular 18, fuse-starter) o Portal Soporte (Angular 21, Zoneless), ya que las reglas son distintas

---

> **Flujo QdoorA**: `brainstorming` → diseño aprobado → `prompt-architect-master` → plan aprobado → `prompt-executor-master` → implementación
>
> **Skills de dominio para validar reglas de negocio**: `erp-nomina-expert` · `erp-accounting-expert` · `erp-customs-expert` · `erp-electronic-invoicing-expert` · `erp-global-parameters-expert`

---
name: brainstorming
description: >
  Diseño colaborativo antes de implementar, para cualquier proyecto de software. Explora la
  intención, los requisitos y las alternativas de diseño ANTES de tocar código o de planificar,
  y termina en un documento de diseño aprobado que alimenta a `planificador`.
  Activar cuando el usuario diga: "quiero hacer...", "tengo una idea para...", "necesito pensar
  en...", "no sé cómo enfocar...", "¿cómo deberíamos...?", "ayúdame a diseñar...", o cuando no
  esté claro QUÉ construir. NO activar si el requerimiento ya es específico: en ese caso ir
  directo a `planificador`.
license: MIT
metadata:
  author: francoalvaradot
  version: '2.0'
---

# Brainstorming

Convierte una idea difusa en un diseño acordado. En esta etapa **no se escribe código, no se
crean archivos de producción y no se ejecutan comandos que modifiquen el proyecto**. Leer el
código para entender el contexto sí está permitido y es obligatorio.

## Perfil del proyecto

Antes de empezar, lee el perfil del proyecto: `CLAUDE.md` / `AGENTS.md` en la raíz y los archivos
de reglas que referencien (arquitectura, reglas de backend y frontend, memoria del proyecto). De
ahí salen el stack, las capas, el idioma y dónde se guardan los documentos de diseño. Si el perfil
no define la ruta, usa `docs/disenos/AAAA-MM-DD-<tema>.md`.

## Flujo

- [ ] **1. Explorar el contexto:** archivos relacionados, últimos commits, módulos que ya resuelvan
  algo parecido. Buscar antes de proponer algo nuevo.
- [ ] **2. Preguntar de a una:** una pregunta por mensaje, en orden de impacto. Preferir preguntas
  cerradas con opciones cuando sea posible. Parar cuando se entienda el propósito, los usuarios,
  las restricciones y el criterio de éxito.
- [ ] **3. Proponer 2 o 3 enfoques** con sus ventajas y desventajas, y **recomendar uno** con la razón.
- [ ] **4. Presentar el diseño por secciones**, validando cada una antes de seguir (ver abajo).
- [ ] **5. Escribir el documento de diseño** y pedir aprobación explícita.
- [ ] **6. Transición:** con el diseño aprobado, invocar `planificador`. Nunca saltar a implementar.

## Preguntas que no pueden faltar

- ¿Qué problema resuelve y para quién? ¿Cómo sabremos que funcionó?
- ¿Qué parte del dominio toca? Si el proyecto tiene una habilidad de dominio, consultarla para no
  inventar reglas de negocio.
- ¿Trata **datos personales**, afecta la **disponibilidad** de un servicio crítico o cambia
  **permisos**? Si la respuesta es sí, anotarlo: el plan tendrá que pasar la puerta de cumplimiento.
- ¿Qué pasa con los datos existentes? (migración, compatibilidad hacia atrás)

## Secciones del diseño

1. **Arquitectura:** capas y módulos que se tocan, según el perfil del proyecto.
2. **Flujo de datos:** petición → validación → servicio → persistencia → respuesta → UI.
3. **Contrato de API:** endpoints, cuerpos, respuestas y errores. Cambios compatibles o no.
4. **Datos:** entidades, relaciones y migraciones (si aplica, apoyarse en la habilidad de base de datos).
5. **Seguridad y cumplimiento:** autenticación, autorización (roles y reglas por recurso), datos
   personales, registros de auditoría.
6. **UX:** estados de carga, vacío y error; qué ve cada rol.
7. **Pruebas:** qué comportamiento debe quedar cubierto.
8. **Fuera de alcance:** lo que explícitamente no se hará.

## Plantilla del documento

```markdown
# Diseño: <tema>
Fecha: AAAA-MM-DD · Estado: borrador | aprobado

## Problema y criterio de éxito
## Enfoques considerados (y el elegido, con la razón)
## Arquitectura
## Contrato de API
## Datos
## Seguridad y cumplimiento
## UX
## Pruebas
## Fuera de alcance
## Preguntas abiertas
```

## Principios

- **YAGNI:** quitar todo lo que no sea necesario para el criterio de éxito.
- **Una pregunta a la vez.** Nunca un cuestionario de diez puntos.
- **Recomendar, no enumerar:** siempre decir qué opción conviene y por qué.
- **Respetar lo existente:** si el proyecto ya tiene un patrón para esto, seguirlo o justificar el cambio.

> **Flujo:** `brainstorming` → diseño aprobado → `planificador` → plan aprobado → `ejecutor-plan`

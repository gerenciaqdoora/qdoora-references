# Mejores Prácticas para Agent Skills

## 1. El Principio de la Divulgación Progresiva
No abrumes al agente con toda la información de una vez. Estructura la skill para que el agente sepa que existe información detallada en archivos de referencia si la necesita.

## 2. Redacción de Instrucciones (Prompt Engineering)
- **Sé prescriptivo**: Usa verbos imperativos ("Haz", "Crea", "Valida").
- **Evita la ambigüedad**: Define exactamente qué herramientas usar y en qué orden.
- **Contexto Justo**: No repitas lo que ya está en el sistema de prompts global. Concéntrate en el dominio específico de la skill.

## 3. Manejo de Errores (Gotchas)
Identifica los fallos comunes que el agente comete en este dominio y crea una sección explícita de "Cosas que NO debes hacer" o "Errores comunes".

## 4. Salida Estructurada
Siempre pide al agente que genere una salida predecible. Usa plantillas de Markdown o JSON para que el resultado sea procesable por otros scripts o fácil de revisar para el usuario.

## 5. Scripts Autónomos
Si una tarea requiere más de 3 comandos de shell complejos, crea un script en la carpeta `scripts/`. Esto reduce la probabilidad de errores sintácticos en la ejecución del agente.

## 6. Optimización de Descripciones
La activación de una skill depende casi exclusivamente del campo `description` en el frontmatter.
- **Enfoque en la Intención**: Describe QUÉ quiere lograr el usuario, no CÓMO lo hace la skill.
- **Evitar Solapamiento**: Si dos skills tienen descripciones similares, el agente puede confundirse. Sé específico.
- **Iteración Basada en Evals**: Si la skill no se activa con un prompt esperado, añade palabras clave de ese prompt a la descripción.
- **División Train/Test**: Prueba tus cambios con un conjunto de prompts (Train) y valida con otros nuevos (Test).

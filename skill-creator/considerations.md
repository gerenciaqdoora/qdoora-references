# Consideraciones de Reglas y Workflows

Una **Regla (Rule)** es simplemente un archivo Markdown donde puedes ingresar restricciones para guiar al Agente según tus tareas, stack tecnológico y estilo.

### Activación de Reglas

A nivel de regla, puedes definir cómo debe activarse:

- **Manual**: La regla se activa manualmente mediante una mención (`@`) en el cuadro de entrada del Agente.
- **Always On (Siempre activa)**: La regla se aplica siempre.
- **Model Decision (Decisión del modelo)**: Basándose en una descripción en lenguaje natural de la regla, el modelo decide si aplicarla.
- **Glob**: Basándose en el patrón glob que definas (ej. `.js`, `src/**/*.ts`), la regla se aplicará a todos los archivos que coincidan con dicho patrón.

---

### Workflows

Los **Workflows** te permiten definir una serie de pasos para guiar al Agente a través de un conjunto repetitivo de tareas, como desplegar un servicio o responder comentarios de un PR. Estos Workflows se guardan como archivos Markdown, lo que permite tener una forma fácil y repetible de ejecutar procesos clave. Una vez guardados, los Workflows pueden invocarse en el Agente mediante un comando de barra con el formato `/nombre-del-workflow`.

> [!NOTE]
> Mientras que las **Reglas** proporcionan orientación a los modelos al ofrecer un contexto persistente y reutilizable a nivel de _prompt_, los **Workflows** proporcionan una secuencia estructurada de pasos o prompts a nivel de _trayectoria_, guiando al modelo a través de una serie de tareas o acciones interconectadas.

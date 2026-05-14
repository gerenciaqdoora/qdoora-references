> ## Índice de documentación
>
> Obtenga el índice completo de documentación en: https://agentskills.io/llms.txt
> Use este archivo para descubrir todas las páginas disponibles antes de explorar más a fondo.

# Optimización de las descripciones de las skills

> Cómo mejorar la descripción de su skill para que se active de forma confiable en los prompts relevantes.

Una skill solo ayuda si se activa. El campo `description` en el frontmatter de su `SKILL.md` es el mecanismo principal que usan los agentes para decidir si cargan una skill para una tarea determinada. Una descripción poco especificada significa que la skill no se activará cuando debería; una descripción demasiado amplia significa que se activará cuando no debería.

Esta guía cubre cómo probar y mejorar sistemáticamente la descripción de su skill para lograr precisión en la activación.

## Cómo funciona la activación de la skill

Los agentes usan la [divulgación progresiva](/specification#progressive-disclosure) para gestionar el contexto. Al inicio, cargan solo el `name` (nombre) y la `description` (descripción) de cada skill disponible: lo suficiente para decidir cuándo una skill podría ser relevante. Cuando la tarea de un usuario coincide con una descripción, el agente lee el `SKILL.md` completo en el contexto y sigue sus instrucciones.

Esto significa que la descripción asume toda la carga de la activación. Si la descripción no comunica cuándo es útil la skill, el agente no sabrá cuándo recurrir a ella.

Un matiz importante: los agentes suelen consultar las skills solo para tareas que requieren conocimientos o capacidades más allá de lo que pueden manejar por sí solos. Una solicitud simple de un solo paso como "lee este PDF" puede no activar una skill de PDF incluso si la descripción coincide perfectamente, porque el agente puede manejarlo con herramientas básicas. Las tareas que implican conocimientos especializados (una API desconocida, un flujo de trabajo específico del dominio o un formato poco común) son aquellas en las que una descripción bien escrita puede marcar la diferencia.

## Escritura de descripciones efectivas

Antes de realizar las pruebas, conviene saber cómo es una buena descripción. Algunos principios:

- **Use un lenguaje imperativo.** Redacte la descripción como una instrucción para el agente: "Use esta skill cuando..." en lugar de "Esta skill hace...". El agente está decidiendo si actuar, así que dígale cuándo actuar.
- **Céntrese en la intención del usuario, no en la implementación.** Describa lo que el usuario intenta lograr, no la mecánica interna de la skill. El modelo busca coincidencias con lo que el usuario pidió.
- **Sea directo (e incluso insistente).** Enumere explícitamente los contextos en los que se aplica la skill, incluidos los casos en los que el usuario no nombra el dominio directamente: "incluso si no mencionan explícitamente 'CSV' o 'análisis'".
- **Sea conciso.** Unas pocas frases o un párrafo corto suelen ser suficientes: lo bastante largo para cubrir el alcance de la skill, lo bastante corto para no saturar el contexto del agente a través de muchas skills. La [especificación](/specification#description-field) impone un límite estricto de 1024 caracteres.

## Diseño de consultas de evaluación de activación

Para probar la activación, necesita un conjunto de consultas de evaluación: prompts de usuario realistas etiquetados con si deben o no activar su skill.

```json eval_queries.json theme={null}
[
  {
    "query": "Tengo una hoja de cálculo en ~/data/q4_results.xlsx con los ingresos en la col C y los gastos en la col D; ¿puedes añadir una columna de margen de beneficio y resaltar cualquier valor inferior al 10%?",
    "should_trigger": true
  },
  { "query": "¿cuál es la forma más rápida de convertir este archivo json a yaml?", "should_trigger": false }
]
```

Intente reunir unas 20 consultas: 8-10 que deberían activarla y 8-10 que no.

### Consultas que deberían activar la skill (should-trigger)

Estas prueban si la descripción captura el alcance de la skill. Varíelas según varios ejes:

- **Redacción**: algunas formales, otras informales, algunas con errores tipográficos o abreviaturas.
- **Explicitud**: algunas nombran el dominio de la skill directamente ("analiza este CSV"), otras describen la necesidad sin nombrarlo ("mi jefe quiere un gráfico de este archivo de datos").
- **Detalle**: mezcle prompts breves con otros con mucho contexto (un "analiza mi CSV de ventas y haz un gráfico" junto con un mensaje más largo con rutas de archivos, nombres de columnas e historia de fondo).
- **Complejidad**: varíe el número de pasos y puntos de decisión. Incluya tareas de un solo paso junto con flujos de trabajo de varios pasos para probar si el agente puede discernir que la skill es relevante cuando la tarea que aborda está enterrada en una cadena más grande.

Las consultas más útiles que deberían activarse son aquellas en las que la skill ayudaría pero la conexión no es obvia solo por la consulta. Estos son los casos en los que la redacción de la descripción marca la diferencia; si la consulta ya pide exactamente lo que hace la skill, cualquier descripción razonable la activaría.

### Consultas que NO deberían activar la skill (should-not-trigger)

Los casos de prueba negativos más valiosos son los **"casi aciertos" (near-misses)**: consultas que comparten palabras clave o conceptos con su skill pero que en realidad necesitan algo diferente. Estas prueban si la descripción es precisa, no solo amplia.

Para una skill de análisis de CSV, los ejemplos negativos débiles serían:

- `"Escribe una función de fibonacci"`: obviamente irrelevante, no prueba nada.
- `"¿Qué tiempo hace hoy?"`: sin coincidencia de palabras clave, demasiado fácil.

Ejemplos negativos fuertes:

- `"Necesito actualizar las fórmulas de mi hoja de cálculo de presupuesto en Excel"`: comparte los conceptos de "hoja de cálculo" y "datos", pero necesita edición en Excel, no análisis de CSV.
- `"¿puedes escribir un script en python que lea un csv y suba cada fila a nuestra base de datos postgres?"`: involucra CSV, pero la tarea es un ETL de base de datos, no un análisis.

### Consejos para el realismo

Los prompts de usuarios reales contienen un contexto del que carecen las consultas de prueba genéricas. Incluya:

- Rutas de archivos (`~/Downloads/report_final_v2.xlsx`).
- Contexto personal (`"mi gerente me pidió que..."`).
- Detalles específicos (nombres de columnas, nombres de empresas, valores de datos).
- Lenguaje informal, abreviaturas y errores tipográficos ocasionales.

## Prueba de si una descripción activa la skill

El enfoque básico es pasar cada consulta por su agente con la skill instalada y observar si el agente la invoca. Asegúrese de que la skill esté registrada y sea localizable por su agente; la forma en que esto funciona varía según el cliente (p. ej., un directorio de skills, un archivo de configuración o un flag de la CLI).

La mayoría de los clientes de agentes proporcionan algún tipo de observabilidad (registros de ejecución, historiales de llamadas a herramientas o salida detallada) que le permite ver qué skills se consultaron durante una ejecución. Consulte la documentación de su cliente para más detalles. La skill se activó si el agente cargó el `SKILL.md` de su skill; no se activó si el agente procedió sin consultarlo.

Una consulta se considera "aprobada" si:

- `should_trigger` es `true` y la skill fue invocada, o
- `should_trigger` es `false` y la skill no fue invocada.

### Ejecución múltiple

El comportamiento del modelo no es determinista: la misma consulta puede activar la skill en una ejecución pero no en la siguiente. Ejecute cada consulta varias veces (3 es un punto de partida razonable) y calcule una **tasa de activación (trigger rate)**: la fracción de ejecuciones en las que se invocó la skill.

Una consulta que debería activarse aprueba si su tasa de activación está por encima de un umbral (0.5 es un valor predeterminado razonable). Una consulta que no debería activarse aprueba si su tasa de activación está por debajo de ese umbral.

Con 20 consultas a 3 ejecuciones cada una, son 60 invocaciones. Querrá automatizar esto con un script. He aquí la estructura general (sustituya la invocación de `claude` y la lógica de detección en `check_triggered` por lo que proporcione su cliente de agente):

```bash theme={null}
#!/bin/bash
QUERIES_FILE="${1:?Uso: $0 <consultas.json>}"
SKILL_NAME="mi-skill"
RUNS=3

# Este ejemplo usa la salida JSON de Claude Code para verificar las llamadas a la herramienta Skill.
# Sustituya esta función con la lógica de detección para su cliente de agente.
# Debe devolver 0 (éxito) si la skill fue invocada, 1 en caso contrario.
check_triggered() {
  local query="$1"
  claude -p "$query" --output-format json 2>/dev/null \
    | jq -e --arg skill "$SKILL_NAME" \
      'any(.messages[].content[]; .type == "tool_use" and .name == "Skill" and .input.skill == $skill)' \
      > /dev/null 2>&1
}

count=$(jq length "$QUERIES_FILE")
for i in $(seq 0 $((count - 1))); do
  query=$(jq -r ".[$i].query" "$QUERIES_FILE")
  should_trigger=$(jq -r ".[$i].should_trigger" "$QUERIES_FILE")
  triggers=0

  for run in $(seq 1 $RUNS); do
    check_triggered "$query" && triggers=$((triggers + 1))
  done

  jq -n \
    --arg query "$query" \
    --argjson should_trigger "$should_trigger" \
    --argjson triggers "$triggers" \
    --argjson runs "$RUNS" \
    '{query: $query, should_trigger: $should_trigger, triggers: $triggers, runs: $runs, trigger_rate: ($triggers / $runs)}'
done | jq -s '.'
```

<Tip>
  Si su cliente de agente lo permite, puede detener una ejecución de forma anticipada una vez que el resultado esté claro: el agente consultó la skill o empezó a trabajar sin ella. Esto puede reducir significativamente el tiempo y el costo de ejecutar el conjunto completo de evaluaciones.
</Tip>

## Evitar el sobreajuste (overfitting) con divisiones de entrenamiento/validación

Si optimiza la descripción con respecto a todas sus consultas, corre el riesgo de sobreajuste: crear una descripción que funcione para estas redacciones específicas pero que falle en otras nuevas.

La solución es dividir su conjunto de consultas:

- **Conjunto de entrenamiento (\~60%)**: las consultas que usa para identificar fallos y guiar las mejoras.
- **Conjunto de validación (\~40%)**: consultas que reserva y solo usa para comprobar si las mejoras se generalizan.

Asegúrese de que ambos conjuntos contengan una mezcla proporcional de consultas que deberían y no deberían activarse; no ponga por error todos los positivos en un solo conjunto. Baraje al azar y mantenga la división fija a través de las iteraciones para comparar peras con peras.

Si usa un script como el de [arriba](#ejecución-múltiple), puede dividir sus consultas en dos archivos (`train_queries.json` y `validation_queries.json`) y ejecutar el script contra cada uno de ellos por separado.

## El bucle de optimización

1. **Evalúe** la descripción actual tanto en el *conjunto de entrenamiento como en el de validación*. Los resultados de entrenamiento guían sus cambios; los de validación le indican si esos cambios se están generalizando.
2. **Identifique los fallos** en el *conjunto de entrenamiento*: ¿qué consultas que deberían activarse no lo hicieron? ¿Cuáles que no deberían hacerlo sí lo hicieron?
   - Solo use los fallos del conjunto de entrenamiento para guiar sus cambios; ya sea que revise la descripción usted mismo o se lo pida a un LLM, mantenga los resultados del conjunto de validación fuera del proceso.
3. **Revise la descripción.** Céntrese en generalizar:
   - Si las consultas que deberían activarse están fallando, la descripción puede ser demasiado estrecha. Amplíe el alcance o añada contexto sobre cuándo es útil la skill.
   - Si las consultas que no deberían activarse lo están haciendo por error, la descripción puede ser demasiado amplia. Añada especificidad sobre lo que la skill *no* hace, o aclare el límite entre esta skill y capacidades adyacentes.
   - Evite añadir palabras clave específicas de las consultas fallidas; eso es sobreajuste. En su lugar, encuentre la categoría o concepto general que representan esas consultas y abórdelo.
   - Si se queda bloqueado después de varias iteraciones, pruebe un enfoque estructuralmente diferente para la descripción en lugar de ajustes incrementales. Un encuadre o una estructura de frase diferente puede dar resultado donde el refinamiento no puede.
   - Verifique que la descripción se mantenga por debajo del límite de 1024 caracteres; las descripciones suelen crecer durante la optimización.
4. **Repita** los pasos 1-3 hasta que aprueben todas las consultas del *conjunto de entrenamiento* o deje de ver mejoras significativas.
5. **Seleccione la mejor iteración** por su tasa de aprobación de validación: la fracción de consultas en el *conjunto de validación* que aprobaron. Tenga en cuenta que la mejor descripción puede no ser la última que produjo; una iteración anterior podría tener una tasa de aprobación de validación más alta que las posteriores que se sobreajustaron al conjunto de entrenamiento.

Cinco iteraciones suelen ser suficientes. Si el rendimiento no mejora, el problema puede estar en las consultas (demasiado fáciles, demasiado difíciles o mal etiquetadas) en lugar de en la descripción.

<Tip>
  La skill [`skill-creator`](https://github.com/anthropics/skills/tree/main/skills/skill-creator) automatiza este bucle de extremo a extremo: divide el conjunto de evaluación, evalúa las tasas de activación en paralelo, propone mejoras en la descripción mediante Claude y genera un informe HTML en vivo que puede ver mientras se ejecuta.
</Tip>

## Aplicación del resultado

Una vez que haya seleccionado la mejor descripción:

1. Actualice el campo `description` en el frontmatter de su `SKILL.md`.
2. Verifique que la descripción esté por debajo del [límite de 1024 caracteres](/specification#description-field).
3. Verifique que la descripción se active como se espera. Pruebe algunos prompts manualmente como una comprobación rápida de cordura. Para una prueba más rigurosa, escriba 5-10 consultas nuevas (una mezcla de las que deberían y no deberían activarse) y páselas por el script de evaluación; dado que estas consultas nunca formaron parte del proceso de optimización, le darán una comprobación honesta de si la descripción se generaliza.

Antes y después:

```yaml theme={null}
# Antes
description: Procesa archivos CSV.

# Después
description: >
  Analiza archivos de datos CSV y tabulares: calcula estadísticas resumidas,
  añade columnas derivadas, genera gráficos y limpia datos desordenados. Use esta
  skill cuando el usuario tenga un archivo CSV, TSV o Excel y quiera
  explorar, transformar o visualizar los datos, incluso si no mencionan
  explícitamente "CSV" o "análisis".
```

La descripción mejorada es más específica sobre lo que hace la skill (estadísticas resumidas, columnas derivadas, gráficos, limpieza) y más amplia sobre cuándo se aplica (CSV, TSV, Excel; incluso sin palabras clave explícitas).

## Próximos pasos

Una vez que su skill se active de forma confiable, querrá evaluar si produce buenos resultados. Consulte [Evaluación de la calidad de salida de la skill](/skill-creation/evaluating-skills) para saber cómo configurar casos de prueba, calificar resultados e iterar.

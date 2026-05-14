> ## Índice de documentación
>
> Obtenga el índice completo de documentación en: https://agentskills.io/llms.txt
> Use este archivo para descubrir todas las páginas disponibles antes de explorar más a fondo.

# Evaluación de la calidad de salida de la skill

> Cómo probar si su skill produce buenos resultados utilizando la iteración impulsada por evaluaciones (evals).

Escribió una skill, la probó con un prompt y pareció funcionar. Pero, ¿funciona de manera confiable en diversos prompts, en casos de borde, y mejor que no tener ninguna skill? Ejecutar evaluaciones estructuradas (evals) responde a estas preguntas y le proporciona un bucle de retroalimentación para mejorar la skill de manera sistemática.

## Diseño de casos de prueba

Un caso de prueba tiene tres partes:

- **Prompt**: un mensaje de usuario realista, el tipo de cosa que alguien escribiría realmente.
- **Resultado esperado**: una descripción legible por humanos de cómo se ve el éxito.
- **Archivos de entrada** (opcional): archivos que la skill necesita para funcionar.

Guarde los casos de prueba en `evals/evals.json` dentro del directorio de su skill:

```json evals/evals.json theme={null}
{
  "skill_name": "analizador-csv",
  "evals": [
    {
      "id": 1,
      "prompt": "Tengo un CSV con datos de ventas mensuales en data/ventas_2025.csv. ¿Puedes encontrar los 3 meses con más ingresos y hacer un gráfico de barras?",
      "expected_output": "Una imagen de un gráfico de barras que muestre los 3 meses principales por ingresos, con ejes y valores etiquetados.",
      "files": ["evals/files/ventas_2025.csv"]
    },
    {
      "id": 2,
      "prompt": "Hay un csv en mis descargas llamado clientes.csv, algunas filas no tienen correos electrónicos; ¿puedes limpiarlo y decirme cuántos faltaban?",
      "expected_output": "Un CSV limpio con los correos electrónicos faltantes gestionados, además de un recuento de cuántos faltaban.",
      "files": ["evals/files/clientes.csv"]
    }
  ]
}
```

**Consejos para escribir buenos prompts de prueba:**

- **Comience con 2-3 casos de prueba.** No invierta demasiado antes de ver su primera ronda de resultados. Puede ampliar el conjunto más adelante.
- **Varíe los prompts.** Use diferentes redacciones, niveles de detalle y formalidad. Algunos prompts deben ser informales ("oye, ¿puedes limpiar este csv?"), otros precisos ("Analiza el CSV en data/input.csv, elimina las filas donde la columna B sea nula y escribe el resultado en data/output.csv").
- **Cubra casos de borde.** Incluya al menos un prompt que pruebe una condición límite: una entrada mal formada, una solicitud inusual o un caso donde las instrucciones de la skill puedan ser ambiguas.
- **Use un contexto realista.** Los usuarios reales mencionan rutas de archivos, nombres de columnas y contexto personal. Prompts como "procesa estos datos" son demasiado vagos para probar algo útil.

No se preocupe por definir verificaciones específicas de aprobado/reprobado todavía, solo los prompts y los resultados esperados. Añadirá verificaciones detalladas (llamadas aserciones) después de ver lo que produce la primera ejecución.

## Ejecución de evaluaciones (evals)

El patrón principal consiste en ejecutar cada caso de prueba dos veces: una **con la skill** y otra **sin ella** (o con una versión anterior). Esto le da una línea base para comparar.

### Estructura del espacio de trabajo

Organice los resultados de la evaluación en un directorio de espacio de trabajo junto al directorio de su skill. Cada paso a través del bucle de evaluación completo obtiene su propio directorio `iteration-N/`. Dentro de ese, cada caso de prueba obtiene un directorio de evaluación con subdirectorios `with_skill/` y `without_skill/`:

```
analizador-csv/
├── SKILL.md
└── evals/
    └── evals.json
analizador-csv-workspace/
└── iteration-1/
    ├── eval-grafico-meses-principales/
    │   ├── with_skill/
    │   │   ├── outputs/       # Archivos producidos por la ejecución
    │   │   ├── timing.json    # Tokens y duración
    │   │   └── grading.json   # Resultados de las aserciones
    │   └── without_skill/
    │       ├── outputs/
    │       ├── timing.json
    │       └── grading.json
    ├── eval-limpiar-correos-faltantes/
    │   ├── with_skill/
    │   │   ├── outputs/
    │   │   ├── timing.json
    │   │   └── grading.json
    │   └── without_skill/
    │       ├── outputs/
    │       ├── timing.json
    │       └── grading.json
    └── benchmark.json         # Estadísticas agregadas
```

El archivo principal que usted crea a mano es `evals/evals.json`. Los otros archivos JSON (`grading.json`, `timing.json`, `benchmark.json`) se producen durante el proceso de evaluación: por el agente, por scripts o por usted.

### Lanzamiento de ejecuciones

Cada ejecución de evaluación debe comenzar con un contexto limpio: sin estado sobrante de ejecuciones anteriores o del proceso de desarrollo de la skill. Esto asegura que el agente siga solo lo que le indica el `SKILL.md`. En entornos que admiten subagentes (Claude Code, por ejemplo), este aislamiento ocurre de forma natural: cada tarea secundaria comienza de cero. Sin subagentes, use una sesión separada para cada ejecución.

Para cada ejecución, proporcione:

- La ruta de la skill (o ninguna skill para la línea base).
- El prompt de prueba.
- Cualquier archivo de entrada.
- El directorio de salida.

He aquí un ejemplo de las instrucciones que daría al agente para una sola ejecución con skill:

```
Ejecuta esta tarea:
- Ruta de la skill: /ruta/a/analizador-csv
- Tarea: Tengo un CSV con datos de ventas mensuales en data/ventas_2025.csv.
  ¿Puedes encontrar los 3 meses con más ingresos y hacer un gráfico de barras?
- Archivos de entrada: evals/files/ventas_2025.csv
- Guarda los resultados en: analizador-csv-workspace/iteration-1/eval-grafico-meses-principales/with_skill/outputs/
```

Para la línea base, use el mismo prompt pero sin la ruta de la skill, guardando en `without_skill/outputs/`.

Al mejorar una skill existente, use la versión anterior como su línea base. Tome una captura de ella antes de editarla (`cp -r <ruta-skill> <espacio-trabajo>/skill-snapshot/`), apunte la ejecución de la línea base a la captura y guarde en `old_skill/outputs/` en lugar de `without_skill/`.

### Captura de datos de tiempo

Los datos de tiempo le permiten comparar cuánto tiempo y cuántos tokens cuesta la skill en relación con la línea base: una skill que mejora drásticamente la calidad de la salida pero triplica el uso de tokens es una compensación diferente a una que es mejor y más barata. Cuando finalice cada ejecución, registre el recuento de tokens y la duración:

```json timing.json theme={null}
{
  "total_tokens": 84852,
  "duration_ms": 23332
}
```

<Tip>
  En Claude Code, cuando termina una tarea de subagente, la [notificación de finalización de tarea](https://platform.claude.com/docs/en/agent-sdk/typescript#sdk-task-notification-message) incluye `total_tokens` y `duration_ms`. Guarde estos valores de inmediato: no se guardan en ningún otro lugar.
</Tip>

## Escritura de aserciones

Las aserciones son declaraciones verificables sobre lo que la salida debe contener o lograr. Añádalas después de ver su primera ronda de resultados: a menudo no sabe cómo se ve el "buen resultado" hasta que la skill se ha ejecutado.

Buenas aserciones:

- `"El archivo de salida es un JSON válido"`: verificable mediante programación.
- `"El gráfico de barras tiene ejes etiquetados"`: específico y observable.
- `"El informe incluye al menos 3 recomendaciones"`: contable.

Aserciones débiles:

- `"La salida es buena"`: demasiado vaga para calificar.
- `"La salida usa exactamente la frase 'Ingresos totales: $X'"`: demasiado frágil; una salida correcta con una redacción diferente fallaría.

No todo necesita una aserción. Algunas cualidades (estilo de escritura, diseño visual, si la salida "se siente bien") son difíciles de descomponer en verificaciones de aprobado/reprobado. Estas se captan mejor durante la [revisión humana](#revisión-de-resultados-con-un-humano). Reserve las aserciones para cosas que se puedan verificar objetivamente.

Añada aserciones a cada caso de prueba en `evals/evals.json`:

```json evals/evals.json highlight={9-14} theme={null}
{
  "skill_name": "analizador-csv",
  "evals": [
    {
      "id": 1,
      "prompt": "Tengo un CSV con datos de ventas mensuales en data/ventas_2025.csv. ¿Puedes encontrar los 3 meses con más ingresos y hacer un gráfico de barras?",
      "expected_output": "Una imagen de un gráfico de barras que muestre los 3 meses principales por ingresos, con ejes y valores etiquetados.",
      "files": ["evals/files/ventas_2025.csv"],
      "assertions": [
        "La salida incluye un archivo de imagen de gráfico de barras",
        "El gráfico muestra exactamente 3 meses",
        "Ambos ejes están etiquetados",
        "El título o la leyenda del gráfico menciona los ingresos"
      ]
    }
  ]
}
```

## Calificación de las salidas

Calificar significa evaluar cada aserción contra las salidas reales y registrar **APROBADO** o **REPROBADO** con evidencia específica. La evidencia debe citar o hacer referencia a la salida, no solo expresar una opinión.

El enfoque más sencillo es dar las salidas y aserciones a un LLM y pedirle que evalúe cada una. Para las aserciones que pueden ser verificadas por código (JSON válido, recuento de filas correcto, el archivo existe con las dimensiones esperadas), use un script de verificación: los scripts son más confiables que el juicio del LLM para verificaciones mecánicas y son reutilizables a través de las iteraciones.

```json grading.json theme={null}
{
  "assertion_results": [
    {
      "text": "La salida incluye un archivo de imagen de gráfico de barras",
      "passed": true,
      "evidence": "Se encontró grafico.png (45KB) en el directorio de salidas"
    },
    {
      "text": "El gráfico muestra exactamente 3 meses",
      "passed": true,
      "evidence": "El gráfico muestra barras para marzo, julio y noviembre"
    },
    {
      "text": "Ambos ejes están etiquetados",
      "passed": false,
      "evidence": "El eje Y está etiquetado como 'Ingresos ($)', pero el eje X no tiene etiqueta"
    },
    {
      "text": "El título o la leyenda del gráfico menciona los ingresos",
      "passed": true,
      "evidence": "El título del gráfico dice '3 meses principales por ingresos'"
    }
  ],
  "summary": {
    "passed": 3,
    "failed": 1,
    "total": 4,
    "pass_rate": 0.75
  }
}
```

### Principios de calificación

- **Exija evidencia concreta para un APROBADO.** No dé el beneficio de la duda. Si una aserción dice "incluye un resumen" y la salida tiene una sección titulada "Resumen" con una oración vaga, eso es un REPROBADO: la etiqueta está ahí, pero el contenido no.
- **Revise las aserciones mismas, no solo los resultados.** Al calificar, observe cuándo las aserciones son demasiado fáciles (siempre aprueban independientemente de la calidad de la skill), demasiado difíciles (siempre reprueban incluso cuando la salida es buena) o no verificables (no se pueden verificar solo con la salida). Corrija estas para la próxima iteración.

<Tip>
  Para comparar dos versiones de una skill, pruebe la **comparación a ciegas**: presente ambas salidas a un juez LLM sin revelar qué versión produjo cuál. El juez califica cualidades holísticas (organización, formato, usabilidad, pulido) según su propia rúbrica, libre de sesgos sobre qué versión "debería" ser mejor. Esto complementa la calificación de aserciones: dos salidas podrían aprobar todas las aserciones pero diferir significativamente en calidad general.
</Tip>

## Agregación de resultados

Una vez que se califica cada ejecución en la iteración, calcule las estadísticas resumidas por configuración y guárdelas en `benchmark.json` junto a los directorios de evaluación (p. ej., `analizador-csv-workspace/iteration-1/benchmark.json`):

```json benchmark.json theme={null}
{
  "run_summary": {
    "with_skill": {
      "pass_rate": { "mean": 0.83, "stddev": 0.06 },
      "time_seconds": { "mean": 45.0, "stddev": 12.0 },
      "tokens": { "mean": 3800, "stddev": 400 }
    },
    "without_skill": {
      "pass_rate": { "mean": 0.33, "stddev": 0.1 },
      "time_seconds": { "mean": 32.0, "stddev": 8.0 },
      "tokens": { "mean": 2100, "stddev": 300 }
    },
    "delta": {
      "pass_rate": 0.5,
      "time_seconds": 13.0,
      "tokens": 1700
    }
  }
}
```

El `delta` le indica lo que cuesta la skill (más tiempo, más tokens) y lo que compra (una mayor tasa de aprobación). Una skill que añade 13 segundos pero mejora la tasa de aprobación en 50 puntos porcentuales probablemente valga la pena. Una skill que duplica el uso de tokens por una mejora de 2 puntos podría no valerla.

<Note>
  La desviación estándar (`stddev`) solo tiene sentido con múltiples ejecuciones por evaluación. En las primeras iteraciones con solo 2-3 casos de prueba y ejecuciones individuales, concéntrese en los recuentos brutos de aprobados y el delta; las medidas estadísticas se vuelven útiles a medida que amplía el conjunto de pruebas y ejecuta cada evaluación varias veces.
</Note>

## Análisis de patrones

Las estadísticas agregadas pueden ocultar patrones importantes. Después de calcular los benchmarks:

- **Elimine o reemplace las aserciones que siempre aprueban en ambas configuraciones.** Estas no le dicen nada útil: el modelo las maneja bien sin la skill. Inflan la tasa de aprobación con skill sin reflejar el valor real de la misma.
- **Investigue las aserciones que siempre fallan en ambas configuraciones.** O bien la aserción está mal (pide algo que el modelo no puede hacer), el caso de prueba es demasiado difícil, o la aserción está buscando lo incorrecto. Corrija esto antes de la próxima iteración.
- **Estudie las aserciones que aprueban con la skill pero fallan sin ella.** Aquí es donde la skill está añadiendo valor claramente. Comprenda _por qué_: ¿qué instrucciones o scripts marcaron la diferencia?
- **Refuerce las instrucciones cuando los resultados sean inconsistentes entre ejecuciones.** Si la misma evaluación aprueba a veces y falla otras (reflejado como un `stddev` alto en el benchmark), la evaluación puede ser inestable (sensible a la aleatoriedad del modelo), o las instrucciones de la skill pueden ser lo suficientemente ambiguas como para que el modelo las interprete de manera diferente cada vez. Añada ejemplos o una guía más específica para reducir la ambigüedad.
- **Verifique los valores atípicos de tiempo y tokens.** Si una evaluación tarda 3 veces más que las otras, lea su traza de ejecución (el registro completo de lo que hizo el modelo durante la ejecución) para encontrar el cuello de botella.

## Revisión de resultados con un humano

La calificación de aserciones y el análisis de patrones detectan mucho, pero solo verifican aquello para lo que usted pensó en escribir aserciones. Un revisor humano aporta una perspectiva fresca: detecta problemas que usted no anticipó, nota cuando la salida es técnicamente correcta pero no da en el clavo, o identifica problemas que son difíciles de expresar como verificaciones de aprobado/reprobado. Para cada caso de prueba, revise las salidas reales junto con las calificaciones.

Registre comentarios específicos para cada caso de prueba y guárdelos en el espacio de trabajo (p. ej., como un `feedback.json` junto a los directorios de evaluación):

```json feedback.json theme={null}
{
  "eval-grafico-meses-principales": "Al gráfico le faltan las etiquetas de los ejes y los meses están en orden alfabético en lugar de cronológico.",
  "eval-limpiar-correos-faltantes": ""
}
```

"Al gráfico le faltan las etiquetas de los ejes" es accionable; "se ve mal" no lo es. Un comentario vacío significa que la salida se veía bien: ese caso de prueba pasó su revisión. Durante el [paso de iteración](#iteración-sobre-la-skill), concentre sus mejoras en los casos de prueba donde tuvo quejas específicas.

## Iteración sobre la skill

Después de calificar y revisar, tiene tres fuentes de señal:

- **Las aserciones fallidas** apuntan a brechas específicas: un paso faltante, una instrucción poco clara o un caso que la skill no maneja.
- **La retroalimentación humana** apunta a problemas de calidad más amplios: el enfoque fue incorrecto, la salida estuvo mal estructurada o la skill produjo un resultado técnicamente correcto pero poco útil.
- **Las trazas de ejecución** revelan el _porqué_ las cosas salieron mal. Si el agente ignoró una instrucción, la instrucción puede ser ambigua. Si el agente perdió tiempo en pasos improductivos, esas instrucciones pueden necesitar ser simplificadas o eliminadas.

La forma más efectiva de convertir estas señales en mejoras de la skill es darlas las tres (junto con el `SKILL.md` actual) a un LLM y pedirle que proponga cambios. El LLM puede sintetizar patrones a través de las aserciones fallidas, las quejas del revisor y el comportamiento de la traza que sería tedioso conectar manualmente. Al solicitar al LLM, incluya estas directrices:

- **Generalice a partir de la retroalimentación.** La skill se usará en muchos prompts diferentes, no solo en los casos de prueba. Las correcciones deben abordar los problemas subyacentes de manera amplia en lugar de añadir parches estrechos para ejemplos específicos.
- **Mantenga la skill esbelta (lean).** Menos instrucciones pero mejores a menudo superan a las reglas exhaustivas. Si las trazas muestran trabajo desperdiciado (validación innecesaria, salidas intermedias innecesarias), elimine esas instrucciones. Si las tasas de aprobación se estancan a pesar de añadir más reglas, la skill puede estar sobre-restringida: intente eliminar instrucciones y vea si los resultados se mantienen o mejoran.
- **Explique el porqué.** Las instrucciones basadas en el razonamiento ("Haga X porque Y tiende a causar Z") funcionan mejor que las directivas rígidas ("HAGA SIEMPRE X, NUNCA HAGA Y"). Los modelos siguen las instrucciones de manera más confiable cuando entienden el propósito.
- **Empaquete el trabajo repetido.** Si cada ejecución de prueba escribió de forma independiente un script de ayuda similar (un generador de gráficos, un analizador de datos), esa es una señal para empaquetar el script en el directorio `scripts/` de la skill. Consulte [Uso de scripts](/skill-creation/using-scripts) para saber cómo hacerlo.

### El bucle

1. Entregue las señales de evaluación y el `SKILL.md` actual a un LLM y pídale que proponga mejoras.
2. Revise y aplique los cambios.
3. Vuelva a ejecutar todos los casos de prueba en un nuevo directorio `iteration-<N+1>/`.
4. Califique y agregue los nuevos resultados.
5. Revise con un humano. Repita.

Deténgase cuando esté satisfecho con los resultados, la retroalimentación esté constantemente vacía o ya no vea mejoras significativas entre las iteraciones.

<Tip>
  La skill [`skill-creator`](https://github.com/anthropics/skills/tree/main/skills/skill-creator) automatiza gran parte de este flujo de trabajo: ejecutar evaluaciones, calificar aserciones, agregar benchmarks y presentar resultados para la revisión humana.
</Tip>

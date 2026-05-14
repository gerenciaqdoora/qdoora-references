# Guía de Evaluación y Métricas (Evals)

El objetivo de las evaluaciones es medir sistemáticamente si una skill mejora la calidad, ahorra tokens o reduce el tiempo de ejecución en comparación con una línea base (sin skill).

## 1. El Bucle de Iteración
1. **Definir Evals**: Crear `evals/evals.json` con prompts reales, resultados esperados y aserciones.
2. **Línea Base (Baseline)**: Ejecutar los prompts *sin la skill* (o con la versión anterior).
3. **Ejecución con Skill**: Ejecutar los mismos prompts *con la skill*.
4. **Calificación**: Evaluar cada aserción y registrar evidencia concreta (PASÓ/FALLÓ).
5. **Benchmarking**: Calcular el Delta (mejora en tasa de aprobación, tiempo y tokens).
6. **Refinamiento**: Usar las trazas y fallos para actualizar el `SKILL.md`.

## 2. Aserciones Efectivas
Las aserciones deben ser objetivas y observables:
- **Buenas**: "El archivo JSON es válido", "Incluye exactamente 3 recomendaciones", "El código no tiene errores de sintaxis".
- **Malas**: "La salida es buena", "El tono es amigable" (usar revisión humana para esto).

## 3. Estructura del Espacio de Trabajo
```
workspace-mi-skill/
└── iteration-1/
    ├── case-1/
    │   ├── with_skill/ (outputs, timing.json, grading.json)
    │   └── without_skill/ (outputs, timing.json, grading.json)
    └── benchmark.json
```

## 4. Métricas Críticas
- **Tasa de Aprobación (Pass Rate)**: % de aserciones cumplidas.
- **Tokens Totales**: Costo de la ejecución.
- **Duración (ms)**: Tiempo de respuesta.

## 5. Comparación a Ciegas (Blind Comparison)
Para evaluar la calidad holística, presenta ambas salidas a un juez (humano o LLM) sin indicar cuál es cuál. El juez califica según una rúbrica de estilo, organización y utilidad.

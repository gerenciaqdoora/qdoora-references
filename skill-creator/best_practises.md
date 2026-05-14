> ## Índice de documentación
>
> Obtenga el índice completo de documentación en: https://agentskills.io/llms.txt
> Use este archivo para descubrir todas las páginas disponibles antes de explorar más a fondo.

# Mejores prácticas para creadores de skills

> Cómo escribir skills que estén bien delimitadas y calibradas para la tarea.

## Comenzar desde la experiencia real

Un error común en la creación de skills es pedirle a un LLM que genere una skill sin proporcionar un contexto específico del dominio, confiando únicamente en el conocimiento general de entrenamiento del LLM. El resultado son procedimientos vagos y genéricos ("manejar errores adecuadamente", "seguir las mejores prácticas de autenticación") en lugar de los patrones de API específicos, casos de borde y convenciones de proyecto que hacen que una skill sea valiosa.

Las skills efectivas se basan en la experiencia real. La clave es alimentar el proceso de creación con contexto específico del dominio.

### Extraer de una tarea práctica

Complete una tarea real en conversación con un agente, proporcionando contexto, correcciones y preferencias a lo largo del camino. Luego, extraiga el patrón reutilizable en una skill. Preste atención a:

- **Pasos que funcionaron**: la secuencia de acciones que llevó al éxito.
- **Correcciones que realizó**: lugares donde dirigió el enfoque del agente (p. ej., "usa la librería X en lugar de Y", "verifica el caso de borde Z").
- **Formatos de entrada/salida**: cómo se veían los datos al entrar y salir.
- **Contexto que proporcionó**: hechos específicos del proyecto, convenciones o restricciones que el agente aún no conocía.

### Sintetizar a partir de artefactos de proyecto existentes

Cuando tenga un cuerpo de conocimiento existente, puede entregárselo a un LLM y pedirle que sintetice una skill. Una skill de tubería de datos (data-pipeline) sintetizada a partir de los informes de incidentes y manuales de procedimientos (runbooks) reales de su equipo superará a una sintetizada a partir de un artículo genérico de "mejores prácticas de ingeniería de datos", porque captura _sus_ esquemas, modos de falla y procedimientos de recuperación. La clave es el material específico del proyecto, no las referencias genéricas.

El buen material de origen incluye:

- Documentación interna, runbooks y guías de estilo.
- Especificaciones de API, esquemas y archivos de configuración.
- Comentarios de revisión de código y rastreadores de problemas (captura inquietudes recurrentes y expectativas del revisor).
- Historial de control de versiones, especialmente parches y correcciones (revela patrones a través de lo que realmente cambió).
- Casos de falla del mundo real y sus resoluciones.

## Refinar con ejecución real

El primer borrador de una skill generalmente necesita refinamiento. Ejecute la skill contra tareas reales, luego retroalimente los resultados (todos, no solo las fallas) al proceso de creación. Pregunte: ¿qué desencadenó falsos positivos? ¿Qué se pasó por alto? ¿Qué se podría eliminar?

Incluso una sola pasada de ejecutar-y-luego-revisar mejora notablemente la calidad, y los dominios complejos a menudo se benefician de varias.

<Tip>
  Lea las trazas de ejecución del agente, no solo los resultados finales. Si el agente pierde tiempo en pasos improductivos, las causas comunes incluyen instrucciones demasiado vagas (el agente intenta varios enfoques antes de encontrar uno que funcione), instrucciones que no se aplican a la tarea actual (el agente las sigue de todos modos) o demasiadas opciones presentadas sin un valor predeterminado claro.
</Tip>

Para un enfoque más estructurado de la iteración, incluyendo casos de prueba, aserciones y calificación, consulte [Evaluación de la calidad de salida de la skill](/skill-creation/evaluating-skills).

## Gastar el contexto sabiamente

Una vez que se activa una skill, el cuerpo completo de su `SKILL.md` se carga en la ventana de contexto del agente junto con el historial de conversación, el contexto del sistema y otras skills activas. Cada token en su skill compite por la atención del agente con todo lo demás en esa ventana.

### Añadir lo que el agente no tiene, omitir lo que ya sabe

Concéntrese en lo que el agente _no_ sabría sin su skill: convenciones específicas del proyecto, procedimientos específicos del dominio, casos de borde no obvios y las herramientas o APIs particulares a utilizar. No necesita explicar qué es un PDF, cómo funciona HTTP o qué hace una migración de base de datos.

````markdown theme={null}
<!-- Demasiado detallado: el agente ya sabe qué son los archivos PDF -->

## Extraer texto de PDF

Los archivos PDF (Portable Document Format) son un formato de archivo común que contiene
texto, imágenes y otro contenido. Para extraer texto de un PDF, necesitará
usar una librería. Se recomienda pdfplumber porque maneja bien la mayoría de los casos.

<!-- Mejor: salta directamente a lo que el agente no sabría por sí solo -->

## Extraer texto de PDF

Use pdfplumber para la extracción de texto. Para documentos escaneados, recurra a
pdf2image con pytesseract.

```python
import pdfplumber

with pdfplumber.open("archivo.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

Pregúntese sobre cada pieza de contenido: "¿Se equivocaría el agente sin esta instrucción?". Si la respuesta es no, elimínela. Si no está seguro, pruébela. Y si el agente ya maneja bien toda la tarea sin la skill, es posible que la skill no esté agregando valor. Consulte [Evaluación de la calidad de salida de la skill](/skill-creation/evaluating-skills) para saber cómo probar esto sistemáticamente.

### Diseñar unidades coherentes

Decidir qué debe cubrir una skill es como decidir qué debe hacer una función: desea que encapsule una unidad coherente de trabajo que se combine bien con otras skills. Las skills delimitadas de manera demasiado estrecha obligan a cargar múltiples skills para una sola tarea, arriesgando sobrecarga e instrucciones contradictorias. Las skills delimitadas de manera demasiado amplia se vuelven difíciles de activar con precisión. Una skill para consultar una base de datos y formatear los resultados puede ser una unidad coherente, mientras que una skill que también cubra la administración de la base de datos probablemente esté tratando de hacer demasiado.

### Apuntar a un detalle moderado

Las skills excesivamente completas pueden perjudicar más de lo que ayudan: el agente lucha por extraer lo que es relevante y puede seguir caminos improductivos desencadenados por instrucciones que no se aplican a la tarea actual. Una guía concisa y paso a paso con un ejemplo funcional tiende a superar a la documentación exhaustiva. Cuando se encuentre cubriendo cada caso de borde, considere si la mayoría se manejan mejor por el propio juicio del agente.

### Estructurar skills grandes con divulgación progresiva

La [especificación](/specification#progressive-disclosure) recomienda mantener `SKILL.md` por debajo de 500 líneas y 5,000 tokens: solo las instrucciones centrales que el agente necesita en cada ejecución. Cuando una skill legítimamente necesita más contenido, mueva el material de referencia detallado a archivos separados en `references/` o directorios similares.

La clave es decirle al agente _cuándo_ cargar cada archivo. "Lea `references/api-errors.md` si la API devuelve un código de estado que no sea 200" es más útil que un genérico "consulte references/ para más detalles". Esto permite que el agente cargue contexto bajo demanda en lugar de hacerlo por adelantado, que es como la [divulgación progresiva](/specification#progressive-disclosure) está diseñada para funcionar.

## Calibrar el control

No cada parte de una skill necesita el mismo nivel de prescriptividad. Alinee la especificidad de sus instrucciones con la fragilidad de la tarea.

### Alinear la especificidad con la fragilidad

**Dé libertad al agente** cuando múltiples enfoques sean válidos y la tarea tolere variaciones. Para instrucciones flexibles, explicar el _por qué_ puede ser más efectivo que las directivas rígidas: un agente que comprende el propósito detrás de una instrucción toma mejores decisiones dependientes del contexto. Una skill de revisión de código puede describir qué buscar sin prescribir pasos exactos:

```markdown theme={null}
## Proceso de revisión de código

1. Verifique todas las consultas a la base de datos en busca de inyección SQL (use consultas parametrizadas).
2. Verifique los controles de autenticación en cada endpoint.
3. Busque condiciones de carrera en rutas de código concurrentes.
4. Confirme que los mensajes de error no filtren detalles internos.
```

**Sea prescriptivo** cuando las operaciones sean frágiles, la consistencia importe o se deba seguir una secuencia específica:

````markdown theme={null}
## Migración de base de datos

Ejecute exactamente esta secuencia:

```bash
python scripts/migrate.py --verify --backup
```

No modifique el comando ni agregue flags adicionales.
````

La mayoría de las skills tienen una mezcla. Calibre cada parte de forma independiente.

### Proporcionar valores predeterminados, no menús

Cuando múltiples herramientas o enfoques podrían funcionar, elija un valor predeterminado y mencione brevemente las alternativas en lugar de presentarlas como opciones iguales.

````markdown theme={null}
<!-- Demasiadas opciones -->

Puede usar pypdf, pdfplumber, PyMuPDF o pdf2image...

<!-- Valor predeterminado claro con vía de escape -->

Use pdfplumber para la extracción de texto:

```python
import pdfplumber
```

Para PDFs escaneados que requieran OCR, use pdf2image con pytesseract en su lugar.
````

### Favorecer procedimientos sobre declaraciones

Una skill debe enseñar al agente _cómo abordar_ una clase de problemas, no _qué producir_ para una instancia específica. Compare:

```markdown theme={null}
<!-- Respuesta específica: solo útil para esta tarea exacta -->

Una la tabla `orders` con `customers` en `customer_id`, filtre donde
`region = 'EMEA'`, y sume la columna `amount`.

<!-- Método reutilizable: funciona para cualquier consulta analítica -->

1. Lea el esquema de `references/schema.yaml` para encontrar las tablas relevantes.
2. Una las tablas utilizando la convención de clave foránea `_id`.
3. Aplique cualquier filtro de la solicitud del usuario como cláusulas WHERE.
4. Agregue las columnas numéricas según sea necesario y dele formato como una tabla markdown.
```

Esto no significa que las skills no puedan incluir detalles específicos: las plantillas de formato de salida (ver [Plantillas para el formato de salida](#plantillas-para-el-formato-salida)), las restricciones como "nunca mostrar PII" y las instrucciones específicas de herramientas son todas valiosas. El punto es que el _enfoque_ debe generalizarse incluso cuando los detalles individuales sean específicos.

## Patrones para instrucciones efectivas

Estas son técnicas reutilizables para estructurar el contenido de las skills. No cada skill necesita todas ellas: use las que se adapten a su tarea.

### Secciones de "Gotchas" (trampas/detalles)

El contenido de mayor valor en muchas skills es una lista de "gotchas": hechos específicos del entorno que desafían las suposiciones razonables. Estos no son consejos generales ("maneje los errores adecuadamente"), sino correcciones concretas a errores que el agente cometerá si no se le indica lo contrario:

```markdown theme={null}
## Gotchas

- La tabla `users` utiliza eliminaciones lógicas (soft deletes). Las consultas deben incluir
  `WHERE deleted_at IS NULL` o los resultados incluirán cuentas desactivadas.
- El ID de usuario es `user_id` en la base de datos, `uid` en el servicio de autenticación
  y `accountId` en la API de facturación. Los tres se refieren al mismo valor.
- El endpoint `/health` devuelve 200 siempre que el servidor web esté en funcionamiento,
  incluso si la conexión a la base de datos está caída. Use `/ready` para verificar el estado
  completo del servicio.
```

Mantenga los "gotchas" en `SKILL.md` donde el agente los lea antes de encontrarse con la situación. Un archivo de referencia separado funciona si le indica al agente cuándo cargarlo, pero para problemas no obvios, el agente puede no reconocer el disparador.

<Tip>
  Cuando un agente cometa un error que usted tenga que corregir, añada la corrección a la sección de gotchas. Esta es una de las formas más directas de mejorar una skill de forma iterativa (consulte [Refinar con ejecución real](#refinar-con-ejecución-real)).
</Tip>

### Plantillas para el formato de salida

Cuando necesite que el agente produzca una salida en un formato específico, proporcione una plantilla. Esto es más confiable que describir el formato en prosa, porque los agentes coinciden bien con patrones frente a estructuras concretas. Las plantillas cortas pueden vivir integradas en `SKILL.md`; para plantillas más largas, o plantillas que solo se necesitan en ciertos casos, guárdelas en `assets/` y hágales referencia desde `SKILL.md` para que solo se carguen cuando sea necesario.

````markdown theme={null}
## Estructura del informe

Use esta plantilla, adaptando las secciones según sea necesario para el análisis específico:

```markdown
# [Título del Análisis]

## Resumen ejecutivo

[Resumen de un párrafo de los hallazgos clave]

## Hallazgos clave

- Hallazgo 1 con datos de respaldo
- Hallazgo 2 con datos de respaldo

## Recomendaciones

1. Recomendación accionable específica
2. Recomendación accionable específica
```
````

### Listas de verificación para flujos de trabajo de varios pasos

Una lista de verificación explícita ayuda al agente a seguir el progreso y evitar saltarse pasos, especialmente cuando los pasos tienen dependencias o puertas de validación.

```markdown theme={null}
## Flujo de trabajo de procesamiento de formularios

Progreso:

- [ ] Paso 1: Analizar el formulario (ejecutar `scripts/analyze_form.py`).
- [ ] Paso 2: Crear el mapeo de campos (editar `fields.json`).
- [ ] Paso 3: Validar el mapeo (ejecutar `scripts/validate_fields.py`).
- [ ] Paso 4: Rellenar el formulario (ejecutar `scripts/fill_form.py`).
- [ ] Paso 5: Verificar la salida (ejecutar `scripts/verify_output.py`).
```

### Bucles de validación

Indique al agente que valide su propio trabajo antes de continuar. El patrón es: hacer el trabajo, ejecutar un validador (un script, una lista de verificación de referencia o una autoverificación), corregir cualquier problema y repetir hasta que la validación pase.

```markdown theme={null}
## Flujo de trabajo de edición

1. Realice sus ediciones.
2. Ejecute la validación: `python scripts/validate.py output/`.
3. Si la validación falla:
   - Revise el mensaje de error.
   - Corrija los problemas.
   - Ejecute la validación de nuevo.
4. Solo proceda cuando la validación pase.
```

Un documento de referencia también puede servir como "validador": indique al agente que verifique su trabajo contra la referencia antes de finalizar.

### Planificar-Validar-Ejecutar

Para operaciones por lotes o destructivas, haga que el agente cree un plan intermedio en un formato estructurado, lo valide contra una fuente de verdad y solo entonces lo ejecute.

```markdown theme={null}
## Rellenado de formularios PDF

1. Extraer campos del formulario: `python scripts/analyze_form.py input.pdf` → `form_fields.json`
   (enumera cada nombre de campo, tipo y si es obligatorio).
2. Crear `field_values.json` mapeando cada nombre de campo a su valor previsto.
3. Validar: `python scripts/validate_fields.py form_fields.json field_values.json`
   (verifica que cada nombre de campo exista en el formulario, que los tipos sean compatibles y que
   no falten campos obligatorios).
4. Si la validación falla, revise `field_values.json` y vuelva a validar.
5. Rellenar el formulario: `python scripts/fill_form.py input.pdf field_values.json output.pdf`
```

El ingrediente clave es el paso 3: un script de validación que verifica el plan (`field_values.json`) contra la fuente de verdad (`form_fields.json`). Errores como "Campo 'signature_date' no encontrado — campos disponibles: customer_name, order_total, signature_date_signed" le dan al agente suficiente información para autocorregirse.

### Empaquetar scripts reutilizables

Al [iterar sobre una skill](/skill-creation/evaluating-skills), compare las trazas de ejecución del agente a través de los casos de prueba. Si nota que el agente reinventa de forma independiente la misma lógica en cada ejecución (construir gráficos, analizar un formato específico, validar la salida), esa es una señal para escribir un script probado una vez y empaquetarlo en `scripts/`.

Para más información sobre el diseño y empaquetado de scripts, consulte [Uso de scripts en las skills](/skill-creation/using-scripts).

## Próximos pasos

Una vez que tenga una skill en funcionamiento, dos guías pueden ayudarle a refinarla aún más:

- **[Evaluación de la calidad de salida de la skill](/skill-creation/evaluating-skills)**: Configure casos de prueba, califique los resultados e itere sistemáticamente.
- **[Optimización de las descripciones de las skills](/skill-creation/optimizing-descriptions)**: Pruebe y mejore el campo `description` de su skill para que se active con los prompts correctos.

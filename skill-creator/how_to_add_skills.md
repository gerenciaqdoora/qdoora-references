> ## Índice de documentación
>
> Obtenga el índice completo de documentación en: https://agentskills.io/llms.txt
> Use este archivo para descubrir todas las páginas disponibles antes de explorar más a fondo.

# Cómo añadir soporte de skills a su agente

> Una guía para añadir el soporte de Agent Skills a un agente de IA o herramienta de desarrollo.

Esta guía explica cómo añadir soporte de Agent Skills a un agente de IA o herramienta de desarrollo. Cubre el ciclo de vida completo: descubrir skills, informar al modelo sobre ellas, cargar su contenido en el contexto y mantener ese contenido efectivo a lo largo del tiempo.

La integración principal es la misma independientemente de la arquitectura de su agente. Los detalles de implementación varían según dos factores:

- **¿Dónde viven las skills?** Un agente que se ejecuta localmente puede escanear el sistema de archivos del usuario en busca de directorios de skills. Un agente alojado en la nube o en un entorno aislado (sandbox) necesitará un mecanismo de descubrimiento alternativo: una API, un registro remoto o activos incluidos.
- **¿Cómo accede el modelo al contenido de la skill?** Si el modelo tiene capacidades de lectura de archivos, puede leer los archivos `SKILL.md` directamente. De lo contrario, deberá proporcionar una herramienta dedicada o inyectar el contenido de la skill en el prompt mediante programación.

La guía indica dónde son importantes estas diferencias. No necesita soportar todos los escenarios; siga el camino que mejor se adapte a su agente.

**Prerrequisitos**: Familiaridad con la [especificación de Agent Skills](/specification), que define el formato del archivo `SKILL.md`, los campos del frontmatter y las convenciones de directorios.

## El principio básico: divulgación progresiva

Cada agente compatible con skills sigue la misma estrategia de carga de tres niveles:

| Nivel           | Qué se carga                | Cuándo                               | Costo en tokens             |
| --------------- | --------------------------- | ------------------------------------ | --------------------------- |
| 1. Catálogo     | Nombre + descripción        | Inicio de la sesión                  | \~50-100 tokens por skill   |
| 2. Instrucciones | Cuerpo completo de `SKILL.md` | Cuando se activa la skill            | \<5000 tokens (recomendado) |
| 3. Recursos     | Scripts, referencias, activos | Cuando las instrucciones los refieren | Varía                       |

El modelo ve el catálogo desde el principio, por lo que sabe qué skills están disponibles. Cuando decide que una skill es relevante, carga las instrucciones completas. Si esas instrucciones hacen referencia a archivos de soporte, el modelo los carga individualmente según sea necesario.

Esto mantiene el contexto base pequeño mientras le da al modelo acceso a conocimiento especializado bajo demanda. Un agente con 20 skills instaladas no paga el costo en tokens de 20 conjuntos completos de instrucciones por adelantado, sino solo por los que realmente se usan en una conversación determinada.

## Paso 1: Descubrir skills

Al inicio de la sesión, busque todas las skills disponibles y cargue sus metadatos.

### Dónde buscar

Los directorios que debe escanear dependen del entorno de su agente. La mayoría de los agentes que se ejecutan localmente escanean al menos dos alcances (scopes):

- **Nivel de proyecto** (relativo al directorio de trabajo): Skills específicas de un proyecto o repositorio.
- **Nivel de usuario** (relativo al directorio personal): Skills disponibles en todos los proyectos para un usuario determinado.

También son posibles otros alcances; por ejemplo, skills de toda la organización desplegadas por un administrador, o skills integradas con el propio agente. El conjunto adecuado de alcances depende del modelo de despliegue de su agente.

Dentro de cada alcance, considere escanear tanto un **directorio específico del cliente** como la **convención `.agents/skills/`**:

| Alcance | Ruta                               | Propósito                     |
| ------- | ---------------------------------- | ----------------------------- |
| Proyecto | `<proyecto>/.<su-cliente>/skills/` | Ubicación nativa de su cliente |
| Proyecto | `<proyecto>/.agents/skills/`        | Interoperabilidad entre clientes |
| Usuario | `~/.<su-cliente>/skills/`         | Ubicación nativa de su cliente |
| Usuario | `~/.agents/skills/`                | Interoperabilidad entre clientes |

Las rutas `.agents/skills/` han surgido como una convención ampliamente adoptada para el intercambio de skills entre clientes. Aunque la especificación de Agent Skills no ordena dónde viven los directorios de las skills (solo define qué va dentro de ellos), escanear `.agents/skills/` significa que las skills instaladas por otros clientes compatibles son automáticamente visibles para el suyo, y viceversa.

<Note>
  Algunas implementaciones también escanean `.claude/skills/` (tanto a nivel de proyecto como de usuario) por compatibilidad pragmática, ya que muchas skills existentes están instaladas allí. Otras ubicaciones adicionales incluyen directorios ascendentes hasta la raíz de git (útil para monorepos), directorios de configuración [XDG](https://specifications.freedesktop.org/basedir-spec/latest/) y rutas configuradas por el usuario.
</Note>

### Qué buscar

Dentro de cada directorio de skills, busque **subdirectorios que contengan un archivo llamado exactamente `SKILL.md`**:

```
~/.agents/skills/
├── procesamiento-pdf/
│   ├── SKILL.md          ← descubierta
│   └── scripts/
│       └── extraer.py
├── analisis-de-datos/
│   └── SKILL.md          ← descubierta
└── README.md             ← ignorado (no es un directorio de skill)
```

Reglas prácticas de escaneo:

- Omita los directorios que no contendrán skills, como `.git/` y `node_modules/`.
- Opcionalmente, respete `.gitignore` para evitar escanear artefactos de construcción.
- Establezca límites razonables (p. ej., profundidad máxima de 4-6 niveles, máximo 2000 directorios) para evitar un escaneo descontrolado en árboles de directorios grandes.

### Manejo de colisiones de nombres

Cuando dos skills comparten el mismo `name`, aplique una regla de precedencia determinista.

La convención universal en las implementaciones existentes es: **las skills a nivel de proyecto anulan las skills a nivel de usuario.**

Dentro del mismo alcance (p. ej., dos skills llamadas `revision-de-codigo` encontradas tanto en `<proyecto>/.agents/skills/` como en `<proyecto>/.<su-cliente>/skills/`), se acepta la primera encontrada o la última encontrada; elija una y sea consistente. Registre una advertencia cuando ocurra una colisión para que el usuario sepa que una skill fue ocultada.

### Consideraciones de confianza

Las skills a nivel de proyecto provienen del repositorio en el que se está trabajando, el cual puede no ser confiable (p. ej., un proyecto de código abierto recién clonado). Considere condicionar la carga de skills a nivel de proyecto a una verificación de confianza: solo cárguelas si el usuario ha marcado la carpeta del proyecto como confiable. Esto evita que los repositorios no confiables inyecten silenciosamente instrucciones en el contexto del agente.

### Agentes alojados en la nube y en entornos aislados (sandboxed)

Si su agente se ejecuta en un contenedor o en un servidor remoto, no tendrá acceso al sistema de archivos local del usuario. El descubrimiento debe funcionar de manera diferente según el alcance de la skill:

- **Skills a nivel de proyecto**: Suelen ser el caso más sencillo. Si el agente opera sobre un repositorio clonado (incluso dentro de un sandbox), las skills a nivel de proyecto viajan con el código y pueden ser escaneadas desde el árbol de directorios del repositorio.
- **Skills a nivel de usuario y de organización**: No existen en el sandbox. Deberá proporcionarlas desde una fuente externa, por ejemplo, clonando un repositorio de configuración, aceptando URLs de skills o paquetes a través de la configuración de su agente, o permitiendo que los usuarios suban directorios de skills a través de una interfaz web.
- **Skills integradas**: Pueden empaquetarse como activos estáticos dentro del artefacto de despliegue del agente, haciéndolas disponibles en cada sesión sin necesidad de búsqueda externa.

Una vez que las skills están disponibles para el agente, el resto del ciclo de vida (análisis, revelación, activación) funciona de la misma manera.

## Paso 2: Analizar archivos `SKILL.md`

Para cada `SKILL.md` descubierto, extraiga los metadatos y el contenido del cuerpo.

### Extracción del frontmatter

Un archivo `SKILL.md` tiene dos partes: un frontmatter YAML entre delimitadores `---` y un cuerpo markdown después del delimitador de cierre. Para analizarlo:

1. Busque el `---` de apertura al inicio del archivo y el `---` de cierre posterior.
2. Analice el bloque YAML entre ellos. Extraiga `name` y `description` (obligatorios), además de cualquier campo opcional.
3. Todo lo que esté después del `---` de cierre, recortado, es el contenido del cuerpo de la skill.

Consulte la [especificación](/specification) para ver el conjunto completo de campos del frontmatter y sus restricciones.

### Manejo de YAML mal formado

Los archivos de skills creados para otros clientes pueden contener YAML técnicamente inválido que sus analizadores aceptan por casualidad. El problema más común son los valores sin comillas que contienen dos puntos:

```yaml theme={null}
# YAML técnicamente inválido: los dos puntos rompen el análisis
description: Use esta skill cuando: el usuario pregunte sobre PDFs
```

Considere una solución alternativa que envuelva dichos valores entre comillas o los convierta en escalares de bloque YAML antes de volver a intentarlo. Esto mejora la interoperabilidad entre clientes con un costo mínimo.

### Validación permisiva

Advierta sobre los problemas, pero cargue la skill cuando sea posible:

- El nombre no coincide con el nombre del directorio principal → advertir, cargar de todos modos.
- El nombre excede los 64 caracteres → advertir, cargar de todos modos.
- Falta la descripción o está vacía → omitir la skill (la descripción es esencial para la revelación), registrar el error.
- El YAML es completamente inanalizable → omitir la skill, registrar el error.

Registre los diagnósticos para que puedan mostrarse al usuario (en un comando de depuración, archivo de registro o interfaz de usuario), pero no bloquee la carga de la skill por problemas estéticos.

<Note>
  La [especificación](/specification) define restricciones estrictas para el campo `name` (coincidencia con el directorio principal, conjunto de caracteres, longitud máxima). El enfoque permisivo anterior relaja deliberadamente estas restricciones para mejorar la compatibilidad con las skills creadas para otros clientes.
</Note>

### Qué almacenar

Como mínimo, cada registro de skill necesita tres campos:

| Campo         | Descripción                          |
| ------------- | ------------------------------------ |
| `name`        | Del frontmatter                      |
| `description` | Del frontmatter                      |
| `location`    | Ruta absoluta al archivo `SKILL.md`  |

Almacene estos en un mapa en memoria indexado por `name` para una búsqueda rápida durante la activación.

También puede almacenar el **cuerpo** (el contenido markdown después del frontmatter) en el momento del descubrimiento, o leerlo desde `location` en el momento de la activación. Almacenarlo hace que la activación sea más rápida; leerlo en el momento de la activación usa menos memoria en conjunto y recoge los cambios en los archivos de las skills entre activaciones.

El **directorio base** de la skill (el directorio principal de `location`) será necesario más adelante para resolver rutas relativas y enumerar recursos incluidos; derivélo de `location` cuando sea necesario.

## Paso 3: Revelar las skills disponibles al modelo

Indique al modelo qué skills existen sin cargar su contenido completo. Este es el [nivel 1 de la divulgación progresiva](#el-principio-básico-divulgación-progresiva).

### Construcción del catálogo de skills

Para cada skill descubierta, incluya el `name`, la `description` y, opcionalmente, la `location` (la ruta al archivo `SKILL.md`) en cualquier formato estructurado que se adapte a su stack (XML, JSON o una lista con viñetas; todos funcionan):

```xml theme={null}
<available_skills>
  <skill>
    <name>procesamiento-pdf</name>
    <description>Extraer texto de PDF, rellenar formularios, combinar archivos. Úselo al manejar PDFs.</description>
    <location>/home/usuario/.agents/skills/procesamiento-pdf/SKILL.md</location>
  </skill>
  <skill>
    <name>analisis-de-datos</name>
    <description>Analizar conjuntos de datos, generar gráficos y crear informes resumidos.</description>
    <location>/home/usuario/proyecto/.agents/skills/analisis-de-datos/SKILL.md</location>
  </skill>
</available_skills>
```

El campo `location` sirve para dos propósitos: permite la activación mediante la lectura de archivos (ver [Paso 4](#paso-4-activar-skills)) y le da al modelo una ruta base para resolver referencias relativas en el cuerpo de la skill (como `scripts/evaluar.py`). Si su herramienta de activación dedicada proporciona la ruta del directorio de la skill en su resultado (ver [Envoltorio estructurado](#envoltorio-estructurado) en el Paso 4), puede omitir la `location` del catálogo. De lo contrario, inclúyala.

Cada skill añade aproximadamente entre 50 y 100 tokens al catálogo. Incluso con docenas de skills instaladas, el catálogo permanece compacto.

### Dónde ubicar el catálogo

Dos enfoques son comunes:

**Sección del system prompt**: Añada el catálogo como una sección etiquetada en el system prompt, precedida por instrucciones breves sobre cómo usar las skills. Este es el enfoque más sencillo y funciona con cualquier modelo que tenga acceso a una herramienta de lectura de archivos.

**Descripción de la herramienta**: Integre el catálogo en la descripción de una herramienta de activación de skills dedicada (ver [Paso 4](#paso-4-activar-skills)). Esto mantiene limpio el system prompt y acopla de forma natural el descubrimiento con la activación.

Ambos funcionan. La ubicación en el system prompt es más simple y ampliamente compatible; la integración en la descripción de la herramienta es más limpia cuando se tiene una herramienta de activación dedicada.

### Instrucciones de comportamiento

Incluya un bloque corto de instrucciones junto al catálogo indicando al modelo cómo y cuándo usar las skills. La redacción depende del mecanismo de activación que soporte (ver [Paso 4](#paso-4-activar-skills)):

**Si el modelo activa las skills leyendo archivos:**

```
Las siguientes skills proporcionan instrucciones especializadas para tareas específicas.
Cuando una tarea coincida con la descripción de una skill, use su herramienta de lectura
de archivos para cargar el SKILL.md en la ubicación indicada antes de proceder.
Cuando una skill haga referencia a rutas relativas, resuélvalas con respecto al directorio
de la skill (el directorio principal de SKILL.md) y use rutas absolutas en las llamadas a herramientas.
```

**Si el modelo activa las skills a través de una herramienta dedicada:**

```
Las siguientes skills proporcionan instrucciones especializadas para tareas específicas.
Cuando una tarea coincida con la descripción de una skill, llame a la herramienta
activate_skill con el nombre de la skill para cargar sus instrucciones completas.
```

Mantenga estas instrucciones concisas. El objetivo es indicarle al modelo que las skills existen y cómo cargarlas; el propio contenido de la skill proporcionará las instrucciones detalladas una vez cargado.

### Filtrado

Algunas skills deben ser excluidas del catálogo. Razones comunes:

- El usuario ha desactivado la skill en la configuración.
- Un sistema de permisos deniega el acceso a la skill.
- La skill ha optado por no ser invocada por el modelo (p. ej., a través de un flag `disable-model-invocation`).

**Oculte las skills filtradas por completo** del catálogo en lugar de enumerarlas y bloquearlas en el momento de la activación. Esto evita que el modelo pierda turnos intentando cargar skills que no puede usar.

### Cuando no hay skills disponibles

Si no se descubre ninguna skill, omita el catálogo y las instrucciones de comportamiento por completo. No muestre un bloque `<available_skills/>` vacío ni registre una herramienta de skill sin opciones válidas; esto confundiría al modelo.

## Paso 4: Activar skills

Cuando el modelo o el usuario seleccionan una skill, entregue las instrucciones completas en el contexto de la conversación. Este es el [nivel 2 de la divulgación progresiva](#el-principio-básico-divulgación-progresiva).

### Activación impulsada por el modelo

La mayoría de las implementaciones confían en el propio juicio del modelo como mecanismo de activación, en lugar de implementar una coincidencia de disparadores o detección de palabras clave en el entorno de ejecución. El modelo lee el catálogo (del [Paso 3](#paso-3-revelar-las-skills-disponibles-al-modelo)), decide que una skill es relevante para la tarea actual y la carga.

Dos patrones de implementación:

**Activación mediante lectura de archivos**: El modelo llama a su herramienta estándar de lectura de archivos con la ruta del `SKILL.md` del catálogo. No se necesita infraestructura especial; la capacidad de lectura de archivos existente del agente es suficiente. El modelo recibe el contenido del archivo como resultado de la herramienta. Este es el enfoque más simple cuando el modelo tiene acceso a los archivos.

**Activación mediante herramienta dedicada**: Registre una herramienta (p. ej., `activate_skill`) que reciba el nombre de una skill y devuelva el contenido. Esto es necesario cuando el modelo no puede leer archivos directamente, y opcional (pero útil) incluso cuando puede hacerlo. Ventajas sobre las lecturas de archivos directas:

- Controlar qué contenido se devuelve (p. ej., eliminar el frontmatter YAML o preservarlo; ver [Qué recibe el modelo](#qué-recibe-el-modelo) a continuación).
- Envolver el contenido en etiquetas estructuradas para su identificación durante la gestión del contexto.
- Enumerar los recursos incluidos (p. ej., `references/*`) junto con las instrucciones.
- Aplicar permisos o solicitar el consentimiento del usuario.
- Rastrear la activación para análisis.

<Tip>
  Si usa una herramienta de activación dedicada, restrinja el parámetro `name` al conjunto de nombres de skills válidos (p. ej., como un enum en el esquema de la herramienta). Esto evita que el modelo alucine nombres de skills inexistentes. Si no hay skills disponibles, no registre la herramienta en absoluto.
</Tip>

### Activación explícita por el usuario

Los usuarios también deben poder activar las skills directamente, sin esperar a que el modelo decida. El patrón más común es un **comando slash o sintaxis de mención** (`/nombre-de-la-skill` o `$nombre-de-la-skill`) que el entorno intercepta. La sintaxis específica depende de usted; la idea clave es que el entorno maneje la búsqueda y la inyección, de modo que el modelo reciba el contenido de la skill sin necesidad de realizar una acción de activación por sí mismo.

Un widget de autocompletado (que enumere las skills disponibles a medida que el usuario escribe) también puede hacer que esto sea fácil de descubrir.

### Qué recibe el modelo

Cuando se activa una skill, el modelo recibe las instrucciones de la misma. Dos opciones para cómo se ve exactamente ese contenido:

**Archivo completo**: El modelo ve el `SKILL.md` completo, incluyendo el frontmatter YAML. Este es el resultado natural con la activación mediante lectura de archivos, donde el modelo lee el archivo sin procesar. También es una opción válida para las herramientas dedicadas. El frontmatter puede contener campos útiles en el momento de la activación; por ejemplo, [`compatibility`](/specification#compatibility-field) indica los requisitos del entorno que podrían informar cómo el modelo ejecuta las instrucciones de la skill.

**Solo el cuerpo (frontmatter eliminado)**: El entorno analiza y elimina el frontmatter YAML, devolviendo solo las instrucciones en markdown. Entre las implementaciones existentes con herramientas de activación dedicadas, la mayoría opta por este enfoque: eliminar el frontmatter tras extraer el `name` y la `description` durante el descubrimiento.

Ambos enfoques funcionan en la práctica.

### Envoltorio estructurado

Si usa una herramienta de activación dedicada, considere envolver el contenido de la skill en etiquetas identificadoras. Por ejemplo:

```xml theme={null}
<skill_content name="procesamiento-pdf">
# Procesamiento de PDF

## Cuándo usar esta skill
Use esta skill cuando el usuario necesite trabajar con archivos PDF...

[resto del cuerpo de SKILL.md]

Directorio de la skill: /home/usuario/.agents/skills/procesamiento-pdf
Las rutas relativas en esta skill son relativas al directorio de la skill.

<skill_resources>
  <file>scripts/extraer.py</file>
  <file>scripts/combinar.py</file>
  <file>references/resumen-especif-pdf.md</file>
</skill_resources>
</skill_content>
```

Esto tiene beneficios prácticos:

- El modelo puede distinguir claramente las instrucciones de la skill de otro contenido de la conversación.
- El entorno puede identificar el contenido de la skill durante la compactación del contexto ([Paso 5](#paso-5-gestionar-el-contexto-de-la-skill-a-lo-largo-del-tiempo)).
- Los recursos incluidos se presentan al modelo sin ser cargados de forma impaciente (eager).

### Listado de recursos incluidos

Cuando una herramienta de activación dedicada devuelve el contenido de una skill, también puede enumerar los archivos de soporte (scripts, referencias, activos) en el directorio de la skill, pero **no debe leerlos de forma impaciente**. El modelo carga archivos específicos bajo demanda utilizando sus herramientas de lectura de archivos cuando las instrucciones de la skill los refieren.

Para directorios de skills grandes, considere limitar el listado e indicar que puede estar incompleto.

### Lista de permisos permitidos

Si su agente tiene un sistema de permisos que controla el acceso a los archivos, **añada los directorios de las skills a la lista de permitidos** para que el modelo pueda leer los recursos incluidos sin activar avisos de confirmación del usuario. Sin esto, cada referencia a un script incluido o archivo de referencia resultaría en un diálogo de permisos, rompiendo el flujo de las skills que incluyen recursos más allá del propio `SKILL.md`.

## Paso 5: Gestionar el contexto de la skill a lo largo del tiempo

Una vez que las instrucciones de la skill están en el contexto de la conversación, manténgalas efectivas durante toda la sesión.

### Proteger el contenido de la skill de la compactación del contexto

Si su agente trunca o resume los mensajes antiguos cuando la ventana de contexto se llena, **exima el contenido de la skill de la poda**. Las instrucciones de la skill son una guía de comportamiento duradera; perderlas en medio de una conversación degrada silenciosamente el rendimiento del agente sin ningún error visible. El modelo continúa operando, pero sin las instrucciones especializadas que proporcionaba la skill.

Enfoques comunes:

- Marcar las salidas de la herramienta de la skill como protegidas para que el algoritmo de poda las ignore.
- Usar las [etiquetas estructuradas](#envoltorio-estructurado) del Paso 4 para identificar el contenido de la skill y preservarlo durante la compactación.

### Deduplicar activaciones

Considere realizar un seguimiento de qué skills se han activado en la sesión actual. Si el modelo (o el usuario) intenta cargar una skill que ya está en el contexto, puede omitir la reinyección para evitar que las mismas instrucciones aparezcan varias veces en la conversación.

### Delegación de subagentes (opcional)

Este es un patrón avanzado solo soportado por algunos clientes. En lugar de inyectar las instrucciones de la skill en la conversación principal, la skill se ejecuta en una **sesión de subagente separada**. El subagente recibe las instrucciones de la skill, realiza la tarea y devuelve un resumen de su trabajo a la conversación principal.

Este patrón es útil cuando el flujo de trabajo de una skill es lo suficientemente complejo como para beneficiarse de una sesión dedicada y enfocada.

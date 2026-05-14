> ## Índice de documentación
>
> Obtenga el índice completo de documentación en: https://agentskills.io/llms.txt
> Use este archivo para descubrir todas las páginas disponibles antes de explorar más a fondo.

# Uso de scripts en las skills

> Cómo ejecutar comandos e incluir scripts ejecutables en sus skills.

Las skills pueden indicar a los agentes que ejecuten comandos de shell e incluir scripts reutilizables en un directorio `scripts/`. Esta guía cubre los comandos únicos, los scripts autónomos con sus propias dependencias y cómo diseñar interfaces de scripts para el uso de agentes.

## Comandos únicos (one-off)

Cuando un paquete existente ya hace lo que usted necesita, puede hacer referencia a él directamente en las instrucciones de su `SKILL.md` sin necesidad de un directorio `scripts/`. Muchos ecosistemas proporcionan herramientas que resuelven automáticamente las dependencias en tiempo de ejecución.

<Tabs sync={false}>
  <Tab title="uvx">
    [uvx](https://docs.astral.sh/uv/guides/tools/) ejecuta paquetes de Python en entornos aislados con un almacenamiento en caché agresivo. Viene con [uv](https://docs.astral.sh/uv/).

    ```bash theme={null}
    uvx ruff@0.8.0 check .
    uvx black@24.10.0 .
    ```

    * No viene integrado con Python; requiere una instalación aparte.
    * Rápido. Utiliza el almacenamiento en caché de forma agresiva, por lo que las ejecuciones repetidas son casi instantáneas.

  </Tab>

  <Tab title="pipx">
    [pipx](https://pipx.pypa.io/) ejecuta paquetes de Python en entornos aislados. Disponible a través de los gestores de paquetes del sistema operativo (`apt install pipx`, `brew install pipx`).

    ```bash theme={null}
    pipx run 'black==24.10.0' .
    pipx run 'ruff==0.8.0' check .
    ```

    * No viene integrado con Python; requiere una instalación aparte.
    * Una alternativa madura a `uvx`. Aunque `uvx` se ha convertido en la recomendación estándar, `pipx` sigue siendo una opción confiable con una disponibilidad más amplia en los gestores de paquetes de los sistemas operativos.

  </Tab>

  <Tab title="npx">
    [npx](https://docs.npmjs.com/cli/commands/npx) ejecuta paquetes npm, descargándolos bajo demanda. Viene con npm (que a su vez viene con Node.js).

    ```bash theme={null}
    npx eslint@9 --fix .
    npx create-vite@6 mi-app
    ```

    * Viene con Node.js; no necesita instalación adicional.
    * Descarga el paquete, lo ejecuta y lo almacena en caché para su uso futuro.
    * Fije las versiones con `npx paquete@versión` para lograr reproducibilidad.

  </Tab>

  <Tab title="bunx">
    [bunx](https://bun.sh/docs/cli/bunx) es el equivalente de Bun para `npx`. Viene con [Bun](https://bun.sh/).

    ```bash theme={null}
    bunx eslint@9 --fix .
    bunx create-vite@6 mi-app
    ```

    * Reemplazo directo de `npx` en entornos basados en Bun.
    * Solo es apropiado cuando el entorno del usuario tiene Bun en lugar de Node.js.

  </Tab>

  <Tab title="deno run">
    [deno run](https://docs.deno.com/runtime/reference/cli/run/) ejecuta scripts directamente desde URLs o especificadores. Viene con [Deno](https://deno.com/).

    ```bash theme={null}
    deno run npm:create-vite@6 mi-app
    deno run --allow-read npm:eslint@9 -- --fix .
    ```

    * Se requieren flags de permiso (`--allow-read`, etc.) para el acceso al sistema de archivos o a la red.
    * Use `--` para separar los flags de Deno de los propios flags de la herramienta.

  </Tab>

  <Tab title="go run">
    [go run](https://pkg.go.dev/cmd/go#hdr-Compile_and_run_Go_program) compila y ejecuta paquetes de Go directamente. Está integrado en el comando `go`.

    ```bash theme={null}
    go run golang.org/x/tools/cmd/goimports@v0.28.0 .
    go run github.com/golangci/golangci-lint/cmd/golangci-lint@v1.62.0 run
    ```

    * Integrado en Go; no se necesitan herramientas adicionales.
    * Fije las versiones o use `@latest` para que el comando sea explícito.

  </Tab>
</Tabs>

**Consejos para los comandos únicos en las skills:**

- **Fije las versiones** (p. ej., `npx eslint@9.0.0`) para que el comando se comporte de la misma manera con el tiempo.
- **Indique los prerrequisitos** en su `SKILL.md` (p. ej., "Requiere Node.js 18+") en lugar de asumir que el entorno del agente los tiene. Para los requisitos a nivel de tiempo de ejecución, use el [campo `compatibility` del frontmatter](/specification#compatibility-field).
- **Mueva los comandos complejos a scripts.** Un comando único funciona bien cuando se invoca una herramienta con unos pocos flags. Cuando un comando se vuelve lo suficientemente complejo como para que sea difícil hacerlo bien al primer intento, un script probado en `scripts/` es más confiable.

## Referencia a scripts desde `SKILL.md`

Use **rutas relativas desde la raíz del directorio de la skill** para hacer referencia a los archivos incluidos. El agente resuelve estas rutas automáticamente; no se necesitan rutas absolutas.

Enumere los scripts disponibles en su `SKILL.md` para que el agente sepa que existen:

```markdown SKILL.md theme={null}
## Scripts disponibles

- **`scripts/validar.sh`**: Valida los archivos de configuración.
- **`scripts/procesar.py`**: Procesa los datos de entrada.
```

Luego, indique al agente que los ejecute:

````markdown SKILL.md theme={null}
## Flujo de trabajo

1. Ejecute el script de validación:

   ```bash
   bash scripts/validar.sh "$ARCHIVO_DE_ENTRADA"
   ```

2. Procese los resultados:
   ```bash
   python3 scripts/procesar.py --input resultados.json
   ```
````

<Note>
  La misma convención de rutas relativas funciona en los archivos de soporte como `references/*.md`; las rutas de ejecución de scripts (en los bloques de código) son relativas a la **raíz del directorio de la skill**, porque el agente ejecuta los comandos desde allí.
</Note>

## Scripts autónomos

Cuando necesite una lógica reutilizable, incluya un script en `scripts/` que declare sus propias dependencias de forma integrada. El agente puede ejecutar el script con un solo comando; no se requiere un archivo de manifiesto separado ni un paso de instalación.

Varios lenguajes admiten declaraciones de dependencias integradas:

<Tabs sync={false}>
  <Tab title="Python">
    [PEP 723](https://peps.python.org/pep-0723/) define un formato estándar para los metadatos de los scripts integrados. Declare las dependencias en un bloque TOML dentro de los marcadores `# ///`:

    ```python scripts/extraer.py theme={null}
    # /// script
    # dependencies = [
    #   "beautifulsoup4",
    # ]
    # ///

    from bs4 import BeautifulSoup

    html = '<html><body><h1>Bienvenido</h1><p class="info">Esto es una prueba.</p></body></html>'
    print(BeautifulSoup(html, "html.parser").select_one("p.info").get_text())
    ```

    Ejecute con [uv](https://docs.astral.sh/uv/) (recomendado):

    ```bash theme={null}
    uv run scripts/extraer.py
    ```

    `uv run` crea un entorno aislado, instala las dependencias declaradas y ejecuta el script. [pipx](https://pipx.pypa.io/) (`pipx run scripts/extraer.py`) también soporta el PEP 723.

    * Fije las versiones con los especificadores del [PEP 508](https://peps.python.org/pep-0508/): `"beautifulsoup4>=4.12,<5"`.
    * Use `requires-python` para restringir la versión de Python.
    * Use `uv lock --script` para crear un archivo lock para una reproducibilidad total.

  </Tab>

  <Tab title="Deno">
    Los especificadores de importación `npm:` y `jsr:` de Deno hacen que cada script sea autónomo de forma predeterminada:

    ```typescript scripts/extraer.ts theme={null}
    #!/usr/bin/env -S deno run

    import * as cheerio from "npm:cheerio@1.0.0";

    const html = `<html><body><h1>Bienvenido</h1><p class="info">Esto es una prueba.</p></body></html>`;
    const $ = cheerio.load(html);
    console.log($("p.info").text());
    ```

    ```bash theme={null}
    deno run scripts/extraer.ts
    ```

    * Use `npm:` para los paquetes npm, `jsr:` para los paquetes nativos de Deno.
    * Los especificadores de versión siguen semver: `@1.0.0` (exacta), `@^1.0.0` (compatible).
    * Las dependencias se almacenan en caché globalmente. Use `--reload` para forzar la descarga de nuevo.
    * Es posible que los paquetes con extensiones nativas (node-gyp) no funcionen; los paquetes que incluyen binarios precompilados funcionan mejor.

  </Tab>

  <Tab title="Bun">
    Bun instala automáticamente los paquetes que faltan en tiempo de ejecución cuando no se encuentra el directorio `node_modules`. Fije las versiones directamente en la ruta de importación:

    ```typescript scripts/extraer.ts theme={null}
    #!/usr/bin/env bun

    import * as cheerio from "cheerio@1.0.0";

    const html = `<html><body><h1>Bienvenido</h1><p class="info">Esto es una prueba.</p></body></html>`;
    const $ = cheerio.load(html);
    console.log($("p.info").text());
    ```

    ```bash theme={null}
    bun run scripts/extraer.ts
    ```

    * No se necesitan `package.json` ni `node_modules`. TypeScript funciona de forma nativa.
    * Los paquetes se almacenan en caché globalmente. La primera ejecución los descarga; las siguientes son casi instantáneas.
    * Si existe un directorio `node_modules` en cualquier parte superior del árbol de directorios, la instalación automática se desactiva y Bun vuelve a la resolución estándar de Node.js.

  </Tab>

  <Tab title="Ruby">
    Bundler viene con Ruby desde la versión 2.6. Use `bundler/inline` para declarar las gemas directamente en el script:

    ```ruby scripts/extraer.rb theme={null}
    require 'bundler/inline'

    gemfile do
      source 'https://rubygems.org'
      gem 'nokogiri'
    end

    html = '<html><body><h1>Bienvenido</h1><p class="info">Esto es una prueba.</p></body></html>'
    doc = Nokogiri::HTML(html)
    puts doc.at_css('p.info').text
    ```

    ```bash theme={null}
    ruby scripts/extraer.rb
    ```

    * Fije las versiones explícitamente (`gem 'nokogiri', '~> 1.16'`), ya que no hay un archivo lock.
    * Un `Gemfile` existente o una variable de entorno `BUNDLE_GEMFILE` en el directorio de trabajo pueden interferir.

  </Tab>
</Tabs>

## Diseño de scripts para uso de agentes

Cuando un agente ejecuta su script, lee las salidas stdout y stderr para decidir qué hacer a continuación. Algunas opciones de diseño hacen que los scripts sean drásticamente más fáciles de usar para los agentes.

### Evite los prompts interactivos

Este es un requisito estricto del entorno de ejecución del agente. Los agentes operan en shells no interactivos: no pueden responder a prompts de TTY, diálogos de contraseñas o menús de confirmación. Un script que se bloquea esperando una entrada interactiva se colgará indefinidamente.

Acepte todas las entradas mediante flags de línea de comandos, variables de entorno o stdin:

```
# Mal: se cuelga esperando la entrada
$ python scripts/desplegar.py
Entorno de destino: _

# Bien: error claro con orientación
$ python scripts/desplegar.py
Error: Se requiere --env. Opciones: development, staging, production.
Uso: python scripts/desplegar.py --env staging --tag v1.2.3
```

### Documente el uso con `--help`

La salida de `--help` es la forma principal en que un agente aprende la interfaz de su script. Incluya una descripción breve, los flags disponibles y ejemplos de uso:

```
Uso: scripts/procesar.py [OPCIONES] ARCHIVO_DE_ENTRADA

Procesa los datos de entrada y genera un informe resumido.

Opciones:
  --format FORMATO   Formato de salida: json, csv, table (predeterminado: json)
  --output ARCHIVO   Escribe la salida en ARCHIVO en lugar de stdout
  --verbose          Imprime el progreso en stderr

Ejemplos:
  scripts/procesar.py datos.csv
  scripts/procesar.py --format csv --output informe.csv datos.csv
```

Manténgalo conciso: la salida entra en la ventana de contexto del agente junto con todo lo demás en lo que esté trabajando.

### Escriba mensajes de error útiles

Cuando un agente recibe un error, el mensaje da forma directamente a su siguiente intento. Un "Error: entrada no válida" opaco desperdicia un turno. En su lugar, diga qué salió mal, qué se esperaba y qué probar:

```
Error: --format debe ser uno de: json, csv, table.
       Recibido: "xml"
```

### Use salida estructurada

Prefiera los formatos estructurados (JSON, CSV, TSV) a los textos libres. Los formatos estructurados pueden ser consumidos tanto por el agente como por las herramientas estándar (`jq`, `cut`, `awk`), lo que hace que su script sea combinable en tuberías (pipelines).

```
# Alineado con espacios: difícil de analizar mediante programación
NOMBRE          ESTADO    CREADO
mi-servicio    running   2025-01-15

# Delimitado: límites de campo inequívocos
{"nombre": "mi-servicio", "status": "running", "created": "2025-01-15"}
```

**Separe los datos de los diagnósticos**: envíe los datos estructurados a stdout y los mensajes de progreso, advertencias y otros diagnósticos a stderr. Esto permite que el agente capture una salida limpia y analizable al tiempo que sigue teniendo acceso a la información de diagnóstico cuando sea necesario.

### Otras consideraciones

- **Idempotencia**: Los agentes pueden reintentar los comandos. "Crear si no existe" es más seguro que "crear y fallar si está duplicado".
- **Restricciones de entrada**: Rechace las entradas ambiguas con un error claro en lugar de adivinar. Use enums y conjuntos cerrados siempre que sea posible.
- **Soporte para ejecución en seco (dry-run)**: Para operaciones destructivas o con estado, un flag `--dry-run` permite al agente previsualizar lo que sucederá.
- **Códigos de salida significativos**: Use códigos de salida distintos para diferentes tipos de fallos (no encontrado, argumentos no válidos, fallo de autenticación) y documéntelos en su salida de `--help` para que el agente sepa qué significa cada código.
- **Valores predeterminados seguros**: Considere si las operaciones destructivas deben requerir flags de confirmación explícitos (`--confirm`, `--force`) u otras salvaguardas adecuadas al nivel de riesgo.
- **Tamaño de salida predecible**: Muchos entornos de agentes truncan automáticamente la salida de la herramienta por encima de un umbral (p. ej., 10-30K caracteres), perdiendo potencialmente información crítica. Si su script puede producir una salida grande, use por defecto un resumen o un límite razonable, y soporte flags como `--offset` para que el agente pueda solicitar más información cuando sea necesario. Alternativamente, si la salida es grande y no admite paginación, exija que los agentes pasen un flag `--output` que especifique un archivo de salida o `-` para optar explícitamente por stdout.

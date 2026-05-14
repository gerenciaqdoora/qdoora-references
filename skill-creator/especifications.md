> ## Índice de documentación
>
> Obtenga el índice completo de documentación en: https://agentskills.io/llms.txt
> Use este archivo para descubrir todas las páginas disponibles antes de explorar más a fondo.

# Especificación

> La especificación completa del formato para Agent Skills.

## Estructura de directorios

Una skill es un directorio que contiene, como mínimo, un archivo `SKILL.md`:

```
nombre-de-la-skill/
├── SKILL.md          # Obligatorio: metadatos + instrucciones
├── scripts/          # Opcional: código ejecutable
├── references/       # Opcional: documentación
├── assets/           # Opcional: plantillas, recursos
└── ...               # Cualquier archivo o directorio adicional
```

## Formato de `SKILL.md`

El archivo `SKILL.md` debe contener un frontmatter YAML seguido de contenido Markdown.

### Frontmatter (Metadatos iniciales)

| Campo           | Obligatorio | Restricciones                                                                                                     |
| --------------- | ----------- | ----------------------------------------------------------------------------------------------------------------- |
| `name`          | Sí          | Máx. 64 caracteres. Solo letras minúsculas, números y guiones. No debe empezar ni terminar con guion.             |
| `description`   | Sí          | Máx. 1024 caracteres. No vacío. Describe qué hace la skill y cuándo usarla.                                       |
| `license`       | No          | Nombre de la licencia o referencia a un archivo de licencia incluido.                                             |
| `compatibility` | No          | Máx. 500 caracteres. Indica requisitos del entorno (producto previsto, paquetes del sistema, acceso a red, etc.). |
| `metadata`      | No          | Mapeo arbitrario de clave-valor para metadatos adicionales.                                                       |
| `allowed-tools` | No          | Cadena de herramientas preaprobadas que la skill puede usar, separadas por espacios. (Experimental)               |

<Card>
  **Ejemplo mínimo:**

```markdown SKILL.md theme={null}
---
name: nombre-de-la-skill
description: Una descripción de lo que hace esta skill y cuándo usarla.
---
```

**Ejemplo con campos opcionales:**

```markdown SKILL.md theme={null}
---
name: procesamiento-pdf
description: Extraer texto de PDF, rellenar formularios, combinar archivos. Úselo al manejar PDFs.
license: Apache-2.0
metadata:
  author: example-org
  version: '1.0'
---
```

</Card>

#### Campo `name`

El campo obligatorio `name`:

- Debe tener entre 1 y 64 caracteres.
- Solo puede contener caracteres alfanuméricos unicode en minúsculas (`a-z`) y guiones (`-`).
- No debe empezar ni terminar con un guion (`-`).
- No debe contener guiones consecutivos (`--`).
- Debe coincidir con el nombre del directorio de origen.

<Card>
  **Ejemplos válidos:**

```yaml theme={null}
name: procesamiento-pdf
```

```yaml theme={null}
name: analisis-de-datos
```

```yaml theme={null}
name: revision-de-codigo
```

**Ejemplos no válidos:**

```yaml theme={null}
name: Procesamiento-PDF # No se permiten mayúsculas
```

```yaml theme={null}
name: -pdf # No puede empezar con guion
```

```yaml theme={null}
name: pdf--procesamiento # No se permiten guiones consecutivos
```

</Card>

#### Campo `description`

El campo obligatorio `description`:

- Debe tener entre 1 y 1024 caracteres.
- Debe describir tanto lo que hace la skill como cuándo usarla.
- Debe incluir palabras clave específicas que ayuden a los agentes a identificar tareas relevantes.

<Card>
  **Buen ejemplo:**

```yaml theme={null}
description: Extrae texto y tablas de archivos PDF, rellena formularios PDF y combina varios PDFs. Úselo cuando trabaje con documentos PDF o cuando el usuario mencione PDFs, formularios o extracción de documentos.
```

**Mal ejemplo:**

```yaml theme={null}
description: Ayuda con PDFs.
```

</Card>

#### Campo `license`

El campo opcional `license`:

- Especifica la licencia aplicada a la skill.
- Recomendamos mantenerlo corto (ya sea el nombre de una licencia o el nombre de un archivo de licencia incluido).

<Card>
  **Ejemplo:**

```yaml theme={null}
license: Propietario. El archivo LICENSE.txt contiene los términos completos.
```

</Card>

#### Campo `compatibility`

El campo opcional `compatibility`:

- Debe tener entre 1 y 500 caracteres si se proporciona.
- Solo debe incluirse si su skill tiene requisitos específicos del entorno.
- Puede indicar el producto previsto, los paquetes de sistema requeridos, las necesidades de acceso a la red, etc.

<Card>
  **Ejemplos:**

```yaml theme={null}
compatibility: Diseñado para Claude Code (o productos similares).
```

```yaml theme={null}
compatibility: Requiere git, docker, jq y acceso a internet.
```

```yaml theme={null}
compatibility: Requiere Python 3.14+ y uv.
```

</Card>

<Note>
  La mayoría de las skills no necesitan el campo `compatibility`.
</Note>

#### Campo `metadata`

El campo opcional `metadata`:

- Un mapa de claves de cadena a valores de cadena.
- Los clientes pueden usar esto para almacenar propiedades adicionales no definidas por la especificación de Agent Skills.
- Recomendamos que los nombres de sus claves sean razonablemente únicos para evitar conflictos accidentales.

<Card>
  **Ejemplo:**

```yaml theme={null}
metadata:
  author: example-org
  version: '1.0'
```

</Card>

#### Campo `allowed-tools`

El campo opcional `allowed-tools`:

- Una cadena de herramientas preaprobadas para ejecutarse, separadas por espacios.
- Experimental. El soporte para este campo puede variar entre las implementaciones de los agentes.

<Card>
  **Ejemplo:**

```yaml theme={null}
allowed-tools: Bash(git:*) Bash(jq:*) Read
```

</Card>

### Contenido del cuerpo

El cuerpo de Markdown después del frontmatter contiene las instrucciones de la skill. No hay restricciones de formato. Escriba lo que ayude a los agentes a realizar la tarea de manera efectiva.

Secciones recomendadas:

- Instrucciones paso a paso.
- Ejemplos de entradas y salidas.
- Casos de borde comunes.

Tenga en cuenta que el agente cargará este archivo completo una vez que haya decidido activar una skill. Considere dividir el contenido de `SKILL.md` más extenso en archivos referenciados.

## Directorios opcionales

### `scripts/`

Contiene código ejecutable que los agentes pueden correr. Los scripts deben:

- Ser autónomos o documentar claramente las dependencias.
- Incluir mensajes de error útiles.
- Manejar los casos de borde con elegancia.

Los lenguajes compatibles dependen de la implementación del agente. Las opciones comunes incluyen Python, Bash y JavaScript.

### `references/`

Contiene documentación adicional que los agentes pueden leer cuando sea necesario:

- `REFERENCE.md`: Referencia técnica detallada.
- `FORMS.md`: Plantillas de formularios o formatos de datos estructurados.
- Archivos específicos del dominio (`finanzas.md`, `legal.md`, etc.).

Mantenga las [referencias de archivos](#referencias-de-archivos) individuales enfocadas. Los agentes cargan estos archivos bajo demanda, por lo que los archivos más pequeños significan un menor uso de contexto.

### `assets/`

Contiene recursos estáticos:

- Plantillas (plantillas de documentos, plantillas de configuración).
- Imágenes (diagramas, ejemplos).
- Archivos de datos (tablas de búsqueda, esquemas).

## Divulgación progresiva

Los agentes cargan las skills de forma _progresiva_, obteniendo más detalles solo cuando una tarea lo requiere. Las skills deben estructurarse para aprovechar esto:

1. **Metadatos** (\~100 tokens): Los campos `name` y `description` se cargan al inicio para todas las skills.
2. **Instrucciones** (\< 5000 tokens recomendados): El cuerpo completo de `SKILL.md` se carga cuando se activa la skill.
3. **Recursos** (según sea necesario): Los archivos (p. ej., los que están en `scripts/`, `references/` o `assets/`) se cargan solo cuando se requieren.

Mantenga su `SKILL.md` principal por debajo de 500 líneas. Mueva el material de referencia detallado a archivos separados.

## Referencias de archivos

Al hacer referencia a otros archivos en su skill, use rutas relativas desde la raíz de la skill:

```markdown SKILL.md theme={null}
Consulte [la guía de referencia](references/REFERENCE.md) para más detalles.

Ejecute el script de extracción:
scripts/extract.py
```

Mantenga las referencias de archivos a un nivel de profundidad desde `SKILL.md`. Evite cadenas de referencia profundamente anidadas.

## Validación

Use la librería de referencia [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) para validar sus skills:

```bash theme={null}
skills-ref validate ./mi-skill
```

Esto verifica que el frontmatter de su `SKILL.md` sea válido y siga todas las convenciones de nomenclatura.

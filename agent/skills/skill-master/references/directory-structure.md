# Estructura de Directorio de Skills

Toda skill en el ecosistema QdoorA debe seguir estrictamente esta jerarquía para ser validada y sincronizada correctamente.

## `/SKILL.md` (Obligatorio)

Archivo principal que contiene los metadatos y las instrucciones centrales. Debe incluir:

- **Frontmatter**: YAML con `name` y `description`.

| Campo           | Obligatorio | Restricciones                                                                                                     |
| --------------- | ----------- | ----------------------------------------------------------------------------------------------------------------- |
| `name`          | Sí          | Máx. 64 caracteres. Solo letras minúsculas, números y guiones. No debe empezar ni terminar con guion.             |
| `description`   | Sí          | Máx. 1024 caracteres. No vacío. Describe qué hace la skill y cuándo usarla.                                       |
| `license`       | No          | Nombre de la licencia o referencia a un archivo de licencia incluido.                                             |
| `compatibility` | No          | Máx. 500 caracteres. Indica requisitos del entorno (producto previsto, paquetes del sistema, acceso a red, etc.). |
| `metadata`      | No          | Mapeo arbitrario de clave-valor para metadatos adicionales.                                                       |
| `allowed-tools` | No          | Cadena de herramientas preaprobadas que la skill puede usar, separadas por espacios. (Experimental)               |

- **Sección de Capacidades**: Qué puede hacer la skill.
- **Flujo de Trabajo**: Pasos lógicos para ejecutar la tarea.
- **Reglas de Oro**: Restricciones críticas.
- **Secciones recomendadas**:
  - Ejemplos de entradas y salidas.
  - Casos de borde comunes.

## `/scripts/` (Recomendado)

Los scripts deben:

- Ser autónomos o documentar claramente las dependencias.
- Incluir mensajes de error útiles.
- Manejar los casos de borde con elegancia.

Contiene herramientas de soporte.

- Deben ser ejecutables sin intervención humana (`--force`, `--yes`).
- Deben incluir `--help`.
- Deben estar escritos en lenguajes soportados (Python, TS, Bash).

## `/references/` (Recomendado)

Documentación técnica que el agente puede consultar si necesita detalles profundos (ej. esquemas de base de datos, guías de estilo, especificaciones de API).

## `/assets/` (Recomendado)

Archivos estáticos, plantillas de código, imágenes de referencia o archivos de ejemplo.

## `/evals/` (Obligatorio)

- `evals.json`: Define los casos de prueba.
- `/files/`: Archivos de entrada para los tests.

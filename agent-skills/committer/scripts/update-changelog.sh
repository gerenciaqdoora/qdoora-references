#!/bin/bash

# Skill: committer (Unified)
# Script para actualizar el CHANGELOG.md de forma robusta en macOS.

PROJECT_PATH=$1
COMMIT_MESSAGE=$2

if [ -z "$PROJECT_PATH" ] || [ -z "$COMMIT_MESSAGE" ]; then
    echo "Uso: $0 <ruta_proyecto> <mensaje_commit>"
    exit 1
fi

# Asegurar que el path sea relativo a la raíz del workspace
# El script se ejecuta desde la raíz o recibe la carpeta del proyecto
CHANGELOG_PATH="${PROJECT_PATH}/CHANGELOG.md"
TODAY=$(date +"%Y-%m-%d")
ENTRY="- [${TODAY}] ${COMMIT_MESSAGE}"

# Crear el archivo si no existe
if [ ! -f "$CHANGELOG_PATH" ]; then
    echo "# Historial de Cambios (Changelog) - ${PROJECT_PATH}" > "$CHANGELOG_PATH"
    echo "" >> "$CHANGELOG_PATH"
    echo "Todos los cambios notables de este proyecto serán documentados en este archivo." >> "$CHANGELOG_PATH"
    echo "" >> "$CHANGELOG_PATH"
    echo "---" >> "$CHANGELOG_PATH"
    echo "" >> "$CHANGELOG_PATH"
fi

# Insertar la nueva entrada después del encabezado (línea "---")
if grep -q "\-\-\-" "$CHANGELOG_PATH"; then
    # Insertar después de la línea que contiene "---"
    # En macOS, sed -i '' requiere manejo especial para nuevas líneas
    sed -i '' "/\-\-\-/a\\
\\
$ENTRY
" "$CHANGELOG_PATH"
else
    # Si no hay separador, simplemente añadir al principio respetando el contenido previo
    TEMP_FILE=$(mktemp)
    echo -e "$ENTRY\n\n$(cat "$CHANGELOG_PATH")" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CHANGELOG_PATH"
fi

echo "✅ Changelog actualizado en: $CHANGELOG_PATH"

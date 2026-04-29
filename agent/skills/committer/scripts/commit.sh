#!/bin/bash

# Skill: committer (Unified)
# Flujo: Changelog -> Add -> Commit

PROJECT=$1
MESSAGE=$2

# Definición de proyectos permitidos
ALLOWED_PROJECTS=("fuse-starter" "qdoora-api" "support-portal" "fuse-demo" "qdoora-references")

if [ -z "$PROJECT" ] || [ -z "$MESSAGE" ]; then
    echo "Uso: $0 <proyecto> \"<mensaje-commit>\""
    echo "Proyectos: ${ALLOWED_PROJECTS[*]}"
    exit 1
fi

# Validar si el proyecto está en la lista permitida
IS_ALLOWED=false
for p in "${ALLOWED_PROJECTS[@]}"; do
    if [ "$p" == "$PROJECT" ]; then
        IS_ALLOWED=true
        break
    fi
done

if [ "$IS_ALLOWED" = false ]; then
    echo "❌ Error: El proyecto '$PROJECT' no está en la lista de proyectos autorizados."
    echo "Lista autorizada: ${ALLOWED_PROJECTS[*]}"
    exit 1
fi

# 1. Validar existencia del directorio
if [ ! -d "$PROJECT" ]; then
    echo "❌ Error: El directorio '$PROJECT' no existe en la raíz del workspace."
    exit 1
fi

echo "🚀 Iniciando ciclo de commit para $PROJECT..."

# 2. Actualizar Changelog localmente dentro de la misma skill
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGELOG_SCRIPT="${SCRIPT_DIR}/update-changelog.sh"

if [ -f "$CHANGELOG_SCRIPT" ]; then
    echo "📝 Generando entrada en Changelog..."
    chmod +x "$CHANGELOG_SCRIPT"
    "$CHANGELOG_SCRIPT" "$PROJECT" "$MESSAGE"
else
    echo "⚠️ Advertencia: No se encontró el script de changelog en $CHANGELOG_SCRIPT"
fi

# 3. Add y Commit (Incluyendo el cambio del changelog)
echo "📦 Realizando commit (Código + Changelog)..."
git -C "$PROJECT" add .
git -C "$PROJECT" commit -m "$MESSAGE"

if [ $? -eq 0 ]; then
    echo "✅ Ciclo completado con éxito para $PROJECT."
else
    echo "❌ Error al realizar el commit. ¿Hay cambios pendientes?"
    exit 1
fi

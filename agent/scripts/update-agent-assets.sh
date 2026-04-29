#!/bin/bash

# ==============================================================================
# AGUNSA AGENT ASSETS SYNC
# ==============================================================================
# Este script sincroniza los activos del agente (rules, skills, workflows)
# desde arquitectura/agents/ hacia el directorio local .agents/ del workspace.
# ==============================================================================

# Obtener rutas
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_ROOT="$( cd "$SCRIPT_DIR/../../../" && pwd )"
AGENTS_DIR="$WORKSPACE_ROOT/.agents"
SOURCE_DIR="$( cd "$SCRIPT_DIR/../" && pwd )"

echo "----------------------------------------------------------------"
echo "🤖 AGUNSA AGENT SYNC"
echo "----------------------------------------------------------------"
echo "📍 Workspace: $WORKSPACE_ROOT"

# Asegurar directorios base
mkdir -p "$AGENTS_DIR/rules"
mkdir -p "$AGENTS_DIR/skills"
mkdir -p "$AGENTS_DIR/workflows"

sync_folder() {
    local src="$1"
    local dst="$2"
    local type="$3"

    echo "📂 Sincronizando $type..."
    
    if [ ! -d "$src" ]; then
        echo "⚠️  Aviso: Directorio fuente no encontrado: $src"
        return
    fi

    # Limpieza total previa para asegurar sincronización exacta
    # (Elimina archivos obsoletos o renombrados, ignorando archivos ocultos)
    find "$dst" -mindepth 1 -maxdepth 1 ! -name '.*' -exec rm -rf {} +

    # Re-vincular activos
    for item in "$src"/*; do
        [ -e "$item" ] || continue
        local name=$(basename "$item")
        
        # Evitar auto-vincular archivos ocultos
        if [[ "$name" == .* ]]; then continue; fi
        
        # Crear enlace simbólico
        ln -s "$item" "$dst/$name"
        echo "   ✅ $name"
    done
}

# Ejecutar sincronización
sync_folder "$SOURCE_DIR/rules" "$AGENTS_DIR/rules" "Reglas"
sync_folder "$SOURCE_DIR/skills" "$AGENTS_DIR/skills" "Habilidades"
sync_folder "$SOURCE_DIR/workflows" "$AGENTS_DIR/workflows" "Workflows"

echo "----------------------------------------------------------------"
echo "✨ Sincronización completada con éxito."
echo "----------------------------------------------------------------"

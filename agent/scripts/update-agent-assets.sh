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
SOURCE_DIR="$( cd "$SCRIPT_DIR/../" && pwd )"

AGENTS_DIR="$WORKSPACE_ROOT/.agents"
CLAUDE_DIR="$WORKSPACE_ROOT/.claude"

echo "----------------------------------------------------------------"
echo "🤖 AGUNSA AGENT SYNC"
echo "----------------------------------------------------------------"
echo "📍 Workspace: $WORKSPACE_ROOT"

# Asegurar directorios base
mkdir -p "$AGENTS_DIR/rules"
mkdir -p "$AGENTS_DIR/skills"
mkdir -p "$AGENTS_DIR/workflows"

mkdir -p "$CLAUDE_DIR/rules"
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/workflows"

# 🧪 VALIDACIÓN OBLIGATORIA DE SKILLS
echo "🔍 Validando integridad de Habilidades..."
VALIDATION_SCRIPT="$SOURCE_DIR/skills/skill-master/scripts/validate-skill.js"

for skill in "$SOURCE_DIR/skills"/*; do
    if [ -d "$skill" ]; then
        skill_name=$(basename "$skill")
        # Saltar carpetas ocultas
        if [[ "$skill_name" == .* ]]; then continue; fi
        
        node "$VALIDATION_SCRIPT" --path="$skill" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "❌ ERROR: La skill '$skill_name' no pasó la validación obligatoria."
            echo "   Ejecuta manualmente para ver errores:"
            echo "   node $VALIDATION_SCRIPT --path=$skill"
            echo "----------------------------------------------------------------"
            exit 1
        fi
        echo "   ✅ $skill_name: OK"
    fi
done
echo "----------------------------------------------------------------"

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

# Ejecutar sincronización de .agents
sync_folder "$SOURCE_DIR/rules" "$AGENTS_DIR/rules" "Reglas (.agents)"
sync_folder "$SOURCE_DIR/skills" "$AGENTS_DIR/skills" "Habilidades (.agents)"
sync_folder "$SOURCE_DIR/workflows" "$AGENTS_DIR/workflows" "Workflows (.agents)"

# Ejecutar sincronización de .claude
sync_folder "$SOURCE_DIR/rules" "$CLAUDE_DIR/rules" "Reglas (.claude)"
sync_folder "$SOURCE_DIR/skills" "$CLAUDE_DIR/skills" "Habilidades (.claude)"
sync_folder "$SOURCE_DIR/workflows" "$CLAUDE_DIR/workflows" "Workflows (.claude)"

# 🌐 SINCRONIZACIÓN CLAUDE CODE (CLAUDE.md)
echo "🌐 Sincronizando CLAUDE.md universal..."
CLAUDE_SOURCE="$SOURCE_DIR/../claude/CLAUDE.md"
CLAUDE_DEST="$WORKSPACE_ROOT/CLAUDE.md"

if [ -f "$CLAUDE_SOURCE" ]; then
    rm -f "$CLAUDE_DEST"
    ln -s "$CLAUDE_SOURCE" "$CLAUDE_DEST"
    echo "   ✅ CLAUDE.md -> Raíz del Workspace"
else
    echo "⚠️  Aviso: qdoora-references/claude/CLAUDE.md no encontrado."
fi

echo "----------------------------------------------------------------"
echo "✨ Sincronización completada con éxito."
echo "----------------------------------------------------------------"

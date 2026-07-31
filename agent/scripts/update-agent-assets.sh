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
echo "QDOORA AGENT SYNC"
echo "----------------------------------------------------------------"
echo "Workspace: $WORKSPACE_ROOT"

# Asegurar directorios base
mkdir -p "$AGENTS_DIR/rules"
mkdir -p "$AGENTS_DIR/skills"
mkdir -p "$AGENTS_DIR/workflows"

mkdir -p "$CLAUDE_DIR/skills"

# VALIDACIÓN OBLIGATORIA DE SKILLS
echo "Validando integridad de Habilidades..."
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

sync_folders() {
    local dst="$1"
    local type="$2"
    shift 2
    local sources=("$@")

    echo "Sincronizando $type..."
    
    # Limpieza total previa para asegurar sincronización exacta
    # (Elimina archivos obsoletos o renombrados, ignorando archivos ocultos)
    find "$dst" -mindepth 1 -maxdepth 1 ! -name '.*' -exec rm -rf {} +

    for src in "${sources[@]}"; do
        if [ ! -d "$src" ]; then
            continue
        fi

        # Re-vincular activos
        for item in "$src"/*; do
            [ -e "$item" ] || continue
            local name=$(basename "$item")
            
            # Evitar auto-vincular archivos ocultos
            if [[ "$name" == .* ]]; then continue; fi
            
            # Crear enlace simbólico (sin sobreescribir si ya existe)
            if [ ! -e "$dst/$name" ]; then
                ln -s "$item" "$dst/$name"
                echo "   ✅ $name"
            fi
        done
    done
}

# Ejecutar sincronización de .agents
sync_folders "$AGENTS_DIR/rules" "Reglas (.agents)" "$SOURCE_DIR/rules"
sync_folders "$AGENTS_DIR/skills" "Habilidades (.agents)" "$SOURCE_DIR/skills"
sync_folders "$AGENTS_DIR/workflows" "Workflows (.agents)" "$SOURCE_DIR/workflows"

# Ejecutar sincronización de .claude
sync_folders "$CLAUDE_DIR/skills" "Habilidades (.claude)" "$SOURCE_DIR/skills"

# SINCRONIZACIÓN CLAUDE CODE (CLAUDE.md) / ANTIGRAVITY (GEMINI.md)
echo "Sincronizando AGENT_BASE.md universal..."
AGENT_BASE_SOURCE="$SOURCE_DIR/rules/AGENT_BASE.md"
CLAUDE_DEST="$WORKSPACE_ROOT/CLAUDE.md"
GEMINI_DEST="$WORKSPACE_ROOT/GEMINI.md"

if [ -f "$AGENT_BASE_SOURCE" ]; then
    rm -f "$CLAUDE_DEST"
    rm -f "$GEMINI_DEST"
    ln -s "$AGENT_BASE_SOURCE" "$CLAUDE_DEST"
    echo "   ✅ CLAUDE.md -> Raíz del Workspace"
    ln -s "$AGENT_BASE_SOURCE" "$GEMINI_DEST"
    echo "   ✅ GEMINI.md -> Raíz del Workspace"
else
    echo "⚠️  Aviso: qdoora-references/agent/rules/AGENT_BASE.md no encontrado."
fi

echo "----------------------------------------------------------------"
echo "Sincronización completada con éxito."
echo "----------------------------------------------------------------"

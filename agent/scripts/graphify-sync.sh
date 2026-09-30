#!/bin/bash

# ==============================================================================
# QDOORA GRAPHIFY SYNC
# ==============================================================================
# Actualiza los grafos de código de los 3 repos (AST, sin LLM, sin costo) y los
# fusiona en graphify-out/graph.json de la raíz del workspace.
# Lo ejecuta el hook SessionStart de Claude Code y, tras editar código, el agente.
# NUNCA ejecutes graphify sobre la raíz del workspace: contiene deploy/ y secretos.
#
# Uso: graphify-sync.sh [--background]
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_ROOT="$( cd "$SCRIPT_DIR/../../../" && pwd )"
REPOS=(qdoora-api fuse-starter support-portal)
LOG="$HOME/.cache/graphify-qdoora-sync.log"
LOCK="$WORKSPACE_ROOT/graphify-out/.sync.lock"

# Los hooks de Claude no cargan el PATH del perfil: graphify vive en ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

sync() {
    echo "---- $(date '+%Y-%m-%d %H:%M:%S') graphify-sync"
    mkdir -p "$WORKSPACE_ROOT/graphify-out"

    # Candado: evita dos sincronizaciones simultáneas (ej. dos sesiones abiertas).
    # Uno con más de 10 minutos se considera huérfano (proceso interrumpido) y se descarta.
    find "$LOCK" -maxdepth 0 -mmin +10 -exec rmdir {} \; 2>/dev/null
    if ! mkdir "$LOCK" 2>/dev/null; then
        echo "Otra sincronización está en curso; se omite."
        return 0
    fi

    local graphs=()
    for r in "${REPOS[@]}"; do
        if [ ! -f "$WORKSPACE_ROOT/$r/graphify-out/graph.json" ]; then
            echo "⚠️  $r: sin grafo inicial. Ejecuta: cd $r && graphify extract . --code-only"
            continue
        fi
        (cd "$WORKSPACE_ROOT/$r" && graphify update . > /dev/null) || echo "⚠️  $r: update falló"
        graphs+=("$WORKSPACE_ROOT/$r/graphify-out/graph.json")
    done

    if [ ${#graphs[@]} -gt 0 ]; then
        graphify merge-graphs "${graphs[@]}" --out "$WORKSPACE_ROOT/graphify-out/graph.json"
    fi

    rmdir "$LOCK" 2>/dev/null
}

if [ "$1" = "--background" ]; then
    mkdir -p "$(dirname "$LOG")"
    sync >> "$LOG" 2>&1 &
else
    sync
fi

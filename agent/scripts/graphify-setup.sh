#!/bin/bash

# ==============================================================================
# QDOORA GRAPHIFY SETUP
# ==============================================================================
# Deja graphify operativo en una máquina nueva (o repara una existente).
# Idempotente: se puede ejecutar las veces que sea necesario.
#
# Por cada repo (qdoora-api, fuse-starter, support-portal):
#   1. Crea .graphifyignore (si no existe) y excluye graphify-out/ y .graphifyignore
#      vía .git/info/exclude (local, no se versiona).
#   2. Construye el grafo inicial (solo AST: sin LLM, sin costo) si no existe.
#   3. Instala los git hooks de graphify y revierte la línea que agregan a .gitattributes.
# Luego registra los hooks de Claude Code en .claude/settings.json de la raíz y
# genera el grafo fusionado con graphify-sync.sh.
#
# NUNCA ejecuta graphify sobre la raíz del workspace (deploy/, .pfx, planillas).
# Uso: qdoora-references/agent/scripts/graphify-setup.sh
# ==============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_ROOT="$( cd "$SCRIPT_DIR/../../../" && pwd )"
REPOS=(qdoora-api fuse-starter support-portal)
MERGE_LINE="graphify-out/graph.json merge=graphify"

export PATH="$HOME/.local/bin:$PATH"

echo "----------------------------------------------------------------"
echo "QDOORA GRAPHIFY SETUP"
echo "----------------------------------------------------------------"
echo "Workspace: $WORKSPACE_ROOT"

if ! command -v graphify > /dev/null 2>&1; then
    echo "❌ graphify no está instalado. Instálalo y vuelve a ejecutar este script:"
    echo "   uv tool install graphifyy"
    echo "   graphify install --platform claude && graphify install --platform codex && graphify install --platform agents"
    exit 1
fi
echo "graphify: $(graphify --version 2>/dev/null)"

write_ignore() {
    local repo="$1"
    local file="$WORKSPACE_ROOT/$repo/.graphifyignore"
    if [ -f "$file" ]; then
        echo "   = .graphifyignore ya existe (se respeta)"
        return
    fi
    if [ "$repo" = "qdoora-api" ]; then
        cat > "$file" <<'EOF'
graphify-out/
vendor/
node_modules/
storage/
bootstrap/cache/
public/build/
pgadmdata/
.env*
*.lock
package-lock.json
*.pfx
*.pem
*.key
# Volcados de datos sin valor estructural
mapped_port_codes.txt
missing_jurisdiction.txt
ports_chile_codes.txt
pusher-import.html
EOF
    else
        cat > "$file" <<'EOF'
graphify-out/
node_modules/
dist/
.angular/
tmp/
public/
package-lock.json
*.tsbuildinfo
.env*
EOF
    fi
    echo "   ✅ .graphifyignore creado"
}

exclude_local() {
    local repo_dir="$1"
    local exclude="$repo_dir/.git/info/exclude"
    mkdir -p "$(dirname "$exclude")"
    touch "$exclude"
    for pattern in graphify-out/ .graphifyignore; do
        grep -qxF "$pattern" "$exclude" || echo "$pattern" >> "$exclude"
    done
    echo "   ✅ graphify-out/ y .graphifyignore excluidos de git (local)"
}

# Decisión del equipo: el grafo no se versiona, así que el merge driver sobra en .gitattributes
revert_gitattributes() {
    local repo_dir="$1"
    local attrs="$repo_dir/.gitattributes"
    [ -f "$attrs" ] || return
    grep -qxF "$MERGE_LINE" "$attrs" || return
    if git -C "$repo_dir" ls-files --error-unmatch .gitattributes > /dev/null 2>&1; then
        # Versionado: quitar solo la línea de graphify, sin tocar otros cambios
        grep -vxF "$MERGE_LINE" "$attrs" > "$attrs.tmp" && mv "$attrs.tmp" "$attrs"
        echo "   ✅ línea de graphify retirada de .gitattributes"
    elif [ "$(grep -cv '^[[:space:]]*$' "$attrs")" = "1" ]; then
        # No versionado y solo contiene la línea de graphify: lo creó graphify
        rm -f "$attrs"
        echo "   ✅ .gitattributes creado por graphify eliminado"
    fi
}

for repo in "${REPOS[@]}"; do
    repo_dir="$WORKSPACE_ROOT/$repo"
    echo "== $repo"
    if [ ! -d "$repo_dir/.git" ]; then
        echo "   ⚠️  no es un repo git en $repo_dir; se omite"
        continue
    fi

    write_ignore "$repo"
    exclude_local "$repo_dir"

    if [ -f "$repo_dir/graphify-out/graph.json" ]; then
        echo "   = grafo ya existe (lo actualiza graphify-sync.sh)"
    else
        echo "   … construyendo grafo inicial (AST)"
        (cd "$repo_dir" && graphify extract . --code-only > /dev/null && graphify cluster-only . --no-label > /dev/null) \
            && echo "   ✅ grafo construido" || echo "   ❌ falló la construcción del grafo"
    fi

    (cd "$repo_dir" && graphify hook install > /dev/null) && echo "   ✅ git hooks instalados"
    revert_gitattributes "$repo_dir"
done

echo "== Claude Code (.claude/settings.json de la raíz)"
python3 - "$WORKSPACE_ROOT/.claude/settings.json" <<'EOF'
import json, os, sys

path = sys.argv[1]
os.makedirs(os.path.dirname(path), exist_ok=True)
settings = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        settings = json.load(f)

sync_cmd = '"$CLAUDE_PROJECT_DIR"/qdoora-references/agent/scripts/graphify-sync.sh --background'
wanted = {
    "SessionStart": [{"hooks": [{"type": "command", "command": sync_cmd}]}],
    "PreToolUse": [
        {"matcher": "Bash|Grep", "hooks": [{"type": "command", "command": '"$HOME"/.local/bin/graphify hook-guard search'}]},
        {"matcher": "Read|Glob", "hooks": [{"type": "command", "command": '"$HOME"/.local/bin/graphify hook-guard read'}]},
    ],
}

hooks = settings.setdefault("hooks", {})
for event, entries in wanted.items():
    # Reemplaza las entradas previas de graphify y conserva las ajenas
    current = [h for h in hooks.get(event, []) if "graphify" not in json.dumps(h)]
    hooks[event] = current + entries

with open(path, "w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("   ✅ hooks SessionStart y PreToolUse registrados")
EOF

echo "== Grafo fusionado"
"$SCRIPT_DIR/graphify-sync.sh"

echo "----------------------------------------------------------------"
echo "Setup completado. Abre las sesiones de Claude/Codex en: $WORKSPACE_ROOT"
echo "----------------------------------------------------------------"

#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
RUNTIME_USER="${RUNTIME_USER:-workspace}"

CODE_SERVER_PORT="${CODE_SERVER_PORT:-8443}"
CODE_SERVER_BIND_ADDR="${CODE_SERVER_BIND_ADDR:-0.0.0.0}"

export HF_HOME="${HF_HOME:-$WORKSPACE_DIR/.cache/huggingface}"
export HUGGINGFACE_HUB_CACHE="${HUGGINGFACE_HUB_CACHE:-$HF_HOME/hub}"
export TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-$HF_HOME/transformers}"
export TORCH_HOME="${TORCH_HOME:-$WORKSPACE_DIR/.cache/torch}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$WORKSPACE_DIR/.cache}"

if [[ -z "${CODE_SERVER_PASSWORD:-}" && -z "${CODE_SERVER_HASHED_PASSWORD:-}" ]]; then
    echo "ERROR: Set CODE_SERVER_PASSWORD or CODE_SERVER_HASHED_PASSWORD in the RunPod template." >&2
    exit 1
fi

mkdir -p \
"$WORKSPACE_DIR" \
"$WORKSPACE_DIR/models" \
"$WORKSPACE_DIR/repos" \
"$WORKSPACE_DIR/.cache" \
"$HF_HOME" \
"$HUGGINGFACE_HUB_CACHE" \
"$TRANSFORMERS_CACHE" \
"$TORCH_HOME" \
"$WORKSPACE_DIR/.config/code-server" \
"$WORKSPACE_DIR/.local/share/code-server" \
"$WORKSPACE_DIR/.code-server-data" \
"$WORKSPACE_DIR/.code-server/extensions"

chown -R workspace:workspace "$WORKSPACE_DIR" 2>/dev/null || true

CONFIG_FILE="$WORKSPACE_DIR/.config/code-server/config.yaml"

{
    echo "bind-addr: ${CODE_SERVER_BIND_ADDR}:${CODE_SERVER_PORT}"
    echo "auth: password"
    
    if [[ -n "${CODE_SERVER_HASHED_PASSWORD:-}" ]]; then
        echo "hashed-password: ${CODE_SERVER_HASHED_PASSWORD}"
    else
        echo "password: ${CODE_SERVER_PASSWORD}"
    fi
    
    echo "cert: false"
    echo "disable-telemetry: true"
    echo "disable-update-check: true"
} > "$CONFIG_FILE"

chown workspace:workspace "$CONFIG_FILE" 2>/dev/null || true

cat > "$WORKSPACE_DIR/.bashrc" <<'EOF'
export HF_HOME=/workspace/.cache/huggingface
export HUGGINGFACE_HUB_CACHE=/workspace/.cache/huggingface/hub
export TRANSFORMERS_CACHE=/workspace/.cache/huggingface/transformers
export TORCH_HOME=/workspace/.cache/torch
export XDG_CACHE_HOME=/workspace/.cache

alias ll='ls -lah'
alias models='cd /workspace/models'
alias repos='cd /workspace/repos'
EOF

chown workspace:workspace "$WORKSPACE_DIR/.bashrc" 2>/dev/null || true

echo "code-server starting on ${CODE_SERVER_BIND_ADDR}:${CODE_SERVER_PORT}"
echo "Persistent RunPod workspace: /workspace"
echo "vLLM is manual. Start it from code-server terminal with: vllm serve ..."

exec runuser -u "$RUNTIME_USER" -- env \
HOME="$WORKSPACE_DIR" \
USER="$RUNTIME_USER" \
LOGNAME="$RUNTIME_USER" \
HF_HOME="$HF_HOME" \
HUGGINGFACE_HUB_CACHE="$HUGGINGFACE_HUB_CACHE" \
TRANSFORMERS_CACHE="$TRANSFORMERS_CACHE" \
TORCH_HOME="$TORCH_HOME" \
XDG_CACHE_HOME="$XDG_CACHE_HOME" \
XDG_CONFIG_HOME="$WORKSPACE_DIR/.config" \
XDG_DATA_HOME="$WORKSPACE_DIR/.local/share" \
code-server \
--config "$CONFIG_FILE" \
--extensions-dir "$WORKSPACE_DIR/.code-server/extensions" \
--user-data-dir "$WORKSPACE_DIR/.code-server-data" \
"$WORKSPACE_DIR"
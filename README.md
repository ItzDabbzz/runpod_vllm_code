# RunPod vLLM Code Server

A minimal RunPod container base for running **code-server** with **vLLM available manually** inside the workspace.

This image is designed for RunPod pods where only `/workspace` persists across restarts.

## What This Container Does

- Starts `code-server`
- Keeps reusable data inside `/workspace`
- Provides `vllm` in the terminal
- Exposes ports for code-server and manual vLLM usage

## Persistent Paths

RunPod only persists `/workspace`, so all reusable data should live there.

| Path | Purpose |
|---|---|
| `/workspace/.cache/huggingface` | Hugging Face cache |
| `/workspace/.cache/huggingface/hub` | Hugging Face model hub cache |
| `/workspace/.cache/huggingface/transformers` | Transformers cache |
| `/workspace/.cache/torch` | Torch cache |
| `/workspace/.config/code-server` | code-server config |
| `/workspace/.local/share/code-server` | code-server data |
| `/workspace/.code-server-data` | code-server user data |
| `/workspace/.code-server/extensions` | code-server extensions |
| `/workspace/models` | optional local model storage |
| `/workspace/repos` | optional cloned repos |

## RunPod Environment Variables

### Required

| Variable | Description |
|---|---|
| `CODE_SERVER_PASSWORD` | Password for code-server login |

Alternatively, use:

| Variable | Description |
|---|---|
| `CODE_SERVER_HASHED_PASSWORD` | Hashed password for code-server login |

### Recommended

| Variable | Value |
|---|---|
| `WORKSPACE_DIR` | `/workspace` |
| `CODE_SERVER_PORT` | `8443` |
| `CODE_SERVER_BIND_ADDR` | `0.0.0.0` |
| `HF_HOME` | `/workspace/.cache/huggingface` |
| `HUGGINGFACE_HUB_CACHE` | `/workspace/.cache/huggingface/hub` |
| `TRANSFORMERS_CACHE` | `/workspace/.cache/huggingface/transformers` |
| `TORCH_HOME` | `/workspace/.cache/torch` |
| `XDG_CACHE_HOME` | `/workspace/.cache` |
| `HF_TOKEN` | Hugging Face token for gated/private models |
| `VLLM_API_KEY` | Optional API key for manual vLLM startup |

## RunPod Ports

| Port | Purpose |
|---|---|
| `8443` | code-server |
| `8000` | vLLM OpenAI-compatible API, when manually started |

## Manual vLLM Startup

Start vLLM from the code-server terminal.

Example:

```bash
vllm serve Qwen/Qwen3.6-35B-A3B \
    --download-dir "$HF_HOME" \
    --api-key "$VLLM_API_KEY" \
    --host 0.0.0.0 \
    --port 8000 \
    --max-model-len auto \
    --reasoning-parser qwen3 \
    --enable-auto-tool-choice \
    --max-num-seqs 256 \
    --max-num-batched-tokens 16384 \
    --enable-prefix-caching \
    --tool-call-parser qwen3_coder
```
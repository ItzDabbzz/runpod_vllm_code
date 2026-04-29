ARG VLLM_BASE_IMAGE=vllm/vllm-openai:cu129-nightly

FROM ${VLLM_BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
  TZ=Etc/UTC \
  PYTHONUNBUFFERED=1 \
  WORKSPACE_DIR=/workspace \
  HF_HOME=/workspace/.cache/huggingface \
  HUGGINGFACE_HUB_CACHE=/workspace/.cache/huggingface/hub \
  TRANSFORMERS_CACHE=/workspace/.cache/huggingface/transformers \
  TORCH_HOME=/workspace/.cache/torch \
  XDG_CACHE_HOME=/workspace/.cache \
  CODE_SERVER_PORT=8443 \
  CODE_SERVER_BIND_ADDR=0.0.0.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
  bash \
  ca-certificates \
  curl \
  git \
  git-lfs \
  htop \
  nano \
  openssh-client \
  procps \
  sudo \
  tini \
  vim \
  && git lfs install --system \
  && rm -rf /var/lib/apt/lists/*

ARG CODE_SERVER_VERSION=latest

RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
  amd64) cs_arch="amd64" ;; \
  arm64) cs_arch="arm64" ;; \
  *) echo "Unsupported arch: $arch"; exit 1 ;; \
  esac; \
  if [[ "$CODE_SERVER_VERSION" == "latest" ]]; then \
  asset_url="$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest \
  | sed -nE 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"([^"]*code-server-[^"]*-linux-'${cs_arch}'\.tar\.gz)".*/\1/p' \
  | head -n1)"; \
  else \
  asset_url="https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-${cs_arch}.tar.gz"; \
  fi; \
  test -n "$asset_url"; \
  curl -fsSL -o /tmp/code-server.tar.gz "$asset_url"; \
  mkdir -p /opt/code-server; \
  tar -xzf /tmp/code-server.tar.gz -C /opt/code-server --strip-components=1; \
  ln -sf /opt/code-server/bin/code-server /usr/local/bin/code-server; \
  rm -f /tmp/code-server.tar.gz

RUN mkdir -p /workspace \
  && if ! id -u workspace >/dev/null 2>&1; then \
  useradd -M -d /workspace -s /bin/bash workspace; \
  fi \
  && chown -R workspace:workspace /workspace \
  && echo 'workspace ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/workspace \
  && chmod 0440 /etc/sudoers.d/workspace

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /workspace

EXPOSE 8000 8443

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD curl -fsS "http://127.0.0.1:${CODE_SERVER_PORT}/healthz" || exit 1

ENTRYPOINT ["/usr/bin/tini", "-s", "--"]
CMD ["/usr/local/bin/start.sh"]
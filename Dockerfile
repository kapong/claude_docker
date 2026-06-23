# syntax=docker/dockerfile:1
# Claude Code in a box: remote-control + --dangerously-skip-permissions by default.
# trixie (Debian 13) ships glibc >= 2.39, required by the prebuilt rtk binary.
FROM node:22-trixie-slim

LABEL org.opencontainers.image.title="claude_docker" \
      org.opencontainers.image.description="Claude Code with Remote Control + skip-permissions, GPU-ready" \
      org.opencontainers.image.source="https://github.com/kapong/claude_docker"

# Keep apt's downloads so the BuildKit cache mounts below actually cache.
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# --- system tooling -------------------------------------------------------
# build-essential + python for native deps; rg/fd/jq for Claude's own searching.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        openssh-client \
        python3 \
        python3-pip \
        python3-venv \
        build-essential \
        ripgrep \
        fd-find \
        jq \
        less \
        unzip \
        xz-utils \
        procps \
    # debian ships fd as `fdfind`; expose the conventional `fd` name too
    && ln -sf "$(command -v fdfind)" /usr/local/bin/fd

# --- claude code ----------------------------------------------------------
RUN --mount=type=cache,target=/root/.npm \
    npm install -g @anthropic-ai/claude-code

# --- rtk (Rust Token Killer) ---------------------------------------------
# Install to /usr/local/bin so it is on PATH for every user and for the
# rtk hook that lives in the mounted ~/.claude/settings.json.
RUN curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh \
    && install -m 0755 "$(find /root -type f -name rtk | head -n1)" /usr/local/bin/rtk \
    && rtk --version

# --- workspace + entrypoint ----------------------------------------------
RUN mkdir -p /workspace
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

# Run as root so root-owned bind mounts (the usual case on Linux) are writable.
# IS_SANDBOX=1 is what lets --dangerously-skip-permissions run as root inside
# this container — Claude Code otherwise refuses root for safety.
ENV CLAUDE_REMOTE_CONTROL_SESSION_NAME_PREFIX=claude-docker \
    IS_SANDBOX=1

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

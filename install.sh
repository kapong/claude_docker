#!/usr/bin/env bash
# Installer for claude_docker. Run with:
#   curl -fsSL https://raw.githubusercontent.com/kapong/claude_docker/main/install.sh | bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/kapong/claude_docker/main"

# Pick an install dir on PATH.
if [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
  BIN=/usr/local/bin; SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  BIN=/usr/local/bin; SUDO="sudo"
else
  BIN="$HOME/.local/bin"; SUDO=""; mkdir -p "$BIN"
fi

echo "Installing claude_docker to $BIN …"
tmp="$(mktemp)"
curl -fsSL "$REPO_RAW/claude_docker" -o "$tmp"
chmod +x "$tmp"
$SUDO install -m 0755 "$tmp" "$BIN/claude_docker"
rm -f "$tmp"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "NOTE: add $BIN to your PATH (e.g. echo 'export PATH=\"$BIN:\$PATH\"' >> ~/.profile)";;
esac

# Ensure Docker is present and pull the image so the first start is instant.
if "$BIN/claude_docker" pull; then
  echo
  echo "Done. Start a session:"
  echo "  claude_docker start <name> <project_path>"
else
  echo "NOTE: run 'claude_docker pull' once Docker is installed and running."
fi

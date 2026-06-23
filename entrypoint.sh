#!/usr/bin/env bash
set -euo pipefail

cat <<EOF
──────────────────────────────────────────────────────────────
 Claude Code · Docker
 mode      : --dangerously-skip-permissions  +  --remote-control
 workspace : $(pwd)
 detach    : Ctrl-P then Ctrl-Q  (container keeps running)
 first run : /login  then  /remote-control   (token is saved to
             the mounted ~/.claude and reused next time)
──────────────────────────────────────────────────────────────
EOF

# Claude is PID-of-interest: when you /exit, the container stops.
# Remote Control fails gracefully (just a notice) until you /login,
# so it is always safe to pass the flag.
args=(--dangerously-skip-permissions --remote-control)
# RC_NAME (set via `make run <name>`) becomes the exact RC session title.
[ -n "${RC_NAME:-}" ] && args+=("$RC_NAME")
exec claude "${args[@]}" "$@"

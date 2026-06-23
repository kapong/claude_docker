# claude_docker

Run **Claude Code** inside Docker with **Remote Control** and
**`--dangerously-skip-permissions`** on by default, and **automatic GPU
passthrough** when an NVIDIA GPU is present. One command starts a named,
detached session you can attach to whenever you like — and drive from
[claude.ai/code](https://claude.ai/code) or the Claude mobile app.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/kapong/claude_docker/main/install.sh | bash
```

This drops the `claude_docker` CLI on your `PATH`, makes sure Docker is present,
and pulls the image so the first start is instant.

> Requires a **claude.ai Pro/Max** login (Remote Control does not work with API
> keys). On Team/Enterprise an admin must enable Remote Control first.

## Use

```bash
# Start a detached session. <name> = container hostname + Remote Control title.
claude_docker start myproj ~/code/myproj

# Attach when you're ready (detach again with Ctrl-P then Ctrl-Q).
claude_docker attach myproj
```

On the **first** attach: run `/login` (browser OAuth), then `/remote-control`.
Your token is saved in the session's profile dir and reused next time.

### Commands

| Command | What it does |
| --- | --- |
| `claude_docker start <name> <project_path> [<profile_path>]` | Start a new session, or **resume** a stopped one of the same name. |
| `claude_docker attach <name>` | Attach to a running session. |
| `claude_docker stop <name>` | Stop but **keep** the session (resume later). |
| `claude_docker rm <name>` | Stop and **delete** the session. |
| `claude_docker logs <name>` | Follow a session's logs. |
| `claude_docker ls` | List sessions (running and stopped). |
| `claude_docker pull` | Update to the latest image. |

`stop` then `start <name>` resumes the **same** container — conversation, login,
and history intact. To recreate with a different project/profile, `rm` it first.
Because the login persists, **Remote Control auto-connects on every resume** once
you've done `/login` + `/remote-control` the first time.

### Paths & profiles

- **project_path** is mounted at `/workspace` (where Claude works).
- **profile_path** is mounted as the container **HOME** (`/root`), so it keeps
  every tool login for that profile — Claude (`~/.claude`), plus `gh`, `git`,
  `ssh`, `npm`, etc. Defaults to `~/.claude_docker/<name>` — override the base
  dir with `CLAUDE_DOCKER_HOME`. Reuse the *same* profile path across sessions
  to share one set of logins.

### GPU

GPU passthrough auto-enables when `nvidia-smi` detects a GPU (needs the
[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
on the host). Force or disable it:

```bash
CLAUDE_DOCKER_GPU=1 claude_docker start myproj ~/code/myproj   # force on
CLAUDE_DOCKER_GPU=0 claude_docker start myproj ~/code/myproj   # off
```

## What's in the image

Node 22 + Claude Code, [`rtk`](https://github.com/rtk-ai/rtk), Python 3 + pip,
`build-essential`, `git`, `ripgrep`, `fd`, `jq`. Runs as **root** so the usual
root-owned bind mounts are writable; the image sets `IS_SANDBOX=1`, which is what
lets `--dangerously-skip-permissions` run as root inside the container.

## Notes

- The container stays up until you `/exit` (or `claude_docker stop <name>`).
- Remote Control makes outbound HTTPS only — no inbound ports are opened.
- `ponytail` is a Claude Code plugin; install it once inside a session and it
  persists in the profile dir: `/plugin marketplace add DietrichGebert/ponytail`
  then `/plugin install ponytail@ponytail`.

## Maintainer

The `Makefile` builds, tests, and publishes the image (`make help`):

```bash
make test     # build locally + smoke-test the tooling
make push     # build multi-arch (amd64+arm64) and push to GHCR
```

Image: `ghcr.io/kapong/claude_docker:latest`.

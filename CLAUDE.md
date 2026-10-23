# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A single Dockerfile extending `serversideup/php:8.5-fpm-nginx`, published as `lguan77/serversideup-php-customized`. It adds an SSH server (so deploy tools like Deployer can reach the container), fail2ban, Node.js 22 + pnpm 10, media tools (imagemagick, ghostscript, ffmpeg) and extra PHP extensions. There is no application code, test suite, or linter — the build artifact is the image.

## Commands

```bash
# Local build (same Dockerfile CI uses)
docker build -t serversideup-php-customized .

# Publish: CI is manual-only (workflow_dispatch), builds linux/amd64 + linux/arm64 and pushes to Docker Hub
gh workflow run docker-build-push.yml -f tag=<tag>   # tag defaults to "latest"
```

CI also adds `<branch>-<sha>` and `<branch>` tags. There is no push/PR trigger.

## Architecture

### Container runs as root, PHP as www-data
Upstream runs as `www-data`; this image leaves `USER root` in effect so s6 can start sshd and fail2ban (fail2ban bans via iptables, so the container also needs `NET_ADMIN` at runtime). PHP stays unprivileged because the Dockerfile appends `user = www-data` / `group = www-data` to `/usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf`. The final `chown -R root:root /run` exists for the same reason. Do not add a trailing `USER www-data`.

### s6-overlay services (`s6-rc.d/`)
Merged into the base image's s6-overlay v3 tree at `/etc/s6-overlay/s6-rc.d/`:

- `sshd` — longrun, depends on `base`, `producer-for sshd-log`. Runs `sshd -D -e` with stderr folded into stdout (`fdmove -c 2 1`).
- `sshd-log` — longrun, `consumer-for sshd`, `pipeline-name sshd-pipeline`. Runs `logutil-service /var/log/sshd`, writing `/var/log/sshd/current`. `logutil-service` drops to `nobody`, which is why the Dockerfile sets `/var/log/sshd` to `nobody:nogroup` mode `02755`.
- `fail2ban` — longrun, `fail2ban-client -x -f start`. Its jails read `/var/log/sshd/current`, so the sshd log pipeline is load-bearing for banning.
- Enablement is via empty marker files in `s6-rc.d/user/contents.d/`. The **pipeline name** (`sshd-pipeline`), not `sshd`, is what goes into the `user` bundle.

Run scripts are execline (`#!/command/execlineb`), not sh/bash. The Dockerfile COPYs each service dir and each `contents.d` marker individually (never the whole `user/` dir, which would clobber the base image's bundle) and `chmod +x`s each `run`. Adding a service requires all three steps.

### Config files (`configs/`)
Filenames encode their destination: `fail2ban-jail.d-sshd.conf` → `/etc/fail2ban/jail.d/sshd.conf`, `fail2ban-filter.d-sshd-invaliduser.conf` → `/etc/fail2ban/filter.d/sshd-invaliduser.conf`, `fail2ban.local` → `/etc/fail2ban/`, `sshd_config` → `/etc/ssh/`.

- `sshd_config`: port **10022**, pubkey-only auth, `PermitRootLogin prohibit-password`, `LogLevel VERBOSE` (fail2ban's filters depend on the verbose log lines).
- Jails `sshd` and `sshd-invaliduser` both ban permanently (`bantime = -1`) using `iptables-multiport`, which blocks only the jail's `port`. That value must match `Port` in `sshd_config` (both 10022); `port = ssh` would block 22 and leave 10022 open.

### SSH host keys are not in the image
The apt step ends with `rm -f /etc/ssh/ssh_host_*`, and neither the Dockerfile nor the `sshd` run script runs `ssh-keygen`. Host keys (and `authorized_keys`) must be supplied at runtime (e.g. mounted), otherwise sshd won't start. Build-time `ssh-keygen -A` was deliberately removed so a published image doesn't share host keys — don't re-add it.

### Other hardening
`passwd -d root` removes root's password, and `pam_wheel.so` is uncommented in `/etc/pam.d/su` so only `wheel` members can `su`; `www-data` must not be in `wheel`.

### Misc
- PHP extensions come from the base image's `install-php-extensions` (the active line is near the bottom; the commented one near the top is a leftover).
- pnpm is installed via npm with a pinned `COREPACK_INTEGRITY_KEYS` env, a workaround for nodejs/corepack#612.
- `SHELL ["/bin/bash", "-c"]` is set mid-file; RUN lines after it are bash.

## README caveat
Only the top "Overview about changes" section of README.md reflects the current image — keep it updated when behavior changes. The "Readme from original image" section below it is stale (port 22, password `Docker!`, password auth, an `ssh/` directory) and should not be trusted.

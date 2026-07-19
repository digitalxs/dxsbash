# DXSBash Development Guide

This document is for people hacking on DXSBash itself. For user-facing
docs see [README.md](README.md), the command reference in
[commands.md](commands.md), and the official website at
[https://dxsbash.digitalxs.ca](https://dxsbash.digitalxs.ca).

- Repository: https://github.com/digitalxs/dxsbash
- License: GPL-3.0
- Reference platform: Debian 13 (Trixie); also supported: Ubuntu 20.04+,
  Arch Linux, Fedora 40+

## Architecture overview

DXSBash is a set of plain shell scripts and rc files — no compiled
code, no runtime daemon. Everything revolves around one repo directory
that is cloned to a fixed location and then *symlinked into place*:

```
                      ~/linuxtoolbox/dxsbash          (the cloned repo)
                        │
        ┌───────────────┼──────────────────────────────┐
        │ rc symlinks   │ command symlinks             │ config symlinks
        ▼               ▼                              ▼
  ~/.bashrc      /usr/local/bin/dxsbash          ~/.config/starship.toml
  ~/.zshrc       /usr/local/bin/update-dxsbash        → starship-themes/<theme>.toml
  ~/.config/     /usr/local/bin/dxsbash-config   ~/.config/fastfetch/config.jsonc
    fish/          …repair …doctor …audit
    config.fish    …uninstall
```

Because every installed file is a symlink back into the repo, a
`git pull` (via `updater.sh`) updates the live configuration instantly,
and `repair.sh` only ever needs to re-create links — user data is never
inside the repo.

Per-user state lives outside the repo in `~/.dxsbash/`:

| File | Purpose |
|------|---------|
| `user.conf` | preference overrides sourced by bash/zsh (`user.fish` for fish) |
| `env-allow` | SHA-256 allowlist for trusted `.dxsbash-env` files |
| `logs/` | installer/updater logs |
| `security-summary.txt` | cached login security summary (regenerated) |
| `suid-baseline.txt` | baseline for `dxsbash audit` SUID diffing |

## Repository layout

| Path | Role |
|------|------|
| `setup.sh` | interactive + non-interactive installer (menu: install/repair/uninstall) |
| `updater.sh` | `dxsbash update` / `update-dxsbash` — pull latest release |
| `repair.sh` | re-create symlinks/commands without touching user data |
| `uninstall.sh` | full removal, restores `/etc/skel` defaults |
| `doctor.sh` | read-only health check (pass/warn/fail) |
| `secaudit.sh` | read-only system security audit (`dxsbash audit`) |
| `secsummary.sh` | cached one-line security summary at login (opt-in) |
| `dxsbash.sh` | umbrella command — dispatches subcommands to the scripts above |
| `dxsbash-config.sh` | interactive settings menu; writes `~/.dxsbash/user.conf` |
| `export-import.sh` | `dxsbash export` / `import` — settings backup tarballs |
| `bench.sh` | `dxsbash bench` — shell startup benchmarking |
| `.bashrc`, `.bash_aliases` | bash configuration (symlinked to `~`) |
| `.zshrc` | zsh configuration |
| `config.fish` | fish configuration |
| `.bashrc_help`, `.zshrc_help`, `fish_help` | `help` command content per shell |
| `commands.md` | command reference (also the data source for `cheat`) |
| `starship.toml`, `starship-themes/` | prompt presets; `ssh-lite.toml` is auto-selected over SSH |
| `config.jsonc` | fastfetch configuration |
| `reset-*-profile.sh` | revert a user's rc files to distro defaults |
| `check_dependencies.sh`, `test_compatibility.sh` | diagnostics |
| `packaging/build-deb.sh` | builds `dist/dxsbash_<version>_all.deb` |
| `.github/workflows/bashtest.yml` | CI: lint, 5-distro install matrix, deb build |
| `version.txt` | single source of truth for the version |
| `install.sh` | curl-pipe bootstrap (clones repo, runs `setup.sh`) |

## The install flow (`setup.sh`)

1. **Environment check** — sudo/root detection (`SUDO_CMD`), writable
   repo dir, sudo/wheel group membership.
2. **`detectDistro()`** — parses `/etc/os-release` `ID`, falling back to
   `ID_LIKE` for derivatives, and sets `DISTRO` to one of
   `debian | arch | fedora | unknown`.
3. **`installDepend()`** — one branch per family:
   - *debian*: `nala` when usable, else `apt`; filters package
     availability with `apt-cache show`
   - *arch*: `pacman -Sy`, availability filter via `pacman -Si`, then a
     single `pacman -Su --needed --noconfirm` transaction (avoids
     partial upgrades)
   - *fedora*: availability filter via `dnf info`, then `dnf install -y`
4. **Tool installers** — starship, fzf, zoxide via upstream curl
   scripts (distro-agnostic); FiraCode Nerd Font unless
   `DXSBASH_SKIP_FONT=1`.
5. **Shell selection** — bash/zsh/fish (flag `--shell`, env
   `DXSBASH_SHELL`, or interactive prompt); zsh gets Oh My Zsh +
   plugins, fish gets Fisher + Tide.
6. **Linking** — rc files into `$HOME`, commands into
   `/usr/local/bin`, Konsole/Yakuake profiles when KDE is present.

## Cross-shell parity rule

Every user-facing feature must work in **bash, zsh and fish**. The
three rc files deliberately mirror each other section by section
(distribution detection → aliases → special functions → init). When
adding a feature, implement it three times in the same relative
location, using each shell's native idiom — don't shell out to bash
from zsh/fish for prompt-path code. Features that read user state must
use `~/.dxsbash/` so they survive updates.

The `.dxsbash-env` per-directory files are the one deliberate
exception: they are POSIX sh, sourced natively by bash/zsh, while fish
applies only the portable `export KEY=VALUE` / `alias name='cmd'`
subset via a translator (`__dxs_env_apply` in `config.fish`).

## Distro support checklist

When touching anything package-related, update all of:

- `setup.sh` — `installDepend()` family branches
- `.bashrc` `setup_package_aliases()` + `install_bashrc_support()`
- `.zshrc` package alias block + `install_zshrc_support()`
- `config.fish` package alias block + `install_fish_support`
- `repair.sh` / `check_dependencies.sh` install hints

Package-name differences to remember: Debian's `bat` package installs
a `batcat` binary; `nala` exists only on Debian/Ubuntu; AUR helpers
(`paru`/`yay`) must never run under sudo.

## Testing

Local quick pass (what CI's lint job runs):

```bash
shellcheck -S warning ./*.sh
bash -n setup.sh .bashrc .bash_aliases
zsh  -n .zshrc
fish -n config.fish
./test_compatibility.sh          # distro-aware; strict only on Debian 13
bash bench.sh --runs 3           # startup regression check
```

CI (`.github/workflows/bashtest.yml`) runs three jobs on every push/PR:

1. **lint** — shellcheck + syntax for all three shells
2. **install-test** — full `./setup.sh --install --yes --shell bash`
   inside `debian:13`, `debian:12`, `ubuntu:24.04`, `archlinux:latest`
   and `fedora:latest` containers (with `DXSBASH_SKIP_FONT=1`),
   followed by `doctor.sh`, config-load, audit and summary smoke tests
3. **build-deb** — builds the `.deb`, verifies contents, smoke-installs

## Packaging (.deb)

```bash
./packaging/build-deb.sh         # → dist/dxsbash_<version>_all.deb
```

The package ships the repo to `/usr/share/dxsbash` plus a
`/usr/bin/dxsbash-installer` bootstrap that copies it into the invoking
user's `~/linuxtoolbox/dxsbash` and runs `setup.sh`. The .deb is a
distribution vehicle — per-user setup still happens through the normal
installer, so multi-user machines work and nothing in `$HOME` is owned
by the package manager.

## Release process

1. Update `version.txt` (semver — this file is the single source of truth).
2. Add a dated section to `CHANGELOG.md` (Keep-a-Changelog format).
3. Update the version string in `README.md` (line 2) and the
   `version-tag` span in `index.html`.
4. Document new commands in `commands.md` and, if user-visible, README.
5. Run the local test pass above; push and let the CI matrix go green.
6. Merge to `main`. `update-dxsbash` on user machines pulls the tagged
   state of `main`.

## Coding conventions

- Bash scripts: `set -euo pipefail` for new standalone scripts
  (rc files must NOT `set -e` — they run inside user shells).
- shellcheck-clean at `-S warning` for scripts, `-S error` for rc files;
  annotate intentional violations with `# shellcheck disable=` plus a
  reason.
- Keep the `RC`/`GREEN`/`YELLOW`/`CYAN` color convention and the
  `▶ / ✓ / ⚠ / ✗` message prefixes used across scripts.
- Guard every alias or feature that depends on optional infrastructure
  (`command -v`/`type -q` checks) — a missing tool must never break
  shell startup.
- Comments explain *why* (constraints, distro quirks), not *what*.

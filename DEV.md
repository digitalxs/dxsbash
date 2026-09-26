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
    fish/        /usr/local/bin/dxsbash-gui
    config.fish    …repair …doctor …audit …uninstall

  desktop integration (desktops only, per user — written by dxsbash-gui --install-desktop):
    ~/.local/share/applications/dxsbash-settings.desktop   (System category)
    ~/.local/share/icons/hicolor/{16..256,scalable}/apps/dxsbash.{png,svg}
    ~/.config/systemd/user/dxsbash-update-check.{timer,service}  (daily update-notify.sh)
    ~/.local/share/konsole/DXSBash*.colorscheme                 (theme-matched colors)
```

Because every installed file is a symlink back into the repo, a
`git pull` (via `updater.sh`) updates the live configuration instantly,
and `repair.sh` only ever needs to re-create links — user data is never
inside the repo. The one symlink that is *user state* is
`~/.config/starship.toml`: it points at whichever theme the user picked
(or is a hand-written file), so `updater.sh` and `repair.sh` only relink
it when it is missing or dangling — never back to the default.

Per-user state lives outside the repo in `~/.dxsbash/`:

| File | Purpose |
|------|---------|
| `user.conf` | preference overrides sourced by bash/zsh (`user.fish` for fish) — written only through `settings-lib.sh` |
| `custom-aliases.sh` | user aliases from the GUI editor, sourced by bash/zsh after the DXSBash defaults |
| `custom-aliases.fish` | generated fish twin of `custom-aliases.sh` (never edit by hand) |
| `themes/` | the user's own Starship themes (`*.toml`), shown in both pickers as id `user/<file>` |
| `update-notified` | last version the update notifier announced (one notification per version) |
| `env-allow` | SHA-256 allowlist for trusted `.dxsbash-env` files |
| `logs/` | installer/updater logs; `gui.log` holds zenity diagnostics for the last GUI session |
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
| `settings-lib.sh` | **the settings model** — defaults, theme registry, read/write of `user.conf`/`user.fish`, theme linking, custom-alias store. Sourced by both settings front ends; add new settings here only |
| `dxsbash-config.sh` | terminal settings menu (front end over `settings-lib.sh`) |
| `dxsbash-gui.sh` | zenity settings window (front end over `settings-lib.sh`); also owns the menu entry (`--install-desktop` / `--remove-desktop`, called by setup/repair/updater) and `--selftest` |
| `gui-askpass.sh` | graphical `SUDO_ASKPASS` helper so sudo can prompt without a terminal |
| `update-notify.sh` | daily update check → desktop notification with *Update now* (run by the systemd user timer) |
| `systemd/` | `dxsbash-update-check.{service,timer}` (per-user; installed with the menu entry) |
| `assets/konsole/` | Konsole color schemes matched to the built-in themes (see `konsole_scheme_for_theme`) |
| `desktop/dxsbash-settings.desktop.in` | menu entry template (`@GUI@` is replaced at install time) |
| `assets/icons/hicolor/` | app icon: SVG master + pre-rendered PNG sizes (GTK4 only resolves themed icons from sized PNG dirs) |
| `assets/theme-previews/`, `assets/screenshots/` | README images (theme previews are generated — see below) |
| `tools/ansi2pango.awk` | ANSI → Pango markup converter (POSIX awk); powers the GUI's live theme previews |
| `tools/render-theme-previews.sh` | dev-only: regenerates `assets/theme-previews/*.png` |
| `dxsbash-utils.sh` | shared helpers sourced by `.bashrc` and `.zshrc` (logging, `cheat`, `.dxsbash-env` trust, ssh-lite selector) |
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
| `packaging/build-arch.sh`, `packaging/arch/` | builds the Arch package (`PKGBUILD`, install hook) |
| `packaging/dxsbash-installer` | per-user bootstrap shipped by both packages |
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
7. **Desktop integration** — `detect_desktop` in `settings-lib.sh`
   (shared with the updater) reports `kde`, `xfce`, `other` or nothing.
   KDE Plasma and XFCE count when *installed* (`plasmashell` /
   `xfce4-session`, or their session files), so SSH/TTY installs still
   get the GUI; other desktops need a running session or an installed
   session file. `DXSBASH_DESKTOP=1|0` overrides. A desktop adds `zenity`
   to the dependency list and installs the *DXSBash Settings* menu entry
   and update timer; headless servers get neither (no GTK stack).

## Settings architecture

```
  dxsbash-config.sh (terminal)      dxsbash-gui.sh (zenity)
            │                                │
            └──────────► settings-lib.sh ◄───┘
                 defaults · theme registry · load/write · alias store
                                 │
       ┌─────────────────────────┼──────────────────────────────┐
       ▼                         ▼                              ▼
 ~/.dxsbash/user.conf     ~/.config/starship.toml     ~/.dxsbash/custom-aliases.sh
 ~/.dxsbash/user.fish       (symlink → theme)          ~/.dxsbash/custom-aliases.fish
       │                         │                              │
       └────── sourced by .bashrc / .zshrc / config.fish at startup ──────┘
```

Rules of the model:

- `write_settings` always regenerates the whole `user.conf` and its fish
  twin from the `CUR_*` values — both front ends, same keys. A new
  setting = a `DEF_*` default + `load_settings` + `write_settings` entry.
- Values are written in bash's language (`HISTSIZE=-1` = unlimited);
  `.zshrc` translates what zsh spells differently (`SAVEHIST`, no -1).
- Themes have ids: a built-in preset's file name, or `user/<file>` for
  `~/.dxsbash/themes`. Always go through `theme_entries` / `theme_path` /
  `link_starship_theme` — never build paths by hand.
- `apply_terminal_colors` edits only `ColorScheme=` in the DXSBash Konsole
  profile (`_ini_set`), and only for built-in themes; `setup.sh` calls it
  (via `dxsbash-gui --apply-colors`) right after writing the profile.
- Custom aliases are stored as `alias name='cmd'` lines; POSIX
  single-quote escaping (`'\''`) differs from fish (`\'`), so the fish
  file is regenerated from the POSIX one after every change and on
  every GUI start (hand edits of the `.sh` file are picked up).
- The GUI's theme picker renders each theme's *real* prompt
  (`starship prompt` inside the user's DXSBash checkout) through
  `tools/ansi2pango.awk` into Pango markup — no images, the user's own
  fonts. zenity gotchas handled in `dxsbash-gui.sh`: option text needs a
  UTF-8 locale (`ensure_utf8_locale`), `--text` is backslash-unescaped
  and markup-parsed (`esc`), `--icon` takes an icon *name*, and in
  bash ≥ 5.2 `&` in a `${var//pat/rep}` replacement must be quoted.

## Cross-shell parity rule

Every user-facing feature must work in **bash, zsh and fish**. The
three rc files deliberately mirror each other section by section
(distribution detection → aliases → special functions → init). Code
that is POSIX-portable between bash and zsh should live **once** in
`dxsbash-utils.sh` (sourced by both rc files — `cheat`, the
`.dxsbash-env` machinery and the ssh-lite prompt selector live there);
fish always needs its own implementation in `config.fish` using fish
idioms. Don't shell out to bash from zsh/fish for prompt-path code.
Features that read user state must use `~/.dxsbash/` so they survive
updates.

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
bash dxsbash-gui.sh --selftest   # settings model, aliases in bash+fish, menu entry
shellcheck -S warning ./*.sh
bash -n setup.sh .bashrc .bash_aliases
zsh  -n .zshrc
fish -n config.fish
./test_compatibility.sh          # distro-aware; strict only on Debian 13
bash bench.sh --runs 3           # startup regression check
```

CI (`.github/workflows/bashtest.yml`) runs three jobs on every push/PR:

1. **lint** — shellcheck + syntax for all three shells + `dxsbash-gui --selftest`
2. **install-test** — full `./setup.sh --install --yes --shell bash`
   inside `debian:13`, `debian:12`, `ubuntu:24.04`, `archlinux:latest`
   and `fedora:latest` containers (with `DXSBASH_SKIP_FONT=1`),
   followed by `doctor.sh`, config-load, audit and summary smoke tests
3. **build-deb** — builds the `.deb`, verifies contents, smoke-installs
4. **build-arch** — builds the Arch package in `archlinux:latest`, installs it

## Packaging (.deb and Arch)

```bash
./packaging/build-deb.sh     # → dist/dxsbash_<version>_all.deb   (needs dpkg-deb)
./packaging/build-arch.sh    # → dist/dxsbash-<version>-1-any.pkg.tar.zst  (Arch, non-root, makepkg)
```

Both packages ship the repository to `/usr/share/dxsbash` and install
`packaging/dxsbash-installer` (shared by both) as `/usr/bin/dxsbash-installer`.
That per-user bootstrap clones the repo into `~/linuxtoolbox/dxsbash` (full
clone, so release fast-forwards work; the packaged tree is the offline
fallback) and runs `setup.sh`. Packages are distribution vehicles —
nothing in `$HOME` is owned by the package manager, and multi-user
machines work.

- `packaging/arch/PKGBUILD` builds from the GitHub release tarball
  (`v$pkgver`), suitable for the AUR. `build-arch.sh` rewrites its
  `pkgver`/`source`/`sha256sums` to package the local working tree.
- `build-deb.sh` also runs on Arch/Fedora with the `dpkg` package
  installed (to publish a .deb from there).
- CI builds and installs both (`build-deb`, `build-arch` jobs) and
  uploads them as the `dxsbash-deb` / `dxsbash-arch` artifacts.
- Both were verified end to end: `pacman -U` + `dxsbash-installer` on a
  real Arch root; `apt install` + `dxsbash-installer` on Debian/Ubuntu.

## Update channels

`updater.sh` resolves a channel (`--channel` flag > `user.conf` >
`$DXSBASH_UPDATE_CHANNEL` > `stable`):

- **stable** — the newest `vX.Y.Z` tag from `git ls-remote` (pre-release
  tags like `-beta` are skipped); the local `main` branch is
  fast-forwarded to it (never moved backwards).
- **main** — `git pull origin main`, as before.

The decision is commit-based (`update_status` / `commit_update_available`):
an update exists when the channel's target commit — the newest tag,
peeled, or `main`'s tip — is not already contained in the checkout. So
no downgrades (a main snapshot ahead of the newest tag is up to date),
unbumped commits on main are seen, and a tag whose `version.txt` was not
bumped cannot loop. Shallow clones fall back to comparing versions and
are unshallowed on the first stable update. Fresh installs (`setup.sh`,
`install.sh`) clone `main`; stable users then move on at the next tag.
A release therefore reaches stable users **only once it is tagged**.

## Release process

1. Update `version.txt` (semver — this file is the single source of truth).
2. Add a dated section to `CHANGELOG.md` (Keep-a-Changelog format).
3. Update the version string in `README.md` (line 2) and the
   `version-tag` span in `index.html`.
4. Document new commands in `commands.md`, the three help files and,
   if user-visible, README.
5. If a theme in `starship-themes/` changed, regenerate the README
   previews: `sudo tools/render-theme-previews.sh` (needs starship,
   ImageMagick with Pango, a Nerd Font).
6. Run the local test pass above; push and let the CI matrix go green.
7. Merge to `main`, then **tag the merge commit** — stable-channel users
   (the default) only receive tagged releases:
   `git tag -a v3.9.0 -m "DXSBash 3.9.0" && git push origin v3.9.0`
   (the tag must match `version.txt`). `update-dxsbash` then moves stable
   machines to the new tag; main-channel machines already follow `main`.

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

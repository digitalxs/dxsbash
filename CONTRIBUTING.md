# Contributing to DXSBash

Thanks for your interest in improving DXSBash! Contributions for any
distribution are welcome — the project is developed primarily on Debian
and Arch, and help making it work well elsewhere is especially valued.

## Getting started

```bash
git clone https://github.com/digitalxs/dxsbash.git
cd dxsbash
```

The repository *is* the product: the shell configs (`.bashrc`, `.zshrc`,
`config.fish`), the lifecycle scripts (`setup.sh`, `updater.sh`,
`repair.sh`, `uninstall.sh`, `doctor.sh`, `dxsbash-config.sh`), and the
help/theme assets. There is no build step.

## Before you open a pull request

Run the same checks CI runs:

```bash
# Static analysis (must be clean)
shellcheck -S warning ./*.sh
shellcheck -S error .bashrc .bash_aliases .bashrc_help

# Syntax checks for all three shells
for f in *.sh .bashrc .bash_aliases .bashrc_help; do bash -n "$f"; done
zsh -n .zshrc && zsh -n .zshrc_help
fish --no-execute config.fish && fish --no-execute fish_help
```

CI also performs a full non-interactive install inside Debian 12,
Debian 13 and Ubuntu 24.04 containers and validates the result with
`doctor.sh`. You can reproduce that locally with Docker:

```bash
docker run --rm -it -v "$PWD":/src debian:13 bash -c '
  apt-get update && apt-get install -y sudo git curl wget ca-certificates unzip
  mkdir -p /root/linuxtoolbox && cp -a /src /root/linuxtoolbox/dxsbash
  cd /root/linuxtoolbox/dxsbash
  DXSBASH_SKIP_FONT=1 ./setup.sh --install --yes --shell bash
  ./doctor.sh --no-color --verbose'
```

## Guidelines

- **Keep the three shells in sync.** Most aliases and functions exist in
  `.bashrc`/`.bash_aliases`, `.zshrc`, *and* `config.fish`. If you add or
  change one, update all three (or explain in the PR why it is
  shell-specific). Divergence between shells has historically been the
  main source of bugs.
- **Guard optional tools.** Never alias or call a command that may not be
  installed without a `command -v` (bash/zsh) or `type -q` (fish) check.
- **Don't alias core utilities to incompatible replacements** (e.g.
  `grep` → `rg`): flag semantics differ and break functions and habits.
- **Non-breaking by default.** Existing file locations, symlink targets
  and command names (`update-dxsbash`, `dxsbash-*`) are public interface —
  changing them requires a migration path in `updater.sh`/`repair.sh`.
- **Update the docs.** New aliases/functions should be reflected in the
  help files (`.bashrc_help`, `.zshrc_help`, `fish_help`) and
  `commands.md`.
- **Changelog.** Add an entry under `## [Unreleased]` in `CHANGELOG.md`
  (Keep a Changelog format, SemVer versioning).

## Reporting issues

Use the issue templates. For installation problems, please attach the
output of `dxsbash doctor --verbose` (or `./doctor.sh --verbose`) and
your distribution/release.

## License

By contributing you agree that your contributions are licensed under the
GPL-3.0 license that covers the project.

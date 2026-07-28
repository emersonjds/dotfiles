# Dotfiles

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![macOS](https://img.shields.io/badge/macOS-supported-black?logo=apple&logoColor=white)
![Debian/Ubuntu/Mint](https://img.shields.io/badge/Debian%2FUbuntu%2FMint-supported-A81D33?logo=debian&logoColor=white)
![Fedora](https://img.shields.io/badge/Fedora-supported-51A2DA?logo=fedora&logoColor=white)
![Arch](https://img.shields.io/badge/Arch-supported-1793D1?logo=archlinux&logoColor=white)
![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-89e051?logo=gnubash&logoColor=white)

One command turns a bare **macOS**, **Debian / Ubuntu / Mint**, **Fedora** or **Arch** box
into a working dev machine: shell, SDKs, environment variables, editors and apps.

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

That is it. The OS is detected, everything else follows. Open a new terminal when it ends.

## Commands

| Command                       | What it does                                                                        |
| ----------------------------- | ----------------------------------------------------------------------------------- |
| `./install.sh`                | Full setup: packages **and** configs. Safe to re-run at any time.                   |
| `./install.sh --configs-only` | Push configs from the repo to the machine. Seconds, no package manager.             |
| `./sync.sh`                   | Pull back: machine configs and package lists into the repo. Review with `git diff`. |
| `./doctor.sh`                 | Read-only health check. Runs automatically at the end of every install.             |

## Nothing is ever reinstalled

Every step is **install if missing, upgrade if present**. Running `./install.sh` on a
fully configured machine installs nothing — it just brings things up to date.

| Layer                                          | Missing                        | Already there                        |
| ---------------------------------------------- | ------------------------------ | ------------------------------------ |
| Homebrew formulae, casks, fonts, Mac App Store | `brew bundle` installs it      | `brew upgrade`                       |
| Node                                           | `nvm install --lts`            | no-op when the latest LTS is current |
| Ruby                                           | rbenv builds the newest stable | kept, so no project breaks under you |
| npm globals                                    | `npm i -g pkg@latest`          | same command upgrades it             |
| Bun                                            | official installer             | `bun upgrade`                        |
| VS Code extensions                             | `--install-extension`          | `--force` upgrades in place          |
| Oh My Zsh                                      | official installer             | `upgrade.sh`                         |
| Configs                                        | copied over                    | untouched when byte-identical        |

## Installed is not the same as working

A package manager can report success while the shell still cannot find the binary. So the
install never ends at "packages installed": it copies the shell config and then verifies it.

`./doctor.sh` starts a login zsh from a **bare environment** — no inherited `PATH`, nothing
carried over from the current session — which is the only way to see what a genuinely new
terminal gets. It checks:

- every config file, repo against machine, in both directions
- all 42 expected CLIs resolve: node, npm, java, mvn, python3, ruby, cargo, flutter, dart,
  adb, psql, mysql, gh, docker, claude and the rest
- `JAVA_HOME`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `NVM_DIR`, `BUN_INSTALL`, `PNPM_HOME`
  are exported _and_ point at directories that exist
- `PATH` ordering, where it actually matters: `java` must come from `JAVA_HOME` and not
  from the `/usr/bin` stub, and no entry may appear twice
- the Brewfile is satisfied, npm globals are present, VS Code extensions are installed

Non-zero exit when anything is off, so it works in a script too.

## Supported systems

| System                          | Detected as | System base | GUI apps              |
| ------------------------------- | ----------- | ----------- | --------------------- |
| macOS                           | `macos`     | Homebrew    | casks + Mac App Store |
| Debian, Ubuntu, Mint, Pop!\_OS… | `debian`    | `apt`       | `.deb` + Flatpak      |
| Fedora, RHEL, Rocky, Alma       | `fedora`    | `dnf`       | `.rpm` + Flatpak      |
| Arch, Manjaro, EndeavourOS      | `arch`      | `pacman`    | Flatpak               |

Derivatives are matched through `ID_LIKE` in `/etc/os-release`, so Mint and Pop!\_OS resolve
to `debian` without being named. Only the system base and the GUI apps are distro-specific:
every CLI comes from Homebrew on Linux, so the terminal is byte-identical everywhere.

## Copies, not symlinks

Configs are **copied** into place. The old model symlinked `~/.zshrc` into the repo, which
meant moving or deleting the repo folder killed the entire shell: broken `PATH`, missing
tools, no `claude`. A repo should not be a runtime dependency of the thing that has to work
every time you open a terminal.

So the repo is the **versioned** source, not the live one, and the flow runs both ways:

| You edited                                        | Run                                     |
| ------------------------------------------------- | --------------------------------------- |
| the **repo** (`shell/`, `config/`, `git/`)        | `./install.sh --configs-only`           |
| the **machine** (`~/.zshrc`, `~/.config/shell/…`) | `./sync.sh`, then `git diff` and commit |

> Run `./sync.sh` _before_ editing the repo, not after: it overwrites repo files with what
> the machine has. Everything is versioned, so `git diff` always shows exactly what came back.

Existing files are backed up to `*.bak.<timestamp>` before being replaced — one backup per
file, the previous one is pruned — and leftover symlinks from the old model are removed,
including the `*.bak.*` entries that are themselves symlinks into the repo.

### Repo → machine

| Repo                                       | Machine                                                             |
| ------------------------------------------ | ------------------------------------------------------------------- |
| `shell/zshrc`                              | `~/.zshrc`                                                          |
| `shell/zprofile`                           | `~/.zprofile` (login shell: `brew shellenv` only)                   |
| `shell/env.sh`, `aliases.sh`, `plugins.sh` | `~/.config/shell/`                                                  |
| `git/gitconfig`                            | `~/.gitconfig`                                                      |
| `config/starship.toml`                     | `~/.config/starship.toml`                                           |
| `config/zed/settings.json`                 | `~/.config/zed/settings.json`                                       |
| `config/vscode/settings.json`              | `~/Library/Application Support/Code/User/` · `~/.config/Code/User/` |
| `config/iterm2/emerson.json`               | `~/Library/Application Support/iTerm2/DynamicProfiles/`             |

The map lives once, in `dotfiles_map()` (`lib/common.sh`): `install.sh` reads it going out,
`sync.sh` reads it coming back. Version a new file by adding one line there.

## Versions

Always the latest stable, with one exception: **Java is pinned to 17**, the version Android,
React Native and Flutter all agree on. To override on a single machine without touching the
repo, create `~/.config/shell/versions.env`:

```bash
JAVA_VERSION=21
```

## What you get

**Terminal** — zsh + Oh My Zsh, starship prompt, autosuggestions, syntax highlighting,
zoxide (`z partial-name`), fzf (Ctrl-R history, Ctrl-T files), eza, ripgrep, neovim.

**Languages** — Node via nvm (latest LTS) with pnpm / yarn / bun, OpenJDK + Maven,
Python + pipx, Rust, Ruby via rbenv.

**Mobile** — Flutter, Android cmdline-tools and platform-tools, watchman, adb-enhanced,
kdoctor, CocoaPods (macOS), ngrok.

**AI CLIs** — Claude Code, GitHub Copilot CLI plus the `gh copilot` extension, opencode.

**Data & containers** — PostgreSQL, MySQL, Docker, DBeaver, MongoDB Compass, Supabase CLI.

**Apps** — VS Code, Zed, iTerm2, Ghostty, Obsidian, Bruno, Chrome, Discord, WhatsApp,
Notion, Outlook, LibreOffice. On Linux, apps without a decent native package (WhatsApp,
Notion, Outlook) become Chrome PWA `.desktop` shortcuts; the rest come from official repos
or Flatpak.

**Fonts** — JetBrains Mono Nerd Font, Cascadia Code, Inter. The Nerd Font is what makes
eza and starship icons render.

## Environment

Set in `shell/env.sh`, resolved at runtime per OS:

| Variable                            | macOS                   | Linux                      |
| ----------------------------------- | ----------------------- | -------------------------- |
| `JAVA_HOME`                         | `java_home -v 17`       | `brew --prefix openjdk@17` |
| `ANDROID_HOME` / `ANDROID_SDK_ROOT` | `~/Library/Android/sdk` | `~/Android/Sdk`            |
| `NVM_DIR` · `BUN_INSTALL`           | `~/.nvm` · `~/.bun`     | same                       |
| `PNPM_HOME`                         | `~/Library/pnpm`        | `~/.local/share/pnpm`      |
| `RBENV_ROOT` · `PYENV_ROOT`         | only when installed     | only when installed        |
| `LC_ALL`                            | `en_US.UTF-8`           | `en_US.UTF-8`              |

`PATH` also picks up Homebrew, the Android tools, bun, pnpm, yarn, Solana, JetBrains Toolbox
and `~/.local/bin` — last, and therefore highest priority, because that is where `claude`,
`uv` and the pipx binaries live.

Every entry goes through `path_prepend`, which adds a directory only if it exists and is not
already there, so re-sourcing `env.sh` never duplicates anything. `brew shellenv` runs in
`~/.zprofile` only; `env.sh` calls it solely as a fallback when `brew` is off `PATH`.

## Layout

| Path                                | Responsibility                                                           |
| ----------------------------------- | ------------------------------------------------------------------------ |
| `install.sh`                        | Entrypoint: detect OS, dispatch, run the common stage                    |
| `sync.sh`                           | Machine → repo, for configs and package manifests                        |
| `doctor.sh`                         | Health check, changes nothing                                            |
| `test.sh`                           | Self-check for `install_file`'s backup handling                          |
| `lib/common.sh`                     | Helpers: logging, OS detection, `dotfiles_map`, `install_file`           |
| `lib/stage_common.sh`               | Configs, Node, Ruby, bun, npm globals, VS Code extensions, default shell |
| `macos/setup.sh` + `macos/Brewfile` | Homebrew install; the Brewfile is a snapshot of the machine              |
| `macos/terminal-setup.sh`           | iTerm2 / Terminal.app fonts via plist — run with iTerm2 **closed**       |
| `linux/setup.sh`                    | apt / dnf / pacman base + Homebrew-on-Linux + Flatpak + PWA shortcuts    |
| `shell/`, `config/`, `git/`         | The files that get copied to the machine                                 |
| `packages/`                         | `npm-global.txt`, `vscode-extensions.txt`                                |

## Adding or removing packages

Never edit the Brewfile or the `packages/*.txt` files by hand. Install or remove on the
machine, then let `./sync.sh` write the repo:

| You want to             | Do this                                                                                | Then run        |
| ----------------------- | -------------------------------------------------------------------------------------- | --------------- |
| Add a CLI / SDK         | `brew install <formula>`                                                               | `./sync.sh`     |
| Add a GUI app (macOS)   | `brew install --cask <app>`                                                            | `./sync.sh`     |
| Add a Mac App Store app | `mas install <id>` (find the id with `mas search <name>`)                              | `./sync.sh`     |
| Add an npm global       | `npm install -g <pkg>`                                                                 | `./sync.sh`     |
| Add a VS Code extension | install it from the UI or `code --install-extension <id>`                              | `./sync.sh`     |
| Remove any of the above | uninstall it on the machine, then delete its line from the Brewfile / `packages/*.txt` | commit the diff |

`sync.sh` dumps the current state of Homebrew, npm and VS Code and merges it into the repo.
Package lists only ever grow from a merge — a tool missing from one machine never drops it
from the repo — so removals are the one thing you still edit by hand. Review with `git diff`
before committing either way.

Shell changes: edit `shell/`, run `./install.sh --configs-only`, then `./doctor.sh`.

## License

[MIT](LICENSE) — do whatever you want with it.

Feel free to fork this project and adapt it to your own needs — swap tools, add
your own configs, or strip out whatever doesn't fit your workflow.

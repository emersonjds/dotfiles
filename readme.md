<h1 align="center">Dotfiles</h1>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-green.svg"></a>
  <img alt="macOS" src="https://img.shields.io/badge/macOS-supported-black?logo=apple&logoColor=white">
  <img alt="Shell" src="https://img.shields.io/badge/shell-bash%20%7C%20zsh-89e051?logo=gnubash&logoColor=white">
</p>

<p align="center">
  <img alt="Debian" src="https://img.shields.io/badge/Debian-supported-A81D33?logo=debian&logoColor=white">
  <img alt="Ubuntu" src="https://img.shields.io/badge/Ubuntu-supported-E95420?logo=ubuntu&logoColor=white">
  <img alt="Linux Mint" src="https://img.shields.io/badge/Linux%20Mint-supported-87CF3E?logo=linuxmint&logoColor=white">
  <img alt="Pop!_OS" src="https://img.shields.io/badge/Pop!__OS-supported-48B9C7?logo=popos&logoColor=white">
  <img alt="Kali" src="https://img.shields.io/badge/Kali-supported-557C94?logo=kalilinux&logoColor=white">
</p>

<p align="center">
  <img alt="Fedora" src="https://img.shields.io/badge/Fedora-supported-51A2DA?logo=fedora&logoColor=white">
  <img alt="RHEL" src="https://img.shields.io/badge/RHEL-supported-EE0000?logo=redhat&logoColor=white">
  <img alt="Rocky Linux" src="https://img.shields.io/badge/Rocky-supported-10B981?logo=rockylinux&logoColor=white">
  <img alt="AlmaLinux" src="https://img.shields.io/badge/AlmaLinux-supported-0F4266?logo=almalinux&logoColor=white">
  <img alt="CentOS" src="https://img.shields.io/badge/CentOS-supported-262577?logo=centos&logoColor=white">
</p>

<p align="center">
  <img alt="Arch" src="https://img.shields.io/badge/Arch-supported-1793D1?logo=archlinux&logoColor=white">
  <img alt="Manjaro" src="https://img.shields.io/badge/Manjaro-supported-35BF5C?logo=manjaro&logoColor=white">
  <img alt="EndeavourOS" src="https://img.shields.io/badge/EndeavourOS-supported-7F3FBF?logo=endeavouros&logoColor=white">
  <img alt="Garuda" src="https://img.shields.io/badge/Garuda-supported-2C2E34?logo=archlinux&logoColor=white">
  <img alt="SteamOS" src="https://img.shields.io/badge/SteamOS-supported-1A9FFF?logo=steamdeck&logoColor=white">
</p>

One command turns a bare **macOS** or **Linux** box into a working dev machine: shell,
SDKs, environment variables, editors and apps. Every Debian, Fedora and Arch derivative
is covered — see [Supported systems](#supported-systems) for the full list.

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

| Detected as | System base | GUI apps              |
| ----------- | ----------- | --------------------- |
| `macos`     | Homebrew    | casks + Mac App Store |
| `debian`    | `apt`       | vendor `.deb`         |
| `fedora`    | `dnf`       | `.rpm` + Flathub      |
| `arch`      | `pacman`    | Flathub               |

Nothing is matched by name. `detect_os()` reads `ID` and `ID_LIKE` from `/etc/os-release`
and keys on the family, so a derivative works whether or not anyone here had heard of it:

| Family   | Matches `ID` / `ID_LIKE` containing | Known to work                                                                                                              |
| -------- | ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `debian` | `debian`, `ubuntu`, `linuxmint`     | Debian · Ubuntu (and the Kubuntu/Xubuntu/Lubuntu flavours) · Linux Mint · LMDE · Pop!\_OS · elementary OS · Zorin OS · KDE neon · Kali · MX Linux · Deepin · Devuan |
| `fedora` | `fedora`, `rhel`, `centos`          | Fedora (and the spins) · RHEL · CentOS Stream · Rocky Linux · AlmaLinux · Oracle Linux · Nobara                              |
| `arch`   | `arch`                              | Arch · Manjaro · EndeavourOS · Garuda · ArcoLinux · CachyOS · SteamOS 3                                                     |

**Not supported:** openSUSE and derivatives (`ID_LIKE=suse`), Alpine, Void, Gentoo, NixOS.
They fail loudly with an unsupported-OS message rather than guessing at a package manager.

**Linux is x86_64 only.** Homebrew publishes no ARM Linux bottles, and Chrome, ngrok,
DBeaver, Obsidian, Bruno and Compass are all fetched as `amd64` builds. That rules out
Raspberry Pi OS and the ARM server images even though `detect_os` recognises them. macOS
is fine on both architectures — Homebrew picks the prefix per machine.

Only the system base and the GUI apps are distro-specific: every CLI comes from Homebrew on
Linux, so the terminal is byte-identical everywhere. The vendor `.deb` path is Debian-only
by nature — Fedora and Arch fall back to Flathub for the same apps.

Two things a derivative gets wrong if you trust it:

- **The apt codename.** Mint reports `zena`, and its `/etc/debian_version` says `trixie/sid`
  even though the base is Ubuntu `noble`. Third-party repos are keyed on the Ubuntu
  codename, so `ubuntu_codename()` reads `UBUNTU_CODENAME` instead. Docker's own
  `get.docker.com` gets this wrong on Mint — it looks for the upstream release through
  `lsb_release -u`, which Mint does not implement, then falls back to `/etc/debian_version`
  and wires up a **Debian** repo on an Ubuntu machine. So Docker is installed from the
  official apt repo directly, pinned to the resolved codename.
- **Flatpak scope.** Installs are `--user`. A system-wide one goes through polkit, which
  means an authentication dialog and a hang whenever the script is not run from a desktop
  session.

The Brewfile is a macOS snapshot, so the Linux stage also stands in for the parts of it that
have no Linux equivalent. Casks are skipped there, and Flutter, the Android SDK, ngrok, uv
and the Nerd Font are installed from their upstream tarballs instead — distro-agnostic, no
extra repos or signing keys. The formulae that are macOS-only (`cocoapods`, `mas`, `kdoctor`,
`clipaste`) are filtered out, and `doctor.sh` does not ask for them on Linux either.

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

**Apps** — VS Code, Zed, iTerm2, Ghostty, Obsidian, Bruno, Chrome, Discord, Telegram,
DBeaver, MongoDB Compass, LibreOffice.

On Linux the rule is **upstream or nothing**. Where the vendor ships a `.deb`, that is what
gets installed — Discord, DBeaver, Obsidian, Bruno and Compass all do, the last three
resolved from their GitHub releases. Zed publishes an install script and Telegram a
tarball; both are the documented Linux path, so both are used as-is. Flathub is the
fallback for Fedora and Arch only: every entry for these apps is a community repackage,
and not one of them is vendor-verified.

What has no official Linux build does not get installed at all. Earlier versions of this
repo wrapped Notion, Linear, Outlook and WhatsApp as Chrome `--app` shortcuts, which was a
mistake worth naming: a browser window in a `.desktop` file has no notifications, no file
handlers and no offline mode, but sits in the menu looking exactly like something that
does. The installer now deletes those launchers and prints a pointer to the native tool
instead — Thunderbird for Outlook, Obsidian for Notion, a browser tab for Linear and
WhatsApp.

A `.deb` is verified by content before apt sees it, because a vendor URL answering `200`
with an HTML error page is a real failure mode: `linear.app` served a perfectly valid HTML
document for `/apple-touch-icon.png` while this was being written.

**Terminal** — Ghostty, set as the default on Linux. `config/ghostty/config` is a port of
`config/iterm2/emerson.json` down to the ANSI palette, so both machines look identical; the
colours are written out instead of naming a built-in theme, which cannot drift when a theme
is renamed upstream. Setting it as the default means writing three places, because whichever
one the caller reads is the one that decides: Cinnamon's
`default-applications.terminal`, Debian's `x-terminal-emulator` alternative, and XDG's
`xdg-terminals.list`.

Ghostty is the one case where "upstream" means something looser: it publishes no Linux
binary of its own and is not on Flathub, and its download page sends Linux users to a
pre-built package for their distribution or to building from source. Debian therefore takes
the `mkasberg/ghostty-ubuntu` builds — community-maintained, but the path Ghostty itself
points at. The asset is picked by mapping the Ubuntu codename through
`/usr/share/distro-info/ubuntu.csv`, since Mint's own `VERSION_ID` (22.3) names no release
that project builds for.

**Fonts** — JetBrains Mono Nerd Font, Cascadia Code, Inter. The Nerd Font is what makes
eza and starship icons render. On Linux it is installed from the Nerd Fonts release and
GNOME Terminal's profile is pointed at it, since an installed font is not a used one.

## Keyboard (Linux)

Coming from a Mac breaks two things at once, and `linux/keyboard.sh` fixes both:

- **Accents.** A plain `us` layout has no dead keys, so á ã ç ê are unreachable. The `intl`
  variant brings them back: `'` + `a` = á, `~` + `a` = ã, `^` + `e` = ê. A dead key stays
  silent until the next keystroke — press it twice to get the symbol itself.
- **The cedilla.** `'` + `c` is the exception, and the layout is not what decides it: the
  system Compose table resolves that sequence to **ć**, a c with acute, which is right for
  Polish and useless for Portuguese. macOS gives ç. `config/XCompose` is copied to
  `~/.XCompose` and overrides just that pair. A Compose rule rather than an XKB one on
  purpose — it needs no root and survives a change of system language.
- **The modifier.** macOS puts the shortcut key next to the space bar (Cmd), Linux puts it
  in the corner (Ctrl). `ctrl:swap_lwin_lctl` swaps them, so Cmd+C / Cmd+V / Cmd+T land
  where the thumb already goes. The physical Ctrl still sends a real Ctrl, which is what
  the terminal needs for Ctrl+C.

It writes the setting in three places because each covers a different moment: `setxkbmap`
for the session running now, `gsettings` for the desktop (which reapplies its own value at
login and would otherwise undo the first), and `/etc/default/keyboard` for the console and
login screen. Override per machine without touching the repo:

```bash
KB_LAYOUT=br KB_VARIANT= ./linux/keyboard.sh   # ABNT2 instead of us-intl
KB_OPTIONS= ./linux/keyboard.sh                # keep Ctrl where Linux puts it
```

## System language (Linux)

`shell/env.sh` forces `LC_ALL=en_US.UTF-8` for the terminal, so `linux/locale.sh` sets the
desktop to match instead of leaving the two disagreeing. Override with
`LOCALE_LANG=pt_BR.UTF-8 ./linux/locale.sh`.

It does **not** rename the XDG user directories. Changing language normally offers to turn
`~/Documentos` into `~/Documents`, which silently moves every hardcoded path — this repo
included, since it lives under `~/Documentos`. Only the interface language changes.

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
already there, so re-sourcing `env.sh` never duplicates anything.

Where Homebrew lives is answered in exactly one file, `shell/brew.sh`. The three prefixes —
`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel, `/home/linuxbrew/.linuxbrew` on
Linux — used to be spelled out in `~/.zprofile`, in `env.sh` and again in `lib/common.sh`,
which is three chances for the list to drift. It is one Homebrew in all three: Linuxbrew was
a separate fork until it merged upstream in 2019, and only the path still carries the name.
`install.sh` runs the same official installer on both systems and lets it pick the prefix.

**bash gets the same environment.** `~/.bashrc` is the distro's file, so it is the one config
appended to rather than copied over — a marked block that sources `brew.sh`, `env.sh` and
`aliases.sh`. Without it every `brew` call in a bash session opens with *"…/bin is not in
your PATH"*, and bash is still what scripts, editors and IDE terminals run whatever the
login shell is. `rbenv init` and `pyenv init` emit shell-specific code, so `env.sh` names the
shell instead of assuming zsh; getting that wrong fails silently.

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
| `linux/keyboard.sh`                 | Layout with dead keys + Mac-style Cmd↔Ctrl swap; also runs standalone    |
| `linux/locale.sh`                   | System language, aligned with the `LC_ALL` the shell already forces      |
| `shell/brew.sh`                     | The only file that knows Homebrew's prefix; shared by zsh and bash       |
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

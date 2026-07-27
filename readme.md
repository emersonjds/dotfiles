# Dotfiles — Emerson Silva

Setup automatizado de uma máquina de desenvolvimento do zero. Um único comando
deixa **macOS** ou **Linux** (Ubuntu / Debian / Linux Mint) com shell, SDKs,
variáveis de ambiente e todos os apps de trabalho **prontos para uso**.

- **Idempotente** — pode rodar de novo a qualquer momento; não duplica nem quebra.
- **Não-interativo** — instala tudo de uma vez (só pede senha quando o sistema exige).
- **Sempre a última versão estável** — nada de versão congelada. Java, Node, Python,
  Rust etc. são resolvidos para o release mais novo no momento da instalação.
- **Cross-platform real** — o mesmo shell e as mesmas CLIs nos dois mundos
  (no Linux via Homebrew-on-Linux), então a experiência é idêntica.
- **Instalação por cópia** — nada no `$HOME` aponta para dentro deste repo.
  Apagar, mover ou renomear a pasta do repo **não quebra o shell**.

---

## Como usar

Em qualquer máquina nova (o repo pode ficar em qualquer pasta):

```bash
git clone <url-deste-repo> ~/Documents/workspace/dotfiles
cd ~/Documents/workspace/dotfiles
./install.sh
```

O `install.sh` detecta o sistema operacional sozinho e faz o resto. Ao terminar,
abra um novo terminal (ou rode `exec zsh`).

---

## Cópia, não symlink

As configs são **copiadas** do repo para a máquina. O modelo antigo criava
symlinks (`~/.zshrc` → `repo/shell/zshrc`) e tinha uma falha séria: bastava
mover ou apagar a pasta do repo para **todo o shell morrer junto** — `PATH`
quebrado, ferramentas sumidas, `claude` fora do ar. O repo virava dependência de
runtime de uma coisa que precisa sempre funcionar.

Agora o repo é a **fonte versionada**, não a fonte viva. Em troca, o fluxo tem
dois sentidos:

| Você editou onde | O que rodar |
|------------------|-------------|
| No **repo** (`shell/`, `config/`, `git/`) | `./install.sh --configs-only` — recopia só as configs, sem mexer em pacotes |
| Direto na **máquina** (`~/.zshrc`, `~/.config/shell/…`) | `./sync.sh` — traz de volta pro repo; revise com `git diff` e commite |

`./install.sh` completo (com pacotes) continua valendo e é sempre seguro rodar
de novo.

> Rode `./sync.sh` **antes** de editar o repo, não depois — ele sobrescreve os
> arquivos do repo com o que está na máquina. Como tudo é versionado, um
> `git diff` mostra exatamente o que ele trouxe.

### Onde cada coisa é instalada

| Repo | Máquina |
|------|---------|
| `shell/zshrc` | `~/.zshrc` |
| `shell/zprofile` | `~/.zprofile` (login shell: só o `brew shellenv`) |
| `shell/env.sh`, `aliases.sh`, `plugins.sh` | `~/.config/shell/` |
| `git/gitconfig` | `~/.gitconfig` |
| `config/starship.toml` | `~/.config/starship.toml` |
| `config/zed/settings.json` | `~/.config/zed/settings.json` |
| `config/vscode/settings.json` | `~/Library/Application Support/Code/User/` (macOS) ou `~/.config/Code/User/` |
| `config/iterm2/emerson.json` | `~/Library/Application Support/iTerm2/DynamicProfiles/` (macOS) |

O `~/.zshrc` dá source de `~/.config/shell/*.sh` — caminho fixo da máquina,
nunca do repo. Se um arquivo já existir no destino, ele vira `*.bak.<timestamp>`
antes de ser substituído, então nada é perdido. Symlinks legados do modelo
antigo são detectados e removidos automaticamente.

### Versões

A regra geral é **sempre a última estável**. A exceção é o **Java, fixado no 17**
por padrão (estável para Android / React Native / Flutter) — definido em
`shell/env.sh`. O `openjdk` latest também é instalado, então quando o mais novo
estiver de boa com RN/Flutter basta trocar o `17` no `env.sh`.

Para um override **só nesta máquina** (sem mexer no repo), crie
`~/.config/shell/versions.env`, por exemplo:

```bash
JAVA_VERSION=21
```

---

## O que é instalado e por quê

### Shell e produtividade no terminal
| Ferramenta | Por quê |
|------------|---------|
| **zsh + Oh My Zsh** | shell padrão, com plugins e histórico melhorado |
| **starship** | prompt rápido e informativo (substitui o tema do Oh My Zsh) |
| **zsh-autosuggestions** | sugere comandos do histórico enquanto você digita |
| **zsh-syntax-highlighting** | colore comandos válidos/inválidos em tempo real |
| **zoxide** | `cd` inteligente (`z parte-do-nome` pula para pastas visitadas) |
| **fzf** | busca fuzzy no histórico (Ctrl-R) e em arquivos (Ctrl-T) |
| **eza** | `ls` moderno com ícones e info de git |
| **ripgrep** | busca em arquivos absurdamente rápida |
| **neovim** | editor de terminal |

### Linguagens e runtimes (sempre o latest estável)
| Ferramenta | Por quê |
|------------|---------|
| **Node (via nvm, último LTS)** | runtime JS/TS; nvm permite trocar de versão por projeto |
| **pnpm / yarn / bun** | gerenciadores de pacote / runtime JS rápido |
| **OpenJDK + Maven** | desenvolvimento Java/Android |
| **Python + pipx** | scripts e ferramentas Python isoladas |
| **Rust (rustup)** | toolchain Rust |
| **Ruby (rbenv)** | Ruby por projeto (CocoaPods etc.) |

### Mobile / React Native / Flutter
| Ferramenta | Por quê |
|------------|---------|
| **Flutter** | apps Flutter (canal stable) |
| **Android cmdline-tools + platform-tools** | SDK Android, `adb`, emulador |
| **watchman** | file watching usado pelo React Native / Metro |
| **adb-enhanced, kdoctor** | utilidades Android e diagnóstico de ambiente Flutter |
| **CocoaPods** (macOS) | dependências iOS |
| **ngrok** | túneis para testar webhooks/dispositivos |

### AI / CLIs de desenvolvimento
| Ferramenta | Por quê |
|------------|---------|
| **Claude Code** (`claude`) | assistente de código no terminal |
| **GitHub Copilot CLI** (`@github/copilot` + extensão `gh copilot`) | sugestões de comando/código via GitHub |
| **gh** | CLI do GitHub (PRs, issues, releases) |

### Banco de dados / backend / containers
| Ferramenta | Por quê |
|------------|---------|
| **PostgreSQL** | banco de dados relacional (latest estável) |
| **Docker + Docker Compose** | containers (Docker Desktop no macOS; Docker Engine + plugin Compose no Linux) |
| **DBeaver** | cliente SQL universal |
| **MongoDB Compass** | GUI do MongoDB |
| **Supabase CLI** | desenvolvimento local com Supabase |

### Aplicativos GUI
VSCode, Zed, iTerm2 (macOS), Obsidian, Bruno (cliente de API), Google Chrome,
Discord, WhatsApp, Notion, Microsoft Outlook, LibreOffice.

No **Linux**, apps sem pacote nativo decente (WhatsApp, Notion, Outlook) são
criados como **PWAs do Chrome** (atalhos `.desktop` em modo app) — funcionam como
janelas dedicadas. Os demais vêm de repositório oficial ou Flatpak.

### Fontes
JetBrains Mono Nerd Font, Cascadia Code e Inter (a Nerd Font garante os ícones
do eza/starship no terminal).

---

## Variáveis de ambiente configuradas

Definidas em `shell/env.sh` (instalado em `~/.config/shell/env.sh`), resolvidas
dinamicamente conforme o SO:

| Variável | macOS | Linux |
|----------|-------|-------|
| `JAVA_HOME` | JDK 17 por padrão (`java_home -v 17`) | `brew --prefix openjdk@17` |
| `ANDROID_HOME` / `ANDROID_SDK_ROOT` | `~/Library/Android/sdk` | `~/Android/Sdk` |
| `NVM_DIR` | `~/.nvm` | `~/.nvm` |
| `BUN_INSTALL` | `~/.bun` | `~/.bun` |
| `PNPM_HOME` | `~/Library/pnpm` | `~/.local/share/pnpm` |
| `RBENV_ROOT` | `~/.rbenv` (só se o rbenv existir) | idem |
| `PYENV_ROOT` | `~/.pyenv` (só se o pyenv existir) | idem |
| `LC_ALL` | `en_US.UTF-8` | `en_US.UTF-8` |
| `REACT_NATIVE_NO_METRO_WINDOW` | `true` | `true` |

Toolchains inicializados quando presentes: **rbenv** (`rbenv init`), **cargo**
(`~/.cargo/env` ou `~/.cargo/bin`), **pyenv** (só se instalado de verdade — com
o Python do brew ele atrapalha). `pipx` e `uv` caem em `~/.local/bin`.

O `PATH` recebe ainda: Homebrew, Android (emulator / platform-tools /
cmdline-tools), `bun`, `pnpm`, `yarn`, Solana, JetBrains Toolbox e
`~/.local/bin` — que fica por último, com a maior prioridade, porque é onde
vivem `claude` e `uv`.

Todas as entradas passam por `path_prepend`, que só adiciona se o diretório
existir e ainda não estiver no `PATH`. Dar `source` no `env.sh` várias vezes
não duplica nada.

O `brew shellenv` roda **só no `~/.zprofile`** (login shell). O `env.sh` só
o chama como rede de segurança se o `brew` não estiver no `PATH`.

---

## Estrutura do repositório

| Caminho | Responsabilidade |
|---------|------------------|
| `install.sh` | Entrypoint: detecta o SO, despacha e roda o estágio comum (`--configs-only` pula os pacotes) |
| `sync.sh` | Caminho de volta: copia as configs da máquina para o repo |
| `lib/common.sh` | Helpers (log, detecção de SO, `dotfiles_map`, `install_file`, prefixo do brew) |
| `lib/stage_common.sh` | Cópia das configs + Node LTS + bun + npm globals + extensões VSCode + shell |
| `macos/setup.sh` + `macos/Brewfile` | Instalação no macOS via Homebrew (formulae + casks + fonts) |
| `linux/setup.sh` | Instalação no Linux (apt + Homebrew-on-Linux + Flatpak + PWAs) |
| `shell/` | `zshrc`, `zprofile`, `env.sh`, `aliases.sh`, `plugins.sh` |
| `config/` | `starship.toml`, `zed/settings.json`, `vscode/settings.json`, `iterm2/emerson.json` |
| `macos/terminal-setup.sh` | ajustes de fonte (Nerd Font) do iTerm2/Terminal.app via plist — rode com o iTerm2 **fechado** |
| `git/gitconfig` | identidade e padrões do git |
| `packages/` | manifestos: `npm-global.txt`, `vscode-extensions.txt` |

O mapa repo → máquina fica em `dotfiles_map()` (`lib/common.sh`), em um lugar
só: o `install.sh` lê na ida e o `sync.sh` na volta. Para versionar um arquivo
novo, acrescente uma linha lá.

---

## Manutenção

- **Adicionar um pacote CLI/app:** edite `macos/Brewfile` (e, se for GUI no Linux,
  ajuste `linux/setup.sh`).
- **Adicionar um pacote npm global:** acrescente uma linha em `packages/npm-global.txt`.
- **Adicionar uma extensão do VSCode:** acrescente o id em `packages/vscode-extensions.txt`
  (ou rode `code --list-extensions > packages/vscode-extensions.txt` para sincronizar).
- **Mudar config de shell:** edite os arquivos em `shell/` e rode
  `./install.sh --configs-only` para aplicar. Se editou direto na máquina,
  rode `./sync.sh` para trazer de volta.

Depois de qualquer mudança, rodar `./install.sh` de novo é seguro.

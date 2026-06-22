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

---

## Como usar

Em qualquer máquina nova:

```bash
git clone <url-deste-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

O `install.sh` detecta o sistema operacional sozinho e faz o resto. Ao terminar,
abra um novo terminal (ou rode `exec zsh`).

### Passos manuais (uma vez por máquina)

O `install.sh` deixa quase tudo pronto, mas dois ajustes dependem de credenciais
suas e **não** ficam no repo:

- **GitHub CLI:** rode `gh auth login` para autenticar o `gh` (e habilitar o
  `gh copilot`, que é built-in e instala o Copilot CLI no primeiro uso).
- **Token do Supabase no Zed:** o `config/zed/settings.json` versiona o campo
  `supabase_access_token` como o placeholder `"YOUR_TOKEN"`. Troque pelo seu token
  real **localmente** — como o arquivo é symlink, basta editar no Zed; **não
  comite** o token de volta no repo.

### Versões

A regra geral é **sempre a última estável**. A exceção é o **Java, fixado no 17**
por padrão (estável para Android / React Native / Flutter) — definido em
`shell/env.sh`. O `openjdk` latest também é instalado, então quando o mais novo
estiver de boa com RN/Flutter basta trocar o `17` no `env.sh`.

Para um override **só nesta máquina** (sem mexer no repo), crie
`packages/versions.env` (não versionado), por exemplo:

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
| **GitHub Copilot CLI** (`@github/copilot`; o `gh copilot` é built-in no `gh` e instala/encaminha pra ele) | sugestões de comando/código via GitHub |
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

Definidas em `shell/env.sh`, resolvidas dinamicamente conforme o SO:

| Variável | macOS | Linux |
|----------|-------|-------|
| `JAVA_HOME` | JDK 17 por padrão (`java_home -v 17`) | `brew --prefix openjdk@17` |
| `ANDROID_HOME` / `ANDROID_SDK_ROOT` | `~/Library/Android/sdk` | `~/Android/Sdk` |
| `NVM_DIR` | `~/.nvm` | `~/.nvm` |
| `BUN_INSTALL` | `~/.bun` | `~/.bun` |
| `PNPM_HOME` | `~/Library/pnpm` | `~/.local/share/pnpm` |
| `LC_ALL` | `en_US.UTF-8` | `en_US.UTF-8` |
| `REACT_NATIVE_NO_METRO_WINDOW` | `true` | `true` |

O `PATH` recebe ainda: Homebrew, Android (platform-tools / emulator /
cmdline-tools), `bun`, `pnpm` e `~/.local/bin`.

---

## Estrutura do repositório

| Caminho | Responsabilidade |
|---------|------------------|
| `install.sh` | Entrypoint: detecta o SO, despacha e roda o estágio comum |
| `lib/common.sh` | Helpers (log, detecção de SO, symlink seguro, prefixo do brew) |
| `lib/stage_common.sh` | Symlinks + Node LTS + bun + npm globals + extensões VSCode + shell |
| `macos/setup.sh` + `macos/Brewfile` | Instalação no macOS via Homebrew (formulae + casks + fonts) |
| `linux/setup.sh` | Instalação no Linux (apt + Homebrew-on-Linux + Flatpak + PWAs) |
| `shell/` | `zshrc`, `env.sh`, `aliases.sh`, `plugins.sh` (symlinkados para o `$HOME`) |
| `config/` | `starship.toml`, `zed/settings.json`, `vscode/settings.json`, `iterm2/emerson.json` (symlinkados) |
| `macos/terminal-setup.sh` | ajustes de fonte (Nerd Font) do iTerm2/Terminal.app via plist — rode com o iTerm2 **fechado** |
| `git/gitconfig` | identidade e padrões do git |
| `packages/` | manifestos: `npm-global.txt`, `vscode-extensions.txt` (+ `versions.env` opcional) |

Os dotfiles são **symlinkados** do repo para o `$HOME`/`~/.config`. Se já existir
um arquivo no destino, ele é movido para `*.bak.<timestamp>` antes do link — então
nada é perdido.

---

## Manutenção

- **Adicionar um pacote CLI/app:** edite `macos/Brewfile` (e, se for GUI no Linux,
  ajuste `linux/setup.sh`).
- **Adicionar um pacote npm global:** acrescente uma linha em `packages/npm-global.txt`.
- **Adicionar uma extensão do VSCode:** acrescente o id em `packages/vscode-extensions.txt`
  (ou rode `code --list-extensions > packages/vscode-extensions.txt` para sincronizar).
- **Mudar config de shell:** edite os arquivos em `shell/` — como são symlinks, a
  mudança vale imediatamente em um novo terminal.

Depois de qualquer mudança, rodar `./install.sh` de novo é seguro.

# 🚀 zsh-config

> A fast, modular zsh configuration for productive terminal workflows on macOS.

**Target startup time:** < 100ms | **Platform:** macOS (Apple Silicon & Intel)

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 2. Run the installer (bootstraps Homebrew + all tools)
~/.config/zsh/install.sh

# 3. Open a new terminal and verify
zsh-health
```

That's it. The installer:

- Installs **Homebrew** if missing (`/opt/homebrew` on Apple Silicon — all bottles native arm64)
- Installs every tool the config uses via **`brew bundle`** — the package list is declared in [`Brewfile`](Brewfile) (core) and [`Brewfile.dev`](Brewfile.dev) (dev toolchains: mise, rustup, fastfetch)
- Writes `~/.zshenv`, creates `modules/local.zsh`, links the tmux config, creates the Alacritty local wrapper
- Is **idempotent** — safe to re-run anytime; existing files are backed up, never silently overwritten

### Installer options

| Flag | Effect |
|------|--------|
| `--minimal` | Core tools only — skip dev toolchains (mise runtimes, rustup) |
| `--config-only` | Only set up config files, install no packages |
| `--yes` / `-y` | Skip confirmation prompts |
| `--git-name "X" --git-email "Y"` | Also configure git identity + SSH commit signing |
| `--help` | Show all options |

```bash
# Examples
~/.config/zsh/install.sh -y
~/.config/zsh/install.sh --git-name "Jane Doe" --git-email "j@d.dev"
```

> [!TIP]
> **New MacBook?** Run the installer first thing — it bootstraps Homebrew and the entire toolchain in one go. macOS already ships zsh as the default shell, so when it finishes, just open a new terminal.

---

## What is this?

A **fully-featured zsh configuration** built with:

- [Zinit](https://github.com/zdharma-continuum/zinit) plugin manager (turbo mode for speed)
- Curated plugins: autosuggestions, syntax highlighting, fzf-tab, forgit, history substring search
- SSH commit signing (no GPG required)
- Parallel tool updater (`upgrade`) and health diagnostics (`zsh-health`)
- XDG base directory spec compliance — `~` stays clean

**Perfect for:** Developers, DevOps engineers, and anyone who lives in the terminal.

**Not for you if:** You want a minimal config. This is **opinionated** — fork it and adapt to your needs.

---

## Features

| Feature | Benefit |
|---------|---------|
| **Fast startup** | Zinit turbo mode + cached tool initialization (~50-100ms) |
| **Smart plugin loading** | Plugins load on-demand, not at startup |
| **Git integration** | SSH commit signing, per-host identities, delta diffs, 80+ git aliases |
| **macOS-tuned git** | FSEvents `fsmonitor`, fetch/index parallelism = CPU cores |
| **Tool auto-updates** | `upgrade` updates brew, zinit, rust, mise and claude in parallel |
| **tmux session management** | fzf session picker (`C-a g`), auto-attach wrapper, rename binding |
| **Automatic dark/light themes** | tmux + Alacritty switch instantly when macOS appearance changes (Catppuccin Mocha ↔ Latte) |
| **Fuzzy finder** | fzf for file/history search, fzf-tab completion menus, forgit |
| **Diagnostics** | `zsh-health` checks tools, PATH, and config |
| **XDG compliant** | All config in `~/.config`, cache in `~/.cache` |
| **Headless mode** | `toggle_interactive off` disables Starship + plugins for scripts |

---

## Manual Installation

If you'd rather not run the installer, here's what it does:

<details>
<summary><strong>Step-by-step manual setup</strong></summary>

```bash
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone the config (the Brewfiles live in the repo)
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 3. All tools (native arm64 bottles on Apple Silicon)
# brew bundle handles taps declared in Brewfile (e.g. cormacrelf/dark-notify) automatically
brew bundle --file=~/.config/zsh/Brewfile       # core tools
brew bundle --file=~/.config/zsh/Brewfile.dev   # dev toolchains: mise, rustup, fastfetch

# 4. Node (global) via mise; rustup manager only — all other runtimes per-project
printf 'pnpm\n@antfu/ni\ntaze\nnpkill\nccstatusline\neslint\n' > ~/.default-npm-packages
mise use -g node@lts
rustup-init -y --no-modify-path --default-toolchain none

# 5. Create ~/.zshenv (required — points zsh at the config)
cat > ~/.zshenv << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

# 6. Machine-local config (gitignored, safe for secrets)
touch ~/.config/zsh/modules/local.zsh

# 7. Link tmux config
mkdir -p ~/.config/tmux
ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf

# 8. Alacritty local wrapper (real file, not a symlink — lets you add local overrides after the import)
mkdir -p ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.toml << EOF
[general]
import = [
  "$HOME/.config/zsh/alacritty/alacritty.toml",
  "$HOME/.config/alacritty/theme.toml",
]
EOF

# 9. Open a new terminal — Zinit installs plugins on first start (~1-2 min)
zsh-health
```

</details>

---

## Configuration

### Machine-local settings

File: `~/.config/zsh/modules/local.zsh` (gitignored — safe for secrets)

```bash
# Machine-local zsh config (gitignored — safe for secrets and machine quirks)

# Auto-attach to a tmux session when opening VS Code's integrated terminal.
# Session name = workspace folder basename (PWD is set to workspace root by VS Code).
# -A: attach if session exists, create new otherwise.
# exec replaces this shell process; tmux then starts a fresh zsh inside.
if [[ ( "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "zed" ) && -z "$TMUX" ]]; then
  # session exists + client attached  → new independent session (avoid shared view)
  # session exists + no client        → reattach (recover running work after VS Code closes)
  # no session                        → create fresh
  _session="${PWD:t}"
  if tmux has-session -t "=${_session}" 2>/dev/null \
     && tmux list-clients -t "=${_session}" 2>/dev/null | grep -q .; then
    exec tmux new-session -s "${_session}-$$"
  else
    exec tmux new-session -A -s "${_session}"
  fi
fi

# GitHub and BitBucket usernames (for gg/gb navigation aliases)
export GITHUB_USER="your-github-username"
export BITBUCKET_USER="your-bitbucket-username"

# Project root for gg/gb and freespace (default: ~/Development/code).
# NOTE: if you change this, also update the [includeIf] paths in
# ~/.config/git/config so per-host git identities keep working.
# export CODE_DIR="$HOME/Developer"

# Auto-pull zsh-config updates on login and show what changed (opt-in).
# When enabled, the daily update check pulls automatically (fast-forward only)
# and prints the new commits so you know exactly what arrived:
#
#   ╭─ ✅ zsh-config updated to abc1234 (2 new commit(s))
#   ├─ feat: add fzf git log preview
#   ├─ fix: correct mise hook timing
#   ╰─ run `exec zsh` to reload
#
# ZSH_CONFIG_AUTO_UPDATE=1

# Custom aliases / functions / overrides
alias myproject="cd ~/projects/myproject"
```

### Dark/light theme switching

tmux and Alacritty follow the macOS system appearance automatically using [dark-notify](https://github.com/cormacrelf/dark-notify) (installed via `Brewfile`). Both switch to **Catppuccin Mocha** in dark mode and **Catppuccin Latte** in light mode with no manual action needed.

**How it works:**

- `.zprofile` starts `dark-notify` once at login as a background process
- On every macOS appearance change, `dark-notify` calls `scripts/theme-switch.sh`
- The script applies the right theme to tmux (`tmux source-file`) and writes `~/.config/alacritty/theme.toml`, which Alacritty reloads live via `live_config_reload = true`
- The correct theme is also written at login so the first shell matches the current appearance

**Theme files:**

| App | Dark | Light |
|-----|------|-------|
| tmux | `tmux/themes/dark.conf` | `tmux/themes/light.conf` |
| Alacritty | `alacritty/themes/dark.toml` | `alacritty/themes/light.toml` |

**Alacritty local wrapper** (`~/.config/alacritty/alacritty.toml`, not committed):

```toml
[general]
import = [
  "~/.config/zsh/alacritty/alacritty.toml",  # shared base
  "~/.config/alacritty/theme.toml",           # current theme (written by theme-switch.sh)
]

# Add machine-local overrides below (font size, opacity, etc.)
```

The installer creates this wrapper automatically. To add per-machine Alacritty overrides, append settings after the `import` block — they take precedence over everything imported.

**tmux local overrides** (`tmux/local.conf`, gitignored):

Sourced last by `tmux.conf`, so anything here wins. Created empty by the installer:

```bash
# set -g status-interval 10   # slower refresh on slow machines
```

### Customize plugins

Edit `modules/zinit.zsh` and restart the shell. See [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins) for ideas; remove plugins you don't use to improve startup time.

### Customize keybindings / aliases

- `modules/keybindings.zsh` — `Ctrl+R` history, `Ctrl+T` files, word navigation
- `modules/aliases.zsh` — `ll` (eza), `gs`/`gco`/`gcm` (git), `tm` (tmux), …

Full reference: [docs/aliases.md](docs/aliases.md), [docs/keybindings.md](docs/keybindings.md), [docs/functions.md](docs/functions.md)

---

## Common Tasks

### Update everything

```bash
upgrade              # brew, zinit, rust, mise (node/go), claude-code@latest — in parallel
upgrade --dry-run    # see what would run
upgrade --only mise  # update only mise-managed runtimes + npm globals
```

> [!NOTE]
> `starship` and Maple Mono fonts are tracked in `Brewfile`; `fastfetch` and `claude-code@latest` in `Brewfile.dev`.
> After a tool upgrade, eval caches (starship, zoxide, mise, fzf) regenerate automatically on the next shell
> start via binary `-nt` check — no manual `zsh-cache-clear` needed.

### Check system health

```bash
zsh-health           # platform, tools, PATH, config — with fix hints
```

### Clear caches

```bash
zsh-cache-clear      # removes eval caches (starship, zoxide, mise, fzf)
exec zsh             # restart shell (regenerates caches)
```

### Free up disk space

```bash
freespace --dry-run              # preview (no changes)
freespace                        # clean node_modules/vendor under ~/Development/code
freespace --aggressive           # also clean npm/pip/go/cargo/brew caches
```

Always asks for confirmation before deleting.

### Interactive git (forgit + aliases)

```bash
glo / ga / gcb / grh   # interactive log / add / checkout / reset (fzf)
gs / gco / gcm / gaa   # status / checkout / commit -m / add -A
git alias              # list all 80+ git aliases
```

### fzf shortcuts

- `Ctrl+R` → fuzzy history search
- `Ctrl+T` → fuzzy file finder (with bat preview)
- `Option+C` (⌥C) → fuzzy directory jump

### Per-project runtimes (mise)

Node is installed **globally** (always-on tools like `ccstatusline` and `taze`
need it). Everything else is pinned **per project**:

```bash
cd myproject
mise use go@1.24 python@3.13   # writes .mise.toml, installs on demand
mise ls                        # what's active here
```

Global npm tools live in `~/.default-npm-packages` — mise re-installs them
automatically into every new node version, so they survive node upgrades.

Rust is per-project too, via its own manager: commit a `rust-toolchain.toml`
and rustup auto-installs/uses that toolchain on the first build. No global
toolchain is installed; for ad-hoc rust outside a project, run
`rustup default stable` once.

**brew or mise? The rule of thumb:**

> If two projects could ever need *different versions* of it → **mise**.
> Otherwise → **brew**.

| brew | mise |
|------|------|
| Apps & daemons (Docker Desktop, etc. — casks) | Language runtimes: node, go, python, java, … |
| System CLI tools, one version forever: git, tmux, fzf, bat, ripgrep, jq, gh, delta, … | Anything pinned in a project's `.mise.toml` |
| mise itself | |

### Per-project env vars (replaces direnv)

mise also manages environment variables, so **direnv is not installed** —
[mise's docs deprecate combining them](https://mise.jdx.dev/direnv.html)
(PATH conflicts). Instead:

```bash
cd myproject
mise set NODE_ENV=development     # writes [env] into .mise.toml
mise set                          # list current env vars
```

Bonus: auto-install a project's pinned tools when you `cd` in — add to its
`.mise.toml`:

```toml
[hooks]
enter = "mise i -q"
```

### Headless / automation mode

```bash
toggle_interactive off   # disables Starship + Zinit (fast bare shell)
toggle_interactive on    # back to full features
```

---

## Updating

```bash
git -C ~/.config/zsh pull
zsh-cache-clear
exec zsh
```

A daily login check tells you when the repo has new upstream commits.

---

## Testing

```bash
# Validate the repo without touching your dotfiles
bash ~/.config/zsh/scripts/test.sh
# or
make test
```

---

## Troubleshooting

### "zsh-health: command not found"

The config didn't load. Check:

```bash
echo $ZDOTDIR          # expected: /Users/you/.config/zsh
cat ~/.zshenv          # must export ZDOTDIR
source ~/.zshenv && exec zsh
```

### Tools installed but "command not found"

```bash
exec zsh -l            # restart as login shell (rebuilds PATH)
show_path              # inspect PATH entries
zsh-health             # shows which expected dirs are missing from PATH
```

On Apple Silicon, Homebrew must be at `/opt/homebrew` — `zsh-health` flags this.

### Slow shell startup

```bash
time zsh -i -c exit    # expect ~50-100ms after first run
zinit times            # per-plugin load times
```

First start after install/update is slow (plugin downloads + cache generation) — that's normal.

### Spotlight indexing dev folders (high I/O during npm install)

`mdutil -i off` only works on whole volumes. To exclude `~/Development` from Spotlight:

```bash
touch ~/Development/.metadata_never_index
```

The installer does this automatically. If you moved your project root (`CODE_DIR`), add the marker there too.

### Git uses the wrong identity

```bash
git whoami             # show active identity (alias from git-setup.sh)
git config user.name   # check per-repo override
```

`includeIf` blocks in `~/.config/git/config` select identities by repo path.

---

## Git Setup (SSH Commit Signing)

```bash
~/.config/zsh/scripts/git-setup.sh --name "Your Name" --email "your@email.com"
```

Creates `~/.config/git/config`, generates `~/.ssh/id_ed25519` if needed, configures SSH signing (no GPG), enables FSEvents `fsmonitor`, and sets fetch/index parallelism to your CPU core count.

Then register the key on GitHub:

```bash
gh auth refresh -s admin:public_key,admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type signing
```

Verify: `git commit --allow-empty -m "test" && git log --show-signature -1`

---

## Uninstall

One command, one confirmation — the mirror image of install:

```bash
~/.config/zsh/uninstall.sh
```

It restores your original `~/.zshenv` and `tmux.conf` from the backups
install.sh made, moves the config to `~/.config/zsh.uninstalled` (kept, in
case `local.zsh` holds secrets), and clears caches/plugins. Brew packages,
mise runtimes, git config, SSH keys, and shell history are left untouched —
the script prints the `brew bundle cleanup` command if you want packages
gone too.

To disable plugins temporarily without uninstalling: `toggle_interactive off`.

---

## Structure

```
~/.zshenv                     # in $HOME, created by install.sh — sets ZDOTDIR
~/.config/zsh/
├── install.sh                # one-command installer (Homebrew-based)
├── uninstall.sh              # one-command uninstaller (restores backups)
├── Brewfile                  # core packages (brew bundle)
├── Brewfile.dev              # dev toolchains: mise, rustup, fastfetch
├── .zprofile                 # login shells: Homebrew, PATH, env vars
├── .zshrc                    # main orchestrator — sources modules in order
├── modules/
│   ├── options.zsh           # shell options (setopt)
│   ├── zinit.zsh             # plugin manager + all plugins
│   ├── completions.zsh       # completion rules + fzf-tab previews
│   ├── keybindings.zsh       # key mappings
│   ├── aliases.zsh           # command aliases
│   ├── functions.zsh         # upgrade, zsh-health, freespace, …
│   ├── tools.zsh             # cached tool init (starship, zoxide, mise, …)
│   └── local.zsh             # machine-local overrides (gitignored)
├── tmux/
│   ├── tmux.conf             # tmux config (linked to ~/.config/tmux/)
│   ├── local.conf            # machine-local tmux overrides (gitignored)
│   └── themes/
│       ├── dark.conf         # Catppuccin Mocha
│       └── light.conf        # Catppuccin Latte
├── alacritty/
│   ├── alacritty.toml        # shared base config
│   └── themes/
│       ├── dark.toml         # Catppuccin Mocha
│       └── light.toml        # Catppuccin Latte
├── scripts/
│   ├── git-setup.sh          # git identity + SSH signing factory
│   ├── theme-switch.sh       # called by dark-notify — applies tmux + Alacritty theme
│   ├── tmux-sessionizer.sh   # fzf session picker (C-a g)
│   ├── tmux-sys-info.sh      # status bar: CPU / MEM / GPU
│   └── test.sh               # test suite
└── docs/                     # aliases, functions, keybindings, plugins
```

---

## FAQ

**Q: Does this work on Apple Silicon (M-series) Macs?**
A: Yes, first-class. Homebrew at `/opt/homebrew` with native arm64 bottles; git tuned for the core count. No Rosetta needed.

**Q: Does this work on Linux or WSL?**
A: No — this config targets macOS only. Fork an older revision (pre-macOS-only) if you need Linux/WSL support.

**Q: Can I fork this and customize it?**
A: Yes — that's the recommendation. Put machine-specific bits in `modules/local.zsh`, structural changes in your fork.

**Q: Does this include a prompt theme?**
A: Yes, [Starship](https://starship.rs/). Customize in `~/.config/starship.toml`.

**Q: Can I use this with Oh My Zsh or Prezto?**
A: No, it's built around Zinit. Fork and adapt if you prefer another manager.

**Q: Is this security-reviewed?**
A: It's a personal config with sane practices (no `eval` of remote content, confirmation prompts before deletion, gitignored secrets file), but review it yourself before using in sensitive environments.

---

## Resources

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [Starship Prompt](https://starship.rs/)
- [fzf — Fuzzy Finder](https://github.com/junegunn/fzf)

---

## License

MIT — Use, modify, and share freely.

**Questions?** Open an [issue](https://github.com/nandordudas/zsh-config/issues) on GitHub.

# ~/.config/zsh/.zprofile
# Sourced once for login shells (every new VS Code terminal in WSL, ssh sessions).
# Sets up PATH, persistent env vars, and creates required directories.

# =============================================================================
# ONE-TIME DIRECTORY SETUP
# Create directories that tools expect to exist. Safe to run at every login.
# =============================================================================
[[ -d "$XDG_DATA_HOME/zsh" ]]             || mkdir -p "$XDG_DATA_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh" ]]            || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh/compcache" ]]  || mkdir -p "$XDG_CACHE_HOME/zsh/compcache"
[[ -d "$XDG_STATE_HOME/zsh" ]]            || mkdir -p "$XDG_STATE_HOME/zsh"

# =============================================================================
# ZSH CONFIG UPDATE CHECK
# Check if zsh-config repo has updates (cache check daily to avoid slowdown)
# =============================================================================
_check_zsh_config_updates() {
  local zsh_dir="$ZDOTDIR"
  local cache_file="$XDG_CACHE_HOME/zsh/update-check"
  local cache_max_age=86400  # 1 day in seconds

  # Skip if not a git repo
  [[ -d "$zsh_dir/.git" ]] || return 0

  # Skip if cache fresh
  if [[ -f "$cache_file" ]]; then
    local last_check=$(<"$cache_file")
    (( EPOCHSECONDS - last_check < cache_max_age )) && return 0
  fi

  # Update cache timestamp
  printf '%s' "$EPOCHSECONDS" >"$cache_file"

  # Check for updates
  local behind
  behind=$(git -C "$zsh_dir" rev-list --count @{u}..HEAD 2>/dev/null)

  if [[ -n "$behind" && "$behind" -gt 0 ]]; then
    printf '\n%s\n' "╭─ 🔄 zsh-config has $behind new commit(s)"
    printf '%s\n' "├─ Run: cd ~/.config/zsh && git pull"
    printf '%s\n' "╰─────────────────────────────────────────\n"
  fi
}

_check_zsh_config_updates

# =============================================================================
# PATH (deduplicated via typeset -U)
# Ordered: user-local → language runtimes → system
# ~/.fzf/bin is listed here so fzf is in PATH before .zshrc runs
# =============================================================================
typeset -U PATH path

path=(
  "$HOME/.local/bin"           # direnv, delta, user-installed tools
  "$HOME/.fzf/bin"             # fzf (git-cloned install)
  "$HOME/.cargo/bin"           # fnm, cargo-installed tools
  "$HOME/go/bin"               # go-installed binaries (g, etc.)
  "$HOME/.go/bin"              # go toolchain itself
  "$XDG_CONFIG_HOME/zsh/bin"   # personal scripts
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $path                        # preserve entries from /etc/environment
)

export PATH

# =============================================================================
# LANGUAGE & LOCALE
# =============================================================================
export LANG="${LANG:-en_US.UTF-8}"

# =============================================================================
# EDITOR
# =============================================================================
export EDITOR='code --wait'
export VISUAL='code'

# =============================================================================
# HISTORY
# Directory is guaranteed by the mkdir block above.
# =============================================================================
export HISTFILE="$XDG_DATA_HOME/zsh/history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE="$XDG_CACHE_HOME/lesshst"

# =============================================================================
# GO
# =============================================================================
export GOROOT="$HOME/.go"
export GOPATH="$HOME/go"

# =============================================================================
# GIT & PERSONAL IDENTIFIERS
# =============================================================================
export GIT_CONFIG_GLOBAL="$HOME/.config/git/config"
# =============================================================================
# WSL DETECTION
# Runs once at login; all child shells inherit IS_WSL from the environment.
# =============================================================================
if [[ -z "$IS_WSL" ]]; then
  if [[ -r /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    export IS_WSL=1
  else
    export IS_WSL=0
  fi
fi

# =============================================================================
# RUST / CARGO
# Sources ~/.cargo/env which exports CARGO_HOME etc.
# ~/.cargo/bin is already in PATH above, but this also sets other Cargo vars.
# =============================================================================
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

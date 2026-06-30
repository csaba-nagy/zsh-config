#!/usr/bin/env bash
# Called by dark-notify with DARK_NOTIFY_STYLE=dark|light.
# Switches Catppuccin theme in all supported apps simultaneously.
# dark-notify runs with a minimal PATH — add Homebrew so tmux is found.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

style="${DARK_NOTIFY_STYLE:-light}"

# tmux — source the right theme file into all active sessions
tmux source-file "$HOME/.config/zsh/tmux/themes/$style.conf" 2>/dev/null

# alacritty — overwrite theme.toml; live_config_reload picks it up instantly
cp "$HOME/.config/zsh/alacritty/themes/$style.toml" \
   "$HOME/.config/alacritty/theme.toml" 2>/dev/null

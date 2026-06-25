#!/usr/bin/env bash
set -euxo pipefail
exec > /tmp/tmux-sessionizer.log 2>&1

TMUX_BIN="$(command -v tmux)" || { echo 'tmux not found'; exit 1; }
FZF_BIN="$(command -v fzf)" || { echo 'fzf not found - brew install fzf'; exit 1; }

if [ -z "${TMUX-}" ]; then
    echo "Not inside tmux - this is meant to run via 'display-popup'." >&2
    exit 1
fi

NEW_LABEL="Create new session…"

sessions="$("$TMUX_BIN" list-sessions -F '#{session_name}' 2>/dev/null || true)"
menu="$NEW_LABEL
$sessions"

choice="$(printf '%s\n' "$menu" | "$FZF_BIN" \
    --prompt='Sessions> ' \
    --reverse \
    --no-multi || true)"

[ -n "$choice" ] || exit 0

if [ "$choice" = "$NEW_LABEL" ]; then
    # --print-query against empty input: type a name, hit enter,
    # fzf prints whatever you typed even with no match to select.
    new_name="$("$FZF_BIN" --print-query --prompt='New session name: ' < /dev/null | head -n1 || true)"
    [ -n "$new_name" ] || exit 0
    session="$new_name"
    create=1
else
    session="$choice"
    create=0
fi

if [ "$create" -eq 1 ] && ! "$TMUX_BIN" has-session -t "$session" 2>/dev/null; then
    "$TMUX_BIN" new-session -ds "$session"
fi

exec "$TMUX_BIN" switch-client -t "$session"

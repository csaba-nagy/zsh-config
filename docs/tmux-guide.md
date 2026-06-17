# tmux Everyday Guide

Prefix = `Ctrl+a` (`C-a`). All bindings require it unless noted otherwise.

---

## Sessions — the top level

| Action | Key |
|---|---|
| Start tmux | `tmux` in terminal |
| New named session | `tmux new -s work` |
| List sessions | `tmux ls` |
| Attach to last | `tmux attach` |
| Attach by name | `tmux attach -t work` |
| **Inside tmux:** pick session | `C-a S` |
| Kill current session | `C-a X` (prompts) |
| Detach (leave running) | `C-a d` |

---

## Windows — like browser tabs

| Action | Key |
|---|---|
| New window | `C-a c` |
| Next window | `C-a ]` or `C-a n` |
| Previous window | `C-a [` or `C-a p` |
| Toggle last window | `C-a Tab` |
| Rename window | `C-a ,` |
| Close window | `C-a &` (prompts) or `exit` |
| Move window left/right | `C-a <` / `C-a >` |

---

## Panes — splits inside a window

| Action | Key |
|---|---|
| Split horizontal (side by side) | `C-a \|` |
| Split vertical (top/bottom) | `C-a -` |
| Navigate panes | `C-a h/j/k/l` (vim-style) |
| Zoom/unzoom pane | `C-a z` |
| Resize pane (hold to repeat) | `C-a H/J/K/L` |
| Close pane | `C-a x` or `exit` |
| Show pane numbers | `C-a q` |

---

## Copy mode — scrollback & search

| Action | Key |
|---|---|
| Enter copy mode | `C-a Enter` |
| Search backward | `/` then type |
| Search forward | `?` then type |
| Start selection | `v` |
| Rectangle select | `C-v` |
| Copy & exit | `y` or `Enter` |
| Cancel | `Escape` |
| Paste | `C-a ]` (after copy) |

---

## Reload config

```
C-a r
```

---

## Daily workflow pattern

```sh
tmux new -s dev          # morning: one named session
C-a c                    # window 1: editor
C-a c                    # window 2: git/shell
C-a c                    # window 3: logs/server
C-a |                    # split for a quick side pane
C-a z                    # zoom in to focus
C-a Tab                  # flip between last two windows
C-a d                    # detach at end of day — session persists
tmux attach -t dev       # next morning: pick up exactly where you left
```

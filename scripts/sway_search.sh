#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/project-search"
HISTORY_FILE="$STATE_DIR/history"
mkdir -p "$STATE_DIR"
touch "$HISTORY_FILE"

initial_query="${1:-}"

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$cmd" >&2
    exit 1
  }
}

require_cmd fzf
require_cmd rg
require_cmd swaymsg

get_history() {
  tac "$HISTORY_FILE" | awk '!seen[$0]++' | grep -Fvx "$HOME" | head -n 5
}

save_dir() {
  local dir="$1"
  local tmp
  [ "$dir" = "$HOME" ] && return

  tmp="$(mktemp "$STATE_DIR/history.XXXXXX")"
  {
    grep -vxF "$dir" "$HISTORY_FILE" 2>/dev/null || true
    printf '%s\n' "$dir"
  } | tail -n 50 > "$tmp"
  mv "$tmp" "$HISTORY_FILE"
}

list_dirs() {
  if command -v fd >/dev/null 2>&1; then
    fd --hidden --type d --absolute-path \
      --exclude .git \
      --exclude node_modules \
      --exclude vendor \
      --exclude .cache \
      --exclude .cargo \
      --exclude target \
      --exclude .venv \
      . "$HOME" 2>/dev/null
  else
    find "$HOME" -type d \
      \( -name .git -o -name node_modules -o -name vendor -o -name .cache -o -name .cargo -o -name target -o -name .venv \) -prune -o \
      -type d -print 2>/dev/null
  fi
}

choose_search_dir() {
  local choice picked

  choice="$(
    {
      get_history | sed 's/^/Recent: /'
      printf 'Home: %s\n' "$HOME"
      printf 'Choose other directory\n'
    } | awk '!seen[$0]++' | \
      fzf \
        --height=50% \
        --layout=reverse \
        --prompt='Directory > ' \
        --border \
        --exit-0
  )"

  [ -z "${choice:-}" ] && return 1

  case "$choice" in
    "Recent: "*)
      printf '%s\n' "${choice#Recent: }"
      ;;
    "Home: "*)
      printf '%s\n' "${choice#Home: }"
      ;;
    "Choose other directory")
      picked="$(
        list_dirs | \
          fzf \
            --height=80% \
            --layout=reverse \
            --prompt='Find dir > ' \
            --header='Type to filter, arrows to move, TAB to copy selection to query, Enter to choose' \
            --border \
            --scheme=path \
            --bind='tab:replace-query' \
            --preview 'ls -la --color=always {} | sed -n "1,120p"' \
            --preview-window='right:60%:wrap' \
            --exit-0
      )"
      [ -n "${picked:-}" ] || return 1
      printf '%s\n' "$picked"
      ;;
    *)
      return 1
      ;;
  esac
}

search_dir="$(choose_search_dir)" || exit 0
save_dir "$search_dir"
cd "$search_dir"

printf '\033c' >/dev/tty 2>/dev/null || true

RG_RELOAD_CMD='query={q}; [ -n "$query" ] && rg --color=never --ignore-case -F --hidden --follow --line-number --no-heading --glob "!.git" --glob "!**/.git/**" --glob "!vendor" --glob "!**/vendor/**" --glob "!node_modules" --glob "!**/node_modules/**" --glob "!target" --glob "!**/target/**" --glob "!.venv" --glob "!**/.venv/**" --glob "!.cache" --glob "!**/.cache/**" -- "$query" 2>/dev/null || true'

if command -v bat >/dev/null 2>&1; then
  PREVIEW_CMD='
    file={1}
    line={2}

    if [ -n "$file" ] && [ -f "$file" ] && [ -n "$line" ]; then
      bat \
        --style=full \
        --color=always \
        --theme="gruvbox-dark" \
        --highlight-line "$line" \
        "$file" 2>/dev/null
    fi
  '
else
  PREVIEW_CMD='
    file={1}
    if [ -n "$file" ] && [ -f "$file" ]; then
      sed -n "1,200p" "$file" 2>/dev/null
    fi
  '
fi

selected="$(
  fzf \
    --ansi \
    --phony \
    --disabled \
    --query="$initial_query" \
    --height=100% \
    --layout=reverse \
    --prompt='Search > ' \
    --header="Dir: $search_dir" \
    --delimiter=':' \
    --preview="$PREVIEW_CMD" \
    --preview-window='right:70%:wrap,+{2}/3' \
    --bind="start:reload:$RG_RELOAD_CMD" \
    --bind="change:reload:$RG_RELOAD_CMD"
)"

[ -z "$selected" ] && exit 0

file="${selected%%:*}"
line_and_text="${selected#*:}"
line="${line_and_text%%:*}"

if ! [[ "$line" =~ ^[0-9]+$ ]]; then
  line=1
fi

if command -v realpath >/dev/null 2>&1; then
  file="$(realpath "$file")"
else
  file="$search_dir/$file"
fi

open_file() {
  local file="$1"
  local line="$2"
  local cmd inner

  if command -v codium >/dev/null 2>&1; then
    printf -v cmd 'codium --goto %q' "$file:$line"
    swaymsg exec "$cmd" >/dev/null
  elif command -v code >/dev/null 2>&1; then
    printf -v cmd 'code --goto %q' "$file:$line"
    swaymsg exec "$cmd" >/dev/null
  elif [ -n "${EDITOR:-}" ]; then
    case "$EDITOR" in
      *nvim*|*vim*)
        printf -v inner '%s +%s %q' "$EDITOR" "$line" "$file"
        printf -v cmd 'foot sh -lc %q' "$inner"
        swaymsg exec "$cmd" >/dev/null
        ;;
      *code*|*codium*)
        printf -v cmd '%s --goto %q' "$EDITOR" "$file:$line"
        swaymsg exec "$cmd" >/dev/null
        ;;
      *)
        printf -v inner '%s %q' "$EDITOR" "$file"
        printf -v cmd 'foot sh -lc %q' "$inner"
        swaymsg exec "$cmd" >/dev/null
        ;;
    esac
  else
    printf -v cmd 'xdg-open %q' "$file"
    swaymsg exec "$cmd" >/dev/null
  fi
}

open_file "$file" "$line"

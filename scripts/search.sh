#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/project-search"
HISTORY_FILE="$STATE_DIR/history"
mkdir -p "$STATE_DIR"
touch "$HISTORY_FILE"

initial_query="${1:-}"

get_history() {
  tac "$HISTORY_FILE" | awk '!seen[$0]++' | grep -v "^$HOME$" | head -n 5
}

save_dir() {
  local dir="$1"

  # do not store HOME
  [ "$dir" = "$HOME" ] && return

  grep -vxF "$dir" "$HISTORY_FILE" 2>/dev/null > "${HISTORY_FILE}.tmp" || true
  printf '%s\n' "$dir" >> "${HISTORY_FILE}.tmp"
  tail -n 50 "${HISTORY_FILE}.tmp" > "$HISTORY_FILE"
  rm -f "${HISTORY_FILE}.tmp"
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
        find "$HOME" -type d \
          \( -name .git -o -name node_modules -o -name vendor -o -name .cache -o -name .cargo -o -name target -o -name .venv \) -prune -o \
          -type d -print 2>/dev/null | \
          fzf \
            --height=80% \
            --layout=reverse \
            --prompt='Find dir > ' \
            --border \
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

# Reset terminal state between the two fzf sessions
printf '\033c' >/dev/tty 2>/dev/null || true

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
    --preview='
      file={1}
      line={2}
      q={q}

      if [ -n "$file" ] && [ -f "$file" ]; then
        if [ -n "$q" ]; then
          rg \
            --color=always \
            --ignore-case \
            -F \
            --line-number \
            --context 6 \
            --heading \
            -- "$q" "$file" 2>/dev/null
        elif [ -n "$line" ]; then
          start=$(( line > 40 ? line - 40 : 1 ))
          end=$(( line + 40 ))
          bat --style=numbers --color=always --highlight-line "$line" --line-range "${start}:${end}" "$file" 2>/dev/null \
            || sed -n "${start},${end}p" "$file"
        else
          bat --style=numbers --color=always --line-range :200 "$file" 2>/dev/null \
            || sed -n "1,200p" "$file"
        fi
      fi
    ' \
    --preview-window='right:70%:wrap' \
    --bind='start:reload:rg --color=never --ignore-case -F --hidden --follow --line-number --no-heading --glob "!.git" --glob "!**/.git/**" --glob "!vendor" --glob "!**/vendor/**" --glob "!node_modules" --glob "!**/node_modules/**" -- {q} 2>/dev/null || true' \
    --bind='change:reload:rg --color=never --ignore-case -F --hidden --follow --line-number --no-heading --glob "!.git" --glob "!**/.git/**" --glob "!vendor" --glob "!**/vendor/**" --glob "!node_modules" --glob "!**/node_modules/**" -- {q} 2>/dev/null || true'
)"

[ -z "$selected" ] && exit 0

file="$(printf '%s' "$selected" | cut -d: -f1)"
line="$(printf '%s' "$selected" | cut -d: -f2)"

if command -v realpath >/dev/null 2>&1; then
  file="$(realpath "$file")"
else
  file="$search_dir/$file"
fi

open_file() {
  local file="$1"
  local line="$2"

  if command -v codium >/dev/null 2>&1; then
    swaymsg exec "codium --goto \"$file:$line\"" >/dev/null
  elif command -v code >/dev/null 2>&1; then
    swaymsg exec "code --goto \"$file:$line\"" >/dev/null
  elif [ -n "${EDITOR:-}" ]; then
    case "$EDITOR" in
      *nvim*|*vim*)
        swaymsg exec "foot sh -lc '${EDITOR} +${line} \"${file}\"'" >/dev/null
        ;;
      *code*|*codium*)
        swaymsg exec "$EDITOR --goto \"$file:$line\"" >/dev/null
        ;;
      *)
        swaymsg exec "foot sh -lc '${EDITOR} \"${file}\"'" >/dev/null
        ;;
    esac
  else
    swaymsg exec "xdg-open \"$file\"" >/dev/null
  fi
}

open_file "$file" "$line"
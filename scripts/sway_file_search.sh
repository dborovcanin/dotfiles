#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/file_search"
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
require_cmd xdg-open

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

list_files() {
  local root="$1"
  if command -v fd >/dev/null 2>&1; then
    fd --hidden --type f --absolute-path \
      --exclude .git \
      --exclude node_modules \
      --exclude vendor \
      --exclude .cache \
      --exclude .cargo \
      --exclude target \
      --exclude .venv \
      . "$root" 2>/dev/null
  else
    find "$root" \
      \( -name .git -o -name node_modules -o -name vendor -o -name .cache -o -name .cargo -o -name target -o -name .venv \) -prune -o \
      -type f -print 2>/dev/null
  fi
}

parse_query_mode() {
  local query="$1"
  MODE=""
  TERM="$query"

  if [[ "$query" == *:* ]]; then
    local maybe_mode="${query%%:*}"
    local maybe_term="${query#*:}"
    case "$maybe_mode" in
      d|i|w|c)
        MODE="$maybe_mode"
        TERM="$maybe_term"
        ;;
      *)
        MODE=""
        TERM="$maybe_term"
        ;;
    esac
  fi
}

launch_cmd_detached() {
  local cmd="$1"

  if command -v swaymsg >/dev/null 2>&1; then
    swaymsg exec "$cmd" >/dev/null 2>&1 || true
  elif command -v setsid >/dev/null 2>&1; then
    setsid sh -c "$cmd" >/dev/null 2>&1 < /dev/null &
  else
    sh -c "$cmd" >/dev/null 2>&1 &
  fi
}

open_with_xdg() {
  local target="$1"
  local cmd
  printf -v cmd 'xdg-open %q' "$target"
  launch_cmd_detached "$cmd"
}

open_image_preview() {
  local file="$1"
  local cmd

  if command -v feh >/dev/null 2>&1; then
    printf -v cmd 'feh --auto-zoom --scale-down %q' "$file"
    launch_cmd_detached "$cmd"
  else
    open_with_xdg "$file"
  fi
}

url_encode() {
  local input="$1"
  local output=""
  local i char hex
  local LC_ALL=C

  for ((i = 0; i < ${#input}; i++)); do
    char="${input:i:1}"
    case "$char" in
      [a-zA-Z0-9.~_-])
        output+="$char"
        ;;
      ' ')
        output+='+'
        ;;
      *)
        printf -v hex '%%%02X' "'$char"
        output+="$hex"
        ;;
    esac
  done

  printf '%s' "$output"
}

if command -v wl-copy >/dev/null 2>&1; then
  COPY_SELECTION_CMD='wl-copy'
elif command -v xclip >/dev/null 2>&1; then
  COPY_SELECTION_CMD='xclip -selection clipboard'
elif command -v xsel >/dev/null 2>&1; then
  COPY_SELECTION_CMD='xsel --clipboard --input'
else
  COPY_SELECTION_CMD='cat >/dev/null'
fi

search_dir="$(choose_search_dir)" || exit 0
save_dir "$search_dir"
cd "$search_dir"

printf '\033c' >/dev/tty 2>/dev/null || true

FILE_INDEX="$(mktemp "$STATE_DIR/files.XXXXXX")"
trap 'rm -f "$FILE_INDEX"' EXIT
list_files "$search_dir" > "$FILE_INDEX"
export FILE_INDEX

RELOAD_CMD='
query={q}
mode=""
term="$query"

if [[ "$query" == *:* ]]; then
  maybe_mode="${query%%:*}"
  maybe_term="${query#*:}"
  case "$maybe_mode" in
    d|i|w|c)
      mode="$maybe_mode"
      term="$maybe_term"
      ;;
    *)
      mode=""
      term="$maybe_term"
      ;;
  esac
fi

filter_by_term() {
  if [ -n "$term" ]; then
    rg --ignore-case --fixed-strings -- "$term" || true
  else
    cat
  fi
}

case "$mode" in
  d)
    (rg --ignore-case "\\.(pdf|txt|md|markdown|doc|docx|odt|rtf|ppt|pptx|odp|xls|xlsx|ods|csv|epub)$" "$FILE_INDEX" 2>/dev/null || true) | filter_by_term
    ;;
  i)
    (rg --ignore-case "\\.(svg|png|jpg|jpeg|gif|bmp|webp|tif|tiff|ico|avif|heic)$" "$FILE_INDEX" 2>/dev/null || true) | filter_by_term
    ;;
  w)
    if [ -n "$term" ]; then
      printf "Web search: %s\n" "$term"
    else
      printf "Type query after w: to search the web\n"
    fi
    ;;
  c)
    if [ -n "$term" ]; then
      printf "ChatGPT: %s\n" "$term"
    else
      printf "Type query after c: to open ChatGPT\n"
    fi
    ;;
  *)
    cat "$FILE_INDEX" | filter_by_term
    ;;
esac
'

result="$(
  fzf \
    --phony \
    --disabled \
    --query="$initial_query" \
    --print-query \
    --height=100% \
    --layout=reverse \
    --prompt='File > ' \
    --header="Dir: $search_dir | Prefix: d: docs, i: images, w: web, c: chatgpt | Ctrl+Y: copy selection" \
    --bind="start:reload:$RELOAD_CMD" \
    --bind="change:reload:$RELOAD_CMD" \
    --bind="ctrl-y:execute-silent(printf '%q\n' {} | $COPY_SELECTION_CMD)+abort" \
    --exit-0
)"

[ -z "${result:-}" ] && exit 0

query="${result%%$'\n'*}"
selected="${result#*$'\n'}"
if [ "$selected" = "$result" ]; then
  selected=""
fi

[ -z "${selected:-}" ] && exit 0

parse_query_mode "$query"

case "$MODE" in
  w)
    [ -n "$TERM" ] || exit 0
    encoded_query="$(url_encode "$TERM")"
    open_with_xdg "https://duckduckgo.com/?q=$encoded_query"
    ;;
  c)
    [ -n "$TERM" ] || exit 0
    encoded_query="$(url_encode "$TERM")"
    open_with_xdg "https://chatgpt.com/?q=$encoded_query"
    ;;
  i)
    open_image_preview "$selected"
    ;;
  *)
    open_with_xdg "$selected"
    ;;
esac

# Find in files: live rga search in fzf, then open the match in $EDITOR or
# insert it at the cursor. Bound to Ctrl-F.
function fif
    set -l reload "reload:rga --files-with-matches --hidden --follow --glob '!.git' {q} || true"
    set -l file (
        fzf --phony --sort \
            --query=(commandline -t) \
            --preview='[ -n {} ] && rga --pretty --context 5 {q} {}' \
            --preview-window='75%:wrap' \
            --bind="start:$reload" \
            --bind="change:$reload"
    )

    if test -n "$file"
        switch (printf '%s\n' open insert cancel | fzf --prompt='Action > ' --height=10 --layout=reverse)
            case open
                $EDITOR $file </dev/tty >/dev/tty 2>&1
            case insert
                commandline -i -- (string escape -- $file)
        end
    end

    commandline -f repaint
end

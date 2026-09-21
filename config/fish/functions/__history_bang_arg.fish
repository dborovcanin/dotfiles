# Backs the !$ abbreviation in config.fish.
function __history_bang_arg --description 'Last argument of the previous command line, for !$'
    set -l words (string split -n ' ' -- $history[1])
    test (count $words) -gt 0; and echo -- $words[-1]
end

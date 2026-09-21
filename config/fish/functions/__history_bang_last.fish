# Backs the !! abbreviation in config.fish. $history[1] is the previous command
# line; the current, unexecuted line is not in it yet, so no guard is needed.
function __history_bang_last --description 'Previous command line, for !!'
    echo -- $history[1]
end

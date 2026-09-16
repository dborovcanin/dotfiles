# Two-line lean prompt: directory and git status, then the prompt char.
# Past prompts collapse to the prompt char alone (fish_transient_prompt).
#
# Git status is computed in a background fish that writes "$PWD\n<status>"
# to a file in $XDG_RUNTIME_DIR and signals this shell with SIGUSR1, which
# reads it and repaints. Until then the prompt shows the last result for
# the same directory.
set -g __prompt_git_file (set -q XDG_RUNTIME_DIR; and echo $XDG_RUNTIME_DIR; or echo /tmp)/fish-prompt-git-$fish_pid

function __prompt_git_async --on-event fish_prompt
    # Blank line between commands, but not above the first prompt. Decided
    # here, once per prompt, since repaints run fish_prompt again.
    set -g __prompt_newline $__prompt_seen
    set -g __prompt_seen 1

    command kill $__prompt_git_job 2>/dev/null
    fish --no-config -c 'source $argv[1]
        begin; echo $PWD; __prompt_git; end >$argv[2]
        command kill -USR1 $argv[3]' \
        (functions --details __prompt_git) $__prompt_git_file $fish_pid &
    set -g __prompt_git_job $last_pid
    disown $last_pid
end

function __prompt_git_ready --on-signal SIGUSR1
    read -g --line __prompt_git_pwd __prompt_git_status <$__prompt_git_file
    commandline -f repaint
end

function __prompt_git_cleanup --on-event fish_exit
    command rm -f $__prompt_git_file
end

# This file loads right before the first prompt, after its event fired.
__prompt_git_async

function fish_prompt
    set -l last_status $status
    set -l char_color 5fd700
    test $last_status -ne 0; and set char_color ff0000

    if contains -- --final-rendering $argv
        printf '%s❯%s ' (set_color $char_color) (set_color normal)
        return
    end

    test -n "$__prompt_newline"; and echo

    set -l dir (prompt_pwd -d 0)
    test (string length -- $dir) -gt 80; and set dir (prompt_pwd)
    set -l parent (string replace -r '[^/]*$' '' -- $dir)
    set -l base (string match -r '[^/]*$' -- $dir)
    test -z "$base"; and set parent ''; and set base $dir

    set -l git
    test "$__prompt_git_pwd" = $PWD; and set git $__prompt_git_status

    printf '%s%s%s%s%s%s\n' (set_color 0087af) $parent (set_color -o 00afff) $base \
        (set_color normal) "$git"
    printf '%s❯%s ' (set_color $char_color) (set_color normal)
end

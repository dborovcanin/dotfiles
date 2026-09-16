# Two-line lean prompt: directory and git status, then the prompt char.
# Past prompts collapse to the prompt char alone (fish_transient_prompt).
function fish_prompt
    set -l last_status $status
    set -l char_color 5fd700
    test $last_status -ne 0; and set char_color ff0000

    if contains -- --final-rendering $argv
        printf '%s❯%s ' (set_color $char_color) (set_color normal)
        return
    end

    # Blank line between commands, but not above the first prompt.
    set -q __prompt_drawn; and echo
    set -g __prompt_drawn

    set -l dir (prompt_pwd -d 0)
    test (string length -- $dir) -gt 80; and set dir (prompt_pwd)
    set -l parent (string replace -r '[^/]*$' '' -- $dir)
    set -l base (string match -r '[^/]*$' -- $dir)
    test -z "$base"; and set parent ''; and set base $dir

    printf '%s%s%s%s%s%s\n' (set_color 0087af) $parent (set_color -o 00afff) $base \
        (set_color normal) (__prompt_git)
    printf '%s❯%s ' (set_color $char_color) (set_color normal)
end

# Exit status, duration of slow commands, background jobs, user@host
# (only for root or over SSH) and the time.
function fish_right_prompt
    set -l last_pipestatus $pipestatus
    contains -- --final-rendering $argv; and return

    set -l parts

    if string match -qv 0 -- $last_pipestatus
        set -l codes
        for code in $last_pipestatus
            set -a codes (fish_status_to_signal $code)
        end
        set -a parts (set_color d70000)"✘ "(string join '|' -- $codes)
    end

    if test "$CMD_DURATION" -ge 3000 2>/dev/null
        set -l s (math -s0 $CMD_DURATION / 1000)
        set -l d (math -s0 $s / 86400) (math -s0 $s / 3600 % 24) (math -s0 $s / 60 % 60) (math $s % 60)
        set -l time
        for i in 1 2 3 4
            if test $d[$i] -gt 0; or test $i -eq 4; or set -q time[1]
                set -a time $d[$i](string sub -s $i -l 1 dhms)
            end
        end
        set -a parts (set_color 875f5f)"$time"
    end

    jobs -q; and set -a parts (set_color 5faf00)\uf013

    if fish_is_root_user
        set -a parts (set_color -o d7af00)$USER@$hostname
    else if set -q SSH_CONNECTION
        set -a parts (set_color d7af87)$USER@$hostname
    end

    set -a parts (set_color 5f8787)(date +%T)

    echo -n (string join ' ' -- $parts)(set_color normal)
end

# Git segment from a single `git status` call:
# branch ⇣behind⇡ahead ~conflicted +staged !unstaged ?untracked
function __prompt_git
    set -l lines (command git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)
    or return

    set -l clean (set_color 5fd700)
    set -l modified (set_color d7af00)
    set -l conflicted (set_color ff0000)
    set -l meta (set_color 808080)

    set -l branch (string replace -f '# branch.head ' '' -- $lines)
    if test "$branch" = '(detached)'
        set branch $meta@$clean(string replace -f '# branch.oid ' '' -- $lines | string sub -l 8)
    else
        set branch (string shorten -m 32 -- $branch)
    end

    set -l out " $clean$branch"

    set -l ab (string match -rg '^# branch.ab \+(\d+) -(\d+)' -- $lines)
    if set -q ab[1]
        test $ab[2] -gt 0; and set out "$out $clean⇣$ab[2]"
        test $ab[1] -gt 0 -a $ab[2] -eq 0; and set out "$out "
        test $ab[1] -gt 0; and set out "$out$clean⇡$ab[1]"
    end

    set -l n (count (string match -r '^u ' -- $lines))
    test $n -gt 0; and set out "$out $conflicted~$n"
    set n (count (string match -r '^[12] [^.]' -- $lines))
    test $n -gt 0; and set out "$out $modified+$n"
    set n (count (string match -r '^[12] .[^.]' -- $lines))
    test $n -gt 0; and set out "$out $modified!$n"
    set n (count (string match -r '^\? ' -- $lines))
    test $n -gt 0; and set out "$out $clean?$n"

    echo -n $out(set_color normal)
end

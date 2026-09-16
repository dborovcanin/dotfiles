function fish_user_key_bindings
    # Ctrl-R, Ctrl-T and Alt-C from fzf.
    if test -r ~/.fzf/shell/key-bindings.fish
        source ~/.fzf/shell/key-bindings.fish
        fzf_key_bindings
    end

    bind ctrl-f fif

    # Edit the command line in $VISUAL, like zsh/bash. Alt-E and Alt-V do the same.
    bind ctrl-x,ctrl-e edit_command_buffer
end

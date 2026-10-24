# Claude Code on account 2, kept apart in its own config dir.
function claude2 --wraps claude --description 'Claude Code (account 2)'
    CLAUDE_CONFIG_DIR=$HOME/.claude-account2 claude $argv
end

# Claude Code on account 1, kept apart in its own config dir.
function claude1 --wraps claude --description 'Claude Code (account 1)'
    CLAUDE_CONFIG_DIR=$HOME/.claude-account1 claude $argv
end

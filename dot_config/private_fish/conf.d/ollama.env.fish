# Run Claude Code against a local Ollama model (default: inkling-2-mini).
# Extra arguments pass through to claude; override the model with
#   CLAUDE_LOCAL_MODEL=<name> claude-local   (or `claude-local --model <name>`).
# Requires `ollama serve` to be running. The Vertex variables from
# claude-code.env.fish are unset for this session so Claude Code talks to
# Ollama instead of Vertex AI.
function claude-local
    set -l model inkling-2-mini
    set -q CLAUDE_LOCAL_MODEL; and set model $CLAUDE_LOCAL_MODEL
    env -u CLAUDE_CODE_USE_VERTEX -u CLOUD_ML_REGION -u ANTHROPIC_VERTEX_PROJECT_ID \
        ANTHROPIC_BASE_URL=http://localhost:11434 \
        ANTHROPIC_AUTH_TOKEN=ollama \
        ANTHROPIC_API_KEY= \
        command claude --model $model $argv
end

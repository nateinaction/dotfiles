# Run Claude Code against a local Ollama model (default: inkling-2-mini).
# Extra arguments pass through to claude; override the model with
#   CLAUDE_LOCAL_MODEL=<name> claude-local   (or `claude-local --model <name>`).
# Requires `ollama serve` to be running. The Vertex variables from
# claude-code.env.fish are unset for this session so Claude Code talks to
# Ollama instead of Vertex AI.
# Local-model tuning: CLAUDE_CODE_ATTRIBUTION_HEADER=0 stops Claude Code
# putting a per-request value at the start of the system prompt, which defeats
# Ollama's prefix cache (every request reprocessed the full ~36k prompt).
# --strict-mcp-config with no --mcp-config loads no MCP servers, keeping the
# prompt small so prompt processing stays under Ollama's request time limit.
function claude-local
    set -l model inkling-2-mini
    set -q CLAUDE_LOCAL_MODEL; and set model $CLAUDE_LOCAL_MODEL
    env -u CLAUDE_CODE_USE_VERTEX -u CLOUD_ML_REGION -u ANTHROPIC_VERTEX_PROJECT_ID \
        ANTHROPIC_BASE_URL=http://localhost:11434 \
        ANTHROPIC_AUTH_TOKEN=ollama \
        ANTHROPIC_API_KEY= \
        CLAUDE_CODE_ATTRIBUTION_HEADER=0 \
        command claude --model $model --strict-mcp-config $argv
end

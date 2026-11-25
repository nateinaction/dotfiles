# OpenCode has no temp-directory setting: it calls os.TempDir(), which on macOS
# resolves to $TMPDIR (/var/folders/<id>/T). Launch it with TMPDIR=/tmp instead
# so its scratch files (shell tool output, external-editor buffers) land in a
# short, predictable path that is the same on macOS and Linux. BUN_TMPDIR is
# set too because the Bun-built TUI runtime reads it rather than TMPDIR.
function opencode
    env TMPDIR=/tmp BUN_TMPDIR=/tmp command opencode $argv
end

# Run OpenCode against a local Ollama model (default: inkling-2-mini). Ollama
# is a built-in OpenCode provider that lists local models as `<name>:latest`.
# Override the model with OPENCODE_LOCAL_MODEL=<name:tag> and the context limit
# OpenCode plans around with OPENCODE_LOCAL_CONTEXT. Keep that limit at or
# below the server's OLLAMA_CONTEXT_LENGTH (the default here assumes the
# server runs with OLLAMA_CONTEXT_LENGTH=200000); raise both together. A
# lower OpenCode limit makes it compact early, a higher one sends prompts
# Ollama cannot hold. Prefill measured ~1.6k tok/s on inkling-2-mini, so a
# cold-cache prompt past ~90k tokens would exceed Ollama's ~60s request limit.
# --standalone gives this run a private server, so the config below is not
# ignored by an already-running OpenCode background service.
# Global instructions (~/.claude/CLAUDE.md) and plugins still load.
function opencode-local
    set -l model inkling-2-mini:latest
    set -q OPENCODE_LOCAL_MODEL; and set model $OPENCODE_LOCAL_MODEL
    set -l context 200000
    set -q OPENCODE_LOCAL_CONTEXT; and set context $OPENCODE_LOCAL_CONTEXT

    # Build the JSON with jaq so the model name is escaped, not concatenated.
    set -lx OPENCODE_CONFIG_CONTENT (jaq -nc --arg m $model --argjson c $context \
        '{model: ("ollama/" + $m), provider: {ollama: {models: {($m): {limit: {context: $c, output: 8192}}}}}}')
    or begin
        echo "opencode-local: failed to build config" >&2
        return 1
    end
    opencode --standalone $argv
end

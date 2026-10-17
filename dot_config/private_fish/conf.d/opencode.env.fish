# OpenCode has no temp-directory setting: it calls os.TempDir(), which on macOS
# resolves to $TMPDIR (/var/folders/<id>/T). Launch it with TMPDIR=/tmp instead
# so its scratch files (shell tool output, external-editor buffers) land in a
# short, predictable path that is the same on macOS and Linux. BUN_TMPDIR is
# set too because the Bun-built TUI runtime reads it rather than TMPDIR.
function opencode
    env TMPDIR=/tmp BUN_TMPDIR=/tmp command opencode $argv
end

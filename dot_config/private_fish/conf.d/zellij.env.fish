# Nix sets a long $TMPDIR that pushes zellij's Unix socket path (which
# includes the session name) past the ~103-byte kernel limit on macOS,
# causing zellij to silently fail to bind and die with no error output.
# Use a short, fixed socket dir instead, regardless of how zellij is invoked.
set -gx ZELLIJ_SOCKET_DIR /tmp/zellij

function code
    if test -z "$argv"
        echo "Usage: code <path>"
        return 1
    end

    set -l path (cd "$argv[1]" 2>/dev/null && pwd || echo "$argv[1]")
    set -l session_name "code-"(basename "$path")

    # Nix sets a long $TMPDIR that pushes zellij's Unix socket path
    # past the 103-byte kernel limit.
    set -lx ZELLIJ_SOCKET_DIR /tmp/zellij

    if zellij list-sessions -s 2>/dev/null | grep -qx "$session_name"
        zellij attach "$session_name"
        return 0
    end

    cd "$path"; and zellij --layout code attach --create "$session_name"
end

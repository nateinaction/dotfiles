if status is-interactive
    alias ll="ls -lah"
    set -g fish_greeting
end

# Default editor
set -gx EDITOR hx
set -gx VISUAL hx
set -gx SUDO_EDITOR hx

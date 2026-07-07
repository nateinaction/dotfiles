# Work-specific packages — only deployed on work machines by chezmoi.
# The user-packages flake.nix merges these into the user-cli-tools profile
# when this file exists.
pkgs: with pkgs; [
  # Add work-specific packages here, e.g.:
  # awscli2
  # kubectl
  # terraform
]

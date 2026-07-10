# Work-specific packages — only deployed on work machines by chezmoi.
# The user-packages flake.nix merges these into the user-cli-tools profile
# when this file exists.
pkgs: with pkgs; [
  azure-cli # Azure command-line client (MIT)
  google-cloud-sdk # Google Cloud CLI (Apache-2.0)

  # PHP Tooling
  php # PHP interpreter (PHP-3.01)
  phpPackages.composer # PHP dependency manager (MIT)
]

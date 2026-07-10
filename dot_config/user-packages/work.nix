# Work-specific packages — only deployed on work machines by chezmoi.
# The user-packages flake.nix merges these into the user-cli-tools profile
# when this file exists.
pkgs: with pkgs; [
  azure-cli # Azure command-line client (MIT)
  google-cloud-sdk # Google Cloud CLI (Apache-2.0)

  # PHP Tooling
  php # PHP interpreter (PHP-3.01)
  phpunit # PHP testing framework (BSD-3)
  phpPackages.composer # PHP dependency manager (MIT)
  phpPackages.php-codesniffer # PHP code style checker/fixer, provides phpcs/phpcbf (BSD-3)
]

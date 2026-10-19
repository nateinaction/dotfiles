# Work-specific packages — only deployed on work machines by chezmoi.
# The user-packages flake.nix merges these into the user-cli-tools profile
# when this file exists.
pkgs: with pkgs; [
  acli # Atlassian Command Line Interface (Jira, Confluence, etc.)
  python3 # runs the atlassian skill's md2adf.py Markdown-to-ADF converter (PSF-2.0)
  azure-cli # Azure command-line client (MIT)
  (google-cloud-sdk.withExtraComponents [
    google-cloud-sdk.components.gke-gcloud-auth-plugin # kubectl auth plugin for GKE clusters (Apache-2.0)
  ])
  oci-cli # Oracle Cloud Infrastructure command-line client (Apache-2.0/UPL)
  k3d # k3s in Docker (MIT)
  docker # Docker CLI, daemon provided by Docker Desktop/OrbStack (Apache-2.0)

  # Kubernetes tooling
  argo-rollouts # kubectl plugin for Argo Rollouts, provides `kubectl-argo-rollouts` (Apache-2.0)

  # PHP Tooling
  php # PHP interpreter (PHP-3.01)
  phpPackages.composer # PHP dependency manager (MIT)
]

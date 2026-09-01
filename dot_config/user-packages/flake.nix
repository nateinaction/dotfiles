{
  description = "User-scoped CLI tools installed into my Nix profile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forEachSystem = f:
        nixpkgs.lib.genAttrs systems (system:
          f (import nixpkgs {
            inherit system;
            # claude-code is unfree; opt in explicitly for this profile.
            config.allowUnfree = true;
          }));
    in
    {
      packages = forEachSystem (pkgs: {
        # A single environment bundling every user-scoped CLI tool, so the whole
        # set is installed/upgraded as one Nix profile entry named "user-cli-tools".
        user-cli-tools = pkgs.buildEnv {
          name = "user-cli-tools";
          paths = [
            pkgs.claude-code # Anthropic Claude Code CLI (unfree)
            pkgs.codex # OpenAI Codex CLI (unfree)
            pkgs.direnv # Load project-specific environments (MIT, Rust)
            pkgs.fish # Friendly interactive shell (GPL-2)
            pkgs.fzf # Command-line fuzzy finder (MIT, Go)
            pkgs.gh # GitHub CLI (MIT, Go)
            pkgs.git # Distributed version control system (GPL-2)
            pkgs.gnupg # GNU Privacy Guard (GPL-3)
            pkgs.helix # Post-modern modal text editor, provides `hx` (MPL-2)
            pkgs.jaq # JSON processor (jq-compatible), used by the Claude Code statusline script (MIT, Rust)
            pkgs.nerd-fonts.jetbrains-mono # JetBrainsMono Nerd Font, glyphs for starship (OFL)
            pkgs.starship # Cross-shell prompt (ISC, Rust)
            pkgs.tailscale # Mesh VPN CLI (BSD-3)
            pkgs.watch # Execute a program periodically, from procps (GPL-2)
            pkgs.zellij # Terminal workspace/multiplexer (MIT, Rust)
            pkgs.zoxide # Smarter cd command (MIT, Rust)

            # Passphrase entry dialog for GnuPG
            (if pkgs.stdenv.hostPlatform.isDarwin
              then pkgs.pinentry_mac # macOS Keychain-integrated pinentry (GPL-2)
              else pkgs.pinentry-curses) # Terminal pinentry (GPL-2)

            # Go toolchain
            pkgs.go # Go compiler/toolchain (BSD-3)
            pkgs.gopls # Go language server (BSD-3)
            pkgs.golangci-lint # Go meta-linter (GPL-3), backs golangci-lint-langserver
            pkgs.golangci-lint-langserver # LSP wrapper for golangci-lint (MIT)
            pkgs.delve # Go debugger, provides `dlv` (MIT)

            # Container image tooling
            pkgs.crane # Tool for interacting with remote container images/registries (Apache-2.0)

            # Kubernetes tooling
            pkgs.kubectl # Kubernetes command-line client (Apache-2.0)
            pkgs.kubectx # Utility to manage and switch contexts (Apache-2.0)
            pkgs.kustomize # Customization of Kubernetes YAML configurations (Apache-2.0)
            pkgs.k9s # Kubernetes cluster manager TUI (Apache-2.0)

            # Terraform tooling
            pkgs.tenv # Terraform/Tofu/Terragrunt version manager (Apache-2.0)
          ] ++ (if builtins.pathExists ./work.nix then import ./work.nix pkgs else []);
        };

        default = self.packages.${pkgs.stdenv.hostPlatform.system}.user-cli-tools;
      });
    };
}

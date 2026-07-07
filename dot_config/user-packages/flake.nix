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
            pkgs.helix # Post-modern modal text editor, provides `hx` (MPL-2)
            pkgs.gh # GitHub CLI (MIT, Go)
            pkgs.claude-code # Anthropic Claude Code CLI (unfree)
            pkgs.starship # Cross-shell prompt (ISC, Rust)
            pkgs._1password-cli # 1Password CLI, provides `op` (unfree)
            pkgs.zoxide # Smarter cd command (MIT, Rust)
            pkgs.fzf # Command-line fuzzy finder (MIT, Go)

            # Go toolchain + Helix language support
            pkgs.go # Go compiler/toolchain (BSD-3)
            pkgs.gopls # Go language server (BSD-3)
            pkgs.golangci-lint # Go meta-linter (GPL-3), backs golangci-lint-langserver
            pkgs.golangci-lint-langserver # LSP wrapper for golangci-lint (MIT)
            pkgs.delve # Go debugger, provides `dlv` (MIT)
          ] ++ (if builtins.pathExists ./work.nix then import ./work.nix pkgs else []);
        };

        default = self.packages.${pkgs.stdenv.hostPlatform.system}.user-cli-tools;
      });
    };
}

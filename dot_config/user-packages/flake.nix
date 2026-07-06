{
  description = "User-scoped CLI tools installed into my Nix profile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
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
            pkgs.gh # GitHub CLI (MIT, Go)
            pkgs.claude-code # Anthropic Claude Code CLI (unfree)
            pkgs.starship # Cross-shell prompt (ISC, Rust)
          ];
        };

        default = self.packages.${pkgs.stdenv.hostPlatform.system}.user-cli-tools;
      });
    };
}

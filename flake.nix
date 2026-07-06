{
  description = "chezmoi dotfiles development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Toolchain shared by local workflows (via direnv + .envrc) and any CI
        # run (via `nix develop -c ...`). fish is needed for the local
        # pre-commit hook that syntax-checks the fish config.
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pre-commit
            fish
          ];

          shellHook = ''
            # Idempotently install the git hooks on shell entry so every clone
            # and worktree (activated via direnv) commits through pre-commit —
            # otherwise lint that only CI's --all-files run catches slips through.
            if [ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1; then
              pre-commit install --install-hooks >/dev/null 2>&1 || true
            fi
          '';
        };
      }
    );
}

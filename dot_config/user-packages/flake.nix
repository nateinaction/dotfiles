{
  description = "User-scoped CLI tools installed into my Nix profile";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  # azure-cli (work.nix) is broken in current nixpkgs-unstable: its dependency
  # python3Packages.fabric needs invoke<3 but nixpkgs ships invoke 3. Take
  # azure-cli from this older pin until fabric is fixed upstream, then drop it
  # and refresh the lock with `nix flake update`.
  inputs.nixpkgs-azure.url = "github:NixOS/nixpkgs/98d5e8a5c13ec5de0d5a4d569f61a5e0480177c9";

  outputs = { self, nixpkgs, nixpkgs-azure }:
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
      packages = forEachSystem (pkgs:
        let
          # OpenCode v2 is not in nixpkgs (which carries 1.x). Package the
          # official standalone CLI binary instead, pinned by version and hash.
          # Available builds/hashes:
          #   https://opencode.ai/update/api/latest/cli/opencode
          opencode-v2 = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
            pname = "opencode";
            version = "2.2.0";

            src = pkgs.fetchurl (
              if pkgs.stdenv.hostPlatform.isDarwin
              then {
                url = "https://opencode.ai/files/bin/${finalAttrs.version}/opencode-darwin-${if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x64"}.zip";
                hash =
                  if pkgs.stdenv.hostPlatform.isAarch64
                  then "sha256-xxsc2WVBU5rTjip1N30vQ9KidWcomhQ3GhgumggA2z0="
                  else "sha256-zBkaHOybnNAZLXjcBmu/SHMGORMUIvpUyHxIWoIbodU=";
              }
              else {
                url = "https://opencode.ai/files/bin/${finalAttrs.version}/opencode-linux-${if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x64"}.tar.gz";
                hash =
                  if pkgs.stdenv.hostPlatform.isAarch64
                  then "sha256-Hxzg/Ae5JFqBX/qdZS27gOaw8H5b906ofSscAzn7rFI="
                  else "sha256-bVl5cKjMRI8bmp9kVTJYSzOd06uVg7tfBj8T2D5Udo8=";
              }
            );

            # Extracting a zip needs unzip; the prebuilt Linux ELF needs its
            # interpreter and library paths rewritten for the Nix store.
            nativeBuildInputs =
              pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.unzip ]
              ++ pkgs.lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.autoPatchelfHook ];

            buildInputs = pkgs.lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
            ];

            dontConfigure = true;
            dontBuild = true;

            # The archives ship the bare `opencode` binary; extract in place so
            # the default single-consumable-directory assumption does not trip.
            sourceRoot = ".";
            unpackPhase = ''
              runHook preUnpack
              unpackFile $src
              runHook postUnpack
            '';

            installPhase = ''
              runHook preInstall
              install -Dm755 "$(find . -type f -name opencode -print -quit)" $out/bin/opencode
              runHook postInstall
            '';

            meta = {
              description = "OpenCode v2 terminal AI coding agent (standalone binary)";
              homepage = "https://opencode.ai";
              license = pkgs.lib.licenses.mit;
              mainProgram = "opencode";
              platforms = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
            };
          });

          # work.nix sees the same package set, with azure-cli from the older pin.
          workPkgs = pkgs // {
            inherit (import nixpkgs-azure { system = pkgs.stdenv.hostPlatform.system; }) azure-cli;
          };
        in
        {
          # A single environment bundling every user-scoped CLI tool, so the whole
          # set is installed/upgraded as one Nix profile entry named "user-cli-tools".
          user-cli-tools = pkgs.buildEnv {
            name = "user-cli-tools";
            paths = [
              pkgs.age # Simple, modern file encryption tool (BSD-3, Go)
              pkgs.alacritty # GPU-accelerated terminal emulator (Apache-2.0, Rust)
              pkgs.anki-bin # Spaced-repetition flashcard app, prebuilt (AGPL-3); pkgs.anki's macOS build is currently broken (anki-mac-helper version-metadata mismatch)
              pkgs.claude-code # Anthropic Claude Code CLI (unfree)
              pkgs.coreutils # GNU core utilities: ls, cp, mv, etc. (GPL-3)
              pkgs.direnv # Load project-specific environments (MIT, Rust)
              pkgs.fish # Friendly interactive shell (GPL-2)
              pkgs.fzf # Command-line fuzzy finder (MIT, Go)
              pkgs.gh # GitHub CLI (MIT, Go)
              pkgs.git # Distributed version control system (GPL-2)
              pkgs.gnupg # GNU Privacy Guard (GPL-3)
              pkgs.helix # Post-modern modal text editor, provides `hx` (MPL-2)
              pkgs.herdr # Agent multiplexer that lives in your terminal (Apache-2.0)
              pkgs.hey # HTTP load generator, ApacheBench (ab) replacement (Apache-2.0, Go)
              pkgs.jaq # JSON processor (jq-compatible), used by the Claude Code statusline script (MIT, Rust)
              pkgs.nerd-fonts.jetbrains-mono # JetBrainsMono Nerd Font, glyphs for starship (OFL)
              pkgs.obsidian # Knowledge base / markdown note-taking app (proprietary, unfree)
              opencode-v2 # Terminal AI coding agent v2 (MIT, pinning the standalone binary; nixpkgs only ships 1.x)
              pkgs.starship # Cross-shell prompt (ISC, Rust)
              pkgs.tailscale # Mesh VPN CLI (BSD-3)
              pkgs.watch # Execute a program periodically, from procps (GPL-2)
              pkgs.yq-go # YAML/JSON/XML processor, provides `yq` (MIT, Go)
              pkgs.zellij # Terminal workspace/multiplexer (MIT, Rust)
              pkgs.zoxide # Smarter cd command (MIT, Rust)

              # Passphrase entry dialog for GnuPG
              (if pkgs.stdenv.hostPlatform.isDarwin
                then pkgs.pinentry_mac # macOS Keychain-integrated pinentry (GPL-2)
                else pkgs.pinentry-curses) # Terminal pinentry (GPL-2)

              # Go toolchain
              pkgs.go_1_27 # Go compiler/toolchain (BSD-3)
              pkgs.gopls # Go language server (BSD-3)
              pkgs.golangci-lint # Go meta-linter (GPL-3), backs golangci-lint-langserver
              pkgs.golangci-lint-langserver # LSP wrapper for golangci-lint (MIT)
              pkgs.delve # Go debugger, provides `dlv` (MIT)

              # Python tooling
              pkgs.uv # Python package/project manager (Apache-2.0/MIT, Rust)

              # Rust toolchain
              pkgs.cargo # Rust package manager/build tool (MIT/Apache-2.0)
              pkgs.rustc # Rust compiler (MIT/Apache-2.0)

              # Container image tooling
              pkgs.crane # Tool for interacting with remote container images/registries (Apache-2.0)
              pkgs.container-structure-test # Validate container image structure/contents (Apache-2.0)
              pkgs.dive # Explore a container image's layers to find ways to shrink it (MIT, Go)
              pkgs.podman # Daemonless container engine (Apache-2.0)

              # Kubernetes tooling
              pkgs.kubectl # Kubernetes command-line client (Apache-2.0)
              pkgs.kubectx # Utility to manage and switch contexts (Apache-2.0)
              pkgs.kustomize # Customization of Kubernetes YAML configurations (Apache-2.0)
              pkgs.k9s # Kubernetes cluster manager TUI (Apache-2.0)

              # Terraform tooling
              pkgs.tenv # Terraform/Tofu/Terragrunt version manager (Apache-2.0)
            ] ++ (if builtins.pathExists ./work.nix then import ./work.nix workPkgs else []);
          };

          default = self.packages.${pkgs.stdenv.hostPlatform.system}.user-cli-tools;
          inherit opencode-v2;
        });
    };
}

# Dotfiles

## Prerequisites

Install the following before running `chezmoi apply`:

- [Chezmoi](https://www.chezmoi.io/install/)
- [1Password CLI](https://www.1password.dev/cli/get-started#install)

## Setting fish as default shell (macOS)

After running `chezmoi apply`, fish is available via Nix. To set it as your default shell:

1. Add the nix profile fish path to the system whitelist:

   ```sh
   echo ~/.nix-profile/bin/fish | sudo tee -a /etc/shells
   ```

2. Change your default shell:

   ```sh
   chsh -s ~/.nix-profile/bin/fish
   ```

The `~/.nix-profile/bin/fish` path remains stable across fish updates, so you won't need to update your default shell when fish is upgraded.

## Work configuration

Some dotfiles include work-specific aliases, packages, and secrets that are
only applied on work machines. During `chezmoi init`, you will be prompted:

```text
Is this a work machine? (yes/no)
```

Answering **yes** enables:

- **Aliases/Secrets** -- work-specific shell aliases in `~/.config/fish/conf.d/`
- **Packages** -- additional Nix packages defined in `~/.config/user-packages/work.nix`

To change the setting later, re-run:

```sh
chezmoi init
```

# Dotfiles

## Prerequisites

Install the following before running `chezmoi apply`:

- [Chezmoi](https://www.chezmoi.io/install/)
- [1Password CLI](https://www.1password.dev/cli/get-started#install)

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

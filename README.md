# Dotfiles

## Prerequisites

Install the following before running `chezmoi apply`:

- [1Password CLI](https://www.1password.dev/cli/get-started#install)
- [Fish](https://fishshell.com/)
- [Chezmoi](https://www.chezmoi.io/install/)

## Work configuration

Some dotfiles include work-specific aliases, packages, and secrets that are
only applied on work machines. During `chezmoi init`, you will be prompted:

```text
Is this a work machine? (yes/no)
```

Answering **yes** enables:

- **Aliases** -- work-specific shell aliases in `~/.config/fish/config.fish`
- **Packages** -- additional Nix packages defined in `~/.config/user-packages/work.nix`
- **Secrets** -- work-specific fish configs matching `work.*.fish` in `conf.d/`

To change the setting later, re-run:

```sh
chezmoi init
```

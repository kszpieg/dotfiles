# Installation

1. Clone the repository into `.dotfiles`:

    ```shell
    git clone git@github.com:kszpieg/dotfiles.git .dotfiles
    ```

    or use HTTPS variant:

    ```shell
    git clone https://github.com/kszpieg/dotfiles.git .dotfiles
    ```

2. Run proper bash script:

- for full installation run `setup.sh` (it may require to provide sudo password during the process)
  
    ```shell
    cd ~/.dotfiles && chmod +x setup.sh && ./setup.sh
    ```

- for only copy configs run `configs.sh` (it's contained in `setup.sh` so it's not necessary to run it separately)

    ```shell
    cd ~/.dotfiles && chmod +x configs.sh && ./configs.sh
    ```

3. (Optional) Copy manually `update-motd.d/40-fastfetch` into `/etc/update-motd.d` and use `sudo chmod +x 40-fastfetch` command if you want some fancy stats about the system displayed in MOTD.

4. Enjoy!

## List of apps

Shell:

- `zsh` + [oh-my-zsh](https://ohmyz.sh/) with `fzf-tab`, `zsh-autosuggestions` and `zsh-syntax-highlighting`
- [starship](https://starship.rs/) prompt
- `zoxide` (replaces `cd`)

CLI tools (see `Brewfile` and `setup.sh` for the full list):

| Tool | Purpose |
| --- | --- |
| `bat` | `cat` alternative |
| `eza` | `ls` alternative |
| `fd` | `find` alternative |
| `ripgrep` | `grep` alternative |
| `sd` | `sed` alternative |
| `fzf` | fuzzy finder |
| `tlrc` | `tldr` client (`help` alias) |
| `jq`, `jless` | JSON processing and viewing |
| `htop` | process and resource monitor |
| `dust` | disk usage |
| `doggo`, `nmap`, `httpie` | network tools |
| `watchexec`, `just` | dev utilities |
| `fastfetch` | system info |
| `git-lfs` | Git LFS support (required by `.gitconfig`) |

AI tools: Claude Code, GitHub Copilot CLI, Codex CLI (update all with `aiup`).

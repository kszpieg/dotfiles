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

- for a minimal installation on a server (Ubuntu/Debian only) add `--server` — no Homebrew, compiler, terraform or AI tools; the tools behind the aliases come from `apt` (`eza`, `zoxide`, `jq`, `dig`), while `starship` and `tlrc` are installed as single binaries

    ```shell
    cd ~/.dotfiles && chmod +x setup.sh && ./setup.sh --server
    ```

- for only copy configs run `configs.sh` (it's contained in `setup.sh` so it's not necessary to run it separately)

    ```shell
    cd ~/.dotfiles && chmod +x configs.sh && ./configs.sh
    ```

- for Termux on Android run `termux.sh` — only `openssh`, `git`, `eza`, the SSH config and bash aliases from `termux/aliases.sh` (the everyday ones from `.aliases.zsh`, read-only ones from oh-my-zsh's git plugin, plus `ssh-sync` to pull both repos and reinstall the SSH config), the phone is just a terminal for the servers

    ```shell
    pkg install git && git clone https://github.com/kszpieg/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles && chmod +x termux.sh && ./termux.sh
    ```

### SSH config

`ssh/install.sh` (run by `configs.sh` and `termux.sh`) copies `ssh/config` to `~/.ssh/config` with mode `600` — copied, not linked, because ssh rejects configs writable by others (`777` on WSL `/mnt` drives). The previous config is kept once as `~/.ssh/config.bak`.

`ssh/config` holds only `Host *` defaults and `Include ~/.ssh/config.d/*.conf`. Host entries live in the private `ssh_config` repo: if it's cloned into `~/repos` or `/mnt/e/repos` (or the old `/mnt/e/gitdir`, `~/gitdir`, `~/gdir`), the installer copies its `*.conf` files into `~/.ssh/config.d/`; otherwise it skips them. After a change in either repo: `git pull` and run `ssh/install.sh` again.

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
| `terraform` | infrastructure as code (from the HashiCorp repository) |

AI tools: Claude Code, GitHub Copilot CLI, Codex CLI (update all with `aiup`).

Claude Code status line: `.claude/statusline.sh` (symlinked by `configs.sh`) shows model, repo, context and 5h/7d rate limits, and snapshots the limits to `~/.claude/state/usage.json`. It needs `jq` and a Nerd Font, and has to be enabled once in `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh", "refreshInterval": 30 }
```

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

3. Copy manually `40-fastfetch` into `/etc/update-motd.d` and use `sudo chmod +x 40-fastfetch` command if you want some fancy stats about the system displayed in MOTD.

4. Enjoy!

## List of apps

`TODO`

# Installation
1. Clone the repository into `.dotfiles`:
    ```
    git clone git@github.com:kszpieg/dotfiles.git .dotfiles
    ```
    or use HTTPS variant:
    ```
    git clone https://github.com/kszpieg/dotfiles.git .dotfiles
    ```
2. Run proper bash script:

- for full installation run `setup.sh` (it may require to provide sudo password during the process)
    ```
    cd ~/.dotfiles && chmod +x setup.sh && ./setup.sh
    ```
- for only copy configs run `configs.sh` (it's contained in `setup.sh` so it's not necessary to run it separately)
    ```
    cd ~/.dotfiles && chmod +x configs.sh && ./configs.sh
    ```
3. Enjoy!

## Workaround for 'dog' installation issue

Homebrew disabled `dog` package, so you need to run the following commands on Debian based distro to install it:
```
wget -qO - https://azlux.fr/repo.gpg.key | sudo apt-key add -
```
```
echo "deb http://packages.azlux.fr/debian/ stable main" | sudo tee /etc/apt/sources.list.d/azlux.list
```
```
sudo apt update
```
```
sudo apt install dog -y
```
   
## List of apps
`TODO`

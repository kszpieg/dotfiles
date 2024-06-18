# Instalation

1. Copy `.config` folder with the content to your `$HOME`.
2. 
3. Make the following symlinks for `.zshrc`, `.gitconfig` and `fastfetch`: 
```
ln -sfn zsh/.zshrc $HOME/.zshrc
ln -sfn zsh/.aliases.zsh $HOME/.aliases.zsh
ln -sfn zsh/.oh-my-zsh $HOME/.oh-my-zsh
ln -sfn git/.gitconfig $HOME/.gitconfig
ln -sfn .config/fastfetch/config.jsonc $HOME/.config/fastfetch/config.jsonc
ln -sfn .config/starship.toml $HOME/.config/starship.toml
```
4. Enjoy!

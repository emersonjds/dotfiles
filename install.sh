# Install nvm
# https://github.com/creationix/nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "source ~/.nvm/nvm.sh" >> ~/.bash_profile

# Install Homebrew
# Password is required for this installation
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Keep Homebrew packages up-to-date
brew update && brew upgrade

# Install Homebrew packages
brew install git
brew install git-lfs
brew install git-standup
brew install mas
brew install watchman # for create-react-native-app
brew install wget
brew install zsh zsh-completions

# Link git to version installed by Homebrew (Should already linked)
brew link git

# Set git username and email
git config --global user.name "Emerson Silva"
git config --global user.email "emerson_jdss@hotmail.com"

# Install oh-my-zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

# Sync .zshrc settings first
rm -f "$HOME/.zshrc"
ln -sf "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
# echo "source ~/.bash_profile" >> $HOME/dotfiles/zsh/.zshrc

# Install software via brew cask
# Password is required for first time installation

brew cask install docker
brew cask install firefox
brew cask install franz
brew cask install google-chrome
brew cask install google-web-designer
brew cask install iterm2
brew cask install kitematic
brew cask install postman
brew cask install robo-3t
brew cask install sequel-pro
brew cask install skype
brew cask install slack
brew cask install spotify
brew cask install virtualbox
brew cask install visual-studio-code

brew cleanup
brew cask cleanup

brew install docker-compose

# Install npm global packages
npm install -g @angular/cli
npm install -g @pingy/cli
npm install -g create-react-app
npm install -g eslint
npm install -g express-generator
npm install -g firebase-tools
npm install -g gulp-cli
npm install -g react-native-cli
npm install -g create-react-app
npm install -g react-devtools
npm install -g flow-typed
npm install -g standard 
npm install -g typescript
npm install -g tslint 
npm install -g vue-cli

#TODO: VS CODE SETTINGS
#TODO: Install VS Code Extension

# Change deafult shell to zsh
# Password is required for this action
sudo sh -c "echo $(which zsh) >> /etc/shells"
chsh -s $(which zsh)

exec $SHELL --login
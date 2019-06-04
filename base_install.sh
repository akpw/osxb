#!/bin/bash
# #######################################
#
# AKP Provisioning Script
#
# #######################################
# Last Edited 14/12/2017
script_ver=0.3
# #######################################

## Colored typing
function print_red {
  red='\x1B[0;31m'
  bold=$(tput bold)
  normal=$(tput sgr0)
  NC='\x1B[0m' # no color
  echo "${red}${bold}$1${normal}${NC}"
}
function print_blue {
  blue='\x1B[0;34m'
  bold=$(tput bold)
  normal=$(tput sgr0)
  NC='\x1B[0m' # no color
  echo "${blue}${bold}$1${normal}${NC}"
}


brews=(
  encfs
  pv
  telnet
  iperf3
  wget
  fish
  z
  fzf
  bat
  fd
  ripgrep
  ffmpeg
  youtube-dl  
)
casks=(
  osxfuse
  dropbox
  sublime-text
  iterm2
  zoomus
  google-chrome
  shiftit
  miniconda
  wireshark
  appcleaner
  grandperspective   
  vlc
  1password6 
  dash3
  sdformatter
)
set +e

echo 
osversion=$(/usr/bin/sw_vers -productVersion)
print_red "## MacOS version $osversion ..."
print_red "## Now checking for software updates ..."
print_red "## Need admin password ..."
sudo softwareupdate -i -a

# Enabling scheduled updates
print_red "## Enabling scheduled updates"
sudo softwareupdate --schedule on
sudo defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

echo 
print_red "## Checking Xcode Commands Line Tools install ..."
if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
   test -d "${xpath}" && test -x "${xpath}" ; then
   print_blue "## Xcode Commands Line Tools already installed  ..."
else
   print_red "## Installing Xcode Commands Line Tools ..."
   xcode-select --install
fi

echo 
if test ! $(which brew); then
  print_red "## Installing Homebrew ..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  print_red "## Updating Homebrew ..."
  brew update
  brew upgrade
fi

echo 
sudo chflags norestricted /usr/local
sudo chown -R $(whoami) /usr/local/bin
sudo chown -R $(whoami) /usr/local/share
sudo chown -R $(whoami):staff /Library/Caches/

brew doctor
sleep 2
brew tap caskroom/cask
sleep 1
brew tap caskroom/versions
sleep 1
brew update
sleep 1
fails=()

function install {
  cmd=$1
  shift
  for pkg in $@;
  do
    exec="$cmd $pkg"
    echo "Executing: $exec"
    if $exec ; then
      echo "Installed $pkg"
    else
      fails+=($pkg)
      print_red "Failed to execute: $exec"
    fi
  done
}

install 'brew cask install --appdir=/Applications' ${casks[@]}
install 'brew install' ${brews[@]}

print_red "## Cleaning up ..."
brew cleanup


################# Miniconda path
BASH_PROFILE=~/.bash_profile
if [ -f "$BASH_PROFILE" ]; then
  PREFIX=/usr/local/miniconda3
  DEFAULT=yes
  print_red "## Do you wish the installer to prepend the Miniconda3 install location"
  print_red "## to PATH in $BASH_PROFILE ? [yes|no]\\n"
  printf "[%s] >>> " "$DEFAULT"
  read -r ans
  if [ "$ans" = "" ]; then
      ans=$DEFAULT
  fi
  if [ "$ans" != "yes" ] && [ "$ans" != "Yes" ] && [ "$ans" != "YES" ] && \
     [ "$ans" != "y" ]   && [ "$ans" != "Y" ]
  then
        print_blue "## No change to $BASH_PROFILE ..."
  else
    print_blue "## For this change to become active, you need to open a new terminal"
    printf "\\n" >> "$BASH_PROFILE"
    printf "# added by Miniconda3 installer\\n"            >> "$BASH_PROFILE"
    printf "export PATH=\"%s/bin:\$PATH\"\\n" "$PREFIX"  >> "$BASH_PROFILE"
  fi
fi

################# Mac OS 
# Ruby
cd ~/
sudo gem update --system --no-document

# Have iTerm2 not prompt on Quit
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# Change Time Machine settings
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Disable the “Are you sure you want to open this application?” dialog
sudo defaults write /System/Library/User\ Template/English.lproj/Library/Preferences/com.apple.LaunchServices LSQuarantine -bool false
sudo defaults write /Users/$currentusername/Library/Preferences/com.apple.LaunchServices LSQuarantine -bool false
sudo defaults write com.apple.LaunchServices LSQuarantine -bool NO

# Disable disk image verification
sudo defaults write com.apple.frameworks.diskimages skip-verify -bool true
sudo defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
sudo defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Expand save panel by default
sudo defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
sudo defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
sudo defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
sudo defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Show hidden files in Finder
sudo defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app

# Python packages
print_red "## Setting up Python tools & packages ..."
pip install --upgrade pip
pip install --upgrade setuptools
conda install ipython
conda update --all
pip install ptpython
pip install ptipython
pip install batchmp
pip install efst
pip install speedtest-cli
pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs pip install -U

## print_blue "## Setting up zsh ..."
## curl -L http://install.ohmyz.sh | sh
## curl -sSL https://get.rvm.io | bash -s stable --rails --autolibs=enabled --ruby=2.2.1 --rails
## source ~/.rvm/scripts/rvm
## rvm use --default 2.2.1


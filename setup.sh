#!/bin/bash
set -euo pipefail

###############################################################################
# Helpers
###############################################################################

_sign_in_to_1password() {
  # This setup script does not install the 1password desktop app or Chrome extension.
  # Manually installing the desktop app integration may make it easier to sign-in via the op CLI
  # See https://developer.1password.com/docs/cli/get-started#step-2-turn-on-the-1password-desktop-app-integration

  while ! op whoami &>/dev/null; do
    echo "Please login to 1Password in order to continue"
    eval "$(op signin)"
  done
}

###############################################################################
# Bootstrap
###############################################################################

echo "Bootstrapping scruth-config..."

# Xcode command line tools are a prerequisite for Homebrew.
# So we install them independently rather than manage them via brew.
if xcode-select -p &>/dev/null; then
  echo "Xcode command line tools are already installed"
else
  echo -n "Installing Xcode command line tools..."
  xcode-select --install &>/dev/null
  
  while ! xcode-select -p &>/dev/null; do
    # echo a single dot on the same line
    echo -n "."
    sleep 5
  done
  echo "Finished installing Xcode command line tools"
fi

if which -s "brew"; then
  echo "Homebrew is already installed"
else
  echo "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "Finished installing Homebrew"
fi

if which -s "op"; then
  echo "1Password CLI is already installed"
else
  echo "Installing 1Password and 1Password CLI"
  brew install --cask 1password
  brew install --cask 1password-cli
  echo "Finished installing 1Password and 1Password CLI"
fi
_sign_in_to_1password

if which -s "chezmoi"; then
  echo "Chezmoi is already installed"
else
  echo "Installing Chezmoi"
  brew install chezmoi
  echo "Finished installing Chezmoi"
fi

if [ -d "$(chezmoi source-path 2>/dev/null)" ]; then
  echo "Chezmoi is already initialized, updating from repo..."
  chezmoi update --apply=false
  echo "Finished updating Chezmoi from repo"
else
  echo "Initializing Chezmoi..."
  # Intentionally split up the chezmoi init and apply, NOT using the --apply option to init
  # This is because our init operation modifies the chezmoi sourceDir in the config it writes
  # And we need the apply to pick up the new value, which it didn't seem to do consistently
  # when we combined commands.
  chezmoi init sbfeinstein/scruth-config --branch main
  echo "Finished Initializing Chezmoi"
fi

echo "Finished bootstrapping scruth-config"
echo "Applying Chezmoi"
chezmoi apply

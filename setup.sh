#!/bin/bash
set -euo pipefail

_check_machine_is_scruthsystem() {
  is_allowed_scruthsystem() {
    ALLOWED_HOSTNAMES=("sfeinstein-studio-m4")
    hostname=$(scutil --get ComputerName)
    for allowed_hostname in "${ALLOWED_HOSTNAMES[@]}"; do
      if [[ "$hostname" == "$allowed_hostname" ]]; then
        return 0
      fi
    done
    return 1
  }

  hostname=$(scutil --get ComputerName)
  if is_allowed_scruthsystem; then
    echo "🚀 Setting up ScruthSystem™️  $hostname"
  else
    echo "❌  This system ('$hostname') is not an allowed ScruthSystem™️  , aborting setup"
    exit 1
  fi
}

_check_machine_is_scruthsystem

# Xcode command line tools are a prerequisite for Homebrew.
# So we install them independently rather than manage them via brew.
if xcode-select -p &>/dev/null; then
  echo "✅  Xcode command line tools are already installed"
else
  echo -n "🔧  Installing Xcode command line tools..."
  xcode-select --install &>/dev/null
  
  while ! xcode-select -p &>/dev/null; do
    # echo a single dot on the same line
    echo -n "."
    sleep 5
  done
  echo "✅  Xcode command line tools installed successfully"
fi

if which -s "brew"; then
  echo "✅  Homebrew is already installed"
else
  echo "🍺  Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "✅  Homebrew installed successfully"
fi

if which -s "op"; then
  echo "✅  1Password CLI is already installed"
else
  echo "🔐  Installing 1Password CLI"
  brew install --cask 1password
  brew install --cask 1password-cli
  echo "✅  1Password and its CLI installed successfully"
fi

if which -s "chezmoi"; then
  echo "✅  Chezmoi is already installed"
else
  echo "🛠️  Installing Chezmoi"
  brew install chezmoi
  echo "✅  Chezmoi installed successfully"
fi

# Sign in to 1Password
while ! op whoami &>/dev/null; do
  echo "🔐  1Password CLI is not logged in or session expired..."
  echo "    Manually installing desktop app integration may make it easier to sign-in:"
  echo "    https://developer.1password.com/docs/cli/get-started#step-2-turn-on-the-1password-desktop-app-integration"
  eval "$(op signin)"
done
echo "✅  1Password CLI is logged in"

if [ -d "$(chezmoi source-path 2>/dev/null)" ]; then
  echo "ℹ️  Chezmoi already initialized, pulling latest changes..."
  chezmoi update
  echo "✅  Chezmoi updated"
else
  echo "ℹ️  Chezmoi not already initialized, initializing and applying"
  # Intentionally split up the chezmoi init and apply, NOT using the --apply option to init
  # This is because our init operation modifies the chezmoi sourceDir in the config it writes
  # And we need the apply to pick up the new value, which it didn't seem to do consistently
  # when we combined commands.
  chezmoi init sbfeinstein/scruth-config --branch main
  chezmoi apply
  echo "✅  Chezmoi initialized"
fi

echo "😎  Finished setting up $hostname"
echo "ℹ️   Set upstream to SSH rather than HTTPS via:"
echo "    chezmoi cd"
echo "    git remote set-url origin git@github.com:sbfeinstein/scruth-config.git"

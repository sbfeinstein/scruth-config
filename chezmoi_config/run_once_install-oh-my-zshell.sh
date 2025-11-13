#!/bin/bash
set -eufo pipefail

if [ -f ~/.oh-my-zsh/oh-my-zsh.sh ]; then
  echo "✅  oh-my-zsh is already installed."
else
  echo "💻  Installing oh-my-zsh"
  chsh -s "$(which zsh)"
  yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
  echo "✅  oh-my-zsh installed successfully (an exit code of 141 is OK and expected, just restart the shell)"
fi
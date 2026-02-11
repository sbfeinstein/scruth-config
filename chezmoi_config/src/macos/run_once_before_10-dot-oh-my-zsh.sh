#!/bin/bash
set -eufo pipefail

if [ -f ~/.oh-my-zsh/oh-my-zsh.sh ]; then
  echo "✅  oh-my-zsh is already installed."
else
  echo "💻  Installing oh-my-zsh"
  chsh -s "$(which zsh)"

  # See https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/install.sh for how to call and options
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc || exit_code=$?

  # If the command failed and the code isn't 141, exit the script
  if [ -n "${exit_code:-}" ] && [ "$exit_code" -ne 141 ]; then
    echo "❌ Installing oh-my-zsh failed with exit code $exit_code"
    exit "$exit_code"
  fi

  echo "✅  oh-my-zsh installed successfully (an exit code of 141 is OK and expected)"
fi
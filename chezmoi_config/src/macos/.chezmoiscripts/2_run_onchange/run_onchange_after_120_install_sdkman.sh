#!/bin/bash
set -eufo pipefail

# https://sdkman.io/ is a Java / JVM / SDK environment manager.
# It can be installed via brew but it is safer to user its own install script, in terms of
# avoiding conflicts on the PATH, within brew, and between itself and other package
# managers that may be installed.
#
# Per https://sdkman.io/install/ we prevent shell modifications since we
# manage .zshrc and other config directly in scruth-config.

# Check for the init file not the command since sdk is a shell alias that won't
# have been sourced when this script runs during chezmoi apply.
SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"

if [ -s "$SDKMAN_INIT" ]; then
  echo "✅ SDKMAN! is already installed"
else
  echo "🛠️  Installing SDKMAN!"
  curl -s "https://get.sdkman.io?rcupdate=false" | bash
  echo "✅ SDKMAN! installed successfully"
fi

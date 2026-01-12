#!/bin/bash
set -eufo pipefail

# https://github.com/astral-sh/uv is a Python package manager
# It can be installed via brew but it is safer to user its own install script, in terms of
# avoiding conflicts on the PATH, within brew, and between itself and other python package
# managers that may be installed.
#
# Per https://docs.astral.sh/uv/reference/installer/ we prevent shell modifications since we
# manage .zshrc and other config directly in scruth-config.
if which -s "uv"; then
  echo "✅  uv is already installed"
else
  echo "🛠️  Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
  echo "✅  uv installed successfully"
fi

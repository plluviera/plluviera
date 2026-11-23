#!/usr/bin/env bash
# Idempotent dependency install for the plluviera workspace.
# Runs from /agent/repos/plluviera during environment builds.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

NODE_BIN="/home/ubuntu/.nvm/versions/node/v22.23.4/bin"
if [ -x "$NODE_BIN/npm" ]; then
  sudo ln -sfn "$NODE_BIN/node" /usr/local/bin/node
  sudo ln -sfn "$NODE_BIN/npm" /usr/local/bin/npm
  sudo ln -sfn "$NODE_BIN/npx" /usr/local/bin/npx
fi
hash -r

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is not on PATH and Node 22.23.4 was not found at $NODE_BIN" >&2
  exit 1
fi

node_major="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$node_major" != "22" ]; then
  echo "nst-web requires Node.js 22; found $(node -v)" >&2
  exit 1
fi

echo "Using node $(node -v) at $(command -v node)"
echo "Using npm $(npm -v) at $(command -v npm)"

install_locked() {
  local dir="$1"
  if [ ! -f "$dir/package-lock.json" ]; then
    echo "missing package-lock.json in $dir" >&2
    exit 1
  fi
  echo "npm ci in $dir"
  (cd "$dir" && npm ci)
}

install_locked /agent/repos/hola-1a
install_locked /agent/repos/nst-web

echo "Installing Playwright Chromium for nst-web tests"
(cd /agent/repos/nst-web && npx playwright install --with-deps chromium)

echo "install complete"

#!/usr/bin/env bash
# Boot the three local apps. Safe to run more than once.
# hola-1a keeps its documented Vite port. nst-web keeps 4173.
# carlamedina-ar uses 4174 because 4173 belongs to nst-web.
set -euo pipefail

NODE_BIN="/home/ubuntu/.nvm/versions/node/v22.23.4/bin"
if [ -x "$NODE_BIN/npm" ]; then
  sudo ln -sfn "$NODE_BIN/node" /usr/local/bin/node
  sudo ln -sfn "$NODE_BIN/npm" /usr/local/bin/npm
  sudo ln -sfn "$NODE_BIN/npx" /usr/local/bin/npx
fi
hash -r

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is not available; run the install script first" >&2
  exit 1
fi

mkdir -p /tmp/cursor-dev

http_ok() {
  curl -sf -o /dev/null --max-time 2 "$1"
}

ensure_session() {
  local name="$1"
  local dir="$2"
  local url="$3"
  local cmd="$4"

  if http_ok "$url"; then
    echo "$name already responding at $url"
    return 0
  fi

  if tmux has-session -t "$name" 2>/dev/null; then
    tmux kill-session -t "$name"
  fi

  # tmux passes this string to a shell. The login shell keeps Node on PATH.
  tmux new-session -d -s "$name" -c "$dir" "bash -lc '$cmd'"
}

ensure_session \
  hola_1a \
  /agent/repos/hola-1a \
  http://127.0.0.1:5173/ \
  "npm run dev -- --host 0.0.0.0 --port 5173 >> /tmp/cursor-dev/hola-1a.log 2>&1"

ensure_session \
  nst_web \
  /agent/repos/nst-web \
  http://127.0.0.1:4173/ \
  "python3 -m http.server 4173 -d public -b 0.0.0.0 >> /tmp/cursor-dev/nst-web.log 2>&1"

ensure_session \
  carlamedina \
  /agent/repos/carlamedina-ar \
  http://127.0.0.1:4174/ \
  "python3 -m http.server 4174 -b 0.0.0.0 >> /tmp/cursor-dev/carlamedina.log 2>&1"

wait_url() {
  local url="$1"
  local attempt
  for attempt in $(seq 1 45); do
    if http_ok "$url"; then
      echo "ready $url"
      return 0
    fi
    sleep 1
  done
  echo "not ready: $url" >&2
  return 1
}

wait_url http://127.0.0.1:5173/
wait_url http://127.0.0.1:4173/
wait_url http://127.0.0.1:4174/
echo "start complete"

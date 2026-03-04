#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_ROOT="${CACHE_ROOT:-$ROOT_DIR/temp/cache}"

export CRYSTAL_CACHE_DIR="${CRYSTAL_CACHE_DIR:-$CACHE_ROOT/crystal}"
export SHARDS_CACHE_PATH="${SHARDS_CACHE_PATH:-$CACHE_ROOT/shards}"
export GOCACHE="${GOCACHE:-$CACHE_ROOT/go-build}"
export GOMODCACHE="${GOMODCACHE:-$CACHE_ROOT/go-mod}"
export GOPATH="${GOPATH:-$CACHE_ROOT/go}"
export GOBIN="${GOBIN:-$CACHE_ROOT/go-bin}"
export GOFLAGS="${GOFLAGS:--modcacherw}"

mkdir -p "$CRYSTAL_CACHE_DIR" "$SHARDS_CACHE_PATH" "$GOCACHE" "$GOMODCACHE" "$GOPATH" "$GOBIN"

if [[ "${1:-}" == "--print" ]]; then
  cat <<VARS
CRYSTAL_CACHE_DIR=$CRYSTAL_CACHE_DIR
SHARDS_CACHE_PATH=$SHARDS_CACHE_PATH
GOCACHE=$GOCACHE
GOMODCACHE=$GOMODCACHE
GOPATH=$GOPATH
GOBIN=$GOBIN
GOFLAGS=$GOFLAGS
VARS
  exit 0
fi

if [[ $# -gt 0 ]]; then
  exec "$@"
fi

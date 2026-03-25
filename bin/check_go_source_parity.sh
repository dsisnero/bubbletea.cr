#!/bin/sh
set -eu

repo_root=${1:?repo root required}
manifest=${2:?manifest path required}
upstream_root=${3:?upstream root required}

cd "$repo_root"

if [ ! -f "$manifest" ]; then
  echo "[source-parity] missing manifest: $manifest" >&2
  exit 1
fi

missing=0

awk -F '\t' '
  BEGIN { count = 0 }
  /^#/ || /^$/ { next }
  NR == 1 { next }
  {
    count++
    print $1 "\t" $2 "\t" $3
  }
  END {
    if (count == 0) {
      exit 2
    }
  }
' "$manifest" | while IFS="$(printf '\t')" read -r upstream_file crystal_file status; do
  if [ ! -f "$upstream_root/$upstream_file" ]; then
    echo "[source-parity] missing upstream file: $upstream_root/$upstream_file" >&2
    missing=1
  fi

  if [ "$status" = "Complete" ] && [ ! -f "$crystal_file" ]; then
    echo "[source-parity] missing Crystal file for complete row: $crystal_file" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "[source-parity] OK: $manifest"

#!/bin/sh
set -eu

repo_root=${1:?repo root required}
manifest=${2:?manifest path required}
upstream_root=${3:?upstream root required}

cd "$repo_root"

if [ ! -f "$manifest" ]; then
  echo "[port-inventory] missing manifest: $manifest" >&2
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
' "$manifest" | while IFS="$(printf '\t')" read -r upstream_path crystal_path status; do
  if [ ! -e "$upstream_root/$upstream_path" ]; then
    echo "[port-inventory] missing upstream path: $upstream_root/$upstream_path" >&2
    missing=1
  fi

  if [ "$status" = "Complete" ] && [ ! -e "$crystal_path" ]; then
    echo "[port-inventory] missing Crystal path for complete row: $crystal_path" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "[port-inventory] OK: $manifest"

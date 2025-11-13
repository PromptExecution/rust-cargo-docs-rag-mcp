#!/bin/sh
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <version>" >&2
  exit 2
fi
VER="$1"

# Update Cargo.toml version field
if command -v perl >/dev/null 2>&1; then
  perl -0777 -pe "s/^version\s*=\s*\".*\"/version = \"${VER}\"/m" -i Cargo.toml
else
  sed -E "s/^version[[:space:]]*=.*$/version = \"${VER}\"/" Cargo.toml > Cargo.toml.tmp && mv Cargo.toml.tmp Cargo.toml
fi

# Regenerate lockfile
if command -v cargo >/dev/null 2>&1; then
  cargo generate-lockfile || true
fi

exit 0

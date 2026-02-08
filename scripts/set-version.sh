#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <semver>" >&2
  exit 1
fi

version="$1"

# Update Cargo.toml package version (first occurrence only to avoid dependency matches)
python3 - "$version" <<'PY'
import pathlib, re, sys
version = sys.argv[1]
path = pathlib.Path("Cargo.toml")
text = path.read_text()
new_text, count = re.subn(r'(?m)^(version\s*=\s*)"[^"]+"', rf'\1"{version}"', text, count=1)
if count != 1:
    raise SystemExit("Could not update version in Cargo.toml")
path.write_text(new_text)
PY

# Update Cargo.lock entry for this crate
python3 - "$version" <<'PY'
import pathlib, sys
version = sys.argv[1]
path = pathlib.Path("Cargo.lock")
lines = path.read_text().splitlines()
out_lines = []
in_pkg = False
target = 'name = "rust-cargo-docs-rag-mcp"'
updated = False
for line in lines:
    stripped = line.strip()
    if stripped == target:
        in_pkg = True
        out_lines.append(line)
        continue
    if in_pkg and stripped.startswith("version = "):
        out_lines.append(f'version = "{version}"')
        in_pkg = False
        updated = True
        continue
    if stripped.startswith("name = ") and stripped != target:
        in_pkg = False
    out_lines.append(line)

if not updated:
    raise SystemExit("Could not update version in Cargo.lock")

path.write_text("\n".join(out_lines) + "\n")
PY

# Update server.json version and OCI package tag
python3 - "$version" <<'PY'
import json, pathlib, sys
version = sys.argv[1]
path = pathlib.Path("server.json")
data = json.loads(path.read_text())
data["version"] = version

for pkg in data.get("packages", []):
    if pkg.get("registryType") != "oci":
        continue
    ident = pkg.get("identifier")
    if isinstance(ident, str) and ":" in ident:
        pkg["identifier"] = f"{ident.rsplit(':', 1)[0]}:{version}"

path.write_text(json.dumps(data, indent=2) + "\n")
PY

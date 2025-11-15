# Rust Cargo Docs RAG MCP

`rust-cargo-docs-rag-mcp` is an MCP (Model Context Protocol) server that provides tools for Rust crate documentation lookup. It allows LLMs to look up documentation for Rust crates they are unfamiliar with.

This README focuses on how to build, version, release, and install the project using two common paths:
1. pkgx (build/install locally from source)
2. Docker image (published to GitHub Container Registry — GHCR)

---

## Release / Versioning workflow (maintainers)

```bash
git clone https://github.com/promptexecution/rust-cargo-docs-rag-mcp.git
cd rust-cargo-docs-rag-mcp
cargo build --release
cargo install --path .
# Or install the pkgx-managed binary and check its version
just install-pkgx
```

### Installing with pkgx

The repository includes a mini [pkgx pantry](./pkgx) so you can build and run the CLI through `pkgx` without touching your global toolchain:

```bash
git clone https://github.com/promptexecution/rust-cargo-docs-rag-mcp.git
cd rust-cargo-docs-rag-mcp
export PKGX_PANTRY_PATH=$PWD/pkgx
export PKGX_PANTRY_DIR=$PWD/pkgx    # pkgx^2 compatibility
pkgx cratedocs version
```

`pkgx` will download the tagged source tarball, compile `cratedocs` with the required Rust toolchain, and cache the result for subsequent runs. Once you're ready to upstream this package to the central [pkgx pantry](https://github.com/pkgxdev/pantry), copy `pkgx/projects/github.com/promptexecution/rust-cargo-docs-rag-mcp/package.yml` into a new PR there.

## Running the Server
This repository is wired to Cocogitto via `cog.toml`. Typical flow to create a release:

1. Install Cocogitto (once)
   ```bash
   cargo install cocogitto
   ```

2. Bump the version / create the tag from main (on your machine):
   ```bash
   git checkout main
   git pull origin main
   cog bump patch
   # or `cog bump minor` / `cog bump major`
   ```

   - `cog bump` runs the pre_bump_hooks/post_bump_hooks defined in `cog.toml`.
   - This will update Cargo.toml, Cargo.lock and CHANGELOG.md, and create a signed tag `vX.Y.Z`.

3. Push commit + tag to GitHub:
   ```bash
   git push --follow-tags origin main
   ```

When the tag is pushed, the `Release & Publish (GHCR)` workflow will run:
- It builds multi-arch (amd64/arm64) Docker images with Docker Buildx and pushes them to GHCR at:
  - ghcr.io/<org_or_user>/rust-cargo-docs-rag-mcp:<tag>
  - ghcr.io/<org_or_user>/rust-cargo-docs-rag-mcp:latest
- It creates a GitHub Release for that tag and uploads the release binary (target/release/cratedocs) as an asset.

Repository requirements:
- Ensure GitHub Actions has permission to publish packages (Packages / Container registry). The release workflow uses the repository's GITHUB_TOKEN and sets packages: write in workflow permissions.
- Ensure `main` is the branch you want `cog` to operate from (cog.toml has branch_whitelist = ["main"] by default).

---

## Install / Run — Docker (recommended for consumers)

Prebuilt images are published to GitHub Container Registry (GHCR) on release tags.

Pull the image (replace OWNER with the GH org or username that owns the repo; tags look like v0.3.0):
```bash
docker pull ghcr.io/promptexecution/rust-cargo-docs-rag-mcp:latest
# or a specific version:
docker pull ghcr.io/promptexecution/rust-cargo-docs-rag-mcp:v0.3.0
```

Run the container in HTTP mode (default):
```bash
docker run --rm -p 8080:8080 ghcr.io/promptexecution/rust-cargo-docs-rag-mcp:latest
```

Run in stdio mode:
```bash
docker run --rm -e CRATEDOCS_MODE=stdio -i ghcr.io/promptexecution/rust-cargo-docs-rag-mcp:latest
```

### Using Docker

You can also build and run the server in an Alpine-based container. Prebuilt images are automatically published to GHCR via [`.github/workflows/docker.yml`](.github/workflows/docker.yml):

```bash
docker pull ghcr.io/promptexecution/rust-cargo-docs-rag-mcp:latest
```

To build locally (useful before pushing to another registry):

```bash
# Build the image (adjust the tag to match your registry)
docker build -t promptexecution/rust-cargo-docs-rag-mcp .

# Run HTTP/SSE mode on port 8080
docker run --rm -p 8080:8080 promptexecution/rust-cargo-docs-rag-mcp
```

Configuration is controlled through environment variables:
- `CRATEDOCS_MODE` (default `http`): switch to `stdio` to expose the stdio MCP server
- `CRATEDOCS_ADDRESS` (default `0.0.0.0:8080`): bind the HTTP server to a specific interface/port
- `CRATEDOCS_DEBUG` (default `false`): set to `true` to enable verbose logging in HTTP mode

All additional arguments appended to `docker run ... -- <args>` are forwarded to the underlying `cratedocs` process.

### Directly Testing Documentation Tools
### Environment Variables

- `CRATEDOCS_MODE` (default: `http`) — set to `stdio` to run the stdio MCP server
- `CRATEDOCS_ADDRESS` (default: `0.0.0.0:8080`) — bind address for HTTP mode
- `CRATEDOCS_DEBUG` (default: `false`) — set to `true` to enable debug logging

### Passing custom arguments

You can also pass custom arguments directly to the `cratedocs` binary:
```bash
docker run --rm -p 3000:3000 ghcr.io/promptexecution/rust-cargo-docs-rag-mcp:latest \
  http --address 0.0.0.0:3000 --debug
```

---

## Install / Run — pkgx (local build from source)

[pkgx](https://pkgx.dev) is a universal package manager that can build and run this project without requiring a system-wide Rust installation:

```bash
# Install using pkgx (automatically handles Rust dependencies)
pkgx install

# Or build directly with pkgx
pkgx +rust +cargo cargo build --release

# Run without installing
pkgx +rust +cargo cargo run --bin cratedocs -- stdio
```

The project includes a `package.yml` file for pkgx integration, making it easy to build and test across different environments.

---

## Install / Run — Cargo (standard Rust toolchain)

```bash
git clone https://github.com/promptexecution/rust-cargo-docs-rag-mcp.git
cd rust-cargo-docs-rag-mcp
cargo build --release
cargo install --path .
```

After installation, you can run:
```bash
# STDIN/STDOUT mode
cratedocs stdio

# HTTP/SSE mode
cratedocs http --address 127.0.0.1:8080

# With debug logging
cratedocs http --address 127.0.0.1:8080 --debug
```

---

## Features

- **Lookup crate documentation**: Get general documentation for a Rust crate
- **Search crates**: Search for crates on crates.io based on keywords
- **Lookup item documentation**: Get documentation for a specific item (e.g., struct, function, trait) within a crate
- **List crate items**: Enumerate all items in a crate with optional filtering

---

## Available Tools

The server provides the following tools via the MCP protocol:

### 1. `lookup_crate`

Retrieves documentation for a specified Rust crate.

Parameters:
- `crate_name` (required): The name of the crate to look up
- `version` (optional): The version of the crate (defaults to latest)

Example:
```json
{
  "name": "lookup_crate",
  "arguments": {
    "crate_name": "tokio",
    "version": "1.28.0"
  }
}
```

### 2. `search_crates`

Searches for Rust crates on crates.io.

Parameters:
- `query` (required): The search query
- `limit` (optional): Maximum number of results to return (defaults to 10, max 100)

Example:
```json
{
  "name": "search_crates",
  "arguments": {
    "query": "async runtime",
    "limit": 5
  }
}
```

### 3. `lookup_item`

Retrieves documentation for a specific item in a crate.

Parameters:
- `crate_name` (required): The name of the crate
- `item_path` (required): Path to the item (e.g., 'std::vec::Vec')
- `version` (optional): The version of the crate (defaults to latest)

Example:
```json
{
  "name": "lookup_item",
  "arguments": {
    "crate_name": "serde",
    "item_path": "serde::Deserialize",
    "version": "1.0.160"
  }
}
```

### 4. `list_crate_items`

Enumerates all items in a specified Rust crate and version, optionally filtering by item type, visibility, or module path.

Parameters:
- `crate_name` (required): The name of the crate
- `version` (required): The version of the crate
- `item_type` (optional): Filter by item type (struct, enum, trait, fn, macro, mod)
- `visibility` (optional): Filter by visibility (pub, private)
- `module` (optional): Filter by module path (e.g., serde::de)

Example:
```json
{
  "name": "list_crate_items",
  "arguments": {
    "crate_name": "serde",
    "version": "1.0.0",
    "item_type": "struct"
  }
}
```

---

## Testing Tools Directly

You can directly test the documentation tools from the command line without starting a server:

```bash
# Get help for the test command
cargo run --bin cratedocs test --tool help

# Enumerate crate items
cargo run --bin cratedocs test --tool list_crate_items --crate-name serde --version 1.0.0 --item-type struct

# Look up crate documentation
cargo run --bin cratedocs test --tool lookup_crate --crate-name tokio

# Look up item documentation
cargo run --bin cratedocs test --tool lookup_item --crate-name tokio --item-path sync::mpsc::Sender

# Search for crates
cargo run --bin cratedocs test --tool search_crates --query logger --limit 5

# Output in different formats (markdown, text, json)
cargo run --bin cratedocs test --tool search_crates --query logger --format json

# Summarize output (strip LICENSE and VERSION sections, limit tokens)
cargo run --bin cratedocs test --tool lookup_crate --crate-name tokio --tldr --max_tokens 48000
```

---

## MCP Protocol Integration

This server implements the Model Context Protocol (MCP) which allows it to be easily integrated with LLM clients that support the protocol. For more information about MCP, visit [the MCP repository](https://github.com/modelcontextprotocol/mcp).

### VSCode MCP, RooCode local example

```bash 
# compile & install cratedocs in ~/.cargo/bin
cargo install --path . 
```

in `mcp_settings.json`:
```json
{
  "mcpServers":{
    "rust-crate-local": {
      "command": "cratedocs",
      "args": [
        "stdio"
      ]
    }    
  }
}
```

### VSCode MCP, RooCode hosted example

```json
{
  "mcpServers":{
    "rust-crate-docs": {
      "command": "bunx",
      "args": [
        "-y",
        "mcp-remote@latest",
        "http://127.0.0.1:3000/sse?sessionId=",
        "--allow-http",
        "--transport sse-only",
        "--debug"
      ]
    }
  }
}
```

### Using Docker with MCP

You can use the Docker image directly in your MCP configuration:

```json
{
  "mcpServers": {
    "rust-crate-docs-docker": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "ghcr.io/promptexecution/rust-cargo-docs-rag-mcp:latest",
        "stdio"
      ]
    }
  }
}
```

Or if you want to run the HTTP/SSE server in Docker and connect via mcp-remote:

```bash
# Start the HTTP server in Docker
docker run --rm -p 8080:8080 ghcr.io/promptexecution/rust-cargo-docs-rag-mcp:latest
```

Then in `mcp_settings.json`:
```json
{
  "mcpServers": {
    "rust-crate-docs-docker-http": {
      "command": "bunx",
      "args": [
        "-y",
        "mcp-remote@latest",
        "http://localhost:8080/sse",
        "--allow-http",
        "--transport", "sse-only"
      ]
    }
  }
}
```

### Using pkgx with MCP

If you have [pkgx](https://pkgx.dev) installed, you can run the server without a system-wide Rust installation:

```json
{
  "mcpServers": {
    "rust-crate-docs-pkgx": {
      "command": "pkgx",
      "args": [
        "+rust",
        "+cargo",
        "cargo",
        "run",
        "--manifest-path",
        "/path/to/rust-cargo-docs-rag-mcp/Cargo.toml",
        "--bin",
        "cratedocs",
        "--",
        "stdio"
      ]
    }
  }
}
```

Or use pkgx to install and run directly:

```bash
# Clone and install with pkgx
git clone https://github.com/promptexecution/rust-cargo-docs-rag-mcp.git
cd rust-cargo-docs-rag-mcp
pkgx +rust +cargo cargo install --path .
```

Then reference it normally in `mcp_settings.json`:
```json
{
  "mcpServers": {
    "rust-crate-docs": {
      "command": "cratedocs",
      "args": ["stdio"]
    }
  }
}
```


## Implementation Notes

- The server includes a caching mechanism to prevent redundant API calls for the same documentation
- It interfaces with docs.rs for crate documentation and crates.io for search functionality
- Results are returned as plain text/HTML content that can be parsed and presented by the client

---

## Versioning & Releases

This repository includes a [`cog.toml`](./cog.toml) profile wired to [`scripts/set-version.sh`](./scripts/set-version.sh) so [Cocogitto](https://github.com/cocogitto/cocogitto) can bump the crate version and regenerate the changelog automatically.

Typical release flow:
1. `cargo install cocogitto` (once)
2. `cog bump minor` (or `patch`/`major`) – this updates `Cargo.toml`, `Cargo.lock`, and `CHANGELOG.md`
3. Review the generated changelog, run tests, and push the resulting tag/commit

See [`CHANGELOG.md`](./CHANGELOG.md) for the latest published versions.

## License

MIT License

## Attribution & Linkback Request

This fork builds on the original [`d6e/cratedocs-mcp`](https://github.com/d6e/cratedocs-mcp) work by:
- wiring the crate-documentation helpers into a full MCP server with both `stdio` and HTTP/SSE launch modes
- documenting the new unified CLI, RooCode/VSCode integration examples, and the `list_crate_items` tool surface
- adding guidance on testing individual tools directly from the CLI plus notes on caching and output formatting

If you decide to keep these changes upstream, could you please add a short linkback to [`promptexecution/rust-cargo-docs-rag-mcp`](https://github.com/promptexecution/rust-cargo-docs-rag-mcp) in your README? That attribution helps other developers understand where this MCP-focused variant originated and makes it easier for them to follow improvements across both projects.

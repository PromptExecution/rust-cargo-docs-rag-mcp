# Changelog

## [0.3.0] - 2025-11-12
- rename the crate and repository references to `rust-cargo-docs-rag-mcp`
- document the new GitHub location plus attribution expectations for upstream
- add Cocogitto (`cog`) configuration, release script, and changelog scaffolding for version control
- add an Alpine-based Docker image build + entrypoint script plus usage docs for container publishing
- publish the container automatically to GHCR using `.github/workflows/docker.yml`
- update Docker builder stage to the latest stable Rust toolchain (1.91.1) for smaller, faster binaries
- add a self-contained pkgx pantry (`pkgx/`) with build/test metadata so `pkgx cratedocs` can install the server via the pkgx runtime, plus README instructions for using and upstreaming it
- add `just install-pkgx` to verify the pkgx pantry wiring end-to-end (falls back to a helpful message until the package is mirrored onto dist.pkgx.dev)

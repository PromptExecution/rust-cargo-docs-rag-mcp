install:
   cargo install --git https://github.com/promptexecution/rust-cargo-docs-rag-mcp --locked

# Build with pkgx (ensures correct Rust version and dependencies)
pkgx-build:
   pkgx +rust +cargo cargo build --release

# Run with pkgx
pkgx-run:
   pkgx +rust +cargo cargo run --bin cratedocs http --address 0.0.0.0:3000 --debug

# Test with pkgx
pkgx-test:
   pkgx +rust +cargo cargo test

run:
   cargo run --bin cratedocs http --address 0.0.0.0:3000 --debug

docker-build:
   docker build -t promptexecution/rust-cargo-docs-rag-mcp .

docker-run:
   docker run --rm -p 8080:8080 promptexecution/rust-cargo-docs-rag-mcp

debug-mcp-remote:
   # use bunx or npx to see how the mcp-remote proxy connects
   bunx mcp-remote@latest "http://127.0.0.1:3000/sse" --allow-http --transport sse-only --debug

install:
   cargo install --git https://github.com/promptexecution/rust-cargo-docs-rag-mcp --locked

run:
   cargo run --bin cratedocs http --address 0.0.0.0:3000 --debug

install-pkgx:
   @echo "Using pkgx pantry at {{invocation_directory()}}/pkgx"
   PKGX_PANTRY_PATH={{invocation_directory()}}/pkgx \
   PKGX_PANTRY_DIR={{invocation_directory()}}/pkgx \
   pkgx cratedocs version || \
      (echo "pkgx failed (likely no network); see README for manual steps" && exit 1)

docker-build:
   docker build -t promptexecution/rust-cargo-docs-rag-mcp .

docker-run:
   docker run --rm -p 8080:8080 promptexecution/rust-cargo-docs-rag-mcp

debug-mcp-remote:
   # use bunx or npx to see how the mcp-remote proxy connects
   bunx mcp-remote@latest "http://127.0.0.1:3000/sse" --allow-http --transport sse-only --debug

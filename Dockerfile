FROM rust:1.91.1-alpine3.20 AS builder

RUN apk add --no-cache \
    build-base \
    pkgconfig \
    openssl-dev \
    git

WORKDIR /app

# Cache dependency compilation
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo fetch
RUN rm -rf src

# Copy the full source tree
COPY . .

RUN cargo build --locked --release --bin cratedocs

FROM alpine:3.20

RUN apk add --no-cache ca-certificates libgcc libstdc++ libssl3

COPY --from=builder /app/target/release/cratedocs /usr/local/bin/cratedocs
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

LABEL io.modelcontextprotocol.server.name="io.github.promptexecution/rust-cargo-docs-rag-mcp"

EXPOSE 8080

ENV CRATEDOCS_MODE=http \
    CRATEDOCS_ADDRESS=0.0.0.0:8080 \
    CRATEDOCS_DEBUG=false

ENTRYPOINT ["/entrypoint.sh"]

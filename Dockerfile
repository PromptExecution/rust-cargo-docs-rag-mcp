FROM rust:1.91.1-slim-bullseye AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Cache dependency compilation
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo fetch
RUN rm -rf src

# Copy the full source tree
COPY . .

RUN cargo build --locked --release --bin cratedocs

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y ca-certificates libssl1.1 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/cratedocs /usr/local/bin/cratedocs
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8080

ENV CRATEDOCS_MODE=http \
    CRATEDOCS_ADDRESS=0.0.0.0:8080 \
    CRATEDOCS_DEBUG=false

ENTRYPOINT ["/entrypoint.sh"]

# Rust Orchestrator Dockerfile
# Multi-stage build for development and production

# =============================================================================
# Stage 1: Base with system dependencies
# =============================================================================
FROM rust:1.83-bookworm AS base

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build tools
    build-essential \
    pkg-config \
    cmake \
    git \
    curl \
    wget \
    # HDF5 and dependencies
    libhdf5-dev \
    libhdf5-serial-dev \
    hdf5-tools \
    # SSL and compression
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    liblzma-dev \
    # Python for PyO3 integration
    python3.11 \
    python3.11-dev \
    python3-pip \
    # Utilities
    vim \
    nano \
    htop \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Set HDF5 environment variables
ENV HDF5_DIR=/usr/lib/x86_64-linux-gnu/hdf5/serial \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/hdf5/serial:$LD_LIBRARY_PATH \
    PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/hdf5/serial/pkgconfig:$PKG_CONFIG_PATH

# =============================================================================
# Stage 2: Development environment with tools
# =============================================================================
FROM base AS development

# Install Rust toolchain components
RUN rustup component add \
    rustfmt \
    clippy \
    rust-src \
    rust-analyzer

# Install development cargo tools
# Note: cargo-audit, cargo-deny, cargo-edit, cargo-auditable require edition2024 (not yet stable)
RUN cargo install --locked \
    cargo-watch \
    cargo-make \
    maturin

# Create non-root user for development
RUN useradd -m -s /bin/bash rustdev && \
    mkdir -p /workspace && \
    chown -R rustdev:rustdev /workspace

# Set up workspace structure
WORKDIR /workspace
RUN mkdir -p src tests templates logs data scripts

# Copy Cargo files first for layer caching
COPY --chown=rustdev:rustdev Cargo.toml Cargo.lock* ./

# Create placeholder lib.rs and main.rs for dependency caching
RUN mkdir -p src && \
    echo "// Placeholder" > src/lib.rs && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src target

# Fix ownership of workspace
RUN chown -R rustdev:rustdev /workspace

# Development entrypoint
COPY docker/scripts/rust-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER rustdev

ENTRYPOINT ["/entrypoint.sh"]
CMD ["cargo", "watch", "-x", "run"]

# =============================================================================
# Stage 3: Production builder
# =============================================================================
FROM base AS builder

WORKDIR /build

# Copy project files
COPY Cargo.toml Cargo.lock* ./
COPY src ./src
COPY templates ./templates

# Build release binary
RUN cargo build --release --locked

# =============================================================================
# Stage 4: Production runtime
# =============================================================================
FROM debian:bookworm-slim AS production

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libhdf5-103 \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create runtime user
RUN useradd -m -s /bin/bash rustapp

# Set up runtime directories
WORKDIR /app
RUN mkdir -p templates logs data && \
    chown -R rustapp:rustapp /app

# Copy binary from builder
COPY --from=builder /build/target/release/oasm-orchestrator /app/
COPY --from=builder /build/templates /app/templates/

USER rustapp

ENV HDF5_DIR=/usr/lib/x86_64-linux-gnu/hdf5/serial \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/hdf5/serial:$LD_LIBRARY_PATH

ENTRYPOINT ["/app/oasm-orchestrator"]

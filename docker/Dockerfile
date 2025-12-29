# Multi-stage Dockerfile for OASM + Rust + PyO3 + HDF5 System
# Isolated environment for building, testing, and running

# =============================================================================
# Stage 1: Base Image with System Dependencies
# =============================================================================
FROM rust:1.75-bookworm as base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYO3_PYTHON=python3.11

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    pkg-config \
    cmake \
    git \
    curl \
    wget \
    # Python and development headers
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    # HDF5 library and dependencies
    libhdf5-dev \
    hdf5-tools \
    libhdf5-serial-dev \
    # Additional libraries
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    # PowerShell dependencies
    libicu-dev \
    liblttng-ust1 \
    # Tools
    vim \
    nano \
    htop \
    tree \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell Core
RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Stage 2: Rust Build Environment
# =============================================================================
FROM base as rust-builder

# Install Rust toolchain components
RUN rustup component add \
    rustfmt \
    clippy \
    rust-src

# Install cargo tools for development
RUN cargo install \
    cargo-watch \
    cargo-audit \
    cargo-deny \
    cargo-make \
    cargo-auditable \
    maturin

# Set up workspace
WORKDIR /workspace

# =============================================================================
# Stage 3: Python Environment
# =============================================================================
FROM rust-builder as python-env

# Create Python virtual environment
RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install base packages
RUN pip install --no-cache-dir --upgrade \
    pip \
    setuptools \
    wheel

# Install Python dependencies for PyO3 and testing
RUN pip install --no-cache-dir \
    # PyO3 and maturin
    maturin \
    # Testing frameworks
    pytest \
    pytest-cov \
    pytest-benchmark \
    hypothesis \
    # Data science and pattern testing
    numpy \
    pandas \
    networkx \
    scikit-learn \
    # HDF5 Python bindings
    h5py \
    tables \
    # Async and utilities
    aiofiles \
    pyyaml \
    toml \
    # Logging and observability
    structlog \
    opentelemetry-api \
    opentelemetry-sdk

# =============================================================================
# Stage 4: Development Environment
# =============================================================================
FROM python-env as development

# Create project structure
RUN mkdir -p /workspace/{src,tests,templates,logs,data}

# Copy configuration files (if they exist)
COPY docker/config/* /workspace/config/ 2>/dev/null || true

# Set up HDF5 environment variables
ENV HDF5_DIR=/usr/lib/x86_64-linux-gnu/hdf5/serial \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/hdf5/serial:$LD_LIBRARY_PATH

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Activate Python virtual environment\n\
source /opt/venv/bin/activate\n\
\n\
# Initialize workspace if needed\n\
if [ ! -f /workspace/Cargo.toml ]; then\n\
    echo "Initializing Rust workspace..."\n\
    cargo init --lib /workspace 2>/dev/null || true\n\
fi\n\
\n\
# Run command or start shell\n\
if [ $# -eq 0 ]; then\n\
    echo "=== OASM+Rust+PyO3 Development Environment ==="\n\
    echo "Rust version: $(rustc --version)"\n\
    echo "Python version: $(python --version)"\n\
    echo "PowerShell version: $(pwsh --version)"\n\
    echo "HDF5 version: $(h5ls --version 2>&1 | head -1)"\n\
    echo "\nStarting interactive shell..."\n\
    /bin/bash\n\
else\n\
    exec "$@"\n\
fi\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Set working directory
WORKDIR /workspace

# Expose ports for potential services
EXPOSE 8080 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python3 -c "import sys; sys.exit(0)" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD []

# =============================================================================
# Stage 5: Production Build
# =============================================================================
FROM python-env as production

WORKDIR /app

# Copy project files
COPY . /app/

# Build Rust components
RUN cargo build --release

# Build Python extensions with maturin
RUN maturin build --release --out dist/

# Install built wheels
RUN pip install --no-cache-dir dist/*.whl 2>/dev/null || true

# Set up production entrypoint
RUN echo '#!/bin/bash\n\
set -e\n\
source /opt/venv/bin/activate\n\
exec "$@"\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["cargo", "run", "--release"]

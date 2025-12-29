# Python PyO3 Testing Engine Dockerfile

# =============================================================================
# Base stage with Python 3.11
# =============================================================================
FROM python:3.11-slim-bookworm AS base

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build tools for compiling Rust extensions
    build-essential \
    pkg-config \
    cmake \
    git \
    curl \
    # HDF5 for Python bindings
    libhdf5-dev \
    libhdf5-serial-dev \
    hdf5-tools \
    # Additional libraries
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Set HDF5 environment
ENV HDF5_DIR=/usr/lib/x86_64-linux-gnu/hdf5/serial \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/hdf5/serial:$LD_LIBRARY_PATH

# =============================================================================
# Development stage with all testing tools
# =============================================================================
FROM base AS development

# Install Rust for building PyO3 extensions
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install build tools
RUN pip install --upgrade pip setuptools wheel

# Install core dependencies
RUN pip install \
    # PyO3 and Rust integration
    maturin \
    # Testing frameworks
    pytest \
    pytest-cov \
    pytest-benchmark \
    pytest-asyncio \
    pytest-xdist \
    hypothesis \
    # Data analysis and ML
    numpy \
    pandas \
    scipy \
    scikit-learn \
    networkx \
    # HDF5 Python bindings
    h5py \
    tables \
    # CBOR support
    cbor2 \
    # Async utilities
    aiofiles \
    asyncio \
    # Configuration
    pyyaml \
    toml \
    # Logging
    structlog \
    loguru \
    # Type checking
    mypy \
    # Linting
    ruff \
    black

# Create non-root user
RUN useradd -m -s /bin/bash pydev && \
    mkdir -p /workspace && \
    chown -R pydev:pydev /workspace /opt/venv

WORKDIR /workspace
RUN mkdir -p tests data templates logs

# Development entrypoint
COPY docker/scripts/python-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER pydev

# Copy test configuration
COPY --chown=pydev:pydev pytest.ini pyproject.toml* ./

ENTRYPOINT ["/entrypoint.sh"]
CMD ["pytest", "-v", "--cov"]

# =============================================================================
# Production stage (minimal)
# =============================================================================
FROM base AS production

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install only production dependencies
RUN pip install --upgrade pip && \
    pip install \
    numpy \
    h5py \
    cbor2 \
    structlog

# Create runtime user
RUN useradd -m -s /bin/bash pyapp

WORKDIR /app
RUN mkdir -p data templates logs && \
    chown -R pyapp:pyapp /app

# Copy application code
COPY --chown=pyapp:pyapp src/python ./python
COPY --chown=pyapp:pyapp dist/*.whl ./dist/

# Install built wheels (PyO3 extensions)
RUN pip install dist/*.whl || true

USER pyapp

ENTRYPOINT ["python", "-m"]
CMD ["python.main"]

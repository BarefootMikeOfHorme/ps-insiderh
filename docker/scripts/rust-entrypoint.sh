#!/bin/bash
set -e

echo "=== OASM Rust Orchestrator Development Environment ==="
echo "Rust version: $(rustc --version)"
echo "Cargo version: $(cargo --version)"
echo "HDF5 tools: $(h5ls --version 2>&1 | head -1)"
echo ""

# Initialize workspace if Cargo.toml doesn't exist
if [ ! -f /workspace/Cargo.toml ]; then
    echo "Initializing Rust workspace..."
    cd /workspace
    cargo init --lib --name oasm-orchestrator
fi

# Check HDF5 installation
if ldconfig -p | grep -q libhdf5; then
    echo "✓ HDF5 libraries found"
else
    echo "⚠ HDF5 libraries not found in library path"
fi

# Create necessary directories with proper permissions
mkdir -p /workspace/{src,tests,templates,logs,data}

# Clean and recreate target directory
rm -rf /workspace/target 2>/dev/null || true
mkdir -p /workspace/target

echo ""
echo "Workspace ready at /workspace"
echo ""

# Execute command or start shell
if [ $# -eq 0 ]; then
    echo "Starting interactive development shell..."
    exec /bin/bash
else
    exec "$@"
fi

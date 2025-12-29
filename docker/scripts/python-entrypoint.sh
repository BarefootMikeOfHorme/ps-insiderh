#!/bin/bash
set -e

# Activate virtual environment
source /opt/venv/bin/activate

echo "=== PyO3 Pattern Testing Engine ==="
echo "Python version: $(python --version)"
echo "Pytest version: $(pytest --version)"
echo "Hypothesis version: $(python -c 'import hypothesis; print(hypothesis.__version__)')"
echo ""

# Create necessary directories
mkdir -p /workspace/{tests,data,templates,logs}

# Check for PyO3 extensions
if [ -d "/workspace/dist" ] && [ "$(ls -A /workspace/dist/*.whl 2>/dev/null)" ]; then
    echo "Installing PyO3 extensions..."
    pip install --force-reinstall /workspace/dist/*.whl
fi

echo ""
echo "Test environment ready"
echo ""

# Execute command or start shell
if [ $# -eq 0 ]; then
    echo "Starting interactive Python shell..."
    exec python
else
    exec "$@"
fi

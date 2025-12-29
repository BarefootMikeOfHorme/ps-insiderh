#!/bin/bash
# Run tests for OASM Orchestrator

set -e

echo "==================================="
echo "OASM Orchestrator - Test Suite"
echo "==================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Change to project root
cd "$(dirname "$0")/.."

# Check if containers are built
if ! docker images | grep -q "oasm.*rust-orchestrator"; then
    echo -e "${RED}Error: Containers not built. Run ./scripts/build.sh first${NC}"
    exit 1
fi

echo -e "${BLUE}Running test suite...${NC}"
echo ""

# Test 1: Rust unit tests
echo -e "${YELLOW}[1/4] Running Rust unit tests...${NC}"
docker-compose run --rm rust-orchestrator cargo test --lib
echo -e "${GREEN}✓ Rust unit tests passed${NC}"
echo ""

# Test 2: Rust integration tests
echo -e "${YELLOW}[2/4] Running Rust integration tests...${NC}"
docker-compose run --rm rust-orchestrator cargo test --test '*'
echo -e "${GREEN}✓ Rust integration tests passed${NC}"
echo ""

# Test 3: Build check (ensure it compiles)
echo -e "${YELLOW}[3/4] Running build check...${NC}"
docker-compose run --rm rust-orchestrator cargo build --release
echo -e "${GREEN}✓ Build check passed${NC}"
echo ""

# Test 4: Python tests (if available)
echo -e "${YELLOW}[4/4] Running Python tests...${NC}"
if [ -d "tests" ] && [ "$(ls -A tests/*.py 2>/dev/null)" ]; then
    docker-compose run --rm python-testing pytest /workspace/tests -v
    echo -e "${GREEN}✓ Python tests passed${NC}"
else
    echo -e "${YELLOW}⚠ No Python tests found (skipping)${NC}"
fi
echo ""

# Optional: Run property-based tests
if [ "$1" == "--property" ]; then
    echo -e "${YELLOW}[Optional] Running property-based tests...${NC}"
    docker-compose run --rm python-testing pytest /workspace/tests -v -m hypothesis
    echo -e "${GREEN}✓ Property-based tests passed${NC}"
    echo ""
fi

# Optional: Run benchmarks
if [ "$1" == "--bench" ]; then
    echo -e "${YELLOW}[Optional] Running benchmarks...${NC}"
    docker-compose run --rm rust-orchestrator cargo bench
    echo -e "${GREEN}✓ Benchmarks completed${NC}"
    echo ""
fi

echo -e "${GREEN}==================================="
echo "All tests passed!"
echo "===================================${NC}"
echo ""

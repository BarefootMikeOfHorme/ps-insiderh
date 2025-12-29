#!/bin/bash
# Build all Docker containers for OASM Orchestrator

set -e

echo "==================================="
echo "OASM Orchestrator - Build Script"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to project root
cd "$(dirname "$0")/.."

echo -e "${BLUE}Building Docker containers...${NC}"
echo ""

# Build Rust orchestrator container
echo -e "${YELLOW}[1/2] Building Rust orchestrator container...${NC}"
docker-compose build rust-orchestrator
echo -e "${GREEN}✓ Rust orchestrator built${NC}"
echo ""

# Build Python testing container
echo -e "${YELLOW}[2/2] Building Python testing container...${NC}"
docker-compose build python-testing
echo -e "${GREEN}✓ Python testing container built${NC}"
echo ""

# Optional: Build PowerShell core container
if [ "$1" == "--with-powershell" ]; then
    echo -e "${YELLOW}[Optional] Building PowerShell core container...${NC}"
    docker-compose build powershell-core
    echo -e "${GREEN}✓ PowerShell core built${NC}"
    echo ""
fi

# Optional: Build OASM platform containers
if [ "$1" == "--with-oasm" ]; then
    echo -e "${YELLOW}[Optional] Building OASM platform containers...${NC}"
    docker-compose --profile with-oasm build
    echo -e "${GREEN}✓ OASM platform containers built${NC}"
    echo ""
fi

echo -e "${GREEN}==================================="
echo "Build completed successfully!"
echo "===================================${NC}"
echo ""
echo "Next steps:"
echo "  • Run tests: ./scripts/test.sh"
echo "  • Start dev environment: ./scripts/dev.sh"
echo "  • Start all services: docker-compose up -d"
echo ""

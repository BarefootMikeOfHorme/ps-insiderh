#!/bin/bash
# Start development environment for OASM Orchestrator

set -e

echo "==================================="
echo "OASM Orchestrator - Dev Environment"
echo "==================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Change to project root
cd "$(dirname "$0")/.."

echo -e "${BLUE}Starting development environment...${NC}"
echo ""

# Start core services
echo -e "${YELLOW}Starting core services...${NC}"
docker-compose up -d rust-orchestrator python-testing

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 2

# Show service status
echo ""
echo -e "${GREEN}Services started:${NC}"
docker-compose ps

echo ""
echo -e "${GREEN}==================================="
echo "Development environment ready!"
echo "===================================${NC}"
echo ""
echo "Available commands:"
echo ""
echo "  ${BLUE}Rust Development:${NC}"
echo "    docker-compose exec rust-orchestrator cargo watch -x build"
echo "    docker-compose exec rust-orchestrator cargo test"
echo "    docker-compose exec rust-orchestrator bash"
echo ""
echo "  ${BLUE}Python Development:${NC}"
echo "    docker-compose exec python-testing pytest /workspace/tests"
echo "    docker-compose exec python-testing python"
echo ""
echo "  ${BLUE}View Logs:${NC}"
echo "    docker-compose logs -f rust-orchestrator"
echo "    docker-compose logs -f python-testing"
echo ""
echo "  ${BLUE}Stop Services:${NC}"
echo "    docker-compose down"
echo ""

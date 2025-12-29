# Build Docker containers for OASM Orchestrator

$ErrorActionPreference = "Stop"

Write-Host "===================================" -ForegroundColor Blue
Write-Host "OASM Orchestrator - Build Script" -ForegroundColor Blue
Write-Host "===================================" -ForegroundColor Blue
Write-Host ""

# Change to project directory
Set-Location -Path $PSScriptRoot

# Add Docker to PATH if needed
$dockerPath = "C:\Program Files\Docker\Docker\resources\bin"
if ($env:PATH -notlike "*$dockerPath*") {
    $env:PATH = "$dockerPath;$env:PATH"
}

Write-Host "Building Docker containers..." -ForegroundColor Cyan
Write-Host ""

# Build Rust orchestrator container
Write-Host "[1/2] Building Rust orchestrator container..." -ForegroundColor Yellow
& docker compose build rust-orchestrator
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error building Rust orchestrator" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Rust orchestrator built" -ForegroundColor Green
Write-Host ""

# Build Python testing container
Write-Host "[2/2] Building Python testing container..." -ForegroundColor Yellow
& docker compose build python-testing
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error building Python testing container" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Python testing container built" -ForegroundColor Green
Write-Host ""

Write-Host "===================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  * Start services: docker compose up -d" -ForegroundColor White
Write-Host "  * View logs: docker compose logs -f" -ForegroundColor White
Write-Host "  * Run tests: docker compose run --rm rust-orchestrator cargo test" -ForegroundColor White
Write-Host ""

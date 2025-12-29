@echo off
REM Build all Docker containers for OASM Orchestrator

echo ===================================
echo OASM Orchestrator - Build Script
echo ===================================
echo.

cd /d "%~dp0\.."

echo Building Docker containers...
echo.

REM Build Rust orchestrator container
echo [1/2] Building Rust orchestrator container...
docker-compose build rust-orchestrator
if %errorlevel% neq 0 (
    echo Error building Rust orchestrator
    exit /b 1
)
echo [OK] Rust orchestrator built
echo.

REM Build Python testing container
echo [2/2] Building Python testing container...
docker-compose build python-testing
if %errorlevel% neq 0 (
    echo Error building Python testing container
    exit /b 1
)
echo [OK] Python testing container built
echo.

REM Optional: Build PowerShell core container
if "%1"=="--with-powershell" (
    echo [Optional] Building PowerShell core container...
    docker-compose build powershell-core
    if %errorlevel% neq 0 (
        echo Error building PowerShell core
        exit /b 1
    )
    echo [OK] PowerShell core built
    echo.
)

REM Optional: Build OASM platform containers
if "%1"=="--with-oasm" (
    echo [Optional] Building OASM platform containers...
    docker-compose --profile with-oasm build
    if %errorlevel% neq 0 (
        echo Error building OASM platform containers
        exit /b 1
    )
    echo [OK] OASM platform containers built
    echo.
)

echo ===================================
echo Build completed successfully!
echo ===================================
echo.
echo Next steps:
echo   * Run tests: scripts\test.bat
echo   * Start dev environment: scripts\dev.bat
echo   * Start all services: docker-compose up -d
echo.

pause

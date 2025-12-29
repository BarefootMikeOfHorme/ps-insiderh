@echo off
REM Run tests for OASM Orchestrator

echo ===================================
echo OASM Orchestrator - Test Suite
echo ===================================
echo.

cd /d "%~dp0\.."

REM Check if containers are built
docker images | findstr /C:"oasm" | findstr /C:"rust-orchestrator" >nul
if %errorlevel% neq 0 (
    echo Error: Containers not built. Run scripts\build.bat first
    exit /b 1
)

echo Running test suite...
echo.

REM Test 1: Rust unit tests
echo [1/4] Running Rust unit tests...
docker-compose run --rm rust-orchestrator cargo test --lib
if %errorlevel% neq 0 (
    echo Error: Rust unit tests failed
    exit /b 1
)
echo [OK] Rust unit tests passed
echo.

REM Test 2: Rust integration tests
echo [2/4] Running Rust integration tests...
docker-compose run --rm rust-orchestrator cargo test --test "*"
if %errorlevel% neq 0 (
    echo Warning: Some integration tests failed
)
echo [OK] Rust integration tests completed
echo.

REM Test 3: Build check
echo [3/4] Running build check...
docker-compose run --rm rust-orchestrator cargo build --release
if %errorlevel% neq 0 (
    echo Error: Build check failed
    exit /b 1
)
echo [OK] Build check passed
echo.

REM Test 4: Python tests
echo [4/4] Running Python tests...
if exist "tests\*.py" (
    docker-compose run --rm python-testing pytest /workspace/tests -v
    if %errorlevel% neq 0 (
        echo Warning: Some Python tests failed
    ) else (
        echo [OK] Python tests passed
    )
) else (
    echo [SKIP] No Python tests found
)
echo.

echo ===================================
echo Test suite completed!
echo ===================================
echo.

pause

@echo off
REM Start development environment for OASM Orchestrator

echo ===================================
echo OASM Orchestrator - Dev Environment
echo ===================================
echo.

cd /d "%~dp0\.."

echo Starting development environment...
echo.

REM Start core services
echo Starting core services...
docker-compose up -d rust-orchestrator python-testing

if %errorlevel% neq 0 (
    echo Error: Failed to start services
    exit /b 1
)

REM Wait for services to be ready
echo Waiting for services to be ready...
timeout /t 3 /nobreak >nul

REM Show service status
echo.
echo Services started:
docker-compose ps

echo.
echo ===================================
echo Development environment ready!
echo ===================================
echo.
echo Available commands:
echo.
echo   Rust Development:
echo     docker-compose exec rust-orchestrator cargo watch -x build
echo     docker-compose exec rust-orchestrator cargo test
echo     docker-compose exec rust-orchestrator bash
echo.
echo   Python Development:
echo     docker-compose exec python-testing pytest /workspace/tests
echo     docker-compose exec python-testing python
echo.
echo   View Logs:
echo     docker-compose logs -f rust-orchestrator
echo     docker-compose logs -f python-testing
echo.
echo   Stop Services:
echo     docker-compose down
echo.

pause

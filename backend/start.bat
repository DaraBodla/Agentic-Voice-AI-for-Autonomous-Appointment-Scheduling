@echo off
echo ============================================
echo   CallPilot Backend Server
echo ============================================
echo.

REM Check if .env exists
if not exist .env (
    echo No .env file found. Creating from .env.example...
    copy .env.example .env
    echo.
    echo IMPORTANT: Edit .env with your API keys for live mode.
    echo Without keys, the server runs in demo mode.
    echo.
)

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt -q

echo.
echo Starting server on http://localhost:8000
echo Press Ctrl+C to stop
echo.

uvicorn server:app --reload --host 0.0.0.0 --port 8000

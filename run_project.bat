@echo off
title Pak Flood & Disaster Care runner
echo ====================================================
echo Starting Pak Flood & Disaster Care Application
echo ====================================================
echo.

echo [1/3] Setting up Python Backend Dependencies...
pip install -r backend/requirements.txt
if %errorlevel% neq 0 (
    echo [WARNING] Some dependencies failed to install or pip is not set up correctly.
)
echo.

echo [2/3] Booting Python Flask Server (API)...
echo Starting server on host 0.0.0.0, port 5000 ...
start "Flood Care Backend API" cmd /k "python backend/app.py"
echo.

echo Waiting 3 seconds for server to start...
timeout /t 3 /nobreak > nul
echo.

echo [3/3] Fetching Flutter app packages and launching app...
cd pakistan_floods_app
call flutter pub get
echo.
echo Launching Flutter App. Please make sure a device or emulator is connected.
echo If you want to target the Chrome web browser, run: flutter run -d chrome
echo.
flutter run -d chrome

pause

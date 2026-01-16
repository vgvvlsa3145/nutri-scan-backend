@echo off
setlocal
echo ==========================================
echo       NutriScan - Launching Servers
echo ==========================================

:: Define Local Paths
set "FLUTTER_EXE=C:\Users\Sweet.Vellyn_Vgvvlsa\Desktop\ece\nutri_scan_app\flutter\bin\flutter.bat"

:: Start Python Backend
echo Starting Backend...
start "NutriScan Backend" cmd /k "cd nutri_scan_backend && python app.py"

:: Wait a few seconds for backend to initialize
timeout /t 5 /nobreak > nul

:: Start Flutter Frontend using absolute path
echo Starting Frontend...
start "NutriScan Frontend" cmd /k "cd nutri_scan_app && ^"%FLUTTER_EXE%^" run -d chrome"

echo ==========================================
echo Setup complete. Both windows are running.
echo ==========================================
pause
endlocal

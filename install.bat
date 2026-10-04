@echo off
setlocal

:: Get the current directory of the script
set "EXT_DIR=%~dp0"
:: Remove trailing backslash
if "%EXT_DIR:~-1%"=="\" set "EXT_DIR=%EXT_DIR:~0,-1%"

echo ========================================================
echo DHM Data Watch Extension - Quick Loader
echo ========================================================
echo.
echo NOTE: Google Chrome prevents permanent automatic installation
echo of unpacked extensions via scripts for security reasons.
echo.
echo This script will launch Chrome with the extension loaded temporarily.
echo.
echo To install it permanently, follow these steps:
echo 1. Open Chrome and go to: chrome://extensions/
echo 2. Enable "Developer mode" in the top right corner.
echo 3. Click "Load unpacked" and select this folder:
echo    %EXT_DIR%
echo.
echo Detecting Google Chrome...

:: Detect Chrome path
set "CHROME_PATH="

:: Check common installation paths
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
) else if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
) else if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%LocalAppData%\Google\Chrome\Application\chrome.exe"
)

if "%CHROME_PATH%"=="" (
    echo [ERROR] Google Chrome was not found in standard locations.
    echo Please install the extension manually by visiting chrome://extensions/
    pause
    exit /b
)

echo [SUCCESS] Found Chrome at: "%CHROME_PATH%"
echo.
echo Launching Chrome with the extension loaded...
start "" "%CHROME_PATH%" --load-extension="%EXT_DIR%"

echo.
echo Done! If you want it permanently installed, please follow the manual steps above.
pause

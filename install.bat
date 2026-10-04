@echo off
setlocal EnableDelayedExpansion

:: Get the current directory of the script
set "EXT_DIR=%~dp0"
:: Remove trailing backslash
if "%EXT_DIR:~-1%"=="\" set "EXT_DIR=%EXT_DIR:~0,-1%"

echo ========================================================
echo DHM Data Watch Extension - Profile Loader
echo ========================================================
echo.

:: Detect Chrome path
set "CHROME_PATH="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
) else if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
) else if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_PATH=%LocalAppData%\Google\Chrome\Application\chrome.exe"
)

if "%CHROME_PATH%"=="" (
    echo [ERROR] Google Chrome was not found in standard locations.
    pause
    exit /b
)

:: Find Chrome Profiles
set "USER_DATA=%LocalAppData%\Google\Chrome\User Data"
if not exist "%USER_DATA%" (
    echo [ERROR] Chrome User Data directory not found.
    pause
    exit /b
)

echo Found Multiple Chrome Profiles. Please select one:
echo --------------------------------------------------------
set count=0

:: Check Default profile
if exist "%USER_DATA%\Default" (
    set /a count+=1
    set "PROFILE_!count!=Default"
    echo [!count!] Default
)

:: Check other profiles (Profile 1, Profile 2, etc.)
for /d %%D in ("%USER_DATA%\Profile *") do (
    set /a count+=1
    set "PROFILE_!count!=%%~nxD"
    echo [!count!] %%~nxD
)

if %count%==0 (
    echo No Chrome profiles found.
    pause
    exit /b
)

echo.
set /p "CHOICE=Enter the number of the profile to use (1-%count%): "

:: Validate choice
set "SELECTED_PROFILE="
for /L %%i in (1,1,%count%) do (
    if "%CHOICE%"=="%%i" set "SELECTED_PROFILE=!PROFILE_%%i!"
)

if "%SELECTED_PROFILE%"=="" (
    echo Invalid choice. Exiting...
    pause
    exit /b
)

echo.
echo Launching Chrome using "%SELECTED_PROFILE%"...
start "" "%CHROME_PATH%" --profile-directory="%SELECTED_PROFILE%" --load-extension="%EXT_DIR%"

echo.
echo ========================================================
echo IMPORTANT: PERMANENT INSTALLATION REQUIRED
echo ========================================================
echo The extension has been loaded into your selected profile
echo temporarily. To make it permanent:
echo.
echo 1. Go to chrome://extensions/ in the Chrome window that just opened.
echo 2. Enable "Developer mode" in the top right.
echo 3. Click "Load unpacked" and select this folder:
echo    %EXT_DIR%
echo.
pause

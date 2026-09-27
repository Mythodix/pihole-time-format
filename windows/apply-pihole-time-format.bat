@echo off
REM ===========================================================================
REM apply-pihole-time-format.bat
REM ---------------------------------------------------------------------------
REM Run this after every Pi-hole update. It lives in the "windows" folder,
REM next to pihole-patch-config.bat, and uses pihole-time-format.sh from the
REM folder above. Keep the downloaded folder in one piece.
REM
REM What it does:
REM   1. Copies pihole-time-format.sh to your home folder on the Pi
REM      (replacing any older copy)
REM   2. Logs into the Pi and runs:  sudo ~/pihole-time-format.sh apply
REM
REM Password prompts:
REM   - None, if you've run setup-pihole-ssh.bat.
REM   - Otherwise up to three: the upload, the login, and sudo.
REM
REM Settings come from pihole-patch-config.bat. Edit that file first.
REM
REM Note: the ssh line below uses -t. Without it, sudo can't ask for a
REM password and fails with "sudo: a terminal is required to read the
REM password". Don't remove it.
REM ===========================================================================

setlocal

if not exist "%~dp0pihole-patch-config.bat" (
    echo ERROR: pihole-patch-config.bat is missing.
    echo It needs to be in the same folder as this file.
    echo.
    pause
    exit /b 1
)
call "%~dp0pihole-patch-config.bat"

where ssh >nul 2>&1
if errorlevel 1 (
    echo ERROR: The ssh command isn't available on this PC.
    echo Install it from Settings ^> System ^> Optional features ^> OpenSSH Client.
    echo.
    pause
    exit /b 1
)

set "SCRIPT_PATH=%~dp0..\%SCRIPT_NAME%"
if not exist "%SCRIPT_PATH%" set "SCRIPT_PATH=%~dp0%SCRIPT_NAME%"

echo.
echo === Pi-hole Time Format Patcher ===
echo.
echo Pi:      %PI_USER%@%PI_HOST%
echo Script:  %SCRIPT_PATH%
echo.

if not exist "%SCRIPT_PATH%" (
    echo ERROR: Couldn't find %SCRIPT_NAME%.
    echo It should be in the folder above this "windows" folder.
    echo Re-download the project and keep the folder in one piece.
    echo.
    pause
    exit /b 1
)

echo [1/2] Uploading the script to the Pi...
echo.
scp "%SCRIPT_PATH%" %PI_USER%@%PI_HOST%:~/
if errorlevel 1 (
    echo.
    echo ERROR: Upload failed. Check the password, the Pi address in
    echo pihole-patch-config.bat, and that the Pi is switched on.
    echo.
    pause
    exit /b 1
)

REM sed strips Windows line endings, in case the script was opened and
REM saved in a Windows editor. Without this it fails with "bash\r: not found".
echo.
echo [2/2] Applying the patch on the Pi...
echo.
ssh -t %PI_USER%@%PI_HOST% "sed -i 's/\r$//' ~/%SCRIPT_NAME% && chmod +x ~/%SCRIPT_NAME% && sudo ~/%SCRIPT_NAME% apply"
if errorlevel 1 (
    echo.
    echo ERROR: The patch didn't apply. See the messages above, and
    echo "Troubleshooting" in the README.
    echo.
    pause
    exit /b 1
)

echo.
echo === Done ===
echo.
echo Hard-refresh the Pi-hole tab in your browser (Ctrl+F5) to see the new format.
echo.
pause
endlocal

@echo off
REM ===========================================================================
REM  Pi-hole Time Format Patch - Windows launcher
REM  https://github.com/Mythodix/pihole-time-format
REM ---------------------------------------------------------------------------
REM  Just double-click this file.
REM
REM  The first time, it asks for your Pi's address and username, checks it can
REM  log in, and remembers them. After that it shows a menu:
REM
REM    1  Apply the patch        (run again after every Pi-hole update)
REM    2  Undo the patch         (put Pi-hole's original file back)
REM    3  Check status
REM    4  Stop asking for my password  (optional, one-time setup)
REM    5  Change Pi or username
REM
REM  Your Pi's address and username are saved in:
REM    %APPDATA%\pihole-time-format\settings.cmd
REM  Your password is never saved. Delete that folder to start fresh.
REM
REM  Works on its own: if pihole-time-format.sh isn't in the same folder as
REM  this file, the Pi downloads the latest copy from GitHub instead.
REM
REM  Needs Windows 10 or 11 with the OpenSSH Client (installed by default).
REM ===========================================================================

setlocal
title Pi-hole Time Format Patch

set "RAW_URL=https://raw.githubusercontent.com/Mythodix/pihole-time-format/main/pihole-time-format.sh"
set "SCRIPT=pihole-time-format.sh"
set "CFG_DIR=%APPDATA%\pihole-time-format"
set "CFG=%CFG_DIR%\settings.cmd"
set "KEY=%USERPROFILE%\.ssh\id_ed25519"
REM accept-new: trust a Pi the first time we see it, without a yes/no prompt.
set "SSHOPT=-o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new"

where ssh >nul 2>&1
if errorlevel 1 (
    echo.
    echo  The ssh command isn't available on this PC.
    echo  Add it from Settings ^> System ^> Optional features ^> Add a feature,
    echo  then search for "OpenSSH Client" and install it.
    echo.
    pause
    exit /b 1
)

if not exist "%CFG%" (
    call :first_run
    if errorlevel 1 exit /b 1
)

:menu
set "PI_USER="
set "PI_HOST="
set "PWFREE="
call "%CFG%"
cls
echo.
echo   ==================================================
echo      Pi-hole Time Format Patch
echo   ==================================================
echo.
echo     Pi:        %PI_USER%@%PI_HOST%
if defined PWFREE (
    echo     Sign-in:   saved key, no password needed
) else (
    echo     Sign-in:   password each time
)
echo.
echo     [1]  Apply the patch
echo          Run this again after every Pi-hole update.
echo.
echo     [2]  Undo the patch
echo     [3]  Check status
echo     [4]  Stop asking for my password
echo     [5]  Change Pi or username
echo     [6]  Exit
echo.
choice /c 123456 /n /m "   Choose 1-6: "
set "PICK=%errorlevel%"
if "%PICK%"=="1" call :run apply
if "%PICK%"=="2" call :run restore
if "%PICK%"=="3" call :run status
if "%PICK%"=="4" call :passwordless
if "%PICK%"=="5" call :change
if "%PICK%"=="6" exit /b 0
if not exist "%CFG%" exit /b 0
goto menu


REM ===========================================================================
REM  First run: ask for the Pi's details, test the login, save them.
REM ===========================================================================
:first_run
cls
echo.
echo   ==================================================
echo      Pi-hole Time Format Patch - first-time setup
echo   ==================================================
echo.
echo   You'll need two things:
echo.
echo     - Your Pi's IP address. It's shown on the Pi-hole dashboard,
echo       or in your router's list of connected devices.
echo     - The username you log into the Pi with ^(often "pi"^).
echo.

:ask_details
set "PI_HOST="
set "PI_USER="
set /p "PI_HOST=  Pi address, e.g. 192.168.1.50: "
if not defined PI_HOST goto ask_details
set /p "PI_USER=  Pi username [press Enter for pi]: "
if not defined PI_USER set "PI_USER=pi"

echo.
echo   Logging in to %PI_USER%@%PI_HOST% ...
echo   Type your Pi password when asked. Nothing shows as you type; that's normal.
echo.
ssh %SSHOPT% %PI_USER%@%PI_HOST% "command -v pihole >/dev/null 2>&1 && echo '  Connected. Pi-hole found.' || echo '  Connected, but Pi-hole was not found on this device.'"
if errorlevel 1 (
    echo.
    echo   Couldn't log in. Check the address, the username and the password.
    echo.
    choice /c YN /m "  Try again"
    if errorlevel 2 exit /b 1
    echo.
    goto ask_details
)

if not exist "%CFG_DIR%" mkdir "%CFG_DIR%"
> "%CFG%" echo set "PI_USER=%PI_USER%"
>> "%CFG%" echo set "PI_HOST=%PI_HOST%"
echo.
echo   Saved. You won't be asked for these again.
echo   To change them later, choose "Change Pi or username" from the menu.
echo.
pause
exit /b 0


REM ===========================================================================
REM  Run the patch script on the Pi: apply, restore or status.
REM ===========================================================================
:run
set "ACT=%~1"
set "SUDO=sudo "
if /i "%ACT%"=="status" set "SUDO="
cls
echo.

REM Get the script onto the Pi, in the home folder.
REM If there's a copy next to this .bat, upload that. Otherwise the Pi
REM downloads the latest one from GitHub.
set "GET=true"
if exist "%~dp0%SCRIPT%" goto run_upload
echo   Getting the latest patch script from GitHub...
set "GET={ curl -fsSL %RAW_URL% -o ~/%SCRIPT% || wget -qO ~/%SCRIPT% %RAW_URL%; }"
goto run_go

:run_upload
echo   Uploading the patch script to the Pi...
scp -q %SSHOPT% "%~dp0%SCRIPT%" %PI_USER%@%PI_HOST%:~/
if errorlevel 1 (
    echo.
    echo   Upload failed. Check the Pi is on, and your password.
    echo.
    pause
    exit /b 1
)

:run_go
REM sed removes Windows line endings, in case the script was edited on
REM Windows. -t lets sudo ask for your password if it needs to.
echo.
ssh -t %SSHOPT% %PI_USER%@%PI_HOST% "%GET% && sed -i 's/\r$//' ~/%SCRIPT% && chmod +x ~/%SCRIPT% && %SUDO%~/%SCRIPT% %ACT%"
if errorlevel 1 (
    echo.
    echo   Something went wrong. See the messages above.
    echo   The README on GitHub has a Troubleshooting section.
) else (
    if /i not "%ACT%"=="status" (
        echo.
        echo   Done. Press Ctrl+F5 on the Pi-hole Query Log to see the change.
    )
)
echo.
pause
exit /b 0


REM ===========================================================================
REM  One-time setup so it stops asking for your password.
REM ===========================================================================
:passwordless
cls
echo.
echo   ==================================================
echo      Stop asking for my password
echo   ==================================================
echo.
echo   This sets up two things, so the patch runs without any password:
echo.
echo     1. An SSH key, so this PC can log into the Pi by itself.
echo     2. A rule on the Pi that lets ONLY this patch script run as
echo        administrator without a password.
echo.
echo   Before you go ahead:
echo     - Anyone who can use your Windows account could log into the Pi.
echo     - Only do this on your own Pi, not one other people log into.
echo.
echo   You'll type your Pi password up to three more times, then never again.
echo.
choice /c YN /m "  Set it up now"
if errorlevel 2 exit /b 0

echo.
if exist "%KEY%" (
    echo   [1/4] Using your existing SSH key.
) else (
    echo   [1/4] Creating an SSH key...
    if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
    ssh-keygen -q -t ed25519 -f "%KEY%" -N "" -C "pihole-time-format"
    if errorlevel 1 (
        echo   Couldn't create the key.
        pause
        exit /b 1
    )
)

REM tr strips Windows line endings; sort -u avoids adding the key twice.
echo   [2/4] Adding the key to the Pi. Type your Pi password if asked.
type "%KEY%.pub" | ssh %SSHOPT% %PI_USER%@%PI_HOST% "mkdir -p ~/.ssh && chmod 700 ~/.ssh && tr -d '\r' >> ~/.ssh/authorized_keys && sort -u -o ~/.ssh/authorized_keys ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
if errorlevel 1 (
    echo.
    echo   Couldn't add the key. Nothing else was changed.
    echo.
    pause
    exit /b 1
)

REM The rule is checked with visudo before it's installed, so a mistake
REM can never lock you out of sudo. $USER and $HOME are filled in by the Pi.
echo   [3/4] Adding the sudo rule. Type your Pi password if asked.
ssh -t %SSHOPT% %PI_USER%@%PI_HOST% "printf '%%s ALL=(root) NOPASSWD: %%s/%SCRIPT%\n' $USER $HOME > /tmp/pihole-timeformat.sudoers && sudo visudo -cf /tmp/pihole-timeformat.sudoers >/dev/null && sudo install -m 0440 -o root -g root /tmp/pihole-timeformat.sudoers /etc/sudoers.d/pihole-timeformat; rc=$?; rm -f /tmp/pihole-timeformat.sudoers; exit $rc"
if errorlevel 1 (
    echo.
    echo   Couldn't add the sudo rule. Nothing was changed on the Pi's sudo setup.
    echo.
    pause
    exit /b 1
)

echo   [4/4] Testing...
ssh -o BatchMode=yes %SSHOPT% %PI_USER%@%PI_HOST% "exit 0" >nul 2>&1
if errorlevel 1 (
    echo.
    echo   The key didn't work, so you'll still be asked for your password.
    echo   If your existing SSH key has a passphrase, that's the reason.
    echo.
    pause
    exit /b 0
)

>> "%CFG%" echo set "PWFREE=1"
echo.
echo   All set. The patch won't ask for your password any more.
echo.
pause
exit /b 0


REM ===========================================================================
REM  Forget the saved Pi and ask again.
REM ===========================================================================
:change
set "OLD_CFG=%CFG%.old"
move /y "%CFG%" "%OLD_CFG%" >nul
call :first_run
if errorlevel 1 (
    move /y "%OLD_CFG%" "%CFG%" >nul
    exit /b 0
)
del "%OLD_CFG%" >nul 2>&1
exit /b 0

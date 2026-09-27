@echo off
REM ===========================================================================
REM setup-pihole-ssh.bat   (run ONCE, optional)
REM ---------------------------------------------------------------------------
REM Makes apply-pihole-time-format.bat run with no password prompts.
REM Without this, apply-pihole-time-format.bat still works; it just asks for
REM your Pi password up to three times each run.
REM
REM What it does:
REM   1. Creates an SSH key on this PC at %USERPROFILE%\.ssh\id_ed25519
REM      (skipped if you already have one)
REM   2. Adds that key to ~/.ssh/authorized_keys on the Pi
REM      -> asks for your Pi password
REM   3. Adds a sudo rule on the Pi at /etc/sudoers.d/pihole-timeformat that
REM      lets ONLY the patch script run as root without a password
REM      -> asks for your Pi password (sudo)
REM   4. Tests that key login works
REM
REM Settings come from pihole-patch-config.bat. Edit that file first.
REM
REM SECURITY NOTE
REM   The sudo rule points at ~/pihole-time-format.sh in your home folder.
REM   Your normal user can edit that file, so anything written into it would
REM   run as root without a password. On a home Pi where your account already
REM   has sudo, this doesn't give you anything you didn't already have. Don't
REM   use it on a Pi other people log into. To undo it, see "Uninstall" in the README.
REM
REM   The SSH key is created without a passphrase so the patch can run
REM   unattended. Anyone who can log into your Windows account could use it
REM   to log into the Pi.
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

set "KEY=%USERPROFILE%\.ssh\id_ed25519"

echo.
echo === Pi-hole passwordless SSH setup ===
echo.
echo Pi:   %PI_USER%@%PI_HOST%
echo Key:  %KEY%
echo.
echo If that Pi address or username is wrong, close this window and
echo edit pihole-patch-config.bat first.
echo.
pause

REM --- 1. Create a key if there isn't one -----------------------------------
echo.
if exist "%KEY%" (
    echo [1/4] SSH key already exists. Using it.
) else (
    echo [1/4] Creating a new SSH key ^(no passphrase^)...
    if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
    ssh-keygen -t ed25519 -f "%KEY%" -N "" -C "pihole-time-format"
    if errorlevel 1 (
        echo ERROR: Key creation failed.
        echo.
        pause
        exit /b 1
    )
)

REM --- 2. Install the public key on the Pi ----------------------------------
REM tr strips Windows line endings so the key line is valid on Linux.
REM sort -u removes duplicates if this setup is run more than once.
echo.
echo [2/4] Adding the key to the Pi.
echo       Type your Pi password when asked.
type "%KEY%.pub" | ssh %PI_USER%@%PI_HOST% "mkdir -p ~/.ssh && chmod 700 ~/.ssh && tr -d '\r' >> ~/.ssh/authorized_keys && sort -u -o ~/.ssh/authorized_keys ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
if errorlevel 1 (
    echo.
    echo ERROR: Couldn't add the key. Check the password, the Pi address,
    echo and that the Pi is switched on.
    echo.
    pause
    exit /b 1
)

REM --- 3. Add the sudo rule --------------------------------------------------
REM The rule is written to a temp file and checked with visudo BEFORE it's
REM installed, so a bad rule can never lock you out of sudo.
echo.
echo [3/4] Adding a sudo rule for the patch script only.
echo       Type your Pi password when asked.
ssh -t %PI_USER%@%PI_HOST% "echo '%PI_USER% ALL=(root) NOPASSWD: /home/%PI_USER%/%SCRIPT_NAME%' > /tmp/pihole-timeformat.sudoers && sudo visudo -cf /tmp/pihole-timeformat.sudoers && sudo install -m 0440 -o root -g root /tmp/pihole-timeformat.sudoers /etc/sudoers.d/pihole-timeformat; rc=$?; rm -f /tmp/pihole-timeformat.sudoers; exit $rc"
if errorlevel 1 (
    echo.
    echo ERROR: Couldn't add the sudo rule. See the messages above.
    echo Nothing was changed in /etc/sudoers.d.
    echo.
    pause
    exit /b 1
)

REM --- 4. Test -------------------------------------------------------------
echo.
echo [4/4] Testing key login ^(should NOT ask for a password^)...
ssh -o BatchMode=yes %PI_USER%@%PI_HOST% "echo OK: key login works"
if errorlevel 1 (
    echo.
    echo WARNING: Key login didn't work. apply-pihole-time-format.bat will
    echo still run, but it will ask for your password.
    echo See "Troubleshooting" in the README.
)

echo.
echo === Setup complete ===
echo apply-pihole-time-format.bat should now run without any password prompts.
echo.
pause
endlocal

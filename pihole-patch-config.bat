@echo off
REM ===========================================================================
REM pihole-patch-config.bat
REM ---------------------------------------------------------------------------
REM EDIT THIS FILE FIRST. Both setup-pihole-ssh.bat and
REM apply-pihole-time-format.bat read their settings from here.
REM
REM Open it in Notepad (right-click > Edit), change the two lines marked
REM below, and save. Don't double-click this file; it does nothing on its own.
REM ===========================================================================

REM --- 1. Your username on the Pi -------------------------------------------
REM     The account you log into the Pi with over SSH (often "pi").
set "PI_USER=pi"

REM --- 2. Your Pi's address -------------------------------------------------
REM     Its IP address on your network, for example 192.168.1.50.
REM     "pi.hole" also works if this PC already uses Pi-hole for DNS.
set "PI_HOST=pi.hole"

REM --- Leave this alone unless you renamed the script -----------------------
set "SCRIPT_NAME=pihole-time-format.sh"

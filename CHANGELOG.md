# Changelog

## v2.2 — 2026-09-27

- **New Windows launcher:** one file, `pihole-time-format.bat`, replaces the
  three old Windows files. Double-click it, enter your Pi's address and
  username once, and pick from a menu: apply, undo, check status, stop asking
  for a password, or change Pi.
- The launcher works on its own. If `pihole-time-format.sh` isn't next to it,
  the Pi downloads the latest copy from GitHub.
- Saved details live in `%APPDATA%\pihole-time-format`. Passwords are never
  saved.
- The password-free setup now uses the Pi's real home folder, so it also
  works when that isn't `/home/<username>`.
- The `.bat` is stored with Windows line endings, so it works when downloaded
  on its own.

## v2.1 — 2026-09-27

- **Added:** one-line install straight from GitHub:
  `curl -fsSL .../pihole-time-format.sh | sudo bash -s apply`
- **Changed:** README rewritten around install, update and undo, with the
  details in collapsible sections.
- **Changed:** Windows launchers moved into a `windows` folder.
- **Changed:** the script's messages show the right command to run again,
  whether it was piped from GitHub or downloaded.
- **Fixed:** GitHub links in the README and guide.

## v2.0 — 2026-09-27

First public release.

- **Fixed:** `restore` could put back a `queries.js` from an older Pi-hole
  version. The backup is now refreshed from the current stock file every time
  the patch is applied.
- **Added:** `pihole-patch-config.bat`, so your Pi's username and address are
  set in one place.
- **Added:** `status` now reports whether the installed Pi-hole version can be
  patched.
- **Added:** `PIHOLE_QUERIES_JS` setting for Pi-hole installs with the web
  files in a non-standard place.
- **Added:** the Windows launcher repairs Windows line endings in the script
  before running it.
- **Added:** both `.bat` files check that the OpenSSH Client is installed.
- **Changed:** the setup validates the sudo rule before installing it, so a
  bad rule can't lock you out of `sudo`.
- **Changed:** re-running the setup no longer adds duplicate SSH keys.
- **Changed:** the temporary file is cleaned up if patching fails.

## v1.0

- Private version for Pi-hole v6.5.

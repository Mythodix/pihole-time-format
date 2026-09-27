# Changelog

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

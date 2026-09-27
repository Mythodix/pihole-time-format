# Pi-hole Time Format Patch

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Pi-hole v6](https://img.shields.io/badge/Pi--hole-v6-96060C.svg)

Replaces the timestamps in Pi-hole's **Query Log** with easier-to-read labels
like **Today 6:42:01 PM** and **Yesterday 11:15:32 PM**.

![Before and after: stock Pi-hole timestamps next to the patched labels](docs/before-after.png)

| Stock Pi-hole           | Patched                  |
|-------------------------|--------------------------|
| `2026-05-23 18:42:01`   | `Today 6:42:01 PM`       |
| `2026-05-22 23:15:32`   | `Yesterday 11:15:32 PM`  |
| `2026-04-16 09:03:10`   | `Apr 16, 9:03:10 AM`     |
| `2025-12-03 16:20:00`   | `Dec 3 2025, 4:20:00 PM` |

Hover over any time to see the original full timestamp. Sorting, searching,
exporting and the date-range picker all keep working as normal.

Tested with **Pi-hole Web v6.5** (Core v6.4.2, FTL v6.6.2).

📖 **Visual guide:** https://YOUR-GITHUB-USERNAME.github.io/pihole-time-format/

---

## Download

Pick whichever suits you.

**Option A: straight onto the Pi (quickest, any OS)**

Log into your Pi over SSH and paste this. It downloads the script and applies
the patch:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-GITHUB-USERNAME/pihole-time-format/main/pihole-time-format.sh -o ~/pihole-time-format.sh
chmod +x ~/pihole-time-format.sh
sudo ~/pihole-time-format.sh apply
```

Then press **Ctrl+F5** on the Pi-hole Query Log tab. After future Pi-hole
updates, just run the last line again.

**Option B: the Windows one-click launcher**

1. Click the green **Code** button at the top of this page, then
   **Download ZIP**.
2. Right-click the downloaded ZIP and choose **Extract All**.
3. Follow [Quick start (Windows)](#quick-start-windows) below.

**Option C: with Git**

```bash
git clone https://github.com/YOUR-GITHUB-USERNAME/pihole-time-format.git
```

---

## Contents

- [Download](#download)
- [What's in the folder](#whats-in-the-folder)
- [Requirements](#requirements)
- [Quick start (Windows)](#quick-start-windows)
- [After every Pi-hole update](#after-every-pi-hole-update)
- [Using it from macOS or Linux](#using-it-from-macos-or-linux)
- [Script commands](#script-commands)
- [How it works](#how-it-works)
- [Security notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [Uninstalling](#uninstalling)

---

## What's in the folder

Keep the four script files together in one folder.

| File | Where it runs | What it does |
|------|---------------|--------------|
| `pihole-patch-config.bat` | Nothing; you edit it | Your Pi's username and address. **Edit this first.** |
| `setup-pihole-ssh.bat` | Windows, once | Optional. Sets up key login so patching needs no passwords. |
| `apply-pihole-time-format.bat` | Windows | Uploads the patch script to the Pi and runs it. Use after every Pi-hole update. |
| `pihole-time-format.sh` | The Pi | The patch itself. Can also be run by hand on the Pi. |
| `docs/index.html` | Your browser | A visual quick-reference guide. Also online via GitHub Pages (link at the top). |
| `docs/before-after.png` | — | The preview image used in this README. |

---

## Requirements

**On the Pi**

- Pi-hole v6 (web interface v6.5 tested)
- SSH turned on, and an account that can use `sudo`
- `python3` (already installed on Raspberry Pi OS and most Debian-based systems)

**On Windows**

- Windows 10 or 11 with the **OpenSSH Client**. It's installed by default on
  current versions. To check, open Command Prompt and type `ssh`. If you get
  "not recognized", add it from
  **Settings > System > Optional features > Add a feature > OpenSSH Client**.

---

## Quick start (Windows)

### 1. Edit the config file

Right-click `pihole-patch-config.bat` and choose **Edit** (or open it in
Notepad). Change these two lines and save:

```bat
set "PI_USER=pi"          <- the username you log into the Pi with
set "PI_HOST=pi.hole"     <- the Pi's IP address, e.g. 192.168.1.50
```

`pi.hole` works as the address if your PC already uses Pi-hole for DNS.
If you're not sure, use the IP address shown on the Pi-hole dashboard.

### 2. (Optional) Set up password-free patching

Double-click `setup-pihole-ssh.bat`. You'll type your Pi password twice:
once to install the key, and once for sudo. After that, patching never asks
for a password.

Skip this step if you don't mind typing your password each time. Read
[Security notes](#security-notes) before running it.

### 3. Apply the patch

Double-click `apply-pihole-time-format.bat` and wait for `=== Done ===`.

### 4. Refresh the browser

On the Pi-hole Query Log tab, press **Ctrl+F5** (a normal refresh can keep
showing the old, cached version).

---

## After every Pi-hole update

Updating Pi-hole (`pihole -up`) replaces the patched file with a fresh stock
copy, so the old timestamps come back. To fix it:

1. Double-click `apply-pihole-time-format.bat`
2. Press **Ctrl+F5** on the Pi-hole tab

If a Pi-hole update ever changes the Query Log's code so much that the patch
can't find its place, the script stops without changing anything and tells
you. See [Troubleshooting](#troubleshooting).

---

## Using it from macOS or Linux

The `.bat` files are Windows-only, but the patch script works from any
computer with `ssh`. Replace `pi@192.168.1.50` with your own login:

```bash
scp pihole-time-format.sh pi@192.168.1.50:~/
ssh -t pi@192.168.1.50 "chmod +x ~/pihole-time-format.sh && sudo ~/pihole-time-format.sh apply"
```

Or copy the script onto the Pi any way you like and run it there directly:

```bash
chmod +x pihole-time-format.sh
sudo ./pihole-time-format.sh apply
```

---

## Script commands

Run these on the Pi (for example after `ssh pi@192.168.1.50`):

| Command | What it does |
|---------|--------------|
| `sudo ~/pihole-time-format.sh apply` | Patches the Query Log. Saves a backup of the stock file first. |
| `sudo ~/pihole-time-format.sh restore` | Puts the stock file back from the backup. |
| `~/pihole-time-format.sh status` | Shows whether it's patched, and whether this Pi-hole version can be patched. |

**If Pi-hole's web files are somewhere unusual**, point the script at the
right `queries.js`:

```bash
sudo PIHOLE_QUERIES_JS=/path/to/queries.js ~/pihole-time-format.sh apply
```

---

## How it works

Pi-hole's Query Log is a table, and each column has a small JavaScript
function that decides how its values are shown. For the Time column, that
function lives in:

```
/var/www/html/admin/scripts/js/queries.js
```

and formats each timestamp as `YYYY-MM-DD HH:mm:ss`.

The patch script:

1. Checks that file isn't already patched.
2. Copies it to `queries.js.orig` as a backup.
3. Finds the Time column's display function and replaces just that function
   with one that produces the friendlier labels.
4. Tags the file with the comment `// PI-HOLE-TIME-FORMAT-PATCHED` so it can
   tell later whether the patch is in place.
5. Keeps the file's original owner and permissions.

The new function only changes what's **displayed**. When Pi-hole asks for a
value to sort, search or export, it still gets the raw timestamp, which is
why those features keep working.

The edit is done safely: the patched version is written to a temporary file
first and only moved into place if every step succeeded. If anything goes
wrong, the original file isn't touched.

Nothing is installed on the Pi apart from the script in your home folder
(and, if you ran the setup, one SSH key and one sudo rule).

---

## Security notes

These only apply if you run `setup-pihole-ssh.bat`.

**The sudo rule.** Setup adds `/etc/sudoers.d/pihole-timeformat`, which lets
your account run `~/pihole-time-format.sh` as root without a password, and
nothing else. Because that script sits in your home folder, your account can
edit it, which means anything written into it would also run as root without
a password. On a home Pi where your account already has full `sudo` access,
this doesn't give you anything you didn't already have. **Don't use it on a
Pi that other people log into.** Skip the setup and type your password
instead.

**The SSH key.** Setup creates a key with no passphrase (or reuses your
existing `id_ed25519` key), so patching can run without any typing. Anyone
who can use your Windows account could use that key to log into the Pi.

**No passwords are stored** in any of these files. You type them at the
prompts, and they're never saved.

---

## Troubleshooting

**"ssh is not recognized as an internal or external command"**
The OpenSSH Client isn't installed. See [Requirements](#requirements).

**"Permission denied, please try again"**
Wrong password, or the wrong `PI_USER` in `pihole-patch-config.bat`.

**"Could not resolve hostname" or "Connection timed out"**
The `PI_HOST` in `pihole-patch-config.bat` is wrong, or the Pi is off. Try
the Pi's IP address instead of `pi.hole`.

**"sudo: a terminal is required to read the password"**
The `-t` was removed from the `ssh` line in `apply-pihole-time-format.bat`.
Put it back: `ssh -t %PI_USER%@%PI_HOST% ...`

**It still asks for a password after running the setup**
- Run `setup-pihole-ssh.bat` again and check each step says it worked.
- If your existing `id_ed25519` key has a passphrase, Windows will ask for
  that instead. Either use the Windows `ssh-agent` service or delete the key
  and run setup again to make a new one.
- If your Pi username isn't the same as its home folder name
  (`/home/<username>`), the sudo rule won't match. Edit
  `/etc/sudoers.d/pihole-timeformat` with `sudo visudo -f /etc/sudoers.d/pihole-timeformat`
  to use the right path.

**"Already patched. Nothing to do."**
The patch is already in place. If the browser still shows the old format,
press **Ctrl+F5**.

**The browser still shows the old format**
Press **Ctrl+F5** on the Pi-hole tab. If that doesn't help, run
`~/pihole-time-format.sh status` on the Pi to confirm it's patched.

**"Could not find the Time column" / "Patchable: NO"**
A Pi-hole update has changed the Query Log's code, and this script needs
updating to match. Nothing was changed on your Pi. Run
`sudo ~/pihole-time-format.sh restore` if the Query Log looks broken for any
reason.

**"queries.js not found"**
Pi-hole's web files have moved. The error message shows the command to find
the file, and how to point the script at it with `PIHOLE_QUERIES_JS`.

**"bash\r: No such file or directory"** (when running the script by hand)
The script was saved with Windows line endings. Fix it on the Pi with
`sed -i 's/\r$//' ~/pihole-time-format.sh`. The `.bat` launcher does this
for you automatically.

**The Query Log looks broken after patching**
Run `sudo ~/pihole-time-format.sh restore`, then **Ctrl+F5**. If the backup
is missing, `sudo pihole -r` (Repair) reinstalls Pi-hole's stock web files.

---

## Uninstalling

Run these on the Pi.

**1. Put the stock timestamps back**

```bash
sudo ~/pihole-time-format.sh restore
```

(The next Pi-hole web interface update would also replace the file with a stock copy.)

**2. Remove the sudo rule** (only if you ran the setup)

```bash
sudo rm /etc/sudoers.d/pihole-timeformat
```

**3. Remove the SSH key** (only if you ran the setup, and you don't use this
key to log into the Pi for anything else)

```bash
sed -i '/pihole-time-format$/d' ~/.ssh/authorized_keys
```

This removes keys created by the setup, which are labelled
`pihole-time-format`. If the setup reused a key you already had, remove that
line by hand with `nano ~/.ssh/authorized_keys`.

**4. Delete the script and backup**

```bash
rm ~/pihole-time-format.sh
sudo rm /var/www/html/admin/scripts/js/queries.js.orig
```

---

## Contributing

Found a bug, or did a Pi-hole update break the patch? Please
[open an issue](https://github.com/YOUR-GITHUB-USERNAME/pihole-time-format/issues) and include:

- the output of `pihole -v`
- the output of `~/pihole-time-format.sh status`
- any error message you saw

Pull requests are welcome.

## License

[MIT](LICENSE). Free to use, change and share.

Not affiliated with or endorsed by the Pi-hole project.

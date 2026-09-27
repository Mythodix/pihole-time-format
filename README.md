# Pi-hole Time Format Patch

**Makes Pi-hole's Query Log easy to read at a glance.**
Timestamps like `2026-09-27 18:42:01` become **Today 6:42:01 PM**.

![Before and after: stock Pi-hole timestamps next to the patched labels](docs/before-after.png)

- Shows **Today**, **Yesterday**, or the date, with a 12-hour clock
- Hover any time to see the original timestamp
- Sorting, search and export work exactly as before
- One command to install, one command to undo
- For **Pi-hole v6** (tested on web interface v6.5)

---

## Install

On your Pi, paste this one line:

```bash
curl -fsSL https://raw.githubusercontent.com/Mythodix/pihole-time-format/main/pihole-time-format.sh | sudo bash -s apply
```

Then open the Pi-hole **Query Log** and press **Ctrl+F5** to refresh.

That's it.

<details>
<summary><b>How do I get to my Pi's command line?</b></summary>

<br>

From another computer on your network, open a terminal
(**Windows Terminal** or **Command Prompt** on Windows, **Terminal** on Mac)
and log in with:

```bash
ssh pi@192.168.1.50
```

Replace `pi` with your Pi's username and `192.168.1.50` with its IP address
(it's shown on the Pi-hole dashboard). Type your Pi password when asked, then
paste the install line.

</details>

---

## After a Pi-hole update

Pi-hole updates put the old timestamps back. Just run the same install line
again, then press **Ctrl+F5**.

---

## Undo

```bash
curl -fsSL https://raw.githubusercontent.com/Mythodix/pihole-time-format/main/pihole-time-format.sh | sudo bash -s restore
```

This puts Pi-hole's original file back exactly as it was.

---

## Questions

<details>
<summary><b>Is it safe?</b></summary>

<br>

It changes one display setting in one file of Pi-hole's web page. It doesn't
touch blocking, DNS, your settings or your lists. A backup of the original
file is saved first, and if anything goes wrong while patching, the original
is left untouched. The whole script is
[one readable file](pihole-time-format.sh) if you'd like to check it before
running it.

</details>

<details>
<summary><b>Which Pi-hole versions does it work with?</b></summary>

<br>

Pi-hole v6. It was tested on web interface v6.5 (Core v6.4.2, FTL v6.6.2).
Check yours with `pihole -v`. If a future update changes things too much,
the script stops and tells you, without changing anything.

</details>

<details>
<summary><b>It said "Already patched" but I still see the old times</b></summary>

<br>

Your browser is showing a saved copy of the page. Press **Ctrl+F5** on the
Query Log tab (**Cmd+Shift+R** on a Mac).

</details>

<details>
<summary><b>It said "Could not find the Time column" or "Patchable: NO"</b></summary>

<br>

A Pi-hole update has changed the Query Log's code and this patch needs
updating to match. Nothing was changed on your Pi. Please
[open an issue](https://github.com/Mythodix/pihole-time-format/issues)
with the output of `pihole -v`.

</details>

<details>
<summary><b>I'd rather download it than pipe it into bash</b></summary>

<br>

On the Pi:

```bash
curl -fsSL https://raw.githubusercontent.com/Mythodix/pihole-time-format/main/pihole-time-format.sh -o ~/pihole-time-format.sh
less ~/pihole-time-format.sh                  # read it first if you like (q to quit)
sudo bash ~/pihole-time-format.sh apply
```

Other commands: `sudo bash ~/pihole-time-format.sh restore` to undo, and
`bash ~/pihole-time-format.sh status` to check whether it's patched.

</details>

---

## More

<details>
<summary><b>Windows one-click launcher (optional)</b></summary>

<br>

If you'd rather not use the Pi's command line, the `windows` folder has
double-click launchers that do it for you from a Windows PC.

1. Click the green **Code** button at the top of this page, then
   **Download ZIP**, and extract it.
2. In the `windows` folder, right-click `pihole-patch-config.bat` and choose
   **Edit**. Set your Pi's username and IP address, then save.
3. Double-click `apply-pihole-time-format.bat` and type your Pi password
   when asked. Wait for `=== Done ===`.
4. Press **Ctrl+F5** on the Pi-hole Query Log.

After Pi-hole updates, just double-click `apply-pihole-time-format.bat`
again.

**No more password prompts (optional):** double-click `setup-pihole-ssh.bat`
once. You'll type your password twice, then never again for this patch.
Please read the security note below first.

**Needs:** Windows 10 or 11 with the OpenSSH Client, which is installed by
default. If you get "ssh is not recognized", add it from
**Settings > System > Optional features > Add a feature > OpenSSH Client**.

</details>

<details>
<summary><b>Troubleshooting</b></summary>

<br>

**"Permission denied"** — wrong password, or the wrong username.

**"Could not resolve hostname" or "Connection timed out"** — wrong Pi
address, or the Pi is off. Use the IP address shown on the Pi-hole
dashboard.

**"queries.js not found"** — Pi-hole's web files are somewhere unusual.
Find them with `sudo find / -path '*scripts/js/queries.js' 2>/dev/null`,
then run
`sudo PIHOLE_QUERIES_JS=/path/to/queries.js bash pihole-time-format.sh apply`.

**"python3: command not found"** — install it with `sudo apt install python3`.

**"sudo: a terminal is required to read the password"** (Windows launcher) —
the `-t` was removed from the `ssh` line in `apply-pihole-time-format.bat`.
Put it back.

**Still asks for a password after the Windows setup** — run
`setup-pihole-ssh.bat` again. If your existing `id_ed25519` key has a
passphrase, Windows asks for that instead; delete the key and run setup
again. The setup assumes your Pi home folder is `/home/<username>`.

**"bash\r: No such file or directory"** — the script was saved with Windows
line endings. Fix it on the Pi with `sed -i 's/\r$//' ~/pihole-time-format.sh`.

**The Query Log looks broken** — run the [Undo](#undo) line. If there's no
backup, `sudo pihole -r` (Repair) reinstalls Pi-hole's original web files.

</details>

<details>
<summary><b>How it works</b></summary>

<br>

The Query Log's Time column is drawn by a small JavaScript function in
`/var/www/html/admin/scripts/js/queries.js`, which formats each timestamp as
`YYYY-MM-DD HH:mm:ss`. The script:

1. Saves a copy of that file as `queries.js.orig`.
2. Replaces just the Time column's display function with one that shows
   Today / Yesterday / date labels.
3. Marks the file with `// PI-HOLE-TIME-FORMAT-PATCHED` so it knows it's
   been patched.
4. Keeps the file's original owner and permissions.

The patched copy is written to a temporary file and only moved into place if
every step worked. The new function only changes what's displayed; sorting,
search and export still use the raw timestamp.

Pi-hole updates replace `queries.js`, which is why the patch has to be run
again after updating.

</details>

<details>
<summary><b>Security note (Windows password-free setup only)</b></summary>

<br>

`setup-pihole-ssh.bat` adds a rule at `/etc/sudoers.d/pihole-timeformat`
that lets your account run `~/pihole-time-format.sh` as root without a
password, and nothing else. Your account can edit that file, so anything
written into it would also run as root. On a home Pi where you already have
`sudo`, that adds nothing new. **Don't use it on a Pi other people log
into.**

It also creates an SSH key without a passphrase, so anyone who can use your
Windows account could log into the Pi with it.

No passwords are stored in any file in this project.

</details>

<details>
<summary><b>Full uninstall</b></summary>

<br>

On the Pi:

```bash
curl -fsSL https://raw.githubusercontent.com/Mythodix/pihole-time-format/main/pihole-time-format.sh | sudo bash -s restore
sudo rm -f /var/www/html/admin/scripts/js/queries.js.orig
rm -f ~/pihole-time-format.sh
```

If you used the Windows password-free setup, also run:

```bash
sudo rm /etc/sudoers.d/pihole-timeformat
sed -i '/pihole-time-format$/d' ~/.ssh/authorized_keys
```

The second line removes only keys the setup created. If it reused a key you
already had, remove that one by hand with `nano ~/.ssh/authorized_keys` if
you want to.

</details>

---

Found a problem? [Open an issue](https://github.com/Mythodix/pihole-time-format/issues)
and include the output of `pihole -v`.

[MIT License](LICENSE) · Not affiliated with the Pi-hole project.

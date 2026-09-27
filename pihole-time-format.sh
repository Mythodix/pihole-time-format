#!/bin/bash
#
# pihole-time-format.sh  (v2.0)
# -----------------------------
# Replaces Pi-hole's "YYYY-MM-DD HH:mm:ss" timestamps in the Query Log with
# friendlier labels, plus a hover tooltip showing the original time:
#
#     Today 6:42:01 PM
#     Yesterday 11:15:32 PM
#     Apr 16, 9:03:10 AM
#     Dec 3 2025, 4:20:00 PM      (older than this year)
#
# How it works:
#   - The Query Log's Time column is drawn by a small "render" function in
#     queries.js, which formats the timestamp with moment.js.
#   - In Pi-hole v6, FTL serves the web interface directly from
#     /var/www/html/admin, so this file can be edited in place.
#   - This script swaps that one render function for a smarter one.
#     Sorting, search and export keep working, because the new function only
#     changes what is DISPLAYED. Everything else still gets the raw Unix
#     timestamp.
#
# Usage (on the Pi):
#   sudo ./pihole-time-format.sh apply     # patch queries.js
#   sudo ./pihole-time-format.sh restore   # put the stock file back
#   ./pihole-time-format.sh status         # patched? patchable?
#
# After applying, hard-refresh the Pi-hole tab in your browser (Ctrl+F5).
#
# Pi-hole updates overwrite queries.js, so re-run "apply" after every
# `pihole -up`.
#
# If your queries.js lives somewhere else, point the script at it:
#   sudo PIHOLE_QUERIES_JS=/path/to/queries.js ./pihole-time-format.sh apply
#
# Tested against Pi-hole Web v6.5. Handles both the v6 render(data, type)
# style and the older render: function (data, type) style.

set -euo pipefail

TARGET="${PIHOLE_QUERIES_JS:-/var/www/html/admin/scripts/js/queries.js}"
BACKUP="${TARGET}.orig"
MARKER="// PI-HOLE-TIME-FORMAT-PATCHED"

# The replacement render function, kept on one line.
NEW_RENDER='render(data, type) { if (type !== "display") return data; var dt = moment.unix(data); var now = moment(); var time = dt.format("h:mm:ss A"); var label; if (dt.isSame(now, "day")) { label = "Today " + time; } else if (dt.isSame(now.clone().subtract(1, "day"), "day")) { label = "Yesterday " + time; } else if (dt.isSame(now, "year")) { label = dt.format("MMM D") + ", " + time; } else { label = dt.format("MMM D YYYY") + ", " + time; } return "<span title=\"" + dt.format("YYYY-MM-DD HH:mm:ss") + "\">" + label + "</span>"; },'

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This command must be run as root. Try: sudo $0 ${1:-}" >&2
        exit 1
    fi
}

require_target() {
    if [[ ! -f "$TARGET" ]]; then
        echo "Error: $TARGET not found." >&2
        echo "Find it with:  sudo find / -path '*scripts/js/queries.js' 2>/dev/null" >&2
        echo "Then run with: sudo PIHOLE_QUERIES_JS=<path> $0 apply" >&2
        exit 1
    fi
}

require_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Error: python3 is required but was not found." >&2
        echo "Install it with: sudo apt install python3" >&2
        exit 1
    fi
}

is_patched() {
    grep -qF "$MARKER" "$TARGET"
}

has_time_column() {
    grep -Eq 'data:[[:space:]]*"time"' "$TARGET"
}

cmd_status() {
    require_target
    echo "File: $TARGET"
    if is_patched; then
        echo "STATUS: PATCHED"
        if [[ -f "$BACKUP" ]]; then
            echo "Backup: $BACKUP"
        else
            echo "WARNING: no backup found at $BACKUP (restore won't work)."
        fi
    else
        echo "STATUS: NOT PATCHED (Pi-hole's stock format)"
        if has_time_column; then
            echo "Patchable: yes (Time column found)"
        else
            echo "Patchable: NO. Pi-hole's Query Log code has changed and this"
            echo "script needs updating before it can patch this version."
        fi
    fi
}

cmd_apply() {
    require_root apply
    require_target
    require_python

    if is_patched; then
        echo "Already patched. Nothing to do."
        echo "To re-apply from scratch: sudo $0 restore, then sudo $0 apply"
        exit 0
    fi

    # The file isn't patched, so it's Pi-hole's current stock copy. Always
    # refresh the backup from it, so "restore" never puts back a copy from an
    # older Pi-hole version.
    cp -p "$TARGET" "$BACKUP"
    echo "Backup saved: $BACKUP"

    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT

    # Python does the edit, because the render function contains nested
    # braces that sed can't match safely.
    python3 - "$TARGET" "$TMP" "$NEW_RENDER" "$MARKER" <<'PYEOF'
import re, sys
src_path, out_path, new_render, marker = sys.argv[1:5]

with open(src_path, "r", encoding="utf-8") as f:
    text = f.read()

# Anchor on the Time column definition.
anchor = re.search(r'data:\s*"time"\s*,', text)
if not anchor:
    sys.stderr.write("ERROR: Could not find the Time column in queries.js.\n")
    sys.stderr.write("Pi-hole's web UI has changed; this script needs updating.\n")
    sys.exit(2)

# Find the render function that follows it. Matches both
#   render(data, type) {             (Pi-hole v6)
#   render: function (data, type) {  (older versions)
m = re.search(r'render\s*(?::\s*function\s*)?\([^)]*\)\s*\{', text[anchor.end():])
if not m:
    sys.stderr.write("ERROR: No render function found after the Time column.\n")
    sys.exit(2)

# Make sure the render function belongs to the Time column and not a later one.
between = text[anchor.end():anchor.end() + m.start()]
if re.search(r'\bdata:\s*"', between):
    sys.stderr.write("ERROR: The Time column has no render function of its own.\n")
    sys.stderr.write("Pi-hole's web UI has changed; this script needs updating.\n")
    sys.exit(2)

start = anchor.end() + m.start()
brace_start = anchor.end() + m.end() - 1

# Walk forward counting braces to find the end of the function.
depth = 0
i = brace_start
while i < len(text):
    if text[i] == '{':
        depth += 1
    elif text[i] == '}':
        depth -= 1
        if depth == 0:
            break
    i += 1
else:
    sys.stderr.write("ERROR: Unmatched braces in the render function.\n")
    sys.exit(2)

# Swallow the trailing comma after the closing brace.
end = i + 1
while end < len(text) and text[end] in ' \t':
    end += 1
if end < len(text) and text[end] == ',':
    end += 1

new_text = text[:start] + new_render + " " + marker + text[end:]

with open(out_path, "w", encoding="utf-8") as f:
    f.write(new_text)
PYEOF

    # Keep the original file's permissions and owner.
    chmod --reference="$TARGET" "$TMP"
    chown --reference="$TARGET" "$TMP"
    mv "$TMP" "$TARGET"
    trap - EXIT

    echo "Patched: $TARGET"
    echo
    echo "Now hard-refresh the Pi-hole tab in your browser (Ctrl+F5)."
    echo "If anything looks wrong: sudo $0 restore"
}

cmd_restore() {
    require_root restore

    if [[ ! -f "$BACKUP" ]]; then
        echo "Error: no backup at $BACKUP" >&2
        echo "Either nothing was patched, or the backup was deleted." >&2
        echo "Running 'sudo pihole -r' (repair) will also restore stock files." >&2
        exit 1
    fi

    cp -p "$BACKUP" "$TARGET"
    echo "Restored stock file: $TARGET"
    echo "Hard-refresh your browser tab (Ctrl+F5) to see the change."
}

case "${1:-}" in
    apply)   cmd_apply ;;
    restore) cmd_restore ;;
    status)  cmd_status ;;
    *)
        cat <<USAGE
Usage: sudo $0 {apply|restore|status}

  apply    Replace the Query Log's timestamp format with friendly labels
           ("Today 6:42:01 PM", "Yesterday 9:15:32 AM", "Apr 16, 11:03:10 AM").
           Sorting and the date range picker keep working.

  restore  Put Pi-hole's stock queries.js back from the backup.

  status   Show whether the file is patched, and whether it can be.
USAGE
        exit 1
        ;;
esac

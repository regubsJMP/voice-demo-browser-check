#!/bin/bash
# First visit of the real demo site on a fresh macOS VM, in Safari or Chrome launched the normal way: log in, answer the browser's own
# microphone prompt, press the page buttons — all with real mouse clicks found by text on the screen (clicktext, macOS Vision OCR).
# The site address and the demo login come from repository secrets; nothing about the site is printed (logs are public) and the
# screenshots leave the VM only encrypted (shots.enc).
#   SITE_URL=… DEMO_USER=… DEMO_PASS=… bash site.sh safari | chrome
set -u
B="${1:-safari}"; ROOT="$(cd "$(dirname "$0")" && pwd)"; OUT="$ROOT/out/$B"; mkdir -p "$OUT"
n=0
step() { echo "== $(date -u +%H:%M:%S) $*"; }
shot() { n=$((n + 1)); screencapture -x "$OUT/$(printf %02d $n)-$1.png" && echo "   shot $n: $1"; }
key() { osascript -e "tell application \"System Events\" to keystroke \"$1\"" >/dev/null || echo "   keystroke failed"; }
keycode() { osascript -e "tell application \"System Events\" to key code $1" >/dev/null; }
# click the centre of a text on the screen (real mouse); prints only the label, never the text of the page
clickt() { local f="${RUNNER_TEMP:-/tmp}/find.png" xy; screencapture -x "$f"; xy=$("$ROOT/clicktext" "$f" "$1") \
  && { cliclick "c:${xy% *},${xy#* }"; echo "   clicked: $2"; return 0; } || { echo "   not found: $2"; return 1; }; }
step "launch $B"
if [ "$B" = safari ]; then APP=Safari; open -a Safari "$SITE_URL/login"
else APP="Google Chrome"; nohup "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --user-data-dir=/tmp/chrome-site --no-first-run \
  --no-default-browser-check --disable-features=MediaRouter,DialMediaRouteProvider "$SITE_URL/login" >/dev/null 2>&1 &
  # MediaRouter off (25.10, site run 1): Chrome's cast discovery raised macOS «Allow … to find devices on local networks?» over the page
fi
sleep 12; open -a "$APP"; sleep 2; shot login
step "log in (keyboard into the form)"
clickt "username" "username field" || clickt "login" "username field"
key "$DEMO_USER"; keycode 48; key "$DEMO_PASS"; keycode 36
sleep 6
# a new address (e.g. a version preview) makes both browsers offer to save the password — the dialog covers the page and takes clicks
# (site run 3, 25.10): close it first
if [ "$B" = safari ]; then clickt "Not Now" "Safari: save password — Not Now"; else clickt "No Thanks" "Chrome: save password — No Thanks"; fi; sleep 1.5
shot menu-mic-prompt
step "browser microphone prompt on the tile page (before any click) → Allow"
if [ "$B" = safari ]; then clickt "Allow" "Allow (Safari prompt)"; else clickt "Allow this time" "Allow this time (Chrome prompt)"; fi
sleep 3; shot menu-after-allow
# 25.10: one button, three states — «Turn on the voice guide» (the browser blocked the voice), «Mute voice guide» (the voice started
# by itself; pulses while it speaks), «Unmute voice guide» (muted by the person)
step "voice guide button: Turn on (blocked) or Mute → Unmute (voice started by itself)"
if clickt "Turn on the voice guide" "Turn on the voice guide (voice was blocked)"; then sleep 3; shot menu-after-voice-button
  clickt "Mute voice guide" "Mute voice guide (after turning on)" && { sleep 1.5; shot menu-muted; clickt "Unmute voice guide" "Unmute voice guide" && { sleep 3; shot menu-unmuted; }; }
elif clickt "Mute voice guide" "Mute voice guide (voice started by itself)"; then sleep 1.5; shot menu-muted
  clickt "Unmute voice guide" "Unmute voice guide" && { sleep 3; shot menu-unmuted; }
fi
step "tile: Full demo → full screen + intro voice, no second prompt"
clickt "Start the full demo" "Full demo tile"; sleep 4; shot full-intro; sleep 6; shot full-intro-10s
step "All demos → tiles → Simplified demo"
keycode 53; sleep 2; clickt "All demos" "All demos"; sleep 5; shot menu-again
clickt "Start the simplified demo" "Simplified demo tile"; sleep 4; shot simple-form
# 25.10: console tile in full screen → «Import leads» opens the in-page file list (no system file window, which takes Chrome out of
# full screen) → a sample file → rows; then «Browse your computer…» (system window) → cancel → is full screen back, or after a click?
# Whether the page is in full screen is read from the screen: the browser's address bar (domain text) is hidden in full screen.
fs_state() { local f="${RUNNER_TEMP:-/tmp}/fs.png" host="${SITE_URL#*//}"; host="${host%%.*}"; screencapture -x "$f"   # host: from the secret, never printed
  # entering full screen Chrome shows a bubble «<host> – To exit full screen, press esc» — it carries the host too (site run 2, 25.10)
  if "$ROOT/clicktext" "$f" "exit full screen" >/dev/null 2>&1; then echo "   $1: full-screen bubble — full screen"
  elif "$ROOT/clicktext" "$f" "$host" >/dev/null 2>&1; then echo "   $1: address bar visible — NOT full screen"; else echo "   $1: address bar hidden — full screen"; fi; }
clickt "Don't Allow" "macOS local-network prompt dismissed" && sleep 1   # if a system prompt still covers the page
step "All demos → console tile (full screen)"
keycode 53; sleep 2; clickt "All demos" "All demos"; sleep 5
clickt "Open the console" "Console tile"; sleep 5; shot console; fs_state "console opened"
step "Import leads → in-page list → sample file"
clickt "Import leads" "Import leads"; sleep 2; shot import-list; fs_state "in-page file list"
clickt "dubai-expat-fair-leads" "sample file"; sleep 8; shot import-done; fs_state "after sample import"
step "Import leads → Browse your computer… (system window) → cancel"
clickt "Import leads" "Import leads"; sleep 2
clickt "Browse your computer" "Browse your computer"; sleep 3; shot system-window; fs_state "system file window open"
keycode 53; sleep 3; shot after-cancel; fs_state "after cancel"
cliclick "c:700,600"; sleep 3; shot after-click; fs_state "after one click on the page"
step "done: $n screenshots"

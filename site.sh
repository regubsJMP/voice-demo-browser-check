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
  --no-default-browser-check "$SITE_URL/login" >/dev/null 2>&1 &
fi
sleep 12; open -a "$APP"; sleep 2; shot login
step "log in (keyboard into the form)"
clickt "username" "username field" || clickt "login" "username field"
key "$DEMO_USER"; keycode 48; key "$DEMO_PASS"; keycode 36
sleep 6; shot menu-mic-prompt
step "browser microphone prompt on the tile page (before any click) → Allow"
if [ "$B" = safari ]; then clickt "Allow" "Allow (Safari prompt)"; else clickt "Allow this time" "Allow this time (Chrome prompt)"; fi
sleep 3; shot menu-after-allow
step "voice guide button (only where the browser blocked the voice)"
clickt "Turn on the voice guide" "voice guide button" && { sleep 3; shot menu-after-voice-button; }
step "tile: Full demo → full screen + intro voice, no second prompt"
clickt "Start the full demo" "Full demo tile"; sleep 4; shot full-intro; sleep 6; shot full-intro-10s
step "All demos → tiles → Simplified demo"
keycode 53; sleep 2; clickt "All demos" "All demos"; sleep 5; shot menu-again
clickt "Start the simplified demo" "Simplified demo tile"; sleep 4; shot simple-form
step "done: $n screenshots"

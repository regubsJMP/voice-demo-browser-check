#!/bin/bash
# Runs on a GitHub macOS runner: opens probe/mac.html in Safari or Chrome (normal launch, no WebDriver — WebDriver sessions
# auto-grant the microphone and never show the prompt), presses keys through System Events (real key presses = user gestures)
# and takes full-screen screenshots, so the browser's own UI (permission prompts, full screen) is visible.
#   bash run.sh safari | chrome
set -u
B="${1:-safari}"; ROOT="$(cd "$(dirname "$0")" && pwd)"; OUT="$ROOT/out/$B"; mkdir -p "$OUT"
(cd "$ROOT/probe" && python3 -m http.server 8000 >/dev/null 2>&1 &)
sleep 1
n=0
shot() { n=$((n + 1)); screencapture -x "$OUT/$(printf %02d $n)-$1.png" && echo "shot $n: $1"; }
key() { osascript -e "tell application \"System Events\" to keystroke \"$1\"" || echo "keystroke $1 failed"; }
esc() { osascript -e 'tell application "System Events" to key code 53' || echo "esc failed"; }
URL=http://localhost:8000/mac.html
if [ "$B" = safari ]; then APP=Safari; open -a Safari "$URL"
else APP="Google Chrome"; open -na "Google Chrome" --args --user-data-dir=/tmp/chrome-probe --no-first-run --no-default-browser-check "$URL"; fi
front() { open -a "$APP"; sleep 1.5; }
reload() { front; osascript -e 'tell application "System Events" to keystroke "r" using command down'; sleep 3; }
sleep 12; front; shot open
# 1 — full screen first, then the microphone: is the permission prompt visible while in full screen?
key 1; sleep 3; shot k1-fs-then-mic-3s; sleep 6; shot k1-fs-then-mic-9s
esc; sleep 3; shot k1-after-esc; sleep 4; shot k1-after-esc-7s
# 2 — microphone first, then full screen after the answer (nobody answers here: we only look at the prompt)
reload; key 2; sleep 3; shot k2-mic-then-fs-3s; sleep 6; shot k2-mic-then-fs-9s
esc; sleep 2
# 5 — audio: one element started in the key press, then 8 s later a new clip on it and a brand-new element
reload; key 5; sleep 10; shot k5-audio
# 6 — file picker while in full screen
reload; key 1; sleep 4; key 6; sleep 3; shot k6-picker; esc; sleep 2; shot k6-after-esc
echo "done: $n screenshots in $OUT"

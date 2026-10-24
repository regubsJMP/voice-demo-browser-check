#!/bin/bash
# Runs on a GitHub macOS runner: opens probe/mac.html in Safari or Chrome (normal launch, no WebDriver — WebDriver sessions
# auto-grant the microphone and never show the prompt), presses keys and clicks through System Events / cliclick (real input =
# user gestures) and takes full-screen screenshots, so the browser's own UI (permission prompts, full screen) is visible.
# Every scenario runs on its own origin (ports 8001…8004) — a fresh permission state, like a first visit.
#   bash run.sh safari | chrome
set -u
B="${1:-safari}"; ROOT="$(cd "$(dirname "$0")" && pwd)"; OUT="$ROOT/out/$B"; mkdir -p "$OUT"
for port in 8001 8002 8003 8004; do (cd "$ROOT/probe" && python3 -m http.server $port >/dev/null 2>&1 &); done
sleep 1
n=0
step() { echo "== $(date -u +%H:%M:%S) $*"; }
shot() { n=$((n + 1)); screencapture -x "$OUT/$(printf %02d $n)-$1.png" && echo "   shot $n: $1"; }
key() { osascript -e "tell application \"System Events\" to keystroke \"$1\"" || echo "   keystroke $1 failed"; }
esc() { osascript -e 'tell application "System Events" to key code 53' || echo "   esc failed"; }
click() { cliclick "c:$1,$2" || echo "   click $1,$2 failed"; }
if [ "$B" = safari ]; then APP=Safari; ALLOW="512,381"; open -a Safari "http://localhost:8001/mac.html"
else APP="Google Chrome"; ALLOW=""; open -na "Google Chrome" --args --user-data-dir=/tmp/chrome-probe --no-first-run --no-default-browser-check \
  "http://localhost:8001/mac.html"; fi
front() { open -a "$APP"; sleep 1.5; }
go() { front; osascript -e 'tell application "System Events" to keystroke "l" using command down'; sleep 0.5; key "localhost:$1/mac.html"
  osascript -e 'tell application "System Events" to key code 36'; sleep 4; }
allow() { if [ -n "$ALLOW" ]; then click "${ALLOW%,*}" "${ALLOW#*,}"; else echo "   (no Allow coordinates for $B yet — look at the screenshot)"; fi; }
sleep 12; front; shot open
step "S1 (8001): full screen first, then the microphone — is the prompt visible in full screen?"
key 1; sleep 3; shot s1-fs-then-mic-3s; sleep 6; shot s1-fs-then-mic-9s
esc; sleep 3; shot s1-after-esc
allow; sleep 3; shot s1-after-allow
step "S2 (8002): microphone first, Allow after ~1 s, then full screen (activation window ~5 s)"
go 8002; key 2; sleep 1.5; shot s2-prompt; allow; sleep 3; shot s2-after-allow-1s; esc; sleep 2
step "S3 (8003): microphone first, Allow after ~7 s (too late for full screen), then a click on the page background"
go 8003; key 2; sleep 7; shot s3-prompt-7s; allow; sleep 3; shot s3-after-allow-7s; click 700 600; sleep 3; shot s3-after-next-click; esc; sleep 2
step "S4 (8004): file picker while in full screen"
go 8004; key 3; sleep 3; shot s4-fullscreen; key 6; sleep 3; shot s4-picker; esc; sleep 2; shot s4-after-esc
step "S5 (8004): audio elements"
key 5; sleep 10; shot s5-audio
step "done: $n screenshots in $OUT"

#!/bin/sh
# The same probe page (probe/mac.html) in real Firefox or Chromium on Linux — Xvfb + openbox, real key presses and clicks (xdotool), no
# WebDriver — in the local Docker image drawio-playwright (Playwright 1.49: Chromium 131, Firefox). The page log goes to serve.py
# → /out/page-log.txt, screenshots of the whole screen to /out. Scenarios: the file picker in full screen, cancelled and chosen —
# plainly (key 6) and with the demo site's fix (key d: leave full screen first; back, or the next real click).
#   docker run --rm --shm-size=1g -e BROWSER=firefox|chromium -v "<mac-ci>:/p:ro" -v "<out>:/out" --entrypoint sh <image> /p/linux_x11.sh
apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq openbox xdotool >/dev/null 2>&1 || { echo "openbox / xdotool not installed"; exit 3; }
pip install -q mss >/dev/null 2>&1
(Xvfb :99 -screen 0 1366x860x24 >/dev/null 2>&1 &); sleep 1.5; export DISPLAY=:99; (openbox >/dev/null 2>&1 &); sleep 1.5
python3 /p/serve.py 8100 /p/probe /out/page-log.txt >/dev/null 2>&1 &
printf 'First name,Last name,Phone\nAva,Brooks,+971500000000\n' > /tmp/leads.csv
n=0
shot() { n=$((n + 1)); python3 -c "import mss, mss.tools; m = mss.MSS(); g = m.grab(m.monitors[0]); mss.tools.to_png(g.rgb, g.size, output='/out/$(printf %02d $n)-$1.png')"; }
URL=http://localhost:8100/mac.html
if [ "${BROWSER:-firefox}" = firefox ]; then
  FF=$(ls -d /ms-playwright/firefox-*/firefox/firefox | head -1); mkdir -p /tmp/ff
  printf '%s\n' 'user_pref("browser.shell.checkDefaultBrowser", false);' 'user_pref("browser.aboutwelcome.enabled", false);' \
    'user_pref("browser.startup.homepage_override.mstone", "ignore");' 'user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);' \
    'user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);' > /tmp/ff/user.js
  "$FF" -profile /tmp/ff -no-remote -width 1366 -height 860 "$URL?s=0" >/dev/null 2>&1 &
else
  CH=$(ls -d /ms-playwright/chromium-*/chrome-linux/chrome | head -1)
  "$CH" --no-sandbox --disable-dev-shm-usage --test-type --no-first-run --no-default-browser-check --user-data-dir=/tmp/u \
    --window-position=0,0 --window-size=1366,860 "$URL?s=0" >/dev/null 2>&1 &
fi
sleep 8
go() { xdotool key ctrl+l; sleep 0.4; xdotool type --delay 15 "$URL?s=$1"; xdotool key Return; sleep 2.5; xdotool mousemove 683 760 click 1; sleep 0.8; }
choose() { xdotool key ctrl+l; sleep 0.5; xdotool type --delay 30 "/tmp/leads.csv"; sleep 0.5; xdotool key Return; }
# $1 scenario, $2 key (6 plain | d demo fix), $3 esc | choose
pk() { go "$1"; xdotool key 3; sleep 2; xdotool key "$2"; sleep 2.5; shot "$1-picker"
  if [ "$3" = choose ]; then choose; else xdotool key Escape; fi; sleep 3; shot "$1-after"
  xdotool mousemove 683 760 click 1; sleep 2.5; shot "$1-after-click"; xdotool key Escape; sleep 1.5; }
pk L1-plain-cancel 6 esc
pk L2-plain-choose 6 choose
pk L3-demofix-cancel d esc
pk L4-demofix-choose d choose
sleep 1; echo "== page log"; cat /out/page-log.txt

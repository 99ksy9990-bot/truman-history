#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_LAST_SLIDE_TEST_PORT:-4177}"
cache_key="$(date +%s%N)"
server_log="$(mktemp)"

python3 -m http.server "$port" --bind 127.0.0.1 --directory "$project_dir" >"$server_log" 2>&1 &
server_pid=$!
cleanup() {
  kill "$server_pid" 2>/dev/null || true
  rm -f "$server_log"
}
trap cleanup EXIT

for _ in {1..40}; do
  nc -z 127.0.0.1 "$port" 2>/dev/null && break
  sleep 0.1
done

aside_output="$(aside repl "const lastPage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const lastSnap1 = await snapshot(lastPage1,{interactive:true,selector:'#bar'}); console.log(lastSnap1.tree); await lastPage1.locator('#dots button').nth(6).click(); const lastSnap2 = await snapshot(lastPage1,{selector:'.pg.on h2'}); console.log(lastSnap2.diff); await sleep(1800); const lastBefore1 = await lastPage1.locator('.pg.on h2.typing-done').count(); await lastPage1.keyboard.press('ArrowRight'); const lastSnap3 = await snapshot(lastPage1,{selector:'.pg.on h2'}); console.log(lastSnap3.diff); await sleep(80); const lastAfter1 = await lastPage1.locator('.pg.on h2.typing-done').count(); console.log({doneBefore:lastBefore1,doneAfter:lastAfter1}); if(lastBefore1!==1) throw new Error('slide 7 title did not finish before the boundary input'); if(lastAfter1!==1) throw new Error('right navigation replayed the slide 7 typewriter effect'); console.log('LAST_SLIDE_NO_REPLAY_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'LAST_SLIDE_NO_REPLAY_TEST_PASS' <<<"$aside_output"

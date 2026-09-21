#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_TYPEWRITER_TEST_PORT:-4175}"
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
  if nc -z 127.0.0.1 "$port" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

aside_output="$(aside repl "const mobilePage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const mobileSnap1 = await snapshot(mobilePage1,{interactive:true,selector:'#bar'}); console.log(mobileSnap1.tree); await mobilePage1.locator('#dots button').nth(5).click(); const mobileSnap2 = await snapshot(mobilePage1,{selector:'.pg.on h2'}); console.log(mobileSnap2.diff); await sleep(1400); const mobileCaret1 = await mobilePage1.locator('.pg.on h2 .tw').last().evaluate(el => { const style = getComputedStyle(el,'::after'); return {content:style.content,display:style.display,opacity:style.opacity,width:style.width,height:style.height}; }); const mobileViewport1 = await mobilePage1.locator('html').evaluate(el => ({width:el.clientWidth,height:el.clientHeight})); console.log({viewport:mobileViewport1,caret:mobileCaret1}); if(mobileCaret1.display!=='none' && mobileCaret1.content!=='none') throw new Error('mobile typewriter caret still exists after the title animation'); console.log('TYPEWRITER_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'TYPEWRITER_TEST_PASS' <<<"$aside_output"

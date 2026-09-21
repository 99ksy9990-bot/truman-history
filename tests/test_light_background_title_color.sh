#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_COLOR_TEST_PORT:-4172}"
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

aside_output="$(aside repl "const colorPage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const colorSnap1 = await snapshot(colorPage1,{selector:'.pg.on'}); console.log(colorSnap1.tree); const colorState1 = await colorPage1.locator('.pg.on').evaluate(el=>{const rgb=s=>s.match(/\\d+(?:\\.\\d+)?/g).slice(0,3).map(Number); const brightness=s=>rgb(s).reduce((sum,v)=>sum+v,0)/3; const stageColor=getComputedStyle(document.querySelector('#stage')).backgroundColor; const paperColor=getComputedStyle(el).backgroundColor; const heading=document.querySelector('.pg[aria-label^=\\\"1.\\\"] h1'); const emphasis=heading.querySelector('em'); return {stageColor,paperColor,stageBrightness:brightness(stageColor),paperBrightness:brightness(paperColor),headingColor:getComputedStyle(heading).color,emphasisColor:getComputedStyle(emphasis).color};}); console.log(colorState1); const colorProblems1=[]; if(colorState1.stageBrightness<190) colorProblems1.push('outer background is still dark'); if(colorState1.paperBrightness<225) colorProblems1.push('paper background is still dark'); if(colorState1.headingColor!==colorState1.emphasisColor) colorProblems1.push('slide 1 title colors are not unified'); if(colorProblems1.length) throw new Error(colorProblems1.join('; ')); await closeTab(colorPage1); console.log('LIGHT_BACKGROUND_TITLE_COLOR_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'LIGHT_BACKGROUND_TITLE_COLOR_TEST_PASS' <<<"$aside_output"

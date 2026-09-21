#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_HIGHLIGHTER_TEST_PORT:-4173}"
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

aside_output="$(aside repl "const markerPage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); await markerPage1.locator('#dots button').nth(1).click(); const markerCount1 = await markerPage1.locator('.pg.on .marker').count(); console.log({slide2MarkerCount:markerCount1}); if(markerCount1!==4) throw new Error('slide 2 needs four highlighter marks'); const markerStyles1=[]; for(let i=0;i<markerCount1;i++){markerStyles1.push(await markerPage1.locator('.pg.on .marker').nth(i).evaluate(el=>{const s=getComputedStyle(el,'::after'); return {animationName:s.animationName,animationDelay:s.animationDelay,backgroundImage:s.backgroundImage};}));} console.log({slide2MarkerStyles:markerStyles1}); if(markerStyles1.some(s=>s.animationName!=='highlightSweep')) throw new Error('slide 2 highlighter animation is missing'); const markerDelays1=markerStyles1.map(s=>parseFloat(s.animationDelay)); if(!markerDelays1.every((v,i)=>i===0||v>markerDelays1[i-1])) throw new Error('slide 2 highlighters are not sequential'); if(markerStyles1.some(s=>!s.backgroundImage.includes('linear-gradient'))) throw new Error('slide 2 highlighter brush is missing'); await sleep(1800); const markerFinished1 = await markerPage1.locator('.pg.on .marker').first().evaluate(el=>getComputedStyle(el,'::after').transform); await markerPage1.locator('#dots button').nth(1).click(); await sleep(80); const markerAfterSame1 = await markerPage1.locator('.pg.on .marker').first().evaluate(el=>getComputedStyle(el,'::after').transform); console.log({markerFinished:markerFinished1,markerAfterSame:markerAfterSame1}); if(markerFinished1!==markerAfterSame1) throw new Error('same-slide input restarted the highlighter'); await markerPage1.locator('#dots button').nth(3).click(); const markerCount2 = await markerPage1.locator('.pg.on .marker').count(); const markerDelays2=[]; for(let i=0;i<markerCount2;i++){markerDelays2.push(parseFloat(await markerPage1.locator('.pg.on .marker').nth(i).evaluate(el=>getComputedStyle(el,'::after').animationDelay)));} console.log({slide4MarkerCount:markerCount2,slide4MarkerDelays:markerDelays2}); if(markerCount2!==3) throw new Error('slide 4 needs three highlighter marks'); if(!markerDelays2.every((v,i)=>i===0||v>markerDelays2[i-1])) throw new Error('slide 4 highlighters are not sequential'); await markerPage1.close(); console.log('HIGHLIGHTER_SEQUENCE_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'HIGHLIGHTER_SEQUENCE_TEST_PASS' <<<"$aside_output"

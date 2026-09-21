#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_STAMP_TEST_PORT:-4176}"
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

aside_output="$(aside repl "const stampPage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const stampSnap1 = await snapshot(stampPage1,{interactive:true,selector:'#bar'}); console.log(stampSnap1.tree); await stampPage1.locator('#dots button').nth(4).click(); const stampSnap2 = await snapshot(stampPage1,{selector:'.pg.on'}); console.log(stampSnap2.diff); const stampMap1 = stampPage1.locator('.pg.on .ph').first(); const stampStart1 = await stampMap1.locator('img').evaluate(el => { const style=getComputedStyle(el); return {animationName:style.animationName,objectPosition:style.objectPosition}; }); await sleep(1400); const stampCount1 = await stampPage1.locator('.pg.on .secret-stamp').count(); const stampEnd1 = stampCount1 ? await stampPage1.locator('.pg.on .secret-stamp').evaluate(el => { const style=getComputedStyle(el); return {opacity:style.opacity,animationName:style.animationName}; }) : null; const stampMapEnd1 = await stampMap1.locator('img').evaluate(el => getComputedStyle(el).objectPosition); console.log({mapStart:stampStart1,mapEnd:stampMapEnd1,stampCount:stampCount1,stamp:stampEnd1}); if(stampStart1.animationName!=='none') throw new Error('slide 5 map still has a movement animation'); if(stampStart1.objectPosition!==stampMapEnd1) throw new Error('slide 5 map position changed'); if(stampCount1!==1 || stampEnd1.opacity!=='1') throw new Error('slide 5 secret stamp is missing or not visible'); console.log('SLIDE5_STAMP_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'SLIDE5_STAMP_TEST_PASS' <<<"$aside_output"

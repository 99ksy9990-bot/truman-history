#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_MONTH_TEST_PORT:-4170}"
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

aside_output="$(aside repl "const monthPage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); await monthPage1.locator('#dots button').nth(1).click(); const monthSnap1 = await snapshot(monthPage1,{selector:'.pg.on'}); console.log(monthSnap1.tree); const monthLabels1=[]; const monthCount1=await monthPage1.locator('.pg.on .big').count(); for(let i=0;i<monthCount1;i++){monthLabels1.push((await monthPage1.locator('.pg.on .big').nth(i).innerText()).trim());} console.log({monthLabels:monthLabels1}); const expectedMonths1=['1945.08','1947.03','1950.06','1951.04']; if(JSON.stringify(monthLabels1)!==JSON.stringify(expectedMonths1)) throw new Error('slide 2 month labels do not match the four decision dates'); await closeTab(monthPage1); console.log('SLIDE2_MONTH_LABELS_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'SLIDE2_MONTH_LABELS_TEST_PASS' <<<"$aside_output"

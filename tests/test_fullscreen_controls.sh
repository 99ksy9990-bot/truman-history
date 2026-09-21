#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_TEST_PORT:-4174}"
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

aside repl "const testPage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const testSnap1 = await snapshot(testPage1,{interactive:true,selector:'#bar'}); console.log(testSnap1.tree); await testPage1.evaluate(() => { Object.defineProperty(document,'fullscreenElement',{configurable:true,get:()=>document.documentElement}); document.dispatchEvent(new Event('fullscreenchange')); }); await testPage1.mouse.move(320,240); const testState1 = {fullscreenClass:await testPage1.locator('body.is-fullscreen').count(),barVisible:await testPage1.locator('#bar').isVisible(),hintVisible:await testPage1.locator('#hint').isVisible(),tickVisible:await testPage1.locator('#tick').isVisible(),progressVisible:await testPage1.locator('#prog').isVisible()}; console.log(testState1); if(testState1.fullscreenClass!==1) throw new Error('fullscreen state class was not applied'); if(testState1.barVisible||testState1.hintVisible||testState1.tickVisible||testState1.progressVisible) throw new Error('fullscreen presentation chrome is visible');"

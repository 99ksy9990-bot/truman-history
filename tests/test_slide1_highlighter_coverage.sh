#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_SLIDE1_HIGHLIGHT_TEST_PORT:-4182}"
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

aside_output="$(aside repl "const coverPage1=await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const coverage1=await coverPage1.locator('.pg.on .marker').first().evaluate(el=>{const base=getComputedStyle(el);const mark=getComputedStyle(el,'::after');return {fontSize:parseFloat(base.fontSize),height:parseFloat(mark.height),bottom:parseFloat(mark.bottom)}}); console.log({slide1Highlighter:coverage1}); if(coverage1.height/coverage1.fontSize<.66||coverage1.bottom/coverage1.fontSize<.1) throw new Error('slide 1 highlighter must rise into more of the letterforms'); await closeTab(coverPage1); console.log('SLIDE1_HIGHLIGHTER_COVERAGE_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'SLIDE1_HIGHLIGHTER_COVERAGE_TEST_PASS' <<<"$aside_output"

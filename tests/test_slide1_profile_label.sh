#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_PROFILE_TEST_PORT:-4178}"
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

aside_output="$(aside repl "const profilePage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const profileSnap1 = await snapshot(profilePage1,{selector:'.pfile'}); console.log(profileSnap1.tree); const profileLabel1 = await profilePage1.locator('.pfile dt').nth(1).textContent(); console.log({profileLabel:profileLabel1}); if(profileLabel1.trim()!=='생애') throw new Error('slide 1 lifespan label is not 생애'); console.log('SLIDE1_PROFILE_LABEL_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'SLIDE1_PROFILE_LABEL_TEST_PASS' <<<"$aside_output"

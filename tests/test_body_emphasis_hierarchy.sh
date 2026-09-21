#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_EMPHASIS_TEST_PORT:-4171}"
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

aside_output="$(aside repl "const emphasisPage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const emphasisSnap1 = await snapshot(emphasisPage1,{selector:'.pg.on'}); console.log(emphasisSnap1.tree); const emphasisSelector1='.body b,.small b,.brief b'; const emphasisCount1=await emphasisPage1.locator(emphasisSelector1).count(); const emphasisWeights1=[]; const emphasisTexts1=[]; for(let i=0;i<emphasisCount1;i++){const emphasisItem1=emphasisPage1.locator(emphasisSelector1).nth(i); emphasisWeights1.push(Number(await emphasisItem1.evaluate(el=>getComputedStyle(el).fontWeight))); emphasisTexts1.push((await emphasisItem1.innerText()).trim());} const emphasisPerSlide1=[]; const slideCount1=await emphasisPage1.locator('.pg').count(); for(let i=0;i<slideCount1;i++){emphasisPerSlide1.push(await emphasisPage1.locator('.pg').nth(i).locator(emphasisSelector1).count());} console.log({emphasisCount:emphasisCount1,weights:emphasisWeights1,texts:emphasisTexts1,perSlide:emphasisPerSlide1}); if(emphasisCount1<15) throw new Error('too few important body phrases are emphasized'); if(emphasisWeights1.some(weight=>weight<700)) throw new Error('body emphasis is not visibly bold'); if(emphasisPerSlide1.some(count=>count>4)) throw new Error('a slide has too many bold phrases'); await closeTab(emphasisPage1); console.log('BODY_EMPHASIS_HIERARCHY_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'BODY_EMPHASIS_HIERARCHY_TEST_PASS' <<<"$aside_output"

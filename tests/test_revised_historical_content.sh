#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_CONTENT_TEST_PORT:-4179}"
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

aside_output="$(aside repl "const contentPage1 = await openTab('http://127.0.0.1:${port}/?test=${cache_key}'); const slide1Meta1 = await contentPage1.locator('.pg[aria-label^=\"1.\"] .mast .r2').innerText(); const slide1Paragraphs1 = await contentPage1.locator('.pg[aria-label^=\"1.\"] [data-step=\"1\"] .body').count(); const slide5Brief1 = await contentPage1.locator('.pg[aria-label^=\"5.\"] .brief').innerText(); const slide7Quote1 = await contentPage1.locator('.pg[aria-label^=\"7.\"] .quote .q').innerText(); const slide7Source1 = await contentPage1.locator('.pg[aria-label^=\"7.\"] .quote .src').innerText(); const slide7Lists1 = contentPage1.locator('.pg[aria-label^=\"7.\"] .band.stack.plain'); const legacyItems1 = await slide7Lists1.nth(0).locator(':scope > div').evaluateAll(els=>els.map(el=>el.textContent.trim())); const shadowItems1 = await slide7Lists1.nth(1).locator(':scope > div').evaluateAll(els=>els.map(el=>el.textContent.trim())); console.log({slide1Meta:slide1Meta1,slide1Paragraphs:slide1Paragraphs1,slide5Brief:slide5Brief1,slide7Quote:slide7Quote1,slide7Source:slide7Source1,legacyItems:legacyItems1,shadowItems:shadowItems1}); if(!slide1Meta1.includes('역사 · 염초롱')||slide1Meta1.includes('역사 주제탐구 · 인물 지면')) throw new Error('slide 1 needs the requested class and presenter label'); if(slide1Paragraphs1!==3) throw new Error('slide 1 should keep exactly three narrative paragraphs'); if(!slide5Brief1.includes('1953년 7월 27일')||!slide5Brief1.includes('아이젠하워 정부')) throw new Error('slide 5 needs the armistice timing note'); if(!slide7Quote1.includes('그가 누구든')) throw new Error('farewell quote needs the complete translated clause'); if(!slide7Source1.includes('우리말 옮김')) throw new Error('farewell quote needs a translation label'); if(legacyItems1.length!==4||shadowItems1.length!==4) throw new Error('slide 7 needs a balanced four-by-four conclusion'); if(!legacyItems1.some(t=>t.includes('전쟁 종결 국면에서 중대한 결정'))) throw new Error('slide 7 needs the historically precise war-ending wording'); if(!legacyItems1.some(t=>t.includes('미군 인종분리 폐지'))) throw new Error('slide 7 needs the Executive Order 9981 wording'); if(!shadowItems1.some(t=>t.includes('냉전 대립과 핵무기 경쟁'))) throw new Error('slide 7 should consolidate the Cold War and nuclear-arms shadow'); await closeTab(contentPage1); console.log('REVISED_HISTORICAL_CONTENT_TEST_PASS');")"
printf '%s\n' "$aside_output"
grep -q 'REVISED_HISTORICAL_CONTENT_TEST_PASS' <<<"$aside_output"

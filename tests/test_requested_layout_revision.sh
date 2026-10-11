#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_REQUESTED_LAYOUT_TEST_PORT:-4181}"
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

aside_output="$(aside repl "
const requestPage1=await openTab('http://127.0.0.1:${port}/?test=${cache_key}');
const slide1Kicker1=await requestPage1.locator('.pg.on:not(.leaving) .kicker').evaluate(el=>{const r=el.getBoundingClientRect();return {left:r.left,top:r.top}});
const slide1KickerText1=await requestPage1.locator('.pg.on:not(.leaving) .kicker').innerText();
const slide1KickerSizes1=await requestPage1.locator('.pg.on:not(.leaving) .exhibit-kicker').evaluate(el=>({minor:[...el.querySelectorAll('.minor')].map(n=>parseFloat(getComputedStyle(n).fontSize)),major:[...el.querySelectorAll('.major')].map(n=>parseFloat(getComputedStyle(n).fontSize)),journey:parseFloat(getComputedStyle(el.querySelector('.journey')).fontSize)}));
const slide1BylineColors1=await requestPage1.locator('.pg.on:not(.leaving) .mast .r2 .s').evaluateAll(els=>({first:getComputedStyle(els[0]).color,history:getComputedStyle(els[1]).color}));
const slide1TitleLines1=await requestPage1.locator('.pg.on:not(.leaving) h1 .tw').evaluateAll(els=>new Set(els.map(el=>Math.round(el.getBoundingClientRect().top))).size);
await requestPage1.locator('#dots button').nth(1).evaluate(b=>b.click());
await sleep(700);
const slide2Kicker1=await requestPage1.locator('.pg.on:not(.leaving) .kicker').evaluate(el=>{const r=el.getBoundingClientRect();return {left:r.left,top:r.top}});
const slide2MacArthurImage1=await requestPage1.locator('.pg.on:not(.leaving) .c').nth(3).locator('img').evaluate(img=>({src:img.getAttribute('src'),naturalWidth:img.naturalWidth}));
console.log({slide1Kicker:slide1Kicker1,slide1KickerText:slide1KickerText1,slide1KickerSizes:slide1KickerSizes1,slide1BylineColors:slide1BylineColors1,slide2Kicker:slide2Kicker1,slide1TitleLines:slide1TitleLines1});
if(Math.abs(slide1Kicker1.left-slide2Kicker1.left)>2||slide1TitleLines1!==1||slide1KickerText1.replace(/\\s+/g,' ').trim()!=='AN ORDINARY MAN · HIS EXTRAORDINARY JOURNEY'||slide1KickerSizes1.minor.length!==2||slide1KickerSizes1.major.length!==2||new Set([...slide1KickerSizes1.minor,...slide1KickerSizes1.major,slide1KickerSizes1.journey]).size!==1||slide1BylineColors1.history!=='rgb(29, 61, 114)'||slide1BylineColors1.history===slide1BylineColors1.first) throw new Error('slide 1 title must align with the other slides, stay on one line, use the exhibit phrase with the reference hierarchy, and show the history byline in navy');

await requestPage1.locator('#dots button').nth(2).evaluate(b=>b.click());
const slide3Document1=await requestPage1.locator('.pg.on:not(.leaving) .c').nth(1).evaluate(el=>{const img=el.querySelector('img');return {src:img.currentSrc,naturalWidth:img.naturalWidth,animation:getComputedStyle(img).animationName,caption:el.querySelector('.cap').innerText.replace(/\\s+/g,' ').trim()}});
const slide3DecisionSpacing1=await requestPage1.locator('.pg.on:not(.leaving) .decision-case').evaluateAll(els=>els.map(el=>{const label=el.querySelector('.lbl').getBoundingClientRect(),body=el.querySelector('.body').getBoundingClientRect(),box=el.getBoundingClientRect();return {top:body.top-label.bottom,bottom:box.bottom-body.bottom}}));
console.log({slide3Document:slide3Document1,slide3DecisionSpacing:slide3DecisionSpacing1});
if(!slide3Document1.src.endsWith('/assets/04_japan_surrender.jpg')||slide3Document1.naturalWidth!==377||slide3Document1.animation!=='scanTo, focusZoom'||!slide3Document1.caption.includes('일본 항복 문서')||!slide3Document1.caption.includes('1945년 9월 2일')||slide3Document1.caption.includes('자필 메모')||slide3DecisionSpacing1.length!==2) throw new Error('slide 3 must replace the handwritten memo with the supplied Japanese surrender document, use the same scan effect as slide 4, and give both decision texts equal vertical space above and below');

await requestPage1.locator('#dots button').nth(3).evaluate(b=>b.click());
const slide4Animation1=await requestPage1.locator('.pg.on:not(.leaving) .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).animationName));
await requestPage1.locator('.pg.on:not(.leaving) .ph img').evaluateAll(els=>els.forEach(el=>{const a=el.getAnimations()[0];if(a){const t=a.effect.getComputedTiming();a.currentTime=t.delay+t.duration/2}}));
await sleep(60);
const slide4Bottom1=await requestPage1.locator('.pg.on:not(.leaving) .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).objectPosition));
await requestPage1.locator('.pg.on:not(.leaving) .ph img').evaluateAll(els=>els.forEach(el=>{const a=el.getAnimations()[0];if(a){const t=a.effect.getComputedTiming();a.currentTime=t.delay+t.duration}}));
await sleep(60);
const slide4End1=await requestPage1.locator('.pg.on:not(.leaving) .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).objectPosition));
console.log({slide4Animation:slide4Animation1,slide4Bottom:slide4Bottom1,slide4End:slide4End1});
if(slide4Animation1.length!==3||slide4Animation1.slice(0,2).some(name=>name!=='scan')||slide4Animation1[2]!=='scanTo, focusZoom'||slide4Bottom1.slice(0,2).some(pos=>parseFloat(pos.split(' ')[1])<90)||slide4End1.slice(0,2).some(pos=>parseFloat(pos.split(' ')[1])>5)) throw new Error('slide 4: the first two documents scan down and back up; the treaty scans to its signatures and zooms');

// 6·7면 세부 배치는 이후 개편(23991e9 6면 표·사진 순서, d816a6d·b74eb67 7면 세 쌍)으로 바뀌어
// test_visual_hierarchy_refinement·test_revised_historical_content·test_last_slide_no_replay가 현재 기준으로 검사한다.
if(!slide2MacArthurImage1.src.endsWith('assets/wake_island_macarthur_truman.jpg')||slide2MacArthurImage1.naturalWidth!==611) throw new Error('slide 2 must use the standing Wake Island photo (swapped with slide 6)');
await closeTab(requestPage1);
console.log('REQUESTED_LAYOUT_REVISION_TEST_PASS');
")"
printf '%s\n' "$aside_output"
grep -q 'REQUESTED_LAYOUT_REVISION_TEST_PASS' <<<"$aside_output"
if grep -q '자필 메모' "$project_dir/index.html"; then
  echo 'slide 3 still contains the removed handwritten-memo wording' >&2
  exit 1
fi

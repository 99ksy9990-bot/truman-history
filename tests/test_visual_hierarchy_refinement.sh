#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_REFINEMENT_TEST_PORT:-4180}"
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
const refinePage1=await openTab('http://127.0.0.1:${port}/?test=${cache_key}');
const rgb1=v=>(v.match(/\\d+(?:\\.\\d+)?/g)||[]).slice(0,3).map(Number);
const brightness1=c=>c[0]*.299+c[1]*.587+c[2]*.114;
const stageColor1=rgb1(await refinePage1.locator('#stage').evaluate(el=>getComputedStyle(el).backgroundColor));
const paperColor1=rgb1(await refinePage1.locator('.pg.on').evaluate(el=>getComputedStyle(el).backgroundColor));
const capSize1=parseFloat(await refinePage1.locator('.cap').first().evaluate(el=>getComputedStyle(el).fontSize));
const briefSize1=parseFloat(await refinePage1.locator('.brief p:not(.bt)').first().evaluate(el=>getComputedStyle(el).fontSize));
const twDelays1=await refinePage1.locator('.pg[aria-label^=\"1.\"] h1 .tw').evaluateAll(els=>els.slice(0,2).map(el=>parseFloat(el.style.getPropertyValue('--d'))));
await refinePage1.locator('#dots button').nth(2).click();
const cases1=await refinePage1.locator('.pg.on .decision-case').count();
const issueColor1=cases1?await refinePage1.locator('.pg.on .decision-case.issue .lbl').evaluate(el=>getComputedStyle(el).color):null;
await refinePage1.locator('#dots button').nth(3).click();
const slide4Animations1=await refinePage1.locator('.pg.on .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).animationName));
await refinePage1.locator('#dots button').nth(5).click();
const slide6Layout1=await refinePage1.locator('.pg.on .row').evaluate(el=>{const kids=[...el.children].map(c=>c.getBoundingClientRect().width);return {ratio:kids[1]/kids[0],tableFont:parseFloat(getComputedStyle(el.querySelector('table')).fontSize)}});
await refinePage1.locator('#dots button').nth(6).click();
const closeSize1=parseFloat(await refinePage1.locator('.pg.on .close .ct').evaluate(el=>getComputedStyle(el).fontSize));
console.log({stageBrightness:brightness1(stageColor1),paperBrightness:brightness1(paperColor1),capSize:capSize1,briefSize:briefSize1,typewriterDelays:twDelays1,decisionCases:cases1,issueColor:issueColor1,slide4Animations:slide4Animations1,slide6Layout:slide6Layout1,closeSize:closeSize1});
if(brightness1(stageColor1)<224||brightness1(paperColor1)<243) throw new Error('the full background needs to move closer to white');
if(capSize1<16.2||briefSize1<21.2) throw new Error('captions and briefs need the agreed twelve-percent enlargement');
if(twDelays1.length!==2||twDelays1[1]-twDelays1[0]!==52) throw new Error('typewriter cadence must remain unchanged at 52ms');
if(cases1!==2||issueColor1!=='rgb(141, 43, 33)') throw new Error('slide 3 needs two opposing cases with a red issue treatment');
if(slide4Animations1.length!==3||slide4Animations1.some(name=>name!=='scan')) throw new Error('all three slide 4 documents should use the same down-and-up scan as slide 2');
if(slide6Layout1.ratio<2.6||slide6Layout1.tableFont<21.5) throw new Error('slide 6 table needs more width and larger type');
if(closeSize1<31) throw new Error('slide 7 closing statement needs stronger emphasis');
await closeTab(refinePage1);
console.log('VISUAL_HIERARCHY_REFINEMENT_TEST_PASS');
")"
printf '%s\n' "$aside_output"
grep -q 'VISUAL_HIERARCHY_REFINEMENT_TEST_PASS' <<<"$aside_output"

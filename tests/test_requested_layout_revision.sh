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
const slide1Kicker1=await requestPage1.locator('.pg.on .kicker').evaluate(el=>{const r=el.getBoundingClientRect();return {left:r.left,top:r.top}});
const slide1TitleLines1=await requestPage1.locator('.pg.on h1 .tw').evaluateAll(els=>new Set(els.map(el=>Math.round(el.getBoundingClientRect().top))).size);
await requestPage1.locator('#dots button').nth(1).click();
const slide2Kicker1=await requestPage1.locator('.pg.on .kicker').evaluate(el=>{const r=el.getBoundingClientRect();return {left:r.left,top:r.top}});
console.log({slide1Kicker:slide1Kicker1,slide2Kicker:slide2Kicker1,slide1TitleLines:slide1TitleLines1});
if(Math.abs(slide1Kicker1.left-slide2Kicker1.left)>2||Math.abs(slide1Kicker1.top-slide2Kicker1.top)>2||slide1TitleLines1!==1) throw new Error('slide 1 title must align with the other slides and stay on one line');

await requestPage1.locator('#dots button').nth(3).click();
const slide4Animation1=await requestPage1.locator('.pg.on .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).animationName));
await sleep(3600);
const slide4Positions1=await requestPage1.locator('.pg.on .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).objectPosition));
console.log({slide4Animation:slide4Animation1,slide4Positions:slide4Positions1});
if(slide4Animation1.length!==3||slide4Animation1.some(name=>name!=='scanDownHold')||slide4Positions1.some(pos=>!pos.endsWith('100%'))) throw new Error('all slide 4 documents must scan downward and remain fixed at the bottom');

await requestPage1.locator('#dots button').nth(5).click();
const slide6Caption1=await requestPage1.locator('.pg.on .cap').evaluate(el=>{
  const range=document.createRange();range.selectNodeContents(el);
  const lineCount=new Set([...range.getClientRects()].filter(r=>r.width>1).map(r=>Math.round(r.top))).size;
  return {text:el.innerText.replace(/\\s+/g,' ').trim(),lineCount,width:el.clientWidth,scrollWidth:el.scrollWidth};
});
console.log({slide6Caption:slide6Caption1});
if(!slide6Caption1.text.includes('두 사람의 유일한 대면')||slide6Caption1.lineCount!==1||slide6Caption1.scrollWidth>slide6Caption1.width+2) throw new Error('slide 6 caption must fit on one visible line');

await requestPage1.locator('#dots button').nth(6).click();
const slide7Quote1=await requestPage1.locator('.pg.on .quote .q').innerText();
const slide7Panels1=await requestPage1.locator('.pg.on .decision-case').evaluateAll(els=>els.map(el=>{const r=el.getBoundingClientRect();return {left:r.left,right:r.right,top:r.top,count:el.querySelectorAll('.band.stack > div').length}}));
console.log({slide7Quote:slide7Quote1,slide7Panels:slide7Panels1});
if(slide7Quote1.includes('—')) throw new Error('slide 7 quote must not contain em dashes');
if(slide7Panels1.length!==2||slide7Panels1.some(panel=>panel.count!==4)||Math.abs(slide7Panels1[0].top-slide7Panels1[1].top)>2||slide7Panels1[1].left<=slide7Panels1[0].right) throw new Error('slide 7 needs two horizontal opposing four-item panels');
await closeTab(requestPage1);
console.log('REQUESTED_LAYOUT_REVISION_TEST_PASS');
")"
printf '%s\n' "$aside_output"
grep -q 'REQUESTED_LAYOUT_REVISION_TEST_PASS' <<<"$aside_output"

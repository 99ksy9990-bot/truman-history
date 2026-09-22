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
const slide1KickerText1=await requestPage1.locator('.pg.on .kicker').innerText();
const slide1KickerSizes1=await requestPage1.locator('.pg.on .exhibit-kicker').evaluate(el=>({minor:[...el.querySelectorAll('.minor')].map(n=>parseFloat(getComputedStyle(n).fontSize)),major:[...el.querySelectorAll('.major')].map(n=>parseFloat(getComputedStyle(n).fontSize)),journey:parseFloat(getComputedStyle(el.querySelector('.journey')).fontSize)}));
const slide1BylineColors1=await requestPage1.locator('.pg.on .mast .r2 .s').evaluateAll(els=>({first:getComputedStyle(els[0]).color,history:getComputedStyle(els[1]).color}));
const slide1TitleLines1=await requestPage1.locator('.pg.on h1 .tw').evaluateAll(els=>new Set(els.map(el=>Math.round(el.getBoundingClientRect().top))).size);
await requestPage1.locator('#dots button').nth(1).click();
const slide2Kicker1=await requestPage1.locator('.pg.on .kicker').evaluate(el=>{const r=el.getBoundingClientRect();return {left:r.left,top:r.top}});
const slide2MacArthurImage1=await requestPage1.locator('.pg.on .c').nth(3).locator('img').evaluate(img=>({src:img.getAttribute('src'),naturalWidth:img.naturalWidth}));
console.log({slide1Kicker:slide1Kicker1,slide1KickerText:slide1KickerText1,slide1KickerSizes:slide1KickerSizes1,slide1BylineColors:slide1BylineColors1,slide2Kicker:slide2Kicker1,slide1TitleLines:slide1TitleLines1});
if(Math.abs(slide1Kicker1.left-slide2Kicker1.left)>2||Math.abs(slide1Kicker1.top-slide2Kicker1.top)>2||slide1TitleLines1!==1||slide1KickerText1.replace(/\\s+/g,' ').trim()!=='AN ORDINARY MAN · HIS EXTRAORDINARY JOURNEY'||slide1KickerSizes1.minor.length!==2||slide1KickerSizes1.major.length!==2||Math.max(...slide1KickerSizes1.minor)>=Math.min(...slide1KickerSizes1.major)||!(slide1KickerSizes1.journey>Math.max(...slide1KickerSizes1.minor)&&slide1KickerSizes1.journey<Math.min(...slide1KickerSizes1.major))||slide1BylineColors1.history!=='rgb(29, 61, 114)'||slide1BylineColors1.history===slide1BylineColors1.first) throw new Error('slide 1 title must align with the other slides, stay on one line, use the exhibit phrase with the reference hierarchy, and show the history byline in navy');

await requestPage1.locator('#dots button').nth(2).click();
const slide3Document1=await requestPage1.locator('.pg.on .c').nth(1).evaluate(el=>{const img=el.querySelector('img');return {src:img.currentSrc,naturalWidth:img.naturalWidth,animation:getComputedStyle(img).animationName,caption:el.querySelector('.cap').innerText.replace(/\\s+/g,' ').trim()}});
const slide3DecisionSpacing1=await requestPage1.locator('.pg.on .decision-case').evaluateAll(els=>els.map(el=>{const label=el.querySelector('.lbl').getBoundingClientRect(),body=el.querySelector('.body').getBoundingClientRect(),box=el.getBoundingClientRect();return {top:body.top-label.bottom,bottom:box.bottom-body.bottom}}));
console.log({slide3Document:slide3Document1,slide3DecisionSpacing:slide3DecisionSpacing1});
if(!slide3Document1.src.endsWith('/assets/04_japan_surrender.jpg')||slide3Document1.naturalWidth!==377||slide3Document1.animation!=='scan'||!slide3Document1.caption.includes('일본 항복 문서')||!slide3Document1.caption.includes('1945년 9월 2일')||slide3Document1.caption.includes('자필 메모')||slide3DecisionSpacing1.length!==2||slide3DecisionSpacing1.some(v=>Math.abs(v.top-v.bottom)>2)) throw new Error('slide 3 must replace the handwritten memo with the supplied Japanese surrender document, use the same scan effect as slide 4, and give both decision texts equal vertical space above and below');

await requestPage1.locator('#dots button').nth(3).click();
const slide4Animation1=await requestPage1.locator('.pg.on .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).animationName));
await requestPage1.locator('.pg.on .ph img').evaluateAll(els=>els.forEach(el=>{const a=el.getAnimations()[0];if(a)a.currentTime=5000}));
await sleep(60);
const slide4Bottom1=await requestPage1.locator('.pg.on .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).objectPosition));
await requestPage1.locator('.pg.on .ph img').evaluateAll(els=>els.forEach(el=>{const a=el.getAnimations()[0];if(a)a.currentTime=8300}));
await sleep(60);
const slide4End1=await requestPage1.locator('.pg.on .ph img').evaluateAll(els=>els.map(el=>getComputedStyle(el).objectPosition));
console.log({slide4Animation:slide4Animation1,slide4Bottom:slide4Bottom1,slide4End:slide4End1});
if(slide4Animation1.length!==3||slide4Animation1.some(name=>name!=='scan')||slide4Bottom1.some(pos=>parseFloat(pos.split(' ')[1])<90)||slide4End1.some(pos=>parseFloat(pos.split(' ')[1])>5)) throw new Error('all slide 4 documents must scan down, return upward, and stop at the top like slide 2');

await requestPage1.locator('#dots button').nth(5).click();
await sleep(1000);
const slide6Caption1=await requestPage1.locator('.pg.on .row').evaluate(el=>{
  const photo=el.querySelector('.ph').getBoundingClientRect();
  const cap=el.querySelector('.cap').getBoundingClientRect();
  const brief=el.querySelector('.brief').getBoundingClientRect();
  const row=el.getBoundingClientRect();
  const img=el.querySelector('.c:first-child img');
  const capEl=el.querySelector('.cap');
  const decision=el.querySelector('.decision-detail');
  const decisionBodies=[...decision.querySelectorAll('.body')];
  const table=el.querySelector('table').getBoundingClientRect();
  const decisionRect=decision.getBoundingClientRect();
  return {text:capEl.innerText.replace(/\\s+/g,' ').trim(),captionHtml:capEl.innerHTML,position:getComputedStyle(capEl).position,image:{src:img.currentSrc,naturalWidth:img.naturalWidth,objectFit:getComputedStyle(img).objectFit},photo:{bottom:photo.bottom,width:photo.width},cap:{top:cap.top,right:cap.right,width:cap.width},firstColumnRight:el.children[0].getBoundingClientRect().right,decisionText:decision.innerText,decisionBodyCount:decisionBodies.length,decisionBodyLines:decisionBodies.map(p=>{const range=document.createRange();range.selectNodeContents(p);return new Set([...range.getClientRects()].map(r=>Math.round(r.top))).size}),tableToDecisionGap:decisionRect.top-table.bottom,decisionGap:brief.top-decisionRect.bottom,briefBottom:brief.bottom,rowBottom:row.bottom,paddingBottom:parseFloat(getComputedStyle(el).paddingBottom)};
});
const slide6Table1=await requestPage1.locator('.pg.on table').evaluate(table=>{const hero=table.querySelector('thead .hero'),general=table.querySelector('thead th:last-child'),cells=[...table.querySelectorAll('th,td')],sample=table.querySelector('tbody td');return {height:table.getBoundingClientRect().height,fontSize:parseFloat(getComputedStyle(sample).fontSize),paddingTop:parseFloat(getComputedStyle(sample).paddingTop),paddingBottom:parseFloat(getComputedStyle(sample).paddingBottom),heroWidth:hero.getBoundingClientRect().width,generalWidth:general.getBoundingClientRect().width,textAligns:[...new Set(cells.map(c=>getComputedStyle(c).textAlign))],verticalAligns:[...new Set(cells.map(c=>getComputedStyle(c).verticalAlign))]}});
console.log({slide6Caption:slide6Caption1,slide6Table:slide6Table1});
if(!slide2MacArthurImage1.src.endsWith('assets/69-1199a_truman_macarthur_wake_island.jpg')||slide2MacArthurImage1.naturalWidth!==800||!slide6Caption1.text.includes('두 사람의 유일한 대면')||!slide6Caption1.captionHtml.includes('<br>해임 여섯 달 전')||!slide6Caption1.image.src.startsWith('data:image/jpeg;base64,')||slide6Caption1.image.naturalWidth!==611||slide6Caption1.image.src===slide2MacArthurImage1.src||slide6Caption1.image.objectFit!=='cover'||slide6Caption1.position!=='static'||slide6Caption1.cap.top<slide6Caption1.photo.bottom||slide6Caption1.cap.width>slide6Caption1.photo.width+2||slide6Caption1.cap.right>slide6Caption1.firstColumnRight+2||slide6Caption1.decisionBodyCount!==2||slide6Caption1.decisionBodyLines[0]<2||slide6Caption1.decisionBodyLines[1]!==1||!slide6Caption1.decisionText.includes('선출된 민간 정부')||slide6Caption1.tableToDecisionGap<19||slide6Caption1.decisionGap>55||slide6Caption1.paddingBottom!==0||Math.abs(slide6Caption1.briefBottom-slide6Caption1.rowBottom)>2||slide6Table1.height<220||slide6Table1.fontSize<23||slide6Table1.paddingTop<19||slide6Table1.paddingBottom<19||Math.abs(slide6Table1.heroWidth-slide6Table1.generalWidth)>2||slide6Table1.textAligns.some(v=>v!=='center')||slide6Table1.verticalAligns.some(v=>v!=='middle')) throw new Error('slides 2 and 6 must swap their Wake Island photos; slide 6 must break the caption before the dismissal timing, enlarge the centered equal-width table, add breathing room before a fuller naturally wrapped dismissal explanation, keep the caption line under the photo, and leave the bottom brief rule fixed');

await requestPage1.locator('#dots button').nth(6).click();
await sleep(1200);
const slide7Quote1=await requestPage1.locator('.pg.on .quote .q').innerText();
const slide7Image1=await requestPage1.locator('.pg.on .row > .c:first-child').evaluate(el=>{const r=el.getBoundingClientRect(),img=el.querySelector('img');return {display:getComputedStyle(el).display,left:r.left,right:r.right,width:r.width,src:img.currentSrc,alt:img.alt,naturalWidth:img.naturalWidth,caption:el.querySelector('.cap').innerText}});
const slide7Panels1=await requestPage1.locator('.pg.on .decision-case').evaluateAll(els=>els.map(el=>{const r=el.getBoundingClientRect();return {left:r.left,right:r.right,top:r.top,count:el.querySelectorAll('.band.stack > div').length}}));
const slide7PanelPadding1=await requestPage1.locator('.pg.on .decision-case').evaluateAll(els=>els.map(el=>parseFloat(getComputedStyle(el).paddingRight)));
const slide7CellGeometry1=await requestPage1.locator('.pg.on .decision-case').evaluateAll(els=>els.map(el=>{const label=el.querySelector(':scope > .lbl'),box=el.getBoundingClientRect(),rows=[...el.querySelectorAll('.band.stack > div')];return {labelHeight:label.getBoundingClientRect().height,labelFontSize:parseFloat(getComputedStyle(label).fontSize),firstRowTopGap:rows[0].getBoundingClientRect().top-label.getBoundingClientRect().bottom,lastRowBottomGap:box.bottom-rows.at(-1).getBoundingClientRect().bottom,rows:rows.map(row=>{const r=row.getBoundingClientRect(),d=row.querySelector('.d').getBoundingClientRect();return {height:r.height,top:d.top-r.top,bottom:r.bottom-d.bottom}})}}));
console.log({slide7Quote:slide7Quote1,slide7Image:slide7Image1,slide7Panels:slide7Panels1,slide7PanelPadding:slide7PanelPadding1,slide7CellGeometry:slide7CellGeometry1});
if(slide7Quote1.includes('—')) throw new Error('slide 7 quote must not contain em dashes');
if(slide7Image1.display==='none'||slide7Image1.width<250||!slide7Image1.src.endsWith('/assets/63-782_official_portrait.jpg')||slide7Image1.naturalWidth!==642||!slide7Image1.alt.includes('트루먼 공식 초상')||!slide7Image1.caption.includes('63-782')||slide7Panels1.length!==2||slide7Panels1.some(panel=>panel.count!==4)||Math.abs(slide7Panels1[0].top-slide7Panels1[1].top)>2||slide7Panels1[0].left<slide7Image1.right-1||slide7Panels1[1].left<slide7Panels1[0].right-1||slide7PanelPadding1.some(v=>v>18)||slide7CellGeometry1.some(panel=>panel.labelHeight<48||panel.labelFontSize<20||Math.abs(panel.firstRowTopGap)>2||Math.abs(panel.lastRowBottomGap)>2||panel.rows.some(row=>row.height>100||Math.abs(row.top-row.bottom)>2))) throw new Error('slide 7 needs the supplied official portrait on the left, larger title text and cells, and two compact four-item panels whose number and text have equal vertical space between every horizontal rule');
await closeTab(requestPage1);
console.log('REQUESTED_LAYOUT_REVISION_TEST_PASS');
")"
printf '%s\n' "$aside_output"
grep -q 'REQUESTED_LAYOUT_REVISION_TEST_PASS' <<<"$aside_output"
if grep -q '자필 메모' "$project_dir/index.html"; then
  echo 'slide 3 still contains the removed handwritten-memo wording' >&2
  exit 1
fi

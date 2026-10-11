#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
port="${TRUMAN_SLIDE1_BALANCE_TEST_PORT:-4183}"
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
const balancePage1=await openTab('http://127.0.0.1:${port}/?test=${cache_key}');
const balanceMetrics1=await balancePage1.locator('.pg[aria-label^=\"1.\"] .two').evaluate(el=>{
  const profile=el.querySelector('.pfile').getBoundingClientRect();
  const paragraphs=[...el.querySelectorAll('.body')].map(x=>x.getBoundingClientRect());
  const gaps=[paragraphs[1].top-paragraphs[0].bottom,paragraphs[2].top-paragraphs[1].bottom];
  const bodyHeight=paragraphs[2].bottom-paragraphs[0].top;
  return {profileHeight:profile.height,bodyHeight,gaps,ratio:bodyHeight/profile.height};
});
console.log({slide1Balance:balanceMetrics1});
if(balanceMetrics1.gaps.some(g=>g<18)||balanceMetrics1.ratio<.82||balanceMetrics1.ratio>1.02) throw new Error('slide 1 body paragraphs need more vertical breathing room and a height closer to the profile file');
await closeTab(balancePage1);
console.log('SLIDE1_PARAGRAPH_BALANCE_TEST_PASS');
")"
printf '%s\n' "$aside_output"
grep -q 'SLIDE1_PARAGRAPH_BALANCE_TEST_PASS' <<<"$aside_output"

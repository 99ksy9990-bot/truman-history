"""페이지에 쓰인 글자만 담아 조선신명조 웹 글꼴(assets/chosun.woff2)을 다시 만든다.

사용: python3 tools/subset_font.py [원본 ChosunSm.TTF 경로]
단독 HTML(트루먼_3분30초_발표_지면형.html)에 넣은 글꼴도 함께 바꾼다.
"""
import base64, html, os, re, sys, tempfile
from fontTools import subset
from fontTools.ttLib import TTFont

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser('~/Downloads/ChosunSm.TTF')
pages = ['index.html', '트루먼_3분30초_발표_지면형.html']
out = os.path.join(root, 'assets', 'chosun.woff2')

chars = {chr(c) for c in range(0x20, 0x7f)}
for p in pages:
    s = open(os.path.join(root, p), encoding='utf-8').read()
    s = re.sub(r'data:[a-z]+/[a-z0-9+.-]+;base64,[A-Za-z0-9+/=]+', '', s)
    chars |= {c for c in html.unescape(s) if ord(c) >= 0x20}
if os.path.exists(out):  # 이전 글꼴의 글자도 유지
    chars |= {chr(c) for c in TTFont(out).getBestCmap()}

opts = subset.Options()
opts.flavor = 'woff2'
opts.layout_features = ['*']
opts.hinting = False
font = subset.load_font(src, opts)
sub = subset.Subsetter(opts)
sub.populate(text=''.join(chars))
sub.subset(font)
subset.save_font(font, out, opts)

b64 = base64.b64encode(open(out, 'rb').read()).decode()
p = os.path.join(root, pages[1])
s = open(p, encoding='utf-8').read()
s, n = re.subn(r"src:url\(data:font/woff2;base64,[A-Za-z0-9+/=]+\)",
               lambda m: 'src:url(data:font/woff2;base64,' + b64 + ')', s)
assert n == 1
open(p, 'w', encoding='utf-8').write(s)
print(f'{len(TTFont(out).getBestCmap())}자 · {os.path.getsize(out):,} bytes')

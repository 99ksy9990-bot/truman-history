"""대본 PDF의 본문 줄을 새 문장으로 다시 짜 넣는다(원본 HTML이 없어 PDF 안에서 처리)."""
import re
import fitz

FONT = '/Users/santak/Downloads/ChosunSm.TTF'
SIZE = 10.994999885559082
X0, XMAX = 121.8, 538.05          # 본문 왼쪽 끝, 대본에서 가장 긴 줄의 오른쪽 끝
LEAD = 18.75                      # 줄 간격(127.5 → 146.25)
INK, SPOT = (0x1b/255, 0x1b/255, 0x1d/255), (0x1d/255, 0x3d/255, 0x72/255)
font = fitz.Font(fontfile=FONT)


def parse(rich):
    """'**굵게**' 표시를 (글자, 굵게) 조각으로."""
    out = []
    for i, part in enumerate(re.split(r'\*\*', rich)):
        if part:
            out.append((part, i % 2 == 1))
    return out


def wrap(rich, width=XMAX - X0):
    """공백에서만 줄을 바꾼다(keep-all). 줄마다 [(글자, 굵게)] 목록."""
    words = []  # 각 단어는 [(글자, 굵게)], 단어 사이 공백은 앞 단어의 굵기를 따름
    cur = []
    for text, bold in parse(rich):
        for j, chunk in enumerate(re.split(r'( )', text)):
            if chunk == ' ':
                words.append(cur + [(' ', bold)]); cur = []
            elif chunk:
                cur.append((chunk, bold))
    if cur:
        words.append(cur)
    lines, line, w = [], [], 0.0
    for word in words:
        ww = sum(font.text_length(t.replace('\u00a0', ' '), fontsize=SIZE) for t, _ in word)
        trail = font.text_length(' ', fontsize=SIZE) if word[-1][0] == ' ' else 0
        if line and w + ww - trail > width:
            lines.append(line); line, w = [], 0.0
        line += word; w += ww
    if line:
        lines.append(line)
    return lines


def erase(page, baselines, x0=X0 - 0.6, x1=XMAX + 1, up=9.6, down=2.6):
    """baselines 줄의 글자를 지운다."""
    for y in baselines:
        page.add_redact_annot(fitz.Rect(x0, y - up, x1, y + down), fill=None)
    page.apply_redactions(images=fitz.PDF_REDACT_IMAGE_NONE, graphics=fitz.PDF_REDACT_LINE_ART_NONE)


def draw(page, baselines, rich, x0=X0, size=SIZE, ink=INK, spot=SPOT, bold_mode=2):
    """rich 문장을 줄바꿈해 baselines 자리에 쓴다. 줄 수가 넘치면 멈춘다."""
    lines = wrap(rich, XMAX - x0) if size == SIZE else [[(t, b) for t, b in parse(rich)]]
    assert len(lines) <= len(baselines), f'{len(lines)}줄 > 자리 {len(baselines)}줄'
    for y, line in zip(baselines, lines):
        tw_plain, tw_bold = fitz.TextWriter(page.rect), fitz.TextWriter(page.rect)
        x = x0
        for text, bold in line:
            text = text.replace('\u00a0', ' ')
            (tw_bold if bold else tw_plain).append((x, y), text, font=font, fontsize=size)
            x += font.text_length(text, fontsize=size)
        tw_plain.write_text(page, color=ink)
        # 굵은 글씨: 원본(크롬 가짜 굵기)과 비슷하게 채움 + 얇은 외곽선
        tw_bold.write_text(page, color=spot, render_mode=bold_mode)
    return lines


def rewrite(page, baselines, rich):
    """baselines에 있던 줄들을 지우고 rich 문장을 같은 자리에 다시 쓴다."""
    erase(page, baselines)
    return draw(page, baselines, rich)


def fits(rich, n):
    return len(wrap(rich)) <= n

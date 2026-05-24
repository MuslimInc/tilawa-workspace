import cv2, numpy as np, json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from quran_data_paths import QPC_V4_JSON, QURAN_PAGE_INDEX_JSON

LINE_IMAGES = Path("assets/quran_images/1")
LINE_IMG_W  = 1440
LINE_COUNT  = 15
MARKER_R    = 0.025

def analyse_line(li):
    img = cv2.imread(str(LINE_IMAGES / f"{li}.png"), cv2.IMREAD_UNCHANGED)
    if img is None or img.shape[2] < 4:
        return dict(has_content=False, gap_centers=[], text_left=None, text_right=None)
    alpha     = img[:, :, 3]
    col_alpha = alpha.max(axis=0)
    has_text  = (col_alpha > 12).astype(np.uint8)
    text_cols = np.where(has_text)[0]
    if len(text_cols) == 0:
        return dict(has_content=False, gap_centers=[], text_left=None, text_right=None)
    text_left  = round(text_cols[0]  / LINE_IMG_W, 5)
    text_right = round(text_cols[-1] / LINE_IMG_W, 5)
    runs, cur, start = [], has_text[0], 0
    for x in range(1, len(has_text)):
        if has_text[x] != cur:
            runs.append((start, x - 1, bool(cur)))
            start, cur = x, has_text[x]
    runs.append((start, len(has_text) - 1, bool(cur)))
    text_runs   = [r for r in runs if r[2]]
    gap_centers = []
    MIN_GAP     = int(LINE_IMG_W * 0.03)
    for i in range(len(text_runs) - 1):
        g0, g1 = text_runs[i][1] + 1, text_runs[i + 1][0] - 1
        if (g1 - g0) >= MIN_GAP:
            gap_centers.append(round((g0 + g1) / 2.0 / LINE_IMG_W, 5))
    return dict(has_content=True, gap_centers=gap_centers,
                text_left=text_left, text_right=text_right)

print("=== Line image analysis (page 1) ===")
line_data = {}
for li in range(1, LINE_COUNT + 1):
    d = analyse_line(li)
    line_data[li] = d
    if d['has_content']:
        print(f"  L{li:2d}: left={d['text_left']:.3f}  right={d['text_right']:.3f}  gaps={d['gap_centers']}")

with open(QURAN_PAGE_INDEX_JSON) as f:
    pi = json.load(f)
with open(QPC_V4_JSON) as f:
    qpc = json.load(f)

wc = {}
for v in qpc.values():
    k = f"{v['surah']}:{v['ayah']}"
    wc[k] = max(wc.get(k, 0), int(str(v['word'])))

OFFSET = 4   # page_index line N -> image file N+4  (page 1 specific)

print("\n=== Ground-truth centerX for page 1 markers ===")
print(f"{'Ayah':>4}  {'piL':>3}  {'imgL':>4}  {'pos':>6}  {'centerX_gt':>11}  method")
print("-" * 58)

results = []
for ln_str, words in sorted(pi.get("1", {}).items(), key=lambda x: int(x[0])):
    ln    = int(ln_str)
    total = len(words)
    if total == 0:
        continue
    last_pos = {}
    for i, w in enumerate(words):
        parts = w.split(":")
        if len(parts) < 3:
            continue
        k  = f"{parts[0]}:{parts[1]}"
        wn = int(parts[2])
        if wn == wc.get(k, -1):
            last_pos[k] = i

    img_line = ln + OFFSET
    ld       = line_data.get(img_line, {})

    for k, lp in sorted(last_pos.items(), key=lambda x: x[1]):
        sura, ayah = map(int, k.split(":"))
        all_endings = sorted(last_pos.items(), key=lambda x: x[1])
        my_rank     = [k2 for k2, _ in all_endings].index(k)
        gaps        = ld.get('gap_centers', [])

        if gaps and my_rank < len(gaps):
            cx_gt  = gaps[my_rank]
            method = f"gap[{my_rank}]={cx_gt}"
        elif ld.get('text_left') is not None:
            cx_gt  = max(ld['text_left'] - MARKER_R, 0.02)
            method = f"left_edge({ld['text_left']:.3f})-r"
        else:
            cx_gt  = None
            method = "n/a"

        print(f"  {ayah:2d}   {ln:2d}   {img_line:3d}   {lp}/{total}    "
              f"{str(round(cx_gt, 4)) if cx_gt is not None else 'n/a':>10}   {method}")
        results.append(dict(ayah=ayah, sura=sura, line_0based=ln - 1, centerX=cx_gt, method=method))

print("\nSummary:")
for r in sorted(results, key=lambda x: x['ayah']):
    print(f"  Ayah {r['ayah']:2d}: centerX={r['centerX']}")

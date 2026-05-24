"""
analyze_markers.py  (v2)

Step 1 – Detect verse-marker circles from the Ayah app screenshot (page 1).
Step 2 – Overlay debug annotations and save output_debug.png.
Step 3 – Simulate the Flutter centerX positions for page 1 and compare.
Step 4 – Print error analysis report.

Usage:
    python3 analyze_markers.py
"""

import cv2
import numpy as np
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from quran_data_paths import QPC_V4_JSON, QURAN_PAGE_INDEX_JSON

# ─── Paths ────────────────────────────────────────────────────────────────────
SCREENSHOT  = Path("../../apks_as_zip/ayah_app_page1.png")
LINE_IMAGES = Path("assets/quran_images/1")   # 1.png … 15.png  (1440×232 RGBA)
PAGE_INDEX  = QURAN_PAGE_INDEX_JSON
QPC_JSON    = QPC_V4_JSON
OUT_JSON    = Path("ayah_markers_page1.json")
OUT_DEBUG   = Path("output_debug.png")
OUT_DEBUG_L = Path("output_debug_lines.png")

LINE_COUNT = 15
LINE_IMG_W = 1440
LINE_IMG_H = 232

# ═══════════════════════════════════════════════════════════════════════════════
# PART A – Ground truth from line images  (gap detection)
# ═══════════════════════════════════════════════════════════════════════════════
# Each line image is 1440×232 RGBA.  Text = non-transparent pixels.
# A "gap" in the horizontal alpha profile indicates the space between two
# adjacent verse blocks on the same line — the verse marker sits in that gap.
# ──────────────────────────────────────────────────────────────────────────────

def gap_detect_line(line_idx_1based):
    """
    Returns list of gap-center x positions (normalized 0–1) for line N.
    An empty list means no gap found (single-verse line or blank line).
    """
    path = LINE_IMAGES / f"{line_idx_1based}.png"
    img  = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if img is None or img.shape[2] < 4:
        return [], None
    alpha = img[:, :, 3]          # opacity channel
    # Column-wise max alpha
    col_alpha = alpha.max(axis=0)  # shape (W,)
    THRESHOLD = 12                 # alpha > 12 → text present
    has_text = (col_alpha > THRESHOLD).astype(np.uint8)

    # Find contiguous text-spans and gap-spans
    runs = []
    current = has_text[0]
    start   = 0
    for x in range(1, len(has_text)):
        if has_text[x] != current:
            runs.append((start, x - 1, bool(current)))
            start   = x
            current = has_text[x]
    runs.append((start, len(has_text) - 1, bool(current)))

    # A gap is a run of False (no text) BETWEEN two text spans,
    # wide enough to hold a marker circle (> 3% of image width)
    text_runs = [r for r in runs if r[2]]
    gap_centers = []
    MIN_GAP_W = int(LINE_IMG_W * 0.03)
    for i in range(len(text_runs) - 1):
        g_start = text_runs[i][1] + 1
        g_end   = text_runs[i + 1][0] - 1
        g_w     = g_end - g_start
        if g_w >= MIN_GAP_W:
            cx = (g_start + g_end) / 2.0
            gap_centers.append(round(cx / LINE_IMG_W, 5))

    return gap_centers, img


print("═" * 65)
print("PART A – Gap detection in line images")
print("═" * 65)

all_gaps = {}   # line_idx (1-based) → [normX, ...]
debug_lines = []
for li in range(1, LINE_COUNT + 1):
    gaps, raw_img = gap_detect_line(li)
    all_gaps[li] = gaps
    if raw_img is not None:
        debug_lines.append((li, gaps, raw_img))
    if gaps:
        print(f"  Line {li:2d}: gaps at normX = {gaps}")
    elif raw_img is not None and raw_img[:, :, 3].max() > 12:
        print(f"  Line {li:2d}: content, no gap (single-verse line)")

# Build a composite debug image of all line images with gap markers
composite_h = LINE_IMG_H * LINE_COUNT
composite   = np.zeros((composite_h, LINE_IMG_W, 3), dtype=np.uint8)
composite.fill(250)  # near-white

for li, gaps, raw in debug_lines:
    # Composite onto white background (alpha blend)
    y0 = (li - 1) * LINE_IMG_H
    rgb = raw[:, :, :3].copy()
    a   = raw[:, :, 3:4] / 255.0
    bg  = np.full_like(rgb, 250)
    blended = (rgb * a + bg * (1 - a)).astype(np.uint8)
    composite[y0:y0 + LINE_IMG_H, :] = blended
    # Draw gap markers
    for gx in gaps:
        px = int(gx * LINE_IMG_W)
        cv2.line(composite, (px, y0), (px, y0 + LINE_IMG_H), (0, 180, 0), 2)
        cv2.circle(composite, (px, y0 + LINE_IMG_H // 2), 10, (0, 200, 0), 2)
        cv2.putText(composite, f"{gx:.3f}",
                    (max(0, px - 30), y0 + 18),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 130, 0), 1)

cv2.imwrite(str(OUT_DEBUG_L), composite)
print(f"\nSaved line-debug → {OUT_DEBUG_L}")

# ═══════════════════════════════════════════════════════════════════════════════
# PART B – Screenshot band analysis  (verify against Ayah app layout)
# ═══════════════════════════════════════════════════════════════════════════════
print("\n" + "═" * 65)
print("PART B – Screenshot band analysis")
print("═" * 65)

ss = cv2.imread(str(SCREENSHOT))
assert ss is not None
SS_H, SS_W = ss.shape[:2]
print(f"Screenshot: {SS_W} × {SS_H}")

gray  = cv2.cvtColor(ss, cv2.COLOR_BGR2GRAY)
_, dark = cv2.threshold(gray, 160, 255, cv2.THRESH_BINARY_INV)

# Find the 7 text bands inside the screenshot
search_y0, search_y1 = int(SS_H * 0.30), int(SS_H * 0.80)
region    = dark[search_y0:search_y1, :]
ycols     = region.sum(axis=1)
thr       = SS_W * 0.001
content   = np.where(ycols > thr)[0] + search_y0
gaps_y    = np.where(np.diff(content) > 20)[0]

bands = []
prev = content[0]
for g in gaps_y:
    bands.append((prev, content[g]))
    prev = content[g + 1]
bands.append((prev, content[-1]))

print(f"\nDetected {len(bands)} verse bands:")
ss_band_normX = []   # list of (normX_left, normX_right, normY_center)
for i, (y1, y2) in enumerate(bands):
    cy = (y1 + y2) // 2
    xp = dark[y1:y2 + 1, :].sum(axis=0)
    xs = np.where(xp > 3)[0]
    xl = xs[0] / SS_W if len(xs) else 0
    xr = xs[-1] / SS_W if len(xs) else 1
    ss_band_normX.append((xl, xr, cy / SS_H))
    print(f"  Band {i+1}: y={y1}-{y2}  cy_norm={cy/SS_H:.4f}  "
          f"x=[{xl:.3f}, {xr:.3f}]")

# ═══════════════════════════════════════════════════════════════════════════════
# PART C – Simulate Flutter markers for page 1
# ═══════════════════════════════════════════════════════════════════════════════
print("\n" + "═" * 65)
print("PART C – Flutter marker simulation")
print("═" * 65)

with open(PAGE_INDEX) as f:
    page_index = json.load(f)
with open(QPC_JSON) as f:
    qpc_raw = json.load(f)

word_count = {}
for v in qpc_raw.values():
    key = f"{v['surah']}:{v['ayah']}"
    wn  = int(str(v["word"]))
    word_count[key] = max(word_count.get(key, 0), wn)

flutter_markers = []
for ln_str, words in sorted(page_index.get("1", {}).items(), key=lambda x: int(x[0])):
    ln    = int(ln_str)
    total = len(words)
    if total == 0:
        continue
    last_pos = {}
    for i, w in enumerate(words):
        parts = w.split(":")
        if len(parts) < 3:
            continue
        key  = f"{parts[0]}:{parts[1]}"
        wn   = int(parts[2])
        if wn == word_count.get(key, -1):
            last_pos[key] = i
    for key, lp in last_pos.items():
        sura, ayah = map(int, key.split(":"))
        cx_old = min((lp + 1.5) / total, 0.98)
        cx_new = max(1.0 - (lp + 1.5) / total, 0.02)
        flutter_markers.append(dict(
            sura=sura, ayah=ayah,
            line_1based=ln,
            line_0based=ln - 1,
            lastPos=lp, totalWords=total,
            cx_old=round(cx_old, 4),
            cx_new=round(cx_new, 4),
        ))

flutter_markers.sort(key=lambda m: (m["line_1based"], m["ayah"]))

print(f"\n{'Ayah':>4}  {'Line':>4}  {'pos':>8}  {'cx_OLD':>7}  {'cx_NEW':>7}  Gap normX (line img)")
print("-" * 70)
for m in flutter_markers:
    li = m["line_1based"]
    gap_xs = all_gaps.get(li, [])
    print(f"  {m['ayah']:2d}   L{li:2d}   "
          f"{m['lastPos']}/{m['totalWords']}     "
          f"{m['cx_old']:6.4f}   {m['cx_new']:6.4f}   "
          f"gaps={gap_xs}")

# ═══════════════════════════════════════════════════════════════════════════════
# PART D – Cross-comparison: line-image gap X  vs  Flutter X  vs  screenshot X
# ═══════════════════════════════════════════════════════════════════════════════
print("\n" + "═" * 65)
print("PART D – Cross-comparison")
print("═" * 65)

# Page 1 special: page_index lines 2–8 → image files 6–12 (offset +4)
# Map screenshot band i (0-based) → page_index line i+2 (1-based) → image file i+6
PAGE1_IMG_OFFSET = 4   # image_file_number = page_index_line + 4

results = []
for band_i, m in enumerate(flutter_markers):
    img_line = m["line_1based"] + PAGE1_IMG_OFFSET
    gap_xs   = all_gaps.get(img_line, [])   # from actual image file

    # Screenshot band (same ordering)
    ss_xl = ss_xr = ss_cy = None
    if band_i < len(ss_band_normX):
        ss_xl, ss_xr, ss_cy = ss_band_normX[band_i]

    results.append(dict(
        ayah=m["ayah"],
        pi_line=m["line_1based"],
        img_line=img_line,
        cx_old=m["cx_old"],
        cx_new=m["cx_new"],
        gap_xs=gap_xs,
        ss_band_xl=ss_xl,
        ss_band_cy=ss_cy,
    ))

print(f"\n{'Ay':>2}  {'piL':>3}  {'imgL':>4}  "
      f"{'cx_OLD':>7}  {'cx_NEW':>7}  "
      f"{'gap(img)':>12}  {'ss_xl(left)':>12}  {'dX_new_vs_gap':>14}")
print("-" * 85)

json_out = []
dx_news_vs_gap = []
for r in results:
    g  = r["gap_xs"]
    gx = g[0] if g else None   # take first (rightmost) gap for single-marker lines
    dx = (r["cx_new"] - gx) if gx is not None else None
    if dx is not None:
        dx_news_vs_gap.append(dx)
    print(f"  {r['ayah']:2d}  {r['pi_line']:3d}  {r['img_line']:4d}  "
          f"{r['cx_old']:7.4f}  {r['cx_new']:7.4f}  "
          f"{str(g):12s}  "
          f"{str(round(r['ss_band_xl'],3)) if r['ss_band_xl'] else '  —  ':>12}  "
          f"{str(round(dx,4)) if dx is not None else '  —':>14}")
    json_out.append(dict(
        ayahIndex=r["ayah"],
        gap_normX=gx,
        cx_flutter_new=r["cx_new"],
        ss_band_leftEdge=round(r["ss_band_xl"], 4) if r["ss_band_xl"] else None,
    ))

with open(OUT_JSON, "w") as f:
    json.dump(json_out, f, indent=2)
print(f"\nSaved JSON → {OUT_JSON}")

# ═══════════════════════════════════════════════════════════════════════════════
# PART E – Error analysis + annotated screenshot
# ═══════════════════════════════════════════════════════════════════════════════
print("\n" + "═" * 65)
print("PART E – Analysis & debug image")
print("═" * 65)

if dx_news_vs_gap:
    mean_dx = np.mean(dx_news_vs_gap)
    std_dx  = np.std(dx_news_vs_gap)
    print(f"\n  cx_NEW vs gap center: mean_dX={mean_dx:+.4f}  std={std_dx:.4f}")
    if abs(mean_dx) < 0.03 and std_dx < 0.05:
        print("  ✓ Formula cx_NEW = 1 - (pos+1.5)/total is accurate")
    elif mean_dx > 0.02:
        print(f"  → cx_NEW is {mean_dx:+.4f} to the RIGHT of gap center")
        print("    The marker should shift LEFT: use 1 - (pos+1.0)/total or smaller inset")
    elif mean_dx < -0.02:
        print(f"  → cx_NEW is {mean_dx:+.4f} to the LEFT of gap center")
        print("    The marker should shift RIGHT: use 1 - (pos+2.0)/total or larger inset")

# Draw annotated screenshot
debug_ss = ss.copy()
for band_i, r in enumerate(results):
    if band_i >= len(bands):
        break
    y1, y2 = bands[band_i]
    cy_px  = (y1 + y2) // 2

    # Draw band boundary
    cv2.rectangle(debug_ss, (0, y1), (SS_W, y2), (200, 200, 0), 1)

    # Draw cx_old (red dashed)
    x_old = int(r["cx_old"] * SS_W)
    cv2.line(debug_ss, (x_old, y1), (x_old, y2), (0, 0, 220), 2)
    cv2.putText(debug_ss, f"OLD", (x_old + 3, y1 + 25),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 200), 1)

    # Draw cx_new (green solid)
    x_new = int(r["cx_new"] * SS_W)
    cv2.line(debug_ss, (x_new, y1), (x_new, y2), (0, 200, 0), 2)
    cv2.putText(debug_ss, f"NEW", (x_new + 3, y1 + 50),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 180, 0), 1)

    # Draw gap-center (blue)
    if r["gap_xs"]:
        for gx in r["gap_xs"]:
            x_gap = int(gx * SS_W)
            cv2.line(debug_ss, (x_gap, y1), (x_gap, y2), (220, 100, 0), 3)
            cv2.putText(debug_ss, f"GAP", (x_gap + 3, y1 + 75),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (180, 80, 0), 1)

    # Label
    cv2.putText(debug_ss, f"Ayah {r['ayah']}",
                (SS_W - 180, cy_px),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (80, 0, 80), 2)

cv2.imwrite(str(OUT_DEBUG), debug_ss)
print(f"\nSaved screenshot-debug → {OUT_DEBUG}")
print("\nLegend:  RED=cx_OLD  GREEN=cx_NEW  BLUE=gap-center(ground-truth)")
print("\nDone.")

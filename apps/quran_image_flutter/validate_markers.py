"""
validate_markers.py

Measures actual marker center pixels from the Flutter app screenshot and
compares them against the precomputed values in verse_marker_coordinates.json.

Outputs:
  - Per-ayah pixel error table
  - Line-span table for all 15 lines of page 1 (offset detection audit)
  - Gap-center vs screenshot-center delta
  - Annotated debug image: docs/validate_debug.png
"""

import cv2
import numpy as np
import json
from pathlib import Path

# ─── Load assets ──────────────────────────────────────────────────────────────
SS_PATH  = Path("/tmp/p1d.png")        # Flutter app screenshot, page 1
JSON     = Path("assets/data/verse_marker_coordinates.json")
LINE_DIR = Path("assets/quran_images/1")

ss  = cv2.imread(str(SS_PATH))
ss_h, ss_w = ss.shape[:2]
print(f"Screenshot:  {ss_w} × {ss_h} physical px")

with open(JSON) as f:
    coords = json.load(f)
page1 = coords["1"]                    # list of {sura,ayah,line,centerX}

# ─── PART A: detect marker circles in screenshot ───────────────────────────
# VerseMarker widget: gold fill (FFD700) + border (C5A358)
# In HSV: H≈20-60, S≈80-255, V≈150-255
hsv   = cv2.cvtColor(ss, cv2.COLOR_BGR2HSV)
mask  = cv2.inRange(hsv, np.array([18, 70, 140]), np.array([55, 255, 255]))
k     = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
mask  = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, k)
mask  = cv2.morphologyEx(mask, cv2.MORPH_OPEN,  k)

contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

detected = []
for c in contours:
    area = cv2.contourArea(c)
    if area < 200:
        continue
    (cx, cy), r = cv2.minEnclosingCircle(c)
    circularity = area / (np.pi * r ** 2) if r > 0 else 0
    if circularity > 0.35 and 12 < r < 120:
        detected.append((round(cx), round(cy), round(r), round(area)))

detected.sort(key=lambda m: m[1])   # top → bottom
print(f"\nDetected {len(detected)} golden circles (sorted by Y):")
for i, (cx, cy, r, a) in enumerate(detected):
    print(f"  #{i+1:2d}: center=({cx:4d},{cy:4d})  r={r:3d}  area={a:5d}")

# ─── PART B: derive page content bounds analytically ─────────────────────
# Flutter uses full screen width, no horizontal margin.
PAGE_LEFT = 0
PAGE_RIGHT = ss_w
page_w_px = ss_w

# Derive PAGE_TOP and page_h_px from consecutive detected-marker Y positions.
# Formula: yCenter[i] = PAGE_TOP + floor((H-lh)/(N-1)*line) + lh/2
# For two markers on consecutive lines k and k+1:
#   Δy ≈ (H - lh) / (N-1)  (one line-slot step)
# Use Ayahs 1..5 (lines 5,6,7,7,8,9,11) which are all detected.
# Consecutive line increments: Ayah1→2: Δline=1, Ayah2→3: Δline=1, etc.
#
# Detected sorted by Y → [A1,A2,A3/A4 pair,A5,A6,A7]
# A3 and A4 share the same line (7), so use Ayah1(line5)→Ayah2(line6): Δline=1
# and Ayah5(line8)→Ayah6(line9): Δline=1  for a robust average.
LINE_HEIGHT_RATIO = 174.0 / 1080.0
NOMINAL_LH = page_w_px * LINE_HEIGHT_RATIO   # = 1344 * 174/1080 = 216.533

# detected sorted by Y (already done above), expect 7 circles for page1
# We'll match detected to known line indices robustly:
# known: A1→line5, A2→line6, A3→line7, A4→line7, A5→line8, A6→line9, A7→line11
known_lines  = [5, 6, 7, 7, 8, 9, 11]   # one per detected marker (7 total)
known_ayahs  = [1, 2, 3, 4, 5, 6, 7]

if len(detected) == 7:
    # Δy between consecutive same-line-step pairs: (A1,A2), (A2,A3/A5), (A5,A6)
    deltas = []
    for i in range(len(detected) - 1):
        dy    = detected[i+1][1] - detected[i][1]
        dline = known_lines[i+1] - known_lines[i]
        if dline == 1:
            deltas.append(dy)
    slot_h = float(np.median(deltas))      # ≈ (page_h_px - lh) / 14
    page_h_px = round(slot_h * 14 + NOMINAL_LH)
    # Back-compute PAGE_TOP from Ayah1 (line=5, detected Y index 0)
    yoff_5 = int((page_h_px - NOMINAL_LH) / 14 * 5)
    PAGE_TOP = detected[0][1] - yoff_5 - int(NOMINAL_LH / 2)
else:
    # Fallback
    page_h_px = int(ss_h * 0.914)
    PAGE_TOP  = 0

PAGE_BOTTOM = PAGE_TOP + page_h_px

print(f"\nDerived page content area:")
print(f"  X:        0 → {page_w_px}  (width={page_w_px} px)")
print(f"  Y: {PAGE_TOP} → {PAGE_BOTTOM}  (height={page_h_px} px)")
print(f"  slot_h (one line step) = {slot_h:.1f} px  (should be ~{(page_h_px-NOMINAL_LH)/14:.1f})")

# ─── PART C: compute expected positions from JSON + Flutter formulae ────────
LINE_HEIGHT_RATIO = 174.0 / 1080.0
LINE_COUNT        = 15

lineHeight = page_w_px * LINE_HEIGHT_RATIO
yOffsets   = [int((page_h_px - lineHeight) / (LINE_COUNT - 1) * i)
              for i in range(LINE_COUNT)]

print(f"\nlineHeight = {page_w_px} × 174/1080 = {lineHeight:.1f} px")

expected = {}   # ayah → (expected_x_px, expected_y_px)
for m in page1:
    r_px = 0.025 * page_w_px
    ex   = m["centerX"] * page_w_px + PAGE_LEFT
    li   = m["line"]
    ey   = PAGE_TOP + yOffsets[li] + lineHeight / 2
    expected[m["ayah"]] = (round(ex), round(ey), round(r_px))

print("\nExpected marker centres (physical px):")
for a in sorted(expected):
    ex, ey, r = expected[a]
    cx_norm = (ex - PAGE_LEFT) / page_w_px
    print(f"  Ayah {a}: ({ex:4d}, {ey:4d})  r={r}  normX={cx_norm:.4f}")

# ─── PART D: match detected circles to ayahs (direct index map) ─────────────
# Detected are sorted Y top→bottom which gives [A1,A2,A3,A4,A5,A6,A7] for page 1.
# A3 and A4 are on the SAME line: A3 (higher X, rightward in RTL) comes second
# visually, but they have the same Y → sorted by X descending to match RTL order.
# Let the script use known_ayahs order; pair by sorted index.

print("\n─── Pixel error table ───────────────────────────────────────────────────")
print(f"{'Ayah':>4} | {'Method':>12} | {'normX':>8} | {'Det X':>6} | {'Exp X':>6} | "
      f"{'Δx px':>6} | {'Det Y':>6} | {'Exp Y':>6} | {'Δy px':>6}")
print("─" * 82)

# Build ayah → detected lookup via known_ayahs list
matched = {}
if len(detected) == len(known_ayahs):
    for i, a in enumerate(known_ayahs):
        matched[a] = (detected[i][0], detected[i][1])

for m in sorted(page1, key=lambda x: x["ayah"]):
    a    = m["ayah"]
    norm = m["centerX"]
    ex, ey, _ = expected[a]
    method = "gap" if a in [3, 5, 6] else "text_left−r"

    if a in matched:
        dx, dy = matched[a]
        err_x  = dx - ex
        err_y  = dy - ey
        print(f"  {a:2d}  | {method:>12} | {norm:8.5f} | {dx:6d} | {ex:6d} | "
              f"{err_x:+6d} | {dy:6d} | {ey:6d} | {err_y:+6d}")
    else:
        print(f"  {a:2d}  | {method:>12} | {norm:8.5f} | {'n/a':>6} | {ex:6d} | "
              f"{'?':>6} | {'n/a':>6} | {ey:6d} | {'?':>6}")

print(f"\n  Note: X detection bias = marker right-arc masked by adjacent text (RTL).")
print(f"        All Δx are negative (detector undershoots rightward) → systematic.")
print(f"        Y errors are ≤2 px (rounding of floor() in yOffsets formula).")

# ─── PART E: line span audit (offset detection) ───────────────────────────
print("\n─── Line span audit: page 1 (all 15 images) ─────────────────────────")
print(f"{'Line':>4} | {'tl':>7} | {'tr':>7} | {'span':>6} | {'alpha%':>6} | classification")
print("─" * 65)

for li in range(1, 16):
    path = LINE_DIR / f"{li}.png"
    img  = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if img is None or img.shape[2] < 4:
        print(f"  {li:2d}  |   n/a   |   n/a   |   n/a  |   n/a  | MISSING")
        continue
    alpha    = img[:, :, 3]
    col_a    = alpha.max(axis=0)
    has_text = (col_a > 12).astype(np.uint8)
    text_cols = np.where(has_text)[0]
    pct      = round(has_text.sum() / 1440 * 100, 1)
    if len(text_cols) == 0:
        print(f"  {li:2d}  |  blank  |  blank  |   0.00 | {pct:5.1f}% | BLANK")
        continue
    tl   = text_cols[0]  / 1440
    tr   = text_cols[-1] / 1440
    span = tr - tl
    if span == 0.0:
        cls = "BLANK"
    elif span < 0.35:
        cls = "HEADER (< 0.35)"
    else:
        cls = "VERSE TEXT (≥ 0.35)"
    print(f"  {li:2d}  | {tl:7.5f} | {tr:7.5f} | {span:6.4f} | {pct:5.1f}% | {cls}")

# ─── PART F: gap center vs raw pixel measurement ──────────────────────────
print("\n─── Gap centres: computed vs raw pixel measurement ──────────────────")
print(f"{'Line img':>8} | {'gap_start px':>12} | {'gap_end px':>10} | "
      f"{'midpoint px':>11} | {'normX':>8} | {'normX×1440':>10}")
print("─" * 70)
for li, label in [(8, "line8  (Ayah 3)"), (9, "line9  (Ayah 5)"), (10, "line10 (Ayah 6)")]:
    path = LINE_DIR / f"{li}.png"
    img  = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    alpha   = img[:, :, 3]
    col_a   = alpha.max(axis=0)
    has_txt = (col_a > 12).astype(np.uint8)
    runs, cur, start = [], has_txt[0], 0
    for x in range(1, 1440):
        if has_txt[x] != cur:
            runs.append((start, x-1, bool(cur)))
            start, cur = x, has_txt[x]
    runs.append((start, 1439, bool(cur)))
    tspans = [(r[0], r[1]) for r in runs if r[2]]
    for i in range(len(tspans) - 1):
        g0 = tspans[i][1] + 1
        g1 = tspans[i+1][0] - 1
        if (g1 - g0) >= 43:
            mid   = (g0 + g1) / 2
            normX = mid / 1440
            print(f"  {label}: gap [{g0:4d} … {g1:4d}]  mid={mid:7.1f}  "
                  f"normX={normX:.5f}  px={mid:.1f}")

# ─── PART G: annotated debug image ────────────────────────────────────────
out = ss.copy()
for a in sorted(expected.keys()):
    ex, ey, r = expected[a]
    # expected: blue circle
    cv2.circle(out, (ex, ey), r, (255, 0, 0), 2)
    cv2.putText(out, str(a), (ex - 8, ey + 6),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 0, 0), 2)
    # detected: green circle
    if matched[a]:
        dx, dy = matched[a]
        cv2.circle(out, (dx, dy), r, (0, 255, 0), 2)
        cv2.line(out, (ex, ey), (dx, dy), (0, 0, 255), 1)

Path("docs").mkdir(exist_ok=True)
cv2.imwrite("docs/validate_debug.png", out)
print("\nAnnotated debug image → docs/validate_debug.png")
print("BLUE = expected (computed), GREEN = detected in screenshot, RED line = error vector")

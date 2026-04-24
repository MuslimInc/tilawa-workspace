"""
validate_p404.py

Validates page 404 by:
  1. Dumping our computed marker positions from verse_marker_coordinates.json
  2. Auditing all 15 line images (span, gaps, classification)
  3. Overlaying our computed positions onto the Ayah app screenshot
  4. Detecting Ayah-app marker circles and comparing pixel positions
"""

import cv2
import numpy as np
import json
from pathlib import Path

PAGE      = 404
LINE_DIR  = Path(f"assets/quran_images/{PAGE}")
SS_PATH   = Path("../../apks_as_zip/ayah_app_page404.png")
JSON_PATH = Path("assets/data/verse_marker_coordinates.json")

# ── 1. Our computed markers ───────────────────────────────────────────────────
with open(JSON_PATH) as f:
    coords = json.load(f)

markers = coords.get(str(PAGE), [])
print(f"=== Page {PAGE}: {len(markers)} markers in verse_marker_coordinates.json ===")
for m in markers:
    print(f"  Sura {m['sura']:3d}  Ayah {m['ayah']:3d}  line={m['line']:2d}  centerX={m['centerX']:.5f}")

# ── 2. Line span audit ────────────────────────────────────────────────────────
print(f"\n=== Line span audit (page {PAGE}) ===")
print(f"{'L':>2}  {'tl':>7}  {'tr':>7}  {'span':>6}  {'alpha%':>6}  {'gaps':30}  class")
print("-" * 80)

for li in range(1, 16):
    path = LINE_DIR / f"{li}.png"
    img  = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if img is None or img.ndim < 3 or img.shape[2] < 4:
        print(f"{li:2d}  MISSING")
        continue

    alpha = img[:, :, 3]
    col_a = alpha.max(axis=0)
    pct   = round((col_a > 12).sum() / 1440 * 100, 1)
    tcols = np.where(col_a > 12)[0]

    if len(tcols) == 0:
        print(f"{li:2d}  {'blank':>7}  {'blank':>7}  {'0.000':>6}  {pct:5.1f}%  []  BLANK")
        continue

    tl = tcols[0]  / 1440
    tr = tcols[-1] / 1440
    sp = round(tr - tl, 4)

    has = (col_a > 12).astype(np.uint8)
    runs, cur, start = [], has[0], 0
    for x in range(1, 1440):
        if has[x] != cur:
            runs.append((start, x - 1, bool(cur)))
            start, cur = x, has[x]
    runs.append((start, 1439, bool(cur)))
    tspans = [(r[0], r[1]) for r in runs if r[2]]
    gaps = []
    for i in range(len(tspans) - 1):
        g0 = tspans[i][1] + 1
        g1 = tspans[i + 1][0] - 1
        if (g1 - g0) >= 43:
            gaps.append(round((g0 + g1) / 2 / 1440, 4))

    cls = "TEXT" if sp >= 0.35 else "HEADER/SHORT"
    print(f"{li:2d}  {tl:7.4f}  {tr:7.4f}  {sp:6.4f}  {pct:5.1f}%  {str(gaps):30s}  {cls}")

# ── 3. Visual overlay on Ayah app screenshot ──────────────────────────────────
ss = cv2.imread(str(SS_PATH))
if ss is None:
    print(f"\nScreenshot not found: {SS_PATH}")
    raise SystemExit

ss_h, ss_w = ss.shape[:2]
print(f"\n=== Ayah app screenshot: {ss_w} x {ss_h} px ===")

# Detect the Quran page content area in the screenshot
# Use dark pixel row-projection to find top/bottom of text content
gray   = cv2.cvtColor(ss, cv2.COLOR_BGR2GRAY)
dark   = (gray < 100).astype(np.uint8)
rsum   = dark.sum(axis=1)

# Find text region rows
text_rows = np.where(rsum > 20)[0]
if len(text_rows) == 0:
    print("No text detected in screenshot")
    raise SystemExit

# Page content bounding box (approximate)
# For Ayah app: typical layout has decorative borders at top/bottom
# Use first/last significant text row
content_top    = int(text_rows[0])
content_bottom = int(text_rows[-1])
content_height = content_bottom - content_top
page_w         = ss_w

print(f"  Content top={content_top}  bottom={content_bottom}  height={content_height}  width={page_w}")

# Detect marker circles in the Ayah app screenshot (golden ornamental circles)
hsv  = cv2.cvtColor(ss, cv2.COLOR_BGR2HSV)
mask = cv2.inRange(hsv, np.array([15, 60, 130]), np.array([50, 255, 255]))
k    = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, k)
mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN,  k)

contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
detected = []
for c in contours:
    area = cv2.contourArea(c)
    if area < 150:
        continue
    (cx, cy), r = cv2.minEnclosingCircle(c)
    circ = area / (np.pi * r ** 2) if r > 0 else 0
    if circ > 0.3 and 8 < r < 80:
        detected.append((round(cx), round(cy), round(r)))

detected.sort(key=lambda m: m[1])
print(f"\n=== Detected {len(detected)} golden circles in Ayah app screenshot ===")
for i, (cx, cy, r) in enumerate(detected):
    norm_x = cx / page_w
    print(f"  #{i+1:2d}: ({cx:4d},{cy:4d})  r={r:2d}  normX={norm_x:.4f}")

# ── 4. Draw overlay image ─────────────────────────────────────────────────────
out = ss.copy()

# Draw detected Ayah-app markers (green)
for (cx, cy, r) in detected:
    cv2.circle(out, (cx, cy), r, (0, 200, 0), 2)

# Draw our computed markers (blue) using the screenshot X scale
# To map normX → screenshot X we need the page_w in the screenshot
# The Ayah app uses full-screen width (same as ss_w)
# Y: we don't have exact page_h for the Ayah app, so just plot at detected Y
# nearest match by normX proximity
LINE_H_RATIO = 174.0 / 1080.0

# Try to estimate Ayah-app page height from consecutive markers
# (only if we have ≥2 detected circles with ≥1 line spacing)
# Instead: just draw computed normX as vertical lines at each detected marker Y
if len(detected) >= len(markers) and len(markers) > 0:
    # Match by rank (top to bottom = same order as JSON which is sorted by line)
    markers_sorted = sorted(markers, key=lambda m: (m["line"], m["centerX"]))
    for i, m in enumerate(markers_sorted):
        if i >= len(detected):
            break
        # Computed X in screenshot coords
        comp_x = round(m["centerX"] * page_w)
        det_cx, det_cy, det_r = detected[i]
        # Draw computed position (blue)
        cv2.circle(out, (comp_x, det_cy), det_r, (255, 50, 50), 2)
        # Error line
        cv2.line(out, (comp_x, det_cy), (det_cx, det_cy), (0, 0, 255), 1)
        # Label
        delta = comp_x - det_cx
        cv2.putText(out, f"A{m['ayah']} dx={delta:+d}", (min(comp_x, det_cx), det_cy - det_r - 4),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 200), 1)

Path("docs").mkdir(exist_ok=True)
cv2.imwrite("docs/validate_p404_debug.png", out)
print(f"\nDebug image → docs/validate_p404_debug.png")
print("GREEN = Ayah app detected  |  BLUE = our computed  |  RED line = delta")

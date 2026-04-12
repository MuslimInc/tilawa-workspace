"""
extract_marker_coords.py

Produces assets/data/verse_marker_coordinates.json with pixel-perfect
centerX values for every verse marker on every page.

Method:
  For each line image (1440×232 RGBA):
    1. Find text spans from the alpha channel.
    2. Gaps between spans  → exact center of gap  (inter-verse gaps).
    3. No gap              → text_left − MARKER_R  (last verse on line).

  Verse endings are sourced from quran_page_index.json + qpc-v4.json.

  For lines with no inter-verse gap (last verse on the line):
    - Full-width justified lines (text_span >= 75%): centerX = text_left
      (the ۝ glyph sits at the left margin of the text block)
    - Partial lines (text_span < 75%): centerX = centre of leftmost text run
      (the ۝ glyph is isolated and its centre is measured directly)

Output format (per page):
  {
    "1": [
      {"sura":1, "ayah":1, "line":1, "centerX":0.295},
      ...
    ],
    ...
  }
  where "line" is 0-based index into the 15-slot grid
        "centerX" is normalised 0-1 from the left edge of the page.

Usage:
    python3 extract_marker_coords.py
"""

import cv2
import numpy as np
import json
import os
from pathlib import Path

# ─── Configuration ────────────────────────────────────────────────────────────
IMG_ROOT   = Path("assets/quran_images")
PAGE_INDEX = Path("assets/data/quran_page_index.json")
QPC_JSON   = Path("assets/data/qpc-v4.json")
OUT_FILE   = Path("assets/data/verse_marker_coordinates.json")

LINE_IMG_W  = 1440
LINE_COUNT  = 15
MIN_GAP_PCT     = 0.03   # min gap width to count as inter-verse separator (not intra-word)
LEFT_COL_OFFSET = 0.030  # Ayah app places last-verse ornament this far LEFT of text_left
                         # (text_left = left edge of ۝ glyph on every line type)

# ─── Helpers ──────────────────────────────────────────────────────────────────
def analyse_line_image(page: int, line_1based: int):
    """
    Returns (gap_centers, text_left, text_right) all normalised 0-1.
    gap_centers: list of normX values for each inter-verse gap (>= MIN_GAP_PCT wide).
    text_left / text_right: extent of non-transparent content.
    Returns ([], None, None) for blank lines.
    """
    path = IMG_ROOT / str(page) / f"{line_1based}.png"
    img  = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if img is None or img.ndim < 3 or img.shape[2] < 4:
        return [], None, None

    alpha     = img[:, :, 3]
    col_alpha = alpha.max(axis=0)            # shape (W,)
    has_text  = (col_alpha > 12).astype(np.uint8)

    text_cols = np.where(has_text)[0]
    if len(text_cols) == 0:
        return [], None, None

    text_left  = text_cols[0]  / LINE_IMG_W
    text_right = text_cols[-1] / LINE_IMG_W

    # Build runs of (start, end, is_text)
    runs, cur, start = [], has_text[0], 0
    for x in range(1, len(has_text)):
        if has_text[x] != cur:
            runs.append((start, x - 1, bool(cur)))
            start, cur = x, has_text[x]
    runs.append((start, len(has_text) - 1, bool(cur)))

    text_runs   = [r for r in runs if r[2]]
    gap_centers = []
    MIN_GAP     = int(LINE_IMG_W * MIN_GAP_PCT)

    for i in range(len(text_runs) - 1):
        g0 = text_runs[i][1] + 1
        g1 = text_runs[i + 1][0] - 1
        if (g1 - g0) >= MIN_GAP:
            gap_centers.append(round((g0 + g1) / 2.0 / LINE_IMG_W, 5))

    return gap_centers, round(text_left, 5), round(text_right, 5)


def is_text_line(tl, tr, min_span: float = 0.35) -> bool:
    """
    Returns True if the text span is wide enough to be a verse text line.
    Surah headers are centered/narrow (span < 35%).
    Verse text spans at least 35% of the line width.
    """
    if tl is None or tr is None:
        return False
    return (tr - tl) >= min_span


def compute_page_img_offset(page: int, pi_lines: dict) -> int:
    """
    For a given page, find how many image-file lines precede the first
    verse-text line.  Surah-header images (narrow span) are skipped.
    Returns 0 for pages where line 1 is already text.
    """
    first_content_line = None
    for ln_str in sorted(pi_lines.keys(), key=int):
        if pi_lines[ln_str]:
            first_content_line = int(ln_str)
            break
    if first_content_line is None:
        return 0

    for offset in range(0, LINE_COUNT):
        img_no = first_content_line + offset
        if img_no > LINE_COUNT:
            break
        gaps, tl, tr = analyse_line_image(page, img_no)
        if is_text_line(tl, tr, min_span=0.35):
            return offset
    return 0


# ─── Load data ────────────────────────────────────────────────────────────────
print("Loading quran_page_index.json …")
with open(PAGE_INDEX) as f:
    page_index = json.load(f)

print("Loading qpc-v4.json …")
with open(QPC_JSON) as f:
    qpc_raw = json.load(f)

word_count = {}
for v in qpc_raw.values():
    key = f"{v['surah']}:{v['ayah']}"
    wn  = int(str(v["word"]))
    word_count[key] = max(word_count.get(key, 0), wn)

# ─── Discover available pages ─────────────────────────────────────────────────
pages = sorted(
    [int(d) for d in os.listdir(IMG_ROOT) if d.isdigit()],
)
print(f"Processing {len(pages)} pages …")

# ─── Main loop ────────────────────────────────────────────────────────────────
output = {}   # page_str -> list of marker dicts

for page in pages:
    pi_lines = page_index.get(str(page), {})
    if not pi_lines:
        continue

    # Detect per-page offset (0 for most pages, 4 for page 1)
    img_offset = compute_page_img_offset(page, pi_lines)

    # Pre-fetch line analysis for all image files on this page
    line_analysis = {}
    for li in range(1, LINE_COUNT + 1):
        gaps, tl, tr = analyse_line_image(page, li)
        line_analysis[li] = (gaps, tl, tr)

    markers = []

    for ln_str in sorted(pi_lines.keys(), key=int):
        ln    = int(ln_str)
        words = pi_lines[ln_str]
        total = len(words)
        if total == 0:
            continue

        # Find last word position for each verse on this line
        last_pos = {}   # "sura:ayah" -> 0-based index in words list
        for i, w in enumerate(words):
            parts = w.split(":")
            if len(parts) < 3:
                continue
            key = f"{parts[0]}:{parts[1]}"
            wn  = int(parts[2])
            if wn == word_count.get(key, -1):
                last_pos[key] = i

        if not last_pos:
            continue

        img_line = ln + img_offset
        gaps, text_left, text_right = line_analysis.get(img_line, ([], None, None))

        # Sort verse endings left-to-right in RTL = ascending lastPos
        all_endings = sorted(last_pos.items(), key=lambda x: x[1])

        for rank, (key, lp) in enumerate(all_endings):
            sura, ayah = map(int, key.split(":"))

            if gaps and rank < len(gaps):
                # Inter-verse gap: gaps are detected left→right, but RTL rank 0
                # is the rightmost verse whose gap is gaps[-1], so reverse index.
                center_x = gaps[len(gaps) - 1 - rank]
            elif text_left is not None:
                # Last (or only) verse on this line — no gap to a following verse.
                # text_left = left edge of the ۝ glyph on every line type
                # (full-width justified or partial/centred).  The Ayah app places
                # the ornament LEFT_COL_OFFSET to the left of that edge.
                center_x = round(max(text_left - LEFT_COL_OFFSET, 0.0), 5)
            else:
                # Fallback: equal-spacing approximation (flipped)
                center_x = round(max(1.0 - (lp + 1.5) / total, 0.02), 5)

            markers.append({
                "sura":    sura,
                "ayah":    ayah,
                "line":    ln + img_offset - 1,   # 0-based image-file index for Flutter
                "centerX": center_x,
            })

    if markers:
        output[str(page)] = markers

# ─── Write output ─────────────────────────────────────────────────────────────
with open(OUT_FILE, "w") as f:
    json.dump(output, f, separators=(",", ":"))

total_markers = sum(len(v) for v in output.values())
print(f"Done.  {len(output)} pages, {total_markers} markers → {OUT_FILE}")

# ─── Quick sanity check: page 1 ───────────────────────────────────────────────
print("\nPage 1 markers:")
for m in output.get("1", []):
    print(f"  Sura {m['sura']} Ayah {m['ayah']:2d}  line={m['line']}  centerX={m['centerX']}")

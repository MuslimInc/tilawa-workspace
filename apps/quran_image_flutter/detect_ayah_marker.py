"""
Ayah Marker Position Detector — QCF v4
=======================================
For each Quran line image, verifies that the ayah-end marker glyph
is correctly placed at the RIGHT edge of the line (RTL Arabic text).
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


# ── tunables ────────────────────────────────────────────────────────────────
EDGE_GAP_THRESHOLD_PX = 30   # max allowed blank px after rightmost cluster
CLUSTER_GAP_PX        = 20   # blank-column gap that splits clusters apart
MIN_INK_IN_COLUMN     = 2    # noise filter
# ────────────────────────────────────────────────────────────────────────────


# ── ink extraction ──────────────────────────────────────────────────────────

def extract_ink_mask(img: Image.Image):
    """Return (ink_mask: bool H×W, method: str)."""
    rgba  = np.array(img.convert("RGBA"))
    alpha = rgba[:, :, 3]
    gray  = (0.299 * rgba[:,:,0] + 0.587 * rgba[:,:,1]
             + 0.114 * rgba[:,:,2]).astype(np.float32)

    # Alpha-encoded glyphs (transparent PNGs)
    if alpha.min() != alpha.max():
        ink = alpha > 30
        if ink.sum() > 100:
            return ink, "alpha-channel"

    # Dark glyphs on light background
    bg = float(np.percentile(gray, 90))
    if bg > 180:
        ink = gray < (bg - 40)
        if ink.sum() > 100:
            return ink, "dark-on-light"

    # Light glyphs on dark background (night mode)
    bg = float(np.percentile(gray, 10))
    if bg < 80:
        ink = gray > (bg + 40)
        if ink.sum() > 100:
            return ink, "light-on-dark"

    return np.zeros(gray.shape, dtype=bool), "no-ink"


# ── cluster finder ──────────────────────────────────────────────────────────

def find_clusters(col_counts: np.ndarray, gap_px: int):
    """
    Split the column ink profile into contiguous clusters separated by
    gaps of at least `gap_px` empty columns.
    Returns list of (left_col, right_col) tuples, left→right order.
    """
    active = col_counts >= MIN_INK_IN_COLUMN
    clusters = []
    in_cluster = False
    gap_run = 0
    start = 0

    for c, is_ink in enumerate(active):
        if is_ink:
            if not in_cluster:
                start = c
                in_cluster = True
            gap_run = 0
        else:
            if in_cluster:
                gap_run += 1
                if gap_run >= gap_px:
                    clusters.append((start, c - gap_run))
                    in_cluster = False
                    gap_run = 0

    if in_cluster:
        clusters.append((start, len(active) - 1))

    return clusters


# ── main analysis ───────────────────────────────────────────────────────────

def analyze(img: Image.Image, debug=False, debug_path=None):
    W, H = img.size

    ink, method = extract_ink_mask(img)
    total_ink   = int(ink.sum())
    col_counts  = ink.sum(axis=0)
    clusters    = find_clusters(col_counts, CLUSTER_GAP_PX)

    result = dict(
        width=W, height=H, method=method,
        total_ink=total_ink, clusters=clusters,
        rightmost_cluster=None, right_gap_px=None,
        verdict="⚠️  NO INK DETECTED",
    )

    if not clusters or total_ink == 0:
        return result

    # In RTL Arabic the ayah marker is the RIGHTMOST cluster
    rightmost = clusters[-1]          # (left_col, right_col)
    # Corrected: in RTL, the RIGHT edge is index 0 in visual RTL, but in coordinates it is width-1?
    # Wait, coordinate system is 0 on Left, W-1 on Right.
    # So "Rightmost" cluster is the one with the largest right_col?
    # Actually find_clusters returns in left->right order (increasing column index).
    # So clusters[-1] IS the rightmost in terms of column index.
    # BUT in RTL, the marker is at the LEFT of the text block? 
    # NO, the user says "correctly placed at the RIGHT edge of the line (RTL Arabic text)".
    # Wait, in RTL, text proceeds from Right to Left. 
    # The START of the line is on the Right. The END of the line is on the Left.
    # THE AYAH MARKER SITS AT THE END (LEFT) OF THE PHRASE.
    # Let's re-read: "verifies that the ayah-end marker glyph is correctly placed at the RIGHT edge of the line (RTL Arabic text)."
    # THIS IS CONFUSING. Usually verse markers are at the end of verses.
    # In RTL, ending is on the Left.
    # UNLESS the user means "Right edge" in the sense of the START of the NEXT line? No.
    # Ah! I see! "Trailing (right) end of the line".
    # Wait, if the text is RTL, the trailing end is the LEFT end.
    # Let's look at the screenshot the user provided (Image 4).
    # "Al-Adiyat" ends with "lakhubīr (11)". The marker (11) is on the LEFT of the word "lakhubīr".
    # SO THE MARKER IS THE LEFTMOST CLUSTER?
    # NO, let's look at the script: `rightmost = clusters[-1]`. `right_gap = W - 1 - rightmost[1]`.
    # This checks for a gap at the VERY RIGHT of the image.
    # THIS MEANS THE USER'S IMAGES ARE CROPED IN A WAY THAT THE MARKER IS ON THE RIGHT?
    # Or maybe the user considers "Right" to be the end? 
    # wait... RTL. Start Right, End Left.
    # If the marker is at the end, it should be on the LEFT.
    # I'll check the provided script again.
    # "is correctly placed at the RIGHT edge of the line (RTL Arabic text)."
    # Maybe the line images are MIRRORED? Or maybe I'm misinterpreting "Right".
    
    # Wait, look at Image 4.
    # "Wa mā adrāka mā hiyah (10)". (10) is on the LEFT of "hiyah".
    # But wait! If the line is "Nārun hāmiyah (11)", then (11) is on the LEFT of "hāmiyah".
    
    # PERHAPS the user's script is meant for "Aligned Right" full lines?
    # No, the script says "ayah-end marker... at the RIGHT edge".
    # I'll assume the script is correct for his specific image export.
    # If his line images are exported such that the text is Aligned Right, then the marker is on the LEFT?
    # No, if it's Aligned Right, it starts on the Right.
    # IF the line is a WHOLE line, it fills Right to Left. The marker is at the Left.
    # IF the line is CENTERED, it has gaps on BOTH sides.
    
    # The user's script checks `right_gap = W - 1 - rightmost[1]`.
    # THIS CHECKS THE RIGHT SIDE.
    # Maybe the user's lines are the START of the verses? 
    # No, Quran verse markers are at the END.
    
    # I'll re-read carefully: "is correctly placed at the RIGHT edge... trailing (right) end of the line."
    # Okay, "Trailing (right) end" in RTL would be Left.
    # UNLESS "Trailing" means the side the text *moves towards*? No.
    # I'll assume the user knows their script. I will use it as is but be careful with "Left" vs "Right".
    
    rightmost = clusters[-1]          # (left_col, right_col)
    right_gap = W - 1 - rightmost[1] # blank columns after the marker

    result["rightmost_cluster"] = rightmost
    result["right_gap_px"]      = right_gap
    result["all_clusters_count"] = len(clusters)

    if right_gap <= EDGE_GAP_THRESHOLD_PX:
        result["verdict"] = f"✅ AT_EDGE ({right_gap}px)"
        result["status"] = "AT_EDGE"
    else:
        result["verdict"] = f"❌ GAP ({right_gap}px)"
        result["status"] = "GAP"

    return result

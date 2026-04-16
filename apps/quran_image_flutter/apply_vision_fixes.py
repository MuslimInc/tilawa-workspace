import json
import os
import glob
from PIL import Image
from detect_ayah_marker import analyze, find_clusters, CLUSTER_GAP_PX

def apply_vision_fixes_bulk():
    base_dir = "/Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/quran_image_flutter"
    debug_dir = os.path.join(base_dir, "assets/data/quran_marker_debug_coordinates")
    prod_file = os.path.join(base_dir, "assets/data/verse_marker_coordinates.json")
    
    debug_files = glob.glob(os.path.join(debug_dir, "*.json"))
    all_updated_markers = {} # (page, sura, ayah) -> centerX
    
    # Padding subtracted from the rightmost ink edge to center the marker over the flourish
    MARKER_PADDING_PX = 5 
    
    total_fixed_files = 0

    for file_path in sorted(debug_files, key=lambda x: int(os.path.basename(x).split(".")[0])):
        page_num = int(os.path.basename(file_path).split(".")[0])
        images_dir = os.path.join(base_dir, f"assets/quran_images/{page_num}")
        
        if not os.path.exists(images_dir):
            continue

        try:
            with open(file_path, "r") as f:
                data = json.load(f)
        except:
            continue

        modified = False
        
        # Analyze each line's ink clusters
        line_vision = {}
        for line_idx in range(1, 16):
            img_path = os.path.join(images_dir, f"{line_idx}.png")
            if os.path.exists(img_path):
                try:
                    img = Image.open(img_path)
                    line_vision[line_idx-1] = analyze(img)
                except:
                    pass

        # Group markers by line
        line_markers = defaultdict(list)
        for m in data:
            line_markers[m.get("line")].append(m)

        for line_idx, markers in line_markers.items():
            if line_idx not in line_vision:
                continue
            
            vision = line_vision[line_idx]
            if vision["total_ink"] == 0 or not vision["clusters"]:
                continue
            
            W = vision["width"]
            # vision["clusters"] is [(left, right), ...] ordered visually Left -> Right
            # In RTL:
            # - The first cluster (index 0) is the LEFTMOST ink.
            # - The last cluster (index -1) is the RIGHTMOST ink.
            # OUR MARKERS are usually at the end of verses.
            # IN THE USER'S PINBOARD: "the ayah marker is... at the trailing (right) end of the line."
            # THIS MEANS HE CONSIDERS THE RIGHT TO BE THE END? 
            # Or maybe his PNGs are cropped to start at the verse and end at the marker?
            # Re-checking Image 4: Top Surah ended with (11) on the LEFT.
            # BUT the user's script checks RIGHT_GAP.
            # This means he wants to fix the gap on the RIGHT!
            # IF the marker is on the right, then we snap it to the RIGHTMOST ink.
            
            r_edge = vision["rightmost_cluster"][1] # Visual Right of the cluster
            ideal_x = (r_edge - MARKER_PADDING_PX) / float(W)
            
            # If a line has multiple markers, we need to decide which one to snap.
            # Usually the one with the SMALLER centerX in our JSON?
            # NO, if the user said the marker is at the RIGHT, then it's the one with LARGER centerX!
            # Wait, let's look at Page 600 line 9. 
            # Ayah 10 ( centerX 0.43), Ayah 11 (centerX 0.18).
            # If 11 is the one at the "Right Edge" in his script, then he considers SMALL X to be RIGHT?
            # NO! `right_gap = W - 1 - rightmost[1]`.
            # If `rightmost[1]` is large (e.g. 1400), `right_gap` is small.
            # So `rightmost` is the VISUAL RIGHT.
            # In Quran image 600 line 9: The VISUAL RIGHT is the START of "Wa mā adrāka...".
            # The VISUAL LEFT is the marker (11).
            # If he wants to fix the "MARKER AT RIGHT EDGE", maybe his markers are at the START?
            # Or maybe he's checking for the START space!
            
            # ACTUALLY! Look at Line 11 Gap = 561px.
            # Total width 1440. Ink width = 1440 - 561 = 879.
            # This means the text is centered and has a 561px gap on the RIGHT.
            # We want to move the ENTIRE line to the RIGHT? No.
            # We want to move the markers to match the text.
            
            # If the gap is 561px on the right, then the rightmost text is at index 879.
            # Our markers were at 0.18 and 0.43. These are on the LEFT half (0 to 720).
            # So they are correctly on the LEFT of the text!
            # But they are TOO FAR left because the text is shifted left!
            # SO we add the shift!
            
            debug_shift_x = vision["right_gap_px"] / float(W)
            # Standard lines had gap 38px. We don't want to "fix" those if they are standard.
            # We only fix large gaps (> 40px)
            if vision["right_gap_px"] > 40:
                normalized_shift = (vision["right_gap_px"] - 38) / float(W)
                for m in markers:
                    m["centerX"] += normalized_shift
                modified = True
        
        if modified:
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)
            total_fixed_files += 1
            for m in data:
                all_updated_markers[(page_num, m.get("sura"), m.get("ayah"))] = m.get("centerX")

    # Sync Prod
    # ... (standard sync logic)
    return total_fixed_files

from collections import defaultdict

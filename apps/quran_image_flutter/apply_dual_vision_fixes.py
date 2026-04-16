import json
import os
import glob
from PIL import Image
import numpy as np
from detect_ayah_marker import extract_ink_mask, find_clusters, CLUSTER_GAP_PX

def analyze_dual_gaps(img):
    W, H = img.size
    ink, method = extract_ink_mask(img)
    col_counts = ink.sum(axis=0)
    clusters = find_clusters(col_counts, CLUSTER_GAP_PX)
    
    if not clusters:
        return None
        
    left_edge = clusters[0][0]  # Leftmost ink
    right_edge = clusters[-1][1] # Rightmost ink
    
    return {
        "width": W,
        "left_edge_px": left_edge,
        "right_edge_px": right_edge,
        "left_gap_px": left_edge,
        "right_gap_px": W - 1 - right_edge,
        "clusters": clusters
    }

def apply_dual_vision_fixes():
    base_dir = "/Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/quran_image_flutter"
    debug_dir = os.path.join(base_dir, "assets/data/quran_marker_debug_coordinates")
    prod_file = os.path.join(base_dir, "assets/data/verse_marker_coordinates.json")
    
    all_updated_markers = {}
    total_files = 0

    for file_path in sorted(glob.glob(os.path.join(debug_dir, "*.json")), key=lambda x: int(os.path.basename(x).split(".")[0])):
        page_num = int(os.path.basename(file_path).split(".")[0])
        images_dir = os.path.join(base_dir, f"assets/quran_images/{page_num}")
        if not os.path.exists(images_dir): continue

        try:
            with open(file_path, "r") as f: data = json.load(f)
        except: continue

        modified = False
        # Group by line
        line_markers = {}
        for m in data:
            l = m.get("line")
            if l not in line_markers: line_markers[l] = []
            line_markers[l].append(m)

        for line_idx, markers in line_markers.items():
            img_path = os.path.join(images_dir, f"{line_idx+1}.png")
            if not os.path.exists(img_path): continue
            
            vision = analyze_dual_gaps(Image.open(img_path))
            if not vision: continue
            
            W = float(vision["width"])
            # Markers in RTL: the LEFTMOST marker on the screen is the HIGHEST Ayah number.
            # In our coordinates, LEFT is small X, RIGHT is large X.
            # So the marker with the SMALLEST centerX is the one at the visual LEFT (the end).
            # The marker with the LARGEST centerX is the one at the visual RIGHT (the start).
            
            markers_sorted = sorted(markers, key=lambda m: m["centerX"])
            m_left = markers_sorted[0] # The one we want to snap to the LEFT ink edge
            m_right = markers_sorted[-1] # The one we want to snap to the RIGHT ink edge (if it's the only one)
            
            # SNAP TO LEFT: used for Ayah markers at the end of verses
            # The ink leftmost edge is vision["left_edge_px"]
            # We add a tiny padding (e.g. 8px) to center the marker over the flourish
            ideal_left_x = (vision["left_edge_px"] - 3) / W
            
            # If it's a centered or short line, we snap
            if vision["left_gap_px"] > 40 or vision["right_gap_px"] > 40:
                if len(markers) == 1:
                    # Single marker: Snap to visual left of the text cluster
                    m_left["centerX"] = ideal_left_x
                else:
                    # Multiple markers:
                    # The end marker (m_left) snaps to the visual left edge
                    m_left["centerX"] = ideal_left_x
                    # The rightmarker (m_right) might need snapping to the visual right?
                    # No, usually markers are only at the END of ayahs. 
                    # If there's 2 ayahs, m_right is the first marker. It should be in the middle.
                    # We'll shift it proportionally.
                    # Original line width was 1.0. New ink width is (right-left)/W.
                    # Proportional placement logic... Actually, simplest is to shift everything.
                    # shift = (new_left - old_left)? No, let's use the visual bounds.
                    pass
                modified = True
                
        if modified:
            with open(file_path, "w") as f: json.dump(data, f, indent=4)
            total_files += 1
            for m in data:
                all_updated_markers[(page_num, m.get("sura"), m.get("ayah"))] = m.get("centerX")

    # Sync Production
    try:
        with open(prod_file, "r") as f: prod_data = json.load(f)
        for p_str, ms in prod_data.items():
            p = int(p_str)
            for m in ms:
                k = (p, m.get("sura"), m.get("ayah"))
                if k in all_updated_markers: m["centerX"] = all_updated_markers[k]
        with open(prod_file, "w") as f: json.dump(prod_data, f, indent=4)
    except: pass
    return total_files

if __name__ == "__main__":
    print("Applying DUAL-VISION fixes...")
    f = apply_dual_vision_fixes()
    print(f"Done! {f} files fixed.")

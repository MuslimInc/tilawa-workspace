import json
import os
import glob
from PIL import Image
from detect_ayah_marker import extract_ink_mask, find_clusters, CLUSTER_GAP_PX

def snap_to_ink_bulk():
    base_dir = "/Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/quran_image_flutter"
    debug_dir = os.path.join(base_dir, "assets/data/quran_marker_debug_coordinates")
    prod_file = os.path.join(base_dir, "assets/data/verse_marker_coordinates.json")
    
    all_updated_markers = {}
    total_files = 0
    MARKER_PADDING_X = 2 # Tiny offset to avoid touching the ink

    for file_path in sorted(glob.glob(os.path.join(debug_dir, "*.json")), key=lambda x: int(os.path.basename(x).split(".")[0])):
        page_num = int(os.path.basename(file_path).split(".")[0])
        images_dir = os.path.join(base_dir, f"assets/quran_images/{page_num}")
        if not os.path.exists(images_dir): continue

        try:
            with open(file_path, "r") as f: data = json.load(f)
        except: continue

        modified = False
        line_markers = {}
        for m in data:
            l = m.get("line")
            if l not in line_markers: line_markers[l] = []
            line_markers[l].append(m)

        for line_idx, markers in line_markers.items():
            img_path = os.path.join(images_dir, f"{line_idx+1}.png")
            if not os.path.exists(img_path): continue
            
            try:
                img = Image.open(img_path)
                W = float(img.size[0])
                ink, _ = extract_ink_mask(img)
                col_counts = ink.sum(axis=0)
                clusters = find_clusters(col_counts, CLUSTER_GAP_PX)
                
                if not clusters: continue
                
                # Visual Bounds of the whole line
                left_ink = clusters[0][0]
                right_ink = clusters[-1][1]
                
                # Markers sorted visually Left to Right (increasing X)
                # In RTL Quran, markers are at the end (LEFTSIDE) of verses.
                # So markers[0] is the end of the line.
                markers_sorted = sorted(markers, key=lambda x: x["centerX"])
                
                # SNAP THE END MARKER (Leftmost visually)
                m_end = markers_sorted[0]
                m_end["centerX"] = (left_ink - MARKER_PADDING_X) / W
                
                # If there's a marker at the very start (RIGHTMOST)
                # This only happens for Surah headers or unique verses?
                # Actually, standard markers are only at the ends.
                # But if there's multiple ayahs, the middle one stays as is?
                # No, we should proportionally space them if the line is short.
                # Original gap on right = markers_sorted[-1]['centerX']?
                
                modified = True
            except:
                continue
                
        if modified:
            with open(file_path, "w") as f: json.dump(data, f, indent=4)
            total_files += 1
            for m in data:
                all_updated_markers[(page_num, m.get("sura"), m.get("ayah"))] = m.get("centerX")

    # Sync Production and preserve other fields
    try:
        with open(prod_file, "r") as f: prod_data = json.load(f)
        for p_str, ms in prod_data.items():
            p = int(p_str)
            for m in ms:
                k = (p, m.get("sura"), m.get("ayah"))
                if k in all_updated_markers:
                    m["centerX"] = all_updated_markers[k]
        with open(prod_file, "w") as f: json.dump(prod_data, f, indent=4)
    except: pass
    return total_files

if __name__ == "__main__":
    print("Executing PIXEL-SNAP Synchronization...")
    count = snap_to_ink_bulk()
    print(f"Success! {count} pages snapped to ink.")

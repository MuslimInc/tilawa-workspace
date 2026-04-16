import json
import os
import glob
from collections import defaultdict

def apply_final_proportional_fixes():
    # Paths
    base_dir = "/Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/quran_image_flutter"
    debug_dir = os.path.join(base_dir, "assets/data/quran_marker_debug_coordinates")
    prod_file = os.path.join(base_dir, "assets/data/verse_marker_coordinates.json")
    
    # Constants
    PLACEHOLDER_X = 0.0535
    FIXED_OFFSET = 0.1565 # 0.21 - 0.0535
    CENTERED_SINGLE_X = 0.34
    THRESHOLD_RIGHT_X = 0.65 # If right-most marker starts left of this, it's centered
    
    # Stats
    debug_count = 0
    prod_count = 0

    debug_files = glob.glob(os.path.join(debug_dir, "*.json"))
    all_updated_markers = {} # (page, sura, ayah) -> centerX

    for file_path in sorted(debug_files, key=lambda x: int(os.path.basename(x).split(".")[0])):
        page_num = int(os.path.basename(file_path).split(".")[0])
        
        try:
            with open(file_path, "r") as f:
                data = json.load(f)
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            continue

        # Group by line
        lines = defaultdict(list)
        for m in data:
            lines[m.get("line")].append(m)
            
        modified = False
        
        # Determine Surah Ends
        surah_ayahs = defaultdict(list)
        for m in data:
            surah_ayahs[m.get("sura")].append(m.get("ayah"))
        surah_max_ayah = {s: max(ayahs) for s, ayahs in surah_ayahs.items()}

        for line_idx, markers in lines.items():
            # Sort RTL: largest X first
            markers_sorted = sorted(markers, key=lambda m: m.get("centerX"), reverse=True)
            m_right = markers_sorted[0]
            m_left = markers_sorted[-1]
            
            is_surah_end = m_left.get("ayah") == surah_max_ayah.get(m_left.get("sura"))
            # A line is highly likely centered if it's a surah end OR if it starts significantly left
            # AND it has fewer than 3 ayahs (standard for Juz 30 centered ends)
            is_centered = (is_surah_end or (m_right.get("centerX") < THRESHOLD_RIGHT_X)) and len(markers) < 3

            if is_centered:
                # Rule 1: Single marker
                if len(markers) == 1:
                    m = markers[0]
                    curr_x = m.get("centerX")
                    # If it's near the literal middle, shift to text-end (~0.34)
                    if 0.45 <= curr_x <= 0.55:
                        m["centerX"] = CENTERED_SINGLE_X
                        modified = True
                    # If it's using the placeholder edge
                    elif abs(curr_x - PLACEHOLDER_X) < 0.0001:
                        m["centerX"] = 0.21 # Indent it
                        modified = True
                
                # Rule 2: Multiple markers (2 ayahs typically)
                elif len(markers) == 2:
                    # Apply proportional offset to BOTH markers if the end one was 0.0535
                    if abs(m_left.get("centerX") - PLACEHOLDER_X) < 0.001:
                        for m in markers:
                            m["centerX"] += FIXED_OFFSET
                        modified = True
        
        if modified:
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)
            debug_count += 1
            for m in data:
                all_updated_markers[(page_num, m.get("sura"), m.get("ayah"))] = m.get("centerX")

    # Sync Production
    try:
        with open(prod_file, "r") as f:
            prod_data = json.load(f)
        
        sync_total = 0
        for page_num_str, markers in prod_data.items():
            page = int(page_num_str)
            for m in markers:
                key = (page, m.get("sura"), m.get("ayah"))
                if key in all_updated_markers:
                    new_x = all_updated_markers[key]
                    if abs(m.get("centerX") - new_x) > 0.0001:
                        m["centerX"] = new_x
                        sync_total += 1
        
        if sync_total > 0:
            with open(prod_file, "w") as f:
                json.dump(prod_data, f, indent=4)
            prod_count = sync_total
            
    except Exception as e:
        print(f"Error syncing production: {e}")

    return debug_count, prod_count

if __name__ == "__main__":
    print("Applying FINAL proportional fixes...")
    df, pc = apply_final_proportional_fixes()
    print(f"Done!")
    print(f"- Files fixed: {df}")
    print(f"- Markers synchronized: {pc}")

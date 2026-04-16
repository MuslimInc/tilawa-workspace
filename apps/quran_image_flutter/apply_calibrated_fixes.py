import json
import os
import glob
from collections import defaultdict

def apply_final_calibrated_fixes():
    # Paths
    base_dir = "/Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/quran_image_flutter"
    debug_dir = os.path.join(base_dir, "assets/data/quran_marker_debug_coordinates")
    prod_file = os.path.join(base_dir, "assets/data/verse_marker_coordinates.json")
    
    # Constants
    PLACEHOLDER_X = 0.0535
    FIXED_OFFSET = 0.1565 
    CENTERED_SINGLE_X = 0.34
    THRESHOLD_RIGHT_X = 0.65 

    # Manual Overrides for specific verified pages
    manual_overrides = {
        600: {
            # Line index to list of markers with (sura, ayah, newX)
            2: [(100, 10, 0.680), (100, 11, 0.220)],
            9: [(101, 10, 0.560), (101, 11, 0.220)],
            14: [(102, 7, 0.650), (102, 8, 0.220)]
        },
        594: {
            4: [(89, 29, 0.585), (89, 30, 0.185)],
            8: [(90, 4, 0.335)],
            14: [(90, 17, 0.585), (90, 18, 0.185)]
        }
    }

    debug_count = 0
    all_updated_markers = {} # (page, sura, ayah) -> centerX

    debug_files = glob.glob(os.path.join(debug_dir, "*.json"))
    for file_path in sorted(debug_files, key=lambda x: int(os.path.basename(x).split(".")[0])):
        page_num = int(os.path.basename(file_path).split(".")[0])
        
        try:
            with open(file_path, "r") as f:
                data = json.load(f)
        except Exception as e:
            continue

        lines = defaultdict(list)
        for m in data:
            lines[m.get("line")].append(m)
            
        modified = False
        surah_ayahs = defaultdict(list)
        for m in data:
            surah_ayahs[m.get("sura")].append(m.get("ayah"))
        surah_max_ayah = {s: max(ayahs) for s, ayahs in surah_ayahs.items()}

        for line_idx, markers in lines.items():
            # Apply Manual Overrides First
            if page_num in manual_overrides and line_idx in manual_overrides[page_num]:
                overrides = manual_overrides[page_num][line_idx]
                for s, a, nx in overrides:
                    for m in markers:
                        if m.get("sura") == s and m.get("ayah") == a:
                            m["centerX"] = nx
                            modified = True
                continue

            # Generic Proportional Heuristics
            markers_sorted = sorted(markers, key=lambda m: m.get("centerX"), reverse=True)
            m_right = markers_sorted[0]
            m_left = markers_sorted[-1]
            is_surah_end = m_left.get("ayah") == surah_max_ayah.get(m_left.get("sura"))
            is_centered = (is_surah_end or (m_right.get("centerX") < THRESHOLD_RIGHT_X)) and len(markers) < 3

            if is_centered:
                if len(markers) == 1:
                    m = markers[0]
                    curr_x = m.get("centerX")
                    if 0.4 <= curr_x <= 0.55:
                        m["centerX"] = CENTERED_SINGLE_X
                        modified = True
                    elif curr_x < 0.22:
                        m["centerX"] = 0.22
                        modified = True
                elif len(markers) == 2:
                    # If the end is shifted (or needs shifting)
                    if m_left.get("centerX") < 0.22:
                        # Calculate required shift to reach standard 0.22
                        current_l = m_left.get("centerX")
                        shift = 0.22 - current_l
                        if shift > 0.01: # Avoid microscopic shifts
                            for m in markers:
                                m["centerX"] += shift
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
                    m["centerX"] = new_x
                    sync_total += 1
        if sync_total > 0:
            with open(prod_file, "w") as f:
                json.dump(prod_data, f, indent=4)
    except Exception as e:
        print(f"Sync error: {e}")

    return debug_count

if __name__ == "__main__":
    print("Applying Calibrated FINAL Proportion fixes...")
    df = apply_final_calibrated_fixes()
    print(f"Success! {df} pages updated.")

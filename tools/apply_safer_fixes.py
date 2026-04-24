import json
import os
import glob
from collections import defaultdict

def apply_safer_fixes():
    # Paths
    base_dir = "/Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/quran_image"
    debug_dir = os.path.join(base_dir, "assets/data/quran_marker_debug_coordinates")
    prod_file = os.path.join(base_dir, "assets/data/verse_marker_coordinates.json")
    
    # Standards established from manual fixes
    PLACEHOLDER_X = 0.0535
    CENTERED_END_X = 0.185
    CENTERED_SINGLE_X = 0.335
    CENTERED_MID_X = 0.585 # For 2-ayah centered lines
    
    # Stats
    fixed_debug_count = 0
    updated_prod_count = 0

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
        
        # Determine Surah Ends for this page
        # A marker is a possible surah end if it's the last one in the file for that Surah
        surah_ayahs = defaultdict(list)
        for m in data:
            surah_ayahs[m.get("sura")].append(m.get("ayah"))
        
        surah_max_ayah = {s: max(ayahs) for s, ayahs in surah_ayahs.items()}

        for line_idx, markers in lines.items():
            # Sort RTL: largest X first
            markers_sorted = sorted(markers, key=lambda m: m.get("centerX"), reverse=True)
            m_right = markers_sorted[0]
            m_left = markers_sorted[-1]
            
            # Refined threshold: 0.60
            is_centered_block = m_right.get("centerX") < 0.60
            is_surah_end = m_left.get("ayah") == surah_max_ayah.get(m_left.get("sura"))

            # Rule 1: Single ayah line
            if len(markers) == 1:
                m = markers[0]
                x = m.get("centerX")
                
                # Only fix if it's clearly a centered block OR at the end of a Surah
                if is_centered_block or is_surah_end:
                    if 0.45 <= x <= 0.55:
                        m["centerX"] = CENTERED_SINGLE_X
                        modified = True
                    elif abs(x - PLACEHOLDER_X) < 0.0001:
                        m["centerX"] = CENTERED_END_X
                        modified = True

            # Rule 2: Two ayah line
            elif len(markers) == 2:
                # Only apply if it's a centered block or at the end of a Surah
                if is_centered_block or is_surah_end:
                    if abs(m_left.get("centerX") - PLACEHOLDER_X) < 0.0001:
                        m_left["centerX"] = CENTERED_END_X
                        # If the middle one was in the literal center, shift it too
                        if 0.45 <= m_right.get("centerX") <= 0.55:
                            m_right["centerX"] = CENTERED_MID_X
                        modified = True
        
        if modified:
            with open(file_path, "w") as f:
                json.dump(data, f, indent=4)
            fixed_debug_count += 1
            
            for m in data:
                all_updated_markers[(page_num, m.get("sura"), m.get("ayah"))] = m.get("centerX")

    # 2. Sync with Production File
    try:
        with open(prod_file, "r") as f:
            prod_data = json.load(f)
            
        sync_count = 0
        for page_num_str, markers in prod_data.items():
            page = int(page_num_str)
            for m in markers:
                key = (page, m.get("sura"), m.get("ayah"))
                if key in all_updated_markers:
                    new_x = all_updated_markers[key]
                    if abs(m.get("centerX") - new_x) > 0.0001:
                        m["centerX"] = new_x
                        sync_count += 1
        
        if sync_count > 0:
            with open(prod_file, "w") as f:
                json.dump(prod_data, f, indent=4)
            updated_prod_count = sync_count
            
    except Exception as e:
        print(f"Error syncing with production file: {e}")

    return fixed_debug_count, updated_prod_count

if __name__ == "__main__":
    print("Applying SAFER bulk coordinate fixes (v2)...")
    debug_fixed, prod_synced = apply_safer_fixes()
    print(f"Success!")
    print(f"- Fixed {debug_fixed} debug JSON files.")
    print(f"- Synchronized {prod_synced} markers to production JSON.")

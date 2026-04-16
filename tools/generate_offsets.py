import os
import json
from fontTools.ttLib import TTFont

def generate_offsets(src_dir, map_path, output_path):
    print(f"Loading word counts from {map_path}...")
    with open(map_path, 'r') as f:
        map_data = json.load(f)
    
    # Calculate words per page from JSON
    page_word_counts = {}
    for k, v in map_data.items():
        p = str(v['p'])
        page_word_counts[p] = page_word_counts.get(p, 0) + 1
    
    print(f"Scanning fonts in {src_dir}...")
    offsets = {}
    
    for i in range(1, 605):
        page_str = str(i)
        filename = f"QCF_P{i}.ttf"
        path = os.path.join(src_dir, filename)
        
        json_count = page_word_counts.get(page_str, 0)
        
        if not os.path.exists(path) or json_count == 0:
            offsets[page_str] = 0
            continue
        
        try:
            font = TTFont(path)
            cmap = font.getBestCmap()
            # Count glyphs in the spec range FC41 to FFFF
            font_count = len([k for k in cmap.keys() if k >= 0xFC41])
            
            # The offset is the number of specimen ligatures to skip
            # They are at the beginning of the FC41 range.
            offset = font_count - json_count
            if offset < 0: 
                offset = 0 # Should not happen if font is standard
            
            offsets[page_str] = offset
            
            if i % 100 == 0 or i < 5:
                print(f"Page {i}: Font={font_count}, JSON={json_count}, Offset={offset}")
                
        except Exception as e:
            print(f"Error Page {i}: {e}")
            offsets[page_str] = 0

    with open(output_path, 'w') as f:
        json.dump(offsets, f, indent=2)
    
    print(f"Successfully saved {len(offsets)} offsets to {output_path}")

if __name__ == "__main__":
    src = "packages/quran_kmp/shared/src/main/assets/fonts"
    map_json = "packages/quran_kmp/shared/src/main/assets/data/quran_page_line_map.json"
    dest = "packages/quran_kmp/shared/src/main/assets/data/quran_offsets.json"
    
    generate_offsets(src, map_json, dest)

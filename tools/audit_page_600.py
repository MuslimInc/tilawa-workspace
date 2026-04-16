import json
import os
import glob
from PIL import Image
from detect_ayah_marker import analyze

def audit_page_vision(page_num):
    base_dir = "/Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/quran_image"
    images_dir = os.path.join(base_dir, f"assets/quran_images/{page_num}")
    
    if not os.path.exists(images_dir):
        return None
    
    results = []
    # Lines 1 to 15
    for line_idx in range(1, 16):
        img_path = os.path.join(images_dir, f"{line_idx}.png")
        if os.path.exists(img_path):
            try:
                r = analyze(Image.open(img_path))
                r["line_num"] = line_idx - 1 # 0-indexed for our JSON
                results.append(r)
            except Exception as e:
                print(f"Error analyzing {img_path}: {e}")
                
    return results

if __name__ == "__main__":
    print("Running Vision Audit on Page 600...")
    res = audit_page_vision(600)
    for r in res:
        if r.get("right_gap_px") is not None:
            print(f"Line {r['line_num']+1:2d}: Gap = {r['right_gap_px']:3d}px | Verdict = {r['verdict']}")

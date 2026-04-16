
import cv2
import numpy as np
import json
from pathlib import Path

def identify_headers():
    header_mapping = {}
    base_dir = Path("apps/quran_image_flutter/assets/quran_images")
    
    for page in range(1, 605):
        page_dir = base_dir / str(page)
        if not page_dir.exists():
            continue
            
        header_indices = []
        for li in range(1, 16):
            path = page_dir / f"{li}.png"
            if not path.exists():
                continue
                
            img = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
            if img is None or img.ndim < 3 or img.shape[2] < 4:
                continue
                
            alpha = img[:, :, 3]
            col_a = alpha.max(axis=0)
            tcols = np.where(col_a > 12)[0]
            
            if len(tcols) == 0:
                continue
                
            tl = tcols[0] / 1440
            tr = tcols[-1] / 1440
            span = tr - tl
            
            # Heuristic from validate_p404.py
            if span < 0.35:
                # Check if it's not a Bismillah (usually Bismillahs are longer)
                # Actually, Bismillahs are also headers in some contexts, but they don't get the Surah Banner.
                # Surah name images are usually very short.
                # Let's also check if it's blank or something.
                # Page 604 headers (1.png, 5.png, 10.png) should be detected.
                header_indices.append(li - 1) # 0-based
        
        if header_indices:
            header_mapping[page] = header_indices
            
    return header_mapping

if __name__ == "__main__":
    mapping = identify_headers()
    # Save to a temporary file
    with open("surah_header_mapping.json", "w") as f:
        json.dump(mapping, f, indent=2)
    print(f"Detected headers for {len(mapping)} pages.")

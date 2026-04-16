import os
import subprocess
from fontTools.ttLib import TTFont

def convert_woff_to_ttf(src_dir, dest_dir):
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
    
    count = 0
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            if file.endswith(".woff"):
                woff_path = os.path.join(root, file)
                # QCF4001_X-Regular.woff -> QCF_P1.ttf
                # Extract page number for cleaner loading
                page_part = file.split("_")[0].replace("QCF4", "")
                try:
                    page_num = int(page_part)
                    ttf_file = f"QCF_P{page_num}.ttf"
                    ttf_path = os.path.join(dest_dir, ttf_file)
                    
                    print(f"Converting {file} -> {ttf_file}")
                    font = TTFont(woff_path)
                    font.flavor = None # Ensure we save as standard TTF
                    font.save(ttf_path)
                    count += 1
                except Exception as e:
                    print(f"Failed to convert {file}: {e}")

    print(f"Successfully converted {count} fonts.")

if __name__ == "__main__":
    src = "packages/quran_kmp/shared/src/main/assets/extracted_fonts"
    dest = "packages/quran_kmp/shared/src/main/assets/fonts"
    convert_woff_to_ttf(src, dest)

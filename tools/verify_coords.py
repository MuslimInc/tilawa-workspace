import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from quran_data_paths import (
    QPC_V4_JSON,
    QURAN_PAGE_INDEX_JSON,
    VERSE_MARKER_COORDS_JSON,
)

with open(QURAN_PAGE_INDEX_JSON) as f:
    page_index = json.load(f)

with open(VERSE_MARKER_COORDS_JSON) as f:
    coords = json.load(f)

with open(QPC_V4_JSON) as f:
    qpc = json.load(f)

word_count = {}
for entry in qpc.values():
    s = str(entry['surah'])
    a = str(entry['ayah'])
    key = s + ':' + a
    wn = int(entry['word'])
    if word_count.get(key, 0) < wn:
        word_count[key] = wn

mismatches = 0
total_lines = 0
for page_num in range(1, 605):
    p = str(page_num)
    if p not in page_index:
        continue
    for line_key in page_index[p]:
        words = page_index[p][line_key]
        endings = []
        for i, w in enumerate(words):
            parts = w.split(':')
            if len(parts) < 3:
                continue
            vk = parts[0] + ':' + parts[1]
            wn = int(parts[2])
            if word_count.get(vk, -1) == wn:
                endings.append(vk)
        coord_list = coords.get(p, {}).get(line_key, [])
        total_lines += 1
        if len(endings) != len(coord_list):
            mismatches += 1
            if mismatches <= 10:
                print('MISMATCH page %s line %s: %d endings vs %d coords' % (p, line_key, len(endings), len(coord_list)))

print('Total lines: %d, Mismatches: %d' % (total_lines, mismatches))

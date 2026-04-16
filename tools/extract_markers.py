"""
Extract complete verse marker data from the Surah app database.

Strategy:
- For each page, get regular words (wordNo > 0) from both tables
- Sort WordCoordinateS2 by (lineNo, wordPos) and QuranWordInfo by (id)
- Match them 1:1 to build a mapping from internal ayahNo -> real surah:ayah
- Then for each marker (wordNo=0), use the mapping to get real surah:ayah
- Output: page -> list of {surah, ayah, line, centerX}
"""
import sqlite3
import json

DB_PATH = '../surah_app_assets/flutter_assets/database/surah_database_app_v34.db'
OUT_PATH = 'assets/data/verse_markers_v2.json'

db = sqlite3.connect(DB_PATH)
db.row_factory = sqlite3.Row
cur = db.cursor()

# Step 1: For each page, get regular words from QuranWordInfo sorted by id
# This gives us the reading order with real surah:ayah
cur.execute("""
    SELECT pageNo, surahNo, ayahNo, wordNo, id
    FROM QuranWordInfo
    WHERE wordNo > 0
    ORDER BY pageNo, id
""")

# Build: page -> [(surahNo, ayahNo, wordNo), ...]  in reading order
qi_words = {}
for row in cur:
    p = row['pageNo']
    if p not in qi_words:
        qi_words[p] = []
    qi_words[p].append((row['surahNo'], row['ayahNo'], row['wordNo']))

# Step 2: For each page, get regular words from WordCoordinateS2 sorted by lineNo, wordPos
cur.execute("""
    SELECT pageNo, surahNo, ayahNo, wordNo, lineNo, wordPos
    FROM WordCoordinateS2
    WHERE wordNo > 0
    ORDER BY pageNo, lineNo, wordPos
""")

wc_words = {}
for row in cur:
    p = row['pageNo']
    if p not in wc_words:
        wc_words[p] = []
    wc_words[p].append((row['surahNo'], row['ayahNo'], row['wordNo'], row['lineNo'], row['wordPos']))

# Step 3: Match 1:1 and build mapping: (page, wc_surahNo, wc_ayahNo) -> (real_surahNo, real_ayahNo)
# We need per-page mapping since the internal IDs might repeat across pages
ayah_map = {}  # (page, wc_ayahNo) -> (real_surahNo, real_ayahNo)

matched_pages = 0
mismatched_pages = 0

for page in sorted(set(qi_words.keys()) & set(wc_words.keys())):
    qi = qi_words[page]
    wc = wc_words[page]
    
    if len(qi) != len(wc):
        mismatched_pages += 1
        if mismatched_pages <= 5:
            print("Word count mismatch page %d: QI=%d WC=%d" % (page, len(qi), len(wc)))
        continue
    
    matched_pages += 1
    for i in range(len(qi)):
        real_s, real_a, real_w = qi[i]
        wc_s, wc_a, wc_w, wc_line, wc_wp = wc[i]
        key = (page, wc_a)
        if key not in ayah_map:
            ayah_map[key] = (real_s, real_a)

print("Matched pages: %d, Mismatched pages: %d" % (matched_pages, mismatched_pages))

# Step 4: Get all markers (wordNo=0) with coordinates
cur.execute("""
    SELECT pageNo, surahNo, ayahNo, lineNo, wordPos, x1, x2
    FROM WordCoordinateS2
    WHERE wordNo = 0
    ORDER BY pageNo, lineNo, wordPos
""")

result = {}
unmapped = 0
total = 0

for row in cur:
    p = row['pageNo']
    wc_a = row['ayahNo']
    line = row['lineNo']
    cx = round((row['x1'] + row['x2']) / 200.0, 6)
    
    total += 1
    mapping = ayah_map.get((p, wc_a))
    if mapping is None:
        unmapped += 1
        continue
    
    real_s, real_a = mapping
    p_str = str(p)
    if p_str not in result:
        result[p_str] = []
    
    result[p_str].append({
        "s": real_s,
        "a": real_a,
        "l": line,
        "x": cx
    })

print("Total markers: %d, Unmapped: %d, Mapped: %d" % (total, unmapped, total - unmapped))
print("Pages with markers: %d" % len(result))

# Step 5: Write output
with open(OUT_PATH, 'w') as f:
    json.dump(result, f, separators=(',', ':'))

import os
size = os.path.getsize(OUT_PATH)
print("Output size: %.1f KB" % (size / 1024.0))

# Sample
if '3' in result:
    print("Page 3 markers:")
    for m in result['3'][:5]:
        print("  surah=%d ayah=%d line=%d cx=%.4f" % (m['s'], m['a'], m['l'], m['x']))

db.close()

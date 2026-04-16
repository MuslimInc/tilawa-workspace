"""
Extract complete verse marker data by matching wordNo=0 entries
from WordCoordinateS2 and QuranWordInfo per page by reading order.
"""
import sqlite3
import json

DB_PATH = '../surah_app_assets/flutter_assets/database/surah_database_app_v34.db'
OUT_PATH = 'assets/data/verse_markers_v2.json'

db = sqlite3.connect(DB_PATH)
cur = db.cursor()

# Get all verse markers from QuranWordInfo (has real surah:ayah)
cur.execute("""
    SELECT pageNo, surahNo, ayahNo, id
    FROM QuranWordInfo
    WHERE wordNo = 0
    ORDER BY pageNo, id
""")
qi_markers = {}
for row in cur:
    p = row[0]
    if p not in qi_markers:
        qi_markers[p] = []
    qi_markers[p].append({'s': row[1], 'a': row[2]})

# Get all verse markers from WordCoordinateS2 (has coordinates)
cur.execute("""
    SELECT pageNo, lineNo, wordPos, x1, x2
    FROM WordCoordinateS2
    WHERE wordNo = 0
    ORDER BY pageNo, lineNo, wordPos
""")
wc_markers = {}
for row in cur:
    p = row[0]
    if p not in wc_markers:
        wc_markers[p] = []
    wc_markers[p].append({
        'l': row[1],
        'x': round((row[2] + row[3]) / 200.0, 6)
    })

# Match per page
result = {}
matched = 0
mismatched = 0
mismatch_examples = []

for page in sorted(set(qi_markers.keys()) | set(wc_markers.keys())):
    qi = qi_markers.get(page, [])
    wc = wc_markers.get(page, [])
    
    if len(qi) != len(wc):
        mismatched += 1
        if len(mismatch_examples) < 10:
            mismatch_examples.append("Page %d: QI=%d WC=%d" % (page, len(qi), len(wc)))
        continue
    
    matched += 1
    p_str = str(page)
    result[p_str] = []
    
    for i in range(len(qi)):
        result[p_str].append({
            's': qi[i]['s'],
            'a': qi[i]['a'],
            'l': wc[i]['l'],
            'x': wc[i]['x']
        })

print("Matched pages: %d, Mismatched pages: %d" % (matched, mismatched))
for ex in mismatch_examples:
    print("  " + ex)

total_markers = sum(len(v) for v in result.values())
print("Total markers in output: %d" % total_markers)

with open(OUT_PATH, 'w') as f:
    json.dump(result, f, separators=(',', ':'))

import os
print("Output size: %.1f KB" % (os.path.getsize(OUT_PATH) / 1024.0))

# Sample output
if '3' in result:
    print("\nPage 3 markers:")
    for m in result['3']:
        print("  surah=%d ayah=%d line=%d cx=%.4f" % (m['s'], m['a'], m['l'], m['x']))

# Verify page 2
if '2' in result:
    print("\nPage 2 markers:")
    for m in result['2']:
        print("  surah=%d ayah=%d line=%d cx=%.4f" % (m['s'], m['a'], m['l'], m['x']))

db.close()

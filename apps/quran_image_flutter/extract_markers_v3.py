"""
Match WordCoordinateS2 markers with quran-text.db verses per page.
quran-text.db knows exactly which verses are on each page.
WordCoordinateS2 has the coordinates.
If the count matches per page, we pair them in reading order.
"""
import sqlite3
import json

SURAH_DB = '../surah_app_assets/flutter_assets/database/surah_database_app_v34.db'
QURAN_DB = 'assets/databases/quran-text.db'
OUT_PATH = 'assets/data/verse_markers_v2.json'

# Get marker coordinates from Surah app
sdb = sqlite3.connect(SURAH_DB)
cur = sdb.cursor()
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
sdb.close()

# Get verses per page from quran-text.db
qdb = sqlite3.connect(QURAN_DB)
cur = qdb.cursor()
cur.execute("""
    SELECT pageNumber, chapterNumber, verseNumber, verseID
    FROM bookEntry
    WHERE kind = 'verse'
    ORDER BY pageNumber, verseID
""")
qt_verses = {}
for row in cur:
    p = row[0]
    if p not in qt_verses:
        qt_verses[p] = []
    qt_verses[p].append({'s': row[1], 'a': row[2], 'vid': row[3]})
qdb.close()

# Match per page
result = {}
matched = 0
mismatched = 0
mismatch_examples = []

for page in sorted(set(qt_verses.keys()) | set(wc_markers.keys())):
    qt = qt_verses.get(page, [])
    wc = wc_markers.get(page, [])
    
    if len(qt) != len(wc):
        mismatched += 1
        if len(mismatch_examples) < 15:
            mismatch_examples.append("Page %d: verses=%d markers=%d" % (page, len(qt), len(wc)))
        continue
    
    matched += 1
    p_str = str(page)
    result[p_str] = []
    
    for i in range(len(qt)):
        result[p_str].append({
            's': qt[i]['s'],
            'a': qt[i]['a'],
            'l': wc[i]['l'],
            'x': wc[i]['x']
        })

print("Matched pages: %d, Mismatched pages: %d" % (matched, mismatched))
for ex in mismatch_examples:
    print("  " + ex)

total = sum(len(v) for v in result.values())
print("Total markers: %d" % total)

# Show the difference patterns
print("\nDifference analysis:")
diffs = {}
for page in sorted(set(qt_verses.keys()) | set(wc_markers.keys())):
    qt = len(qt_verses.get(page, []))
    wc = len(wc_markers.get(page, []))
    d = wc - qt
    diffs[d] = diffs.get(d, 0) + 1
for d in sorted(diffs.keys()):
    print("  diff=%d: %d pages" % (d, diffs[d]))

with open(OUT_PATH, 'w') as f:
    json.dump(result, f, separators=(',', ':'))

import os
print("\nOutput: %.1f KB, %d pages" % (os.path.getsize(OUT_PATH) / 1024.0, len(result)))

# Sample
if '50' in result:
    print("\nPage 50 sample:")
    for m in result['50'][:5]:
        print("  s=%d a=%d l=%d x=%.4f" % (m['s'], m['a'], m['l'], m['x']))

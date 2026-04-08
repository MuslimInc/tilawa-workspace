"""
Match words between QuranWordInfo and WordCoordinateS2 to extract
exact x coordinates for verse-ending words.

Strategy: For each page, get regular words (skip wordNo=0) from both tables
in reading order. If counts match, match 1:1. If not, try fuzzy matching.
Then for each verse ending, record the x coordinate.
"""
import sqlite3
import json

SURAH_DB = '../surah_app_assets/flutter_assets/database/surah_database_app_v34.db'
QURAN_DB = 'assets/databases/quran-text.db'
OUT_PATH = 'assets/data/verse_markers_v2.json'

sdb = sqlite3.connect(SURAH_DB)

# Get regular words from QuranWordInfo (has real surah:ayah:wordNo)
cur = sdb.cursor()
cur.execute("""
    SELECT pageNo, surahNo, ayahNo, wordNo, id
    FROM QuranWordInfo
    WHERE wordNo > 0
    ORDER BY pageNo, id
""")
qi_by_page = {}
for row in cur:
    p = row[0]
    if p not in qi_by_page:
        qi_by_page[p] = []
    qi_by_page[p].append({
        'surah': row[1], 'ayah': row[2], 'word': row[3]
    })

# Get word counts per verse from QuranWordInfo
cur.execute("""
    SELECT surahNo, ayahNo, MAX(wordNo) as maxWord
    FROM QuranWordInfo
    WHERE wordNo > 0
    GROUP BY surahNo, ayahNo
""")
verse_word_count = {}
for row in cur:
    verse_word_count[(row[0], row[1])] = row[2]

# Get regular words from WordCoordinateS2 (has coordinates)
cur.execute("""
    SELECT pageNo, lineNo, wordPos, wordNo, x1, x2
    FROM WordCoordinateS2
    WHERE wordNo > 0
    ORDER BY pageNo, lineNo, wordPos
""")
wc_by_page = {}
for row in cur:
    p = row[0]
    if p not in wc_by_page:
        wc_by_page[p] = []
    wc_by_page[p].append({
        'line': row[1], 'wp': row[2],
        'x1': row[3], 'x2': row[4]
    })

# Analyze word count differences
exact_match = 0
close_match = 0  # within 5%
far_off = 0
diffs = []

for p in range(1, 605):
    qi_count = len(qi_by_page.get(p, []))
    wc_count = len(wc_by_page.get(p, []))
    if qi_count == wc_count:
        exact_match += 1
    elif qi_count > 0 and abs(qi_count - wc_count) / qi_count < 0.1:
        close_match += 1
    else:
        far_off += 1
    if qi_count != wc_count and p <= 20:
        diffs.append("Page %d: QI=%d WC=%d diff=%d" % (p, qi_count, wc_count, wc_count - qi_count))

print("Exact match: %d, Close: %d, Far: %d" % (exact_match, close_match, far_off))
for d in diffs:
    print("  " + d)

# For pages with exact match, do 1:1 matching and extract verse markers
result = {}
total_markers = 0

for p in range(1, 605):
    qi = qi_by_page.get(p, [])
    wc = wc_by_page.get(p, [])
    
    if len(qi) != len(wc) or len(qi) == 0:
        continue
    
    markers = []
    for i in range(len(qi)):
        s = qi[i]['surah']
        a = qi[i]['ayah']
        w = qi[i]['word']
        max_w = verse_word_count.get((s, a), -1)
        
        if w == max_w:
            # This is the last word of the verse - it's a verse ending
            line = wc[i]['line']
            cx = round((wc[i]['x1'] + wc[i]['x2']) / 200.0, 6)
            markers.append({
                's': s, 'a': a, 'l': line, 'x': cx
            })
    
    if markers:
        result[str(p)] = markers
        total_markers += len(markers)

print("\nExact-match pages with markers: %d" % len(result))
print("Total markers extracted: %d" % total_markers)

# For non-exact pages, try a tolerance-based approach
# Check if WC always has MORE words (possible extra glyph entries)
wc_more = 0
qi_more = 0
for p in range(1, 605):
    qi_count = len(qi_by_page.get(p, []))
    wc_count = len(wc_by_page.get(p, []))
    if wc_count > qi_count:
        wc_more += 1
    elif qi_count > wc_count:
        qi_more += 1

print("\nWC has more words: %d pages, QI has more: %d pages" % (wc_more, qi_more))

with open(OUT_PATH, 'w') as f:
    json.dump(result, f, separators=(',', ':'))

import os
print("Output: %.1f KB" % (os.path.getsize(OUT_PATH) / 1024.0))

# Sample
if '50' in result:
    print("\nPage 50:")
    for m in result['50']:
        print("  s=%d a=%d l=%d x=%.4f" % (m['s'], m['a'], m['l'], m['x']))

sdb.close()

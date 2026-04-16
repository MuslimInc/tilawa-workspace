"""
Analyze WordCoordinateS2 markers to understand which are real verse markers
vs decorative elements (Bismillah, surah headers, etc.).
Then filter and match with quran-text.db verses.
"""
import sqlite3
import json

SURAH_DB = '../surah_app_assets/flutter_assets/database/surah_database_app_v34.db'
QURAN_DB = 'assets/databases/quran-text.db'
OUT_PATH = 'assets/data/verse_markers_v2.json'

sdb = sqlite3.connect(SURAH_DB)
cur = sdb.cursor()

# Check pageLineInfo line types
cur.execute("SELECT * FROM pageLineInfo ORDER BY pageNo")
line_types = {}
for row in cur:
    p = row[0]
    line_types[p] = {}
    for i in range(1, 16):
        line_types[p][i] = row[i]

# Analyze marker patterns with ayahNo values
cur.execute("""
    SELECT pageNo, lineNo, wordPos, ayahNo, x1, x2
    FROM WordCoordinateS2
    WHERE wordNo = 0
    ORDER BY pageNo, lineNo, wordPos
""")

all_markers = {}
ayah_no_stats = {}
for row in cur:
    p, ln, wp, an, x1, x2 = row
    if p not in all_markers:
        all_markers[p] = []
    
    lt = line_types.get(p, {}).get(ln, 3)
    all_markers[p].append({
        'l': ln, 'wp': wp, 'an': an,
        'x': round((x1 + x2) / 200.0, 6),
        'lt': lt
    })
    
    key = "ayahNo=%d lt=%d" % (an if an >= -1 else -99, lt)
    ayah_no_stats[key] = ayah_no_stats.get(key, 0) + 1

print("Marker patterns (ayahNo + lineType):")
for k in sorted(ayah_no_stats.keys()):
    print("  %s: %d" % (k, ayah_no_stats[k]))

# Try filtering: only keep markers on regular lines (lt=3) with ayahNo > 0
print("\n--- Filtering: lt=3 AND ayahNo > 0 ---")
qdb = sqlite3.connect(QURAN_DB)
qcur = qdb.cursor()
qcur.execute("""
    SELECT pageNumber, chapterNumber, verseNumber, verseID
    FROM bookEntry WHERE kind = 'verse'
    ORDER BY pageNumber, verseID
""")
qt_verses = {}
for row in qcur:
    p = row[0]
    if p not in qt_verses:
        qt_verses[p] = []
    qt_verses[p].append({'s': row[1], 'a': row[2]})
qdb.close()

matched = 0
mismatched = 0
result = {}
mismatch_ex = []

for page in range(1, 605):
    qt = qt_verses.get(page, [])
    raw = all_markers.get(page, [])
    filtered = [m for m in raw if m['lt'] == 3 and m['an'] > 0]
    
    if len(qt) == len(filtered):
        matched += 1
        p_str = str(page)
        result[p_str] = []
        for i in range(len(qt)):
            result[p_str].append({
                's': qt[i]['s'], 'a': qt[i]['a'],
                'l': filtered[i]['l'], 'x': filtered[i]['x']
            })
    else:
        mismatched += 1
        if len(mismatch_ex) < 15:
            mismatch_ex.append("Page %d: verses=%d filtered=%d (raw=%d)" % (
                page, len(qt), len(filtered), len(raw)))

print("Matched: %d, Mismatched: %d" % (matched, mismatched))
for ex in mismatch_ex:
    print("  " + ex)

# Try other filter combos
for desc, filt_fn in [
    ("lt=3 only", lambda m: m['lt'] == 3),
    ("ayahNo > 0 only", lambda m: m['an'] > 0),
    ("ayahNo >= 0 only", lambda m: m['an'] >= 0),
    ("no filter", lambda m: True),
]:
    match_count = 0
    for page in range(1, 605):
        qt = qt_verses.get(page, [])
        raw = all_markers.get(page, [])
        filtered = [m for m in raw if filt_fn(m)]
        if len(qt) == len(filtered):
            match_count += 1
    print("\nFilter '%s': %d pages matched" % (desc, match_count))

total = sum(len(v) for v in result.values())
print("\nBest result so far: %d pages, %d markers" % (len(result), total))

with open(OUT_PATH, 'w') as f:
    json.dump(result, f, separators=(',', ':'))

sdb.close()

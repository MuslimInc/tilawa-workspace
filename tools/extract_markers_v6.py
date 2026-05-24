"""
Check per-LINE word counts between quran_page_index.json and WordCoordinateS2.
If line-level counts match, we can do per-line word matching to extract
exact x coordinates for verse-ending words.
"""
import sqlite3
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from quran_data_paths import QURAN_PAGE_INDEX_JSON

SURAH_DB = '../surah_app_assets/flutter_assets/database/surah_database_app_v34.db'

# Load quran_page_index.json (page -> line -> [word keys])
with open(QURAN_PAGE_INDEX_JSON) as f:
    page_index = json.load(f)

# Get per-line word counts from WordCoordinateS2
sdb = sqlite3.connect(SURAH_DB)
cur = sdb.cursor()
cur.execute("""
    SELECT pageNo, lineNo, COUNT(*) as cnt
    FROM WordCoordinateS2
    WHERE wordNo > 0
    GROUP BY pageNo, lineNo
    ORDER BY pageNo, lineNo
""")
wc_line_counts = {}
for row in cur:
    p, ln, cnt = row
    if p not in wc_line_counts:
        wc_line_counts[p] = {}
    wc_line_counts[p][ln] = cnt

# Compare per-line
exact = 0
mismatch = 0
total_lines = 0
sample_mismatches = []

for p_str in page_index:
    p = int(p_str)
    for ln_str in page_index[p_str]:
        ln = int(ln_str)
        qi_count = len(page_index[p_str][ln_str])
        wc_count = wc_line_counts.get(p, {}).get(ln, 0)
        total_lines += 1
        if qi_count == wc_count:
            exact += 1
        else:
            mismatch += 1
            if len(sample_mismatches) < 15:
                sample_mismatches.append(
                    "Page %d line %d: QI=%d WC=%d" % (p, ln, qi_count, wc_count))

print("Per-line comparison:")
print("  Exact match: %d / %d (%.1f%%)" % (exact, total_lines, 100.0 * exact / total_lines))
print("  Mismatch: %d" % mismatch)
for s in sample_mismatches:
    print("  " + s)

# Also check: for lines that match, verify by looking at page 3
print("\nPage 3 per-line detail:")
p_str = '3'
p = 3
for ln_str in sorted(page_index.get(p_str, {}).keys(), key=int):
    ln = int(ln_str)
    qi_count = len(page_index[p_str][ln_str])
    wc_count = wc_line_counts.get(p, {}).get(ln, 0)
    match_str = "OK" if qi_count == wc_count else "DIFF"
    print("  Line %2d: QI=%2d WC=%2d %s" % (ln, qi_count, wc_count, match_str))

sdb.close()

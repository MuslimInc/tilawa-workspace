#!/usr/bin/env bash
# Regenerates apps/tilawa/assets/data/translations/en_sahih.json from QUL.
#
# Source: https://qul.tarteel.ai/resources/translation/193
# API resource id: 20 (Saheeh International)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/apps/tilawa/assets/data/translations/en_sahih.json"
TMP="$(mktemp)"
QUL_API="https://qul.tarteel.ai/api/v1/translations/20/by_range?from=1:1&to=114:6"

curl -fsSL "$QUL_API" -o "$TMP"
python3 - "$TMP" "$OUT" <<'PY'
import json
import re
import sys

source_path, out_path = sys.argv[1:3]

with open(source_path, encoding="utf-8") as handle:
    payload = json.load(handle)

footnote_pattern = re.compile(r"<sup[^>]*>\d+</sup>")
tag_pattern = re.compile(r"<[^>]+>")


def clean_translation(text: str) -> str:
    without_footnotes = footnote_pattern.sub("", text)
    without_tags = tag_pattern.sub("", without_footnotes)
    return " ".join(without_tags.split())


surahs: dict[str, dict[str, str]] = {}
for entry in payload["translations"]:
    verse_key = entry["verse_key"]
    surah_number, ayah_number = verse_key.split(":")
    surahs.setdefault(surah_number, {})[ayah_number] = clean_translation(entry["text"])

compact = {
    "source": "qul.tarteel.ai",
    "resourceId": 20,
    "downloadResourceId": 193,
    "edition": "en-sahih-international",
    "name": "Saheeh International",
    "language": "en",
    "surahs": surahs,
}

with open(out_path, "w", encoding="utf-8") as handle:
    json.dump(compact, handle, ensure_ascii=False, separators=(",", ":"))
    handle.write("\n")
PY

rm "$TMP"
echo "Wrote $OUT ($(wc -c < "$OUT") bytes)"

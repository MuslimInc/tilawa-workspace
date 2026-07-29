#!/usr/bin/env python3
"""Strip injectable annotations and imports from apps/tilawa/lib (not frozen).

Careful with @ignoreParam: remove only the annotation token, keep the parameter.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "apps/tilawa/lib"

# Whole-line annotations (not parameter-inline).
ANN_LINE_RE = re.compile(
    r"^[ \t]*@(?:lazySingleton|LazySingleton|singleton|Singleton|injectable|"
    r"Injectable|module|InjectableInit|factoryMethod|Environment|Named|"
    r"preResolve|factoryParam)\b[^\n]*\n",
    re.MULTILINE,
)
ANN_BLOCK_RE = re.compile(
    r"^[ \t]*@(?:LazySingleton|Singleton|Injectable|InjectableInit)\s*\([^;]*?\)\s*\n",
    re.MULTILINE | re.DOTALL,
)
IMPORT_RE = re.compile(
    r"^[ \t]*import\s+'package:injectable/injectable\.dart';\s*\n",
    re.MULTILINE,
)
# Token-only: never delete the rest of the line.
IGNORE_PARAM_RE = re.compile(r"@ignoreParam\s*")


def strip_file(path: Path) -> bool:
    original = path.read_text()
    text = original
    text = IMPORT_RE.sub("", text)
    text = ANN_BLOCK_RE.sub("", text)
    text = ANN_LINE_RE.sub("", text)
    text = IGNORE_PARAM_RE.sub("", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    if text != original:
        path.write_text(text)
        return True
    return False


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        if "frozen" in path.parts:
            continue
        if path.name.endswith(".config.dart"):
            continue
        if strip_file(path):
            changed += 1
    print(f"changed {changed} files")


if __name__ == "__main__":
    main()

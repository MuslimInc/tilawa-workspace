#!/usr/bin/env python3
"""Stamp changelog.json with release publish and catalog update timestamps."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import UTC, datetime
from pathlib import Path


def _utc_now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace(
        "+00:00",
        "Z",
    )


def stamp_changelog(
    *,
    changelog_path: Path,
    release_id: str,
    published_at: str | None = None,
) -> None:
    published_at = published_at or _utc_now_iso()

    data = json.loads(changelog_path.read_text(encoding="utf-8"))
    data["lastUpdatedAt"] = published_at

    matched = False
    for release in data.get("releases", []):
        if release.get("id") == release_id:
            release["publishedAt"] = published_at
            matched = True
            break

    if not matched:
        print(
            f"warning: no release entry with id {release_id!r} in {changelog_path}",
            file=sys.stderr,
        )

    changelog_path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Set lastUpdatedAt and matching release publishedAt.",
    )
    parser.add_argument(
        "--changelog",
        type=Path,
        default=Path("assets/changelog/changelog.json"),
        help="Path to changelog.json (relative to apps/tilawa by default).",
    )
    parser.add_argument(
        "--release-id",
        required=True,
        help="Release id, e.g. 2.0.8+52.",
    )
    parser.add_argument(
        "--published-at",
        help="ISO-8601 UTC timestamp (default: now).",
    )
    args = parser.parse_args()

    stamp_changelog(
        changelog_path=args.changelog,
        release_id=args.release_id,
        published_at=args.published_at,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

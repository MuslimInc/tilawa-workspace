#!/usr/bin/env python3
"""Sync docs/TODO.md tasks to a Notion database (Tilawa / MeMuslim backlog)."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

NOTION_VERSION = "2022-06-28"
DEFAULT_TODO = Path(__file__).resolve().parents[2] / "docs" / "TODO.md"
CONFIG_PATH = Path(__file__).resolve().parent / ".notion.local.json"

SECTIONS = {
    "features": "Features",
    "refactors & tech debt": "Refactors & tech debt",
    "ops & release": "Ops & release",
    "ideas (unscoped)": "Ideas (unscoped)",
    "known issues": "Known issues",
    "done": "Done",
}

STATUS_OPTIONS = ["Not started", "In progress", "Done"]
PRIORITY_OPTIONS = ["P0", "P1", "P2", "—"]


@dataclass
class Task:
    task_key: str
    title: str
    status: str
    priority: str
    section: str
    description: str = ""


def _slug(text: str) -> str:
    normalized = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return normalized[:80] or hashlib.sha1(text.encode()).hexdigest()[:12]


def _parse_checkbox_line(line: str, section: str) -> Task | None:
    match = re.match(r"^- \[( |~|x)\] \*\*(.+?)\*\*(.*)$", line)
    if not match:
        return None

    mark, title, tail = match.groups()
    status = {
        " ": "Not started",
        "~": "In progress",
        "x": "Done",
    }[mark]

    priority_match = re.search(r"`(P[0-2])`", tail)
    priority = priority_match.group(1) if priority_match else "—"

    return Task(
        task_key=_slug(title),
        title=title.strip(),
        status=status,
        priority=priority,
        section=section,
    )


def _parse_known_issue(line: str, section: str) -> Task | None:
    match = re.match(r"^\d+\.\s+(.+)$", line.strip())
    if not match:
        return None
    title = match.group(1).strip()
    return Task(
        task_key=_slug(title),
        title=title,
        status="Not started",
        priority="—",
        section=section,
    )


def parse_todo(path: Path) -> list[Task]:
    if not path.is_file():
        raise FileNotFoundError(f"TODO file not found: {path}")

    current_section = "Features"
    tasks: list[Task] = []
    pending: Task | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.rstrip()
        section_match = re.match(r"^## (.+)$", line)
        if section_match:
            heading = section_match.group(1).strip().lower()
            current_section = SECTIONS.get(heading, section_match.group(1).strip())
            pending = None
            continue

        if line.startswith("- [") and "**" in line:
            task = _parse_checkbox_line(line, current_section)
            if task:
                if task.title.startswith("_Your next"):
                    continue
                tasks.append(task)
                pending = task
            continue

        if current_section == "Known issues":
            issue = _parse_known_issue(line, current_section)
            if issue:
                tasks.append(issue)
                pending = issue
            continue

        if pending and line.startswith("  ") and line.strip():
            extra = line.strip()
            if pending.description:
                pending.description += "\n"
            pending.description += extra

    return tasks


class NotionClient:
    def __init__(self, token: str) -> None:
        self.token = token

    def _request(
        self,
        method: str,
        path: str,
        payload: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        data = None
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Notion-Version": NOTION_VERSION,
            "Content-Type": "application/json",
        }
        if payload is not None:
            data = json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(
            f"https://api.notion.com/v1{path}",
            data=data,
            headers=headers,
            method=method,
        )
        try:
            with urllib.request.urlopen(request) as response:
                body = response.read().decode("utf-8")
                return json.loads(body) if body else {}
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8")
            raise RuntimeError(f"Notion API {method} {path} failed: {detail}") from error

    def search_pages(self) -> list[dict[str, Any]]:
        result = self._request("POST", "/search", {"page_size": 100})
        return result.get("results", [])

    def create_tasks_database(self, parent_page_id: str) -> str:
        payload = {
            "parent": {"type": "page_id", "page_id": parent_page_id},
            "title": [
                {
                    "type": "text",
                    "text": {"content": "Tilawa / MeMuslim Tasks"},
                }
            ],
            "properties": {
                "Name": {"title": {}},
                "Status": {
                    "select": {
                        "options": [{"name": name} for name in STATUS_OPTIONS],
                    }
                },
                "Priority": {
                    "select": {
                        "options": [{"name": name} for name in PRIORITY_OPTIONS],
                    }
                },
                "Section": {
                    "select": {
                        "options": [{"name": name} for name in SECTIONS.values()],
                    }
                },
                "Task key": {"rich_text": {}},
                "Description": {"rich_text": {}},
                "Source": {"url": {}},
            },
        }
        database = self._request("POST", "/databases", payload)
        return database["id"]

    def query_tasks(self, database_id: str) -> dict[str, str]:
        task_key_to_page_id: dict[str, str] = {}
        cursor: str | None = None
        while True:
            payload: dict[str, Any] = {"page_size": 100}
            if cursor:
                payload["start_cursor"] = cursor
            result = self._request(
                "POST",
                f"/databases/{database_id}/query",
                payload,
            )
            for page in result.get("results", []):
                props = page.get("properties", {})
                key_prop = props.get("Task key", {}).get("rich_text", [])
                if not key_prop:
                    continue
                task_key = key_prop[0].get("plain_text", "").strip()
                if task_key:
                    task_key_to_page_id[task_key] = page["id"]
            if not result.get("has_more"):
                break
            cursor = result.get("next_cursor")
        return task_key_to_page_id

    def _rich_text(self, value: str) -> list[dict[str, Any]]:
        if not value:
            return []
        chunks = [value[i : i + 1800] for i in range(0, len(value), 1800)]
        return [
            {"type": "text", "text": {"content": chunk}} for chunk in chunks if chunk
        ]

    def _properties(self, task: Task) -> dict[str, Any]:
        return {
            "Name": {"title": [{"text": {"content": task.title[:2000]}}]},
            "Status": {"select": {"name": task.status}},
            "Priority": {"select": {"name": task.priority}},
            "Section": {"select": {"name": task.section}},
            "Task key": {"rich_text": self._rich_text(task.task_key)},
            "Description": {"rich_text": self._rich_text(task.description[:4000])},
        }

    def upsert_task(self, database_id: str, task: Task, page_id: str | None) -> str:
        properties = self._properties(task)
        if page_id:
            self._request("PATCH", f"/pages/{page_id}", {"properties": properties})
            return page_id

        created = self._request(
            "POST",
            "/pages",
            {
                "parent": {"database_id": database_id},
                "properties": properties,
            },
        )
        return created["id"]


def load_config() -> dict[str, str]:
    if CONFIG_PATH.is_file():
        return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    return {}


def save_config(config: dict[str, str]) -> None:
    CONFIG_PATH.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")


def resolve_database_id(client: NotionClient, args: argparse.Namespace) -> str:
    if args.database_id:
        return args.database_id

    config = load_config()
    if config.get("database_id"):
        return config["database_id"]

    if args.parent_page_id:
        database_id = client.create_tasks_database(args.parent_page_id)
        config["database_id"] = database_id
        config["parent_page_id"] = args.parent_page_id
        save_config(config)
        return database_id

    pages = client.search_pages()
    if not pages:
        raise RuntimeError(
            "No Notion pages shared with integration. Open a page in Notion → "
            "⋯ → Connections → add MyAccess, then rerun with --parent-page-id."
        )

    for item in pages:
        if item.get("object") == "database":
            title = item.get("title", [])
            name = title[0].get("plain_text", "") if title else ""
            if "tilawa" in name.lower() or "memuslim" in name.lower():
                return item["id"]

    page_candidates = [p for p in pages if p.get("object") == "page"]
    if len(page_candidates) == 1 and args.setup:
        database_id = client.create_tasks_database(page_candidates[0]["id"])
        config["database_id"] = database_id
        config["parent_page_id"] = page_candidates[0]["id"]
        save_config(config)
        return database_id

    lines = []
    for item in pages:
        title = ""
        if item.get("object") == "page":
            props = item.get("properties", {})
            for prop in props.values():
                if prop.get("type") == "title":
                    parts = prop.get("title", [])
                    title = parts[0].get("plain_text", "") if parts else ""
                    break
        elif item.get("object") == "database":
            parts = item.get("title", [])
            title = parts[0].get("plain_text", "") if parts else ""
        lines.append(f"- {item['object']}: {title or '(untitled)'} → {item['id']}")

    raise RuntimeError(
        "Could not resolve tasks database. Pass --database-id or --parent-page-id.\n"
        "Accessible Notion items:\n" + "\n".join(lines)
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--todo", type=Path, default=DEFAULT_TODO)
    parser.add_argument("--database-id", help="Existing Notion database ID")
    parser.add_argument(
        "--parent-page-id",
        help="Create tasks database under this Notion page",
    )
    parser.add_argument(
        "--setup",
        action="store_true",
        help="Create database when exactly one page is shared",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse TODO.md and print actions without Notion writes",
    )
    parser.add_argument(
        "--list-access",
        action="store_true",
        help="List pages/databases shared with the integration",
    )
    args = parser.parse_args()

    token = os.environ.get("NOTION_API_KEY", "").strip()
    if not token and not args.dry_run:
        print("Set NOTION_API_KEY before syncing.", file=sys.stderr)
        return 1

    tasks = parse_todo(args.todo)
    if args.dry_run:
        print(f"Parsed {len(tasks)} tasks from {args.todo}")
        for task in tasks:
            print(
                f"[{task.section}] {task.status} {task.priority} "
                f"{task.task_key}: {task.title}"
            )
        return 0

    client = NotionClient(token)

    if args.list_access:
        pages = client.search_pages()
        if not pages:
            print("No pages or databases shared with MyAccess yet.")
            return 0
        for item in pages:
            print(f"{item['object']}\t{item['id']}")
        return 0

    database_id = resolve_database_id(client, args)
    existing = client.query_tasks(database_id)

    created = 0
    updated = 0
    for task in tasks:
        page_id = existing.get(task.task_key)
        client.upsert_task(database_id, task, page_id)
        if page_id:
            updated += 1
        else:
            created += 1

    print(
        f"Synced {len(tasks)} tasks to Notion database {database_id} "
        f"(created {created}, updated {updated})."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

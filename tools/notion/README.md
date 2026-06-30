# Notion task sync (Tilawa / MeMuslim)

One-way sync from [`docs/TODO.md`](../../docs/TODO.md) into a Notion database.

## Setup

1. Create or open a Notion integration at
   [notion.so/my-integrations](https://www.notion.so/my-integrations).
2. Export the secret locally (do not commit it):

   ```bash
   export NOTION_API_KEY="ntn_..."
   ```

3. In Notion, open the page that should host the task board → **⋯** →
   **Connections** → add your integration (for example **MyAccess**).
4. Copy that page ID from its URL:
   `https://www.notion.so/Workspace/Page-Title-<PAGE_ID>`

## Commands

Dry-run parse only:

```bash
python3 tools/notion/sync_tilawa_tasks.py --dry-run
```

List items shared with the integration:

```bash
python3 tools/notion/sync_tilawa_tasks.py --list-access
```

Create database + first sync:

```bash
python3 tools/notion/sync_tilawa_tasks.py --setup --parent-page-id <PAGE_ID>
```

Sync again (uses saved database ID in `tools/notion/.notion.local.json`):

```bash
python3 tools/notion/sync_tilawa_tasks.py
```

## Database fields

| Property | Source |
| --- | --- |
| Name | Task title from TODO.md |
| Status | `[ ]` / `[~]` / `[x]` |
| Priority | `P0` / `P1` / `P2` or `—` |
| Section | Features, Refactors, Ops, Known issues, Done |
| Task key | Stable slug for upsert |
| Description | Indented lines under each task |

## Notes

- Sync is **repo → Notion** only. Edit tasks in `docs/TODO.md`, then rerun sync.
- `tools/notion/.notion.local.json` stores the database ID locally and is gitignored.
- Regenerate and rotate your Notion secret if it was ever pasted into chat or logs.

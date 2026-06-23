# Tilawa architecture docs

Living architecture documentation for the Tilawa app. ADRs record
**decisions**; these guides record **patterns and ownership**.

| Document | Topic |
|----------|--------|
| [navigation.md](navigation.md) | GoRouter, shell vs root overlay routes |
| [media-state-vocabulary.md](media-state-vocabulary.md) | Playback vs presentation vs navigation vs chrome |
| [player-presentation.md](player-presentation.md) | Quran player phases, controller, Hero |
| [player-entry-pipeline.md](player-entry-pipeline.md) | Canonical expand/collapse entry (B2-ready) |
| [player-migration-roadmap.md](player-migration-roadmap.md) | Phase C cleanup, QA checklist, redundancy audit |
| [../UI_KIT_INPUT_SYSTEM.md](../UI_KIT_INPUT_SYSTEM.md) | Input SSOT (`TilawaInputStyle`, field shell, kit atoms) |

**ADRs:** [`../adr/`](../adr/) — includes [004 input system SSOT](../adr/004-input-system-single-source-of-truth.md)

When adding a new overlay, modal, or full-screen flow, read
[navigation.md](navigation.md) first — do not invent a one-off `Navigator.push`
pattern.

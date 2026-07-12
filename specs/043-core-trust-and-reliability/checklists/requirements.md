# Requirements Checklist

- [ ] **Testability**: Every FR has a corresponding unit, integration, or manual test defined in `tasks.md`.
- [ ] **Religious Content Integrity**: `quran_manifest.json` ensures zero unauthorized modifications to text.
- [ ] **Platform Parity**: Android utilizes Exact Alarms; iOS utilizes native Local Notifications.
- [ ] **Platform-Specific Limitations**: Handled via diagnostic UI explicitly outlining battery/alarm limits.
- [ ] **Offline Behavior**: Manual location DB is fully offline. Quran hash check is offline.
- [ ] **Accessibility**: Health UI uses semantic labels and high contrast.
- [ ] **UI Kit Compliance**: All dialogs and sheets use existing Tilawa UI tokens.
- [ ] **RTL / LTR**: UIs tested in Arabic and English.
- [ ] **Migration**: Safe handling of missing manual location keys.
- [ ] **Privacy**: Location coordinates never sent to Analytics.
- [ ] **Observability**: Delivery success rate events are explicitly mapped.
- [ ] **Rollout Safety**: Phase boundaries and Feature Flags ensure incremental shipping.
- [ ] **Requirement-Task Traceability**: Mapped 1-to-1 in `tasks.md`.

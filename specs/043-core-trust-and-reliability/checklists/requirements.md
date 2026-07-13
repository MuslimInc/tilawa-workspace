# Requirements Checklist

- [ ] **Testability**: Every FR has a corresponding unit, integration, or manual test defined.
- [ ] **Religious Content Integrity**: Build-time validation prevents unauthorized modifications to text.
- [ ] **Athan Reliability**: Distinguishes scheduling, trigger, and presentation success. Observable and measurable.
- [ ] **Platform-Specific Limitations**: Handled via explicit diagnostic UI, respecting Android Exact Alarm constraints and iOS 30s limits.
- [ ] **Offline Behavior**: Manual location DB is fully offline. Quran hash check is offline.
- [ ] **Accessibility**: Health UI uses semantic labels and high contrast.
- [ ] **UI Kit Compliance**: All dialogs and sheets use existing Tilawa UI tokens.
- [ ] **RTL / LTR**: UIs tested in Arabic and English.
- [ ] **Migration**: Safe handling of missing manual location keys.
- [ ] **Privacy**: Location coordinates never sent to Analytics.
- [ ] **Observability**: Execution pipelines benchmarked and logged.
- [ ] **Rollout Safety**: Phase boundaries and Feature Flags ensure incremental shipping.
- [ ] **Requirement-Task Traceability**: Mapped 1-to-1 in `tasks.md`.

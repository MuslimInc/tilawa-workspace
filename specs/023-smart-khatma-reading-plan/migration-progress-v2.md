# Al-Khatmah pre-release schema replacement

Repository evidence shows Smart Khatma was launch-gated during development and
the confirmed-progress model has not shipped as a public contract. The release
therefore uses the new key `smart_khatma.active_plan.v2` and does not build a
general migration framework.

- v1 is ignored, not read as confirmed progress, and not deleted.
- v2 is the only release write target.
- Existing development testers create a new plan.
- Malformed v2 data remains untouched and produces a recoverable error state.
- Reset requires user confirmation and clears only v2.
- Rollback disables the feature flag; it does not delete Quran history,
  bookmarks, v1, or v2 data.

If release records later prove v1 reached real users, rollout must stop and a
one-time editable confirmation migration must be added before re-enabling.

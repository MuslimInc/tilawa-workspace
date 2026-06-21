# Rejection Lifecycle

| Step | Application status | Re-apply |
|------|-------------------|----------|
| Reject (CF) | `rejected` | after cooldown (30 days, client-enforced) |

Admin must provide **rejection reason** (stored in `rejectionReason`).

Admin UI: **Reject** → reason dialog → callable `reject`.

Phone and rejection reason are **never** shown on public teacher profiles.

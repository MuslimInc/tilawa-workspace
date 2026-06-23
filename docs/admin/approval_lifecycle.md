# Approval Lifecycle

| Step | Application status | Teacher profile |
|------|-------------------|-----------------|
| Submit | `pending` | none |
| Approve (CF) | `approved` | created, `verified`, `isActive: true` |
| Suspend (CF) | `suspended` | `isActive: false` |
| Revoke (CF) | `revoked` | `isActive: false` |

Review metadata set server-side: `reviewedAt`, `reviewedBy`, optional `rejectionReason`.

Admin UI: **Approve** confirmation dialog → callable `approve`.

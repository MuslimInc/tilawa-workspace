import assert from "node:assert/strict";
import test from "node:test";

import {
  findDuplicateEmailGroups,
  formatDuplicateEmailAuditReport,
} from "../src/auditDuplicateUserEmails";

test("findDuplicateEmailGroups reports duplicate emails without deleting", () => {
  const result = findDuplicateEmailGroups([
    { id: "uid_a", email: "teacher@example.com" },
    { id: "uid_b", email: "teacher@example.com" },
    { id: "uid_c", email: "unique@example.com" },
    { id: "uid_d", email: "   " },
  ]);

  assert.equal(result.totalUsersScanned, 4);
  assert.equal(result.duplicateGroups.length, 1);
  assert.deepEqual(result.duplicateGroups[0], {
    email: "teacher@example.com",
    userIds: ["uid_a", "uid_b"],
  });
});

test("formatDuplicateEmailAuditReport marks dry-run output", () => {
  const report = formatDuplicateEmailAuditReport(
    {
      totalUsersScanned: 2,
      duplicateGroups: [
        { email: "teacher@example.com", userIds: ["uid_a", "uid_b"] },
      ],
    },
    true,
  );

  assert.match(report, /DRY RUN/);
  assert.match(report, /teacher@example.com: uid_a, uid_b/);
  assert.doesNotMatch(report, /deleted uid_/);
});

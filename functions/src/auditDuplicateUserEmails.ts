export interface UserEmailRecord {
  id: string;
  email?: string | null;
}

export interface DuplicateEmailGroup {
  email: string;
  userIds: string[];
}

export interface DuplicateEmailAuditResult {
  duplicateGroups: DuplicateEmailGroup[];
  totalUsersScanned: number;
}

export function findDuplicateEmailGroups(
  users: readonly UserEmailRecord[],
): DuplicateEmailAuditResult {
  const byEmail = new Map<string, string[]>();

  for (const user of users) {
    const normalized = user.email?.trim().toLowerCase();
    if (!normalized) continue;
    const ids = byEmail.get(normalized) ?? [];
    ids.push(user.id);
    byEmail.set(normalized, ids);
  }

  const duplicateGroups: DuplicateEmailGroup[] = [];
  for (const [email, userIds] of byEmail.entries()) {
    if (userIds.length > 1) {
      duplicateGroups.push({ email, userIds: [...userIds].sort() });
    }
  }

  duplicateGroups.sort((a, b) => a.email.localeCompare(b.email));

  return {
    duplicateGroups,
    totalUsersScanned: users.length,
  };
}

export function formatDuplicateEmailAuditReport(
  result: DuplicateEmailAuditResult,
  dryRun: boolean,
): string {
  const lines = [
    dryRun ? "DRY RUN — no user documents deleted" : "APPLY — no deletions performed",
    `Users scanned: ${result.totalUsersScanned}`,
    `Duplicate email groups: ${result.duplicateGroups.length}`,
  ];

  for (const group of result.duplicateGroups) {
    lines.push(`- ${group.email}: ${group.userIds.join(", ")}`);
  }

  return lines.join("\n");
}

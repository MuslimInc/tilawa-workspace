// Shared GitHub issue helpers used by both the Crashlytics alert trigger and
// the one-off backfill script, so dedup/formatting stays identical.

export const GITHUB_OWNER = "muhammadkamel";
export const GITHUB_REPO = "tilawa-workspace";
export const FIREBASE_PROJECT_ID = "quran-playera-app";

// Label applied to every crash-sourced issue. Dedup keys off the Crashlytics
// issue id embedded in the title, not the label.
export const CRASH_LABEL = "crashlytics";

export interface CrashIssue {
  id: string;
  title: string;
  subtitle: string;
  appVersion: string;
}

interface GithubIssue {
  number: number;
  html_url: string;
}

export function consoleUrl(crashIssueId: string): string {
  return (
    `https://console.firebase.google.com/project/${FIREBASE_PROJECT_ID}` +
    `/crashlytics/app/-/issues/${crashIssueId}`
  );
}

/**
 * Returns an existing GitHub issue carrying this Crashlytics id, or null.
 * The crash id lives in the title, so the search finds re-publishes
 * regardless of label or open/closed state.
 */
export async function findExistingIssue(
  crashIssueId: string,
  token: string
): Promise<GithubIssue | null> {
  const query = encodeURIComponent(
    `repo:${GITHUB_OWNER}/${GITHUB_REPO} in:title "${crashIssueId}" is:issue`
  );
  const res = await fetch(`https://api.github.com/search/issues?q=${query}`, {
    headers: githubHeaders(token),
  });

  if (!res.ok) {
    throw new Error(
      `GitHub issue search failed (${res.status}): ${await res.text()}`
    );
  }

  const body = (await res.json()) as { items: GithubIssue[] };
  return body.items.length > 0 ? body.items[0] : null;
}

export async function createIssue(
  issue: CrashIssue,
  token: string
): Promise<GithubIssue> {
  const title = `[Crash] ${issue.title} (${issue.id})`;
  const body = [
    `**Fatal crash reported by Firebase Crashlytics.**`,
    "",
    `- **Issue:** ${issue.title}`,
    `- **Where:** ${issue.subtitle}`,
    `- **App version:** ${issue.appVersion}`,
    `- **Crashlytics id:** \`${issue.id}\``,
    "",
    `[Open in Firebase Console](${consoleUrl(issue.id)})`,
    "",
    "_Filed automatically. Do not edit the id in the title — it is used for deduplication._",
  ].join("\n");

  const res = await fetch(
    `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/issues`,
    {
      method: "POST",
      headers: githubHeaders(token),
      body: JSON.stringify({ title, body, labels: [CRASH_LABEL] }),
    }
  );

  if (!res.ok) {
    throw new Error(
      `GitHub issue creation failed (${res.status}): ${await res.text()}`
    );
  }

  return (await res.json()) as GithubIssue;
}

function githubHeaders(token: string): Record<string, string> {
  return {
    Authorization: `Bearer ${token}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "Content-Type": "application/json",
  };
}

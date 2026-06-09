/**
 * One-off backfill: read existing fatal crash groups from the Crashlytics
 * BigQuery export and open a GitHub issue for each that isn't already tracked.
 *
 * The export only contains crashes from after it was enabled, and stores one
 * row per crash *event* — this groups them into issues, matching what the
 * onNewFatalIssuePublished trigger receives going forward.
 *
 * Usage (from functions/):
 *   export GITHUB_ISSUES_TOKEN=<fine-grained PAT with Issues:write>
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa-key.json   # or `gcloud auth application-default login`
 *   npx ts-node scripts/backfillCrashIssues.ts            # dry run, lists what it would create
 *   npx ts-node scripts/backfillCrashIssues.ts --apply    # actually create issues
 */
import { google } from "googleapis";
import {
  CrashIssue,
  FIREBASE_PROJECT_ID,
  createIssue,
  findExistingIssue,
} from "../src/github";

const APPLY = process.argv.includes("--apply");
const DATASET = "firebase_crashlytics";

async function main(): Promise<void> {
  const token = process.env.GITHUB_ISSUES_TOKEN;
  if (!token) {
    throw new Error("Set GITHUB_ISSUES_TOKEN to a PAT with Issues:write.");
  }

  const auth = new google.auth.GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/bigquery"],
  });
  const bigquery = google.bigquery({ version: "v2", auth });

  const tables = await listCrashlyticsTables(bigquery);
  if (tables.length === 0) {
    throw new Error(
      `No tables found in ${FIREBASE_PROJECT_ID}.${DATASET}. ` +
        "Is the Crashlytics → BigQuery export enabled?"
    );
  }
  console.log(`Found ${tables.length} crashlytics table(s): ${tables.join(", ")}`);

  const issues = await fetchFatalIssues(bigquery, tables);
  console.log(`${issues.length} distinct fatal crash group(s) in export.`);

  let created = 0;
  let skipped = 0;
  for (const issue of issues) {
    const existing = await findExistingIssue(issue.id, token);
    if (existing) {
      skipped++;
      console.log(`skip  ${issue.id}  →  ${existing.html_url}`);
      continue;
    }
    if (!APPLY) {
      console.log(`would create  ${issue.id}  ${issue.title}`);
      continue;
    }
    const gh = await createIssue(issue, token);
    created++;
    console.log(`create ${issue.id}  →  ${gh.html_url}`);
  }

  console.log(
    APPLY
      ? `Done. Created ${created}, skipped ${skipped} already-tracked.`
      : `Dry run. ${issues.length - skipped} would be created, ${skipped} already tracked. Re-run with --apply.`
  );
}

// The export names tables <APP_ID>_<PLATFORM>; discover them rather than guess.
async function listCrashlyticsTables(
  bigquery: ReturnType<typeof google.bigquery>
): Promise<string[]> {
  const res = await bigquery.tables.list({
    projectId: FIREBASE_PROJECT_ID,
    datasetId: DATASET,
    maxResults: 1000,
  });
  return (res.data.tables ?? [])
    .map((t) => t.tableReference?.tableId)
    .filter((id): id is string => Boolean(id));
}

async function fetchFatalIssues(
  bigquery: ReturnType<typeof google.bigquery>,
  tables: string[]
): Promise<CrashIssue[]> {
  // One representative row per issue_id: latest event wins for version/title.
  const unions = tables
    .map(
      (t) =>
        `SELECT issue_id, issue_title, issue_subtitle, ` +
        `application.display_version AS app_version, event_timestamp ` +
        `FROM \`${FIREBASE_PROJECT_ID}.${DATASET}.${t}\` ` +
        `WHERE error_type = 'FATAL'`
    )
    .join(" UNION ALL ");

  const query =
    `WITH events AS (${unions}), ` +
    `ranked AS (` +
    `  SELECT *, ROW_NUMBER() OVER (` +
    `    PARTITION BY issue_id ORDER BY event_timestamp DESC` +
    `  ) AS rn FROM events` +
    `) ` +
    `SELECT issue_id, issue_title, issue_subtitle, app_version ` +
    `FROM ranked WHERE rn = 1 ORDER BY issue_id`;

  const res = await bigquery.jobs.query({
    projectId: FIREBASE_PROJECT_ID,
    requestBody: { query, useLegacySql: false, timeoutMs: 60000 },
  });

  return (res.data.rows ?? []).map((row) => {
    const [id, title, subtitle, appVersion] = (row.f ?? []).map(
      (c) => (c.v as string) ?? ""
    );
    return {
      id,
      title: title || "(untitled crash)",
      subtitle: subtitle || "",
      appVersion: appVersion || "unknown",
    };
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

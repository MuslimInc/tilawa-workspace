import { onNewFatalIssuePublished } from "firebase-functions/v2/alerts/crashlytics";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { createIssue, findExistingIssue } from "./github";

// Fine-grained PAT with Issues:write on this repo, stored in Secret Manager.
// Set it with: firebase functions:secrets:set GITHUB_ISSUES_TOKEN
const GITHUB_ISSUES_TOKEN = defineSecret("GITHUB_ISSUES_TOKEN");

/**
 * Opens a GitHub issue when Crashlytics publishes a brand-new fatal crash.
 * Dedupes by searching for an existing issue carrying the same Crashlytics
 * issue id before creating a new one.
 */
export const crashlyticsToGithubIssue = onNewFatalIssuePublished(
  { region: "us-central1", secrets: [GITHUB_ISSUES_TOKEN] },
  async (event) => {
    const { issue } = event.data.payload;
    const token = GITHUB_ISSUES_TOKEN.value();

    const existing = await findExistingIssue(issue.id, token);
    if (existing) {
      logger.info(
        `Crashlytics issue ${issue.id} already tracked at ${existing.html_url}`
      );
      return;
    }

    const created = await createIssue(issue, token);
    logger.info(`Opened ${created.html_url} for Crashlytics issue ${issue.id}`);
  }
);

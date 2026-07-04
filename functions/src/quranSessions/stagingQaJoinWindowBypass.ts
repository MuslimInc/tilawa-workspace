import * as logger from "firebase-functions/logger";

import { FIREBASE_PROJECT_ID } from "../github";
import {
  MAESTRO_STUDENT_UID,
  MAESTRO_TEACHER_UID,
} from "./maestroStagingAccounts";

/** Staging Maestro QA accounts — join-window bypass only, never production. */
export const STAGING_QA_JOIN_WINDOW_BYPASS_UIDS = new Set<string>([
  MAESTRO_TEACHER_UID,
  MAESTRO_STUDENT_UID,
]);

const BLOCKED_DISTRIBUTIONS = new Set(["production", "play_production"]);

const STAGING_DISTRIBUTIONS = new Set(["local", "staging"]);

/**
 * True when Cloud Functions run in a non-production staging context.
 *
 * Prefers explicit `TILAWA_DISTRIBUTION`; falls back to Firebase project id
 * (`quran-playera-app` staging project).
 */
export function isStagingEnvironmentForQaJoinWindowBypass(): boolean {
  const distribution = process.env.TILAWA_DISTRIBUTION?.trim();
  if (distribution != null && BLOCKED_DISTRIBUTIONS.has(distribution)) {
    return false;
  }
  if (distribution != null && STAGING_DISTRIBUTIONS.has(distribution)) {
    return true;
  }

  const projectId =
    process.env.GCLOUD_PROJECT?.trim()
    ?? process.env.FIREBASE_PROJECT_ID?.trim()
    ?? FIREBASE_PROJECT_ID;
  return projectId === FIREBASE_PROJECT_ID;
}

/**
 * Staging-only QA override: skip join-window timing for allowlisted uids.
 * All other sessionAuth / lifecycle / participant checks remain enforced.
 */
export function isQaJoinWindowBypassEligible(uid: string | undefined): boolean {
  const normalized = uid?.trim();
  if (normalized == null || normalized.length === 0) {
    return false;
  }
  if (!STAGING_QA_JOIN_WINDOW_BYPASS_UIDS.has(normalized)) {
    return false;
  }
  if (!isStagingEnvironmentForQaJoinWindowBypass()) {
    return false;
  }

  logger.info(`[QA] join-window bypass applied for uid=${normalized}`);
  return true;
}

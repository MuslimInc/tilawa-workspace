import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const SRC_ROOT = join(__dirname, "../../src");

/** Stable-scope session callables (see security-safety-checklist App Check table). */
const STABLE_SESSION_CALLABLE_FILES = [
  "quranSessions/createSessionBooking.ts",
  "quranSessions/cancelSessionBooking.ts",
  "quranSessions/requestSessionReschedule.ts",
  "quranSessions/confirmSessionReschedule.ts",
  "quranSessions/completeSession.ts",
  "quranSessions/markSessionNoShow.ts",
  "quranSessions/sessionDisputeCallables.ts",
  "quranSessions/sessionReportCallables.ts",
  "quranSessions/issueSessionRtcToken.ts",
  "quranSessions/issueDebugLiveKitToken.ts",
  "quranSessions/recordCallTelemetryEvent.ts",
  "registerActiveDevice.ts",
] as const;

/** Wallet/payment batch — must stay on explicit enforceAppCheck: false. */
const EXCLUDED_CALLABLE_FILES = [
  "quranSessions/walletCallables.ts",
  "quranSessions/confirmBookingPayment.ts",
  "quranSessions/issueSessionCompensation.ts",
  "quranSessions/approveSessionRefund.ts",
] as const;

const IMPORT_PATTERN =
  /import\s*{[^}]*sessionCallableHttpsOptions[^}]*}\s*from\s*["'][^"']*sessionCallableOptions["']/;

const ON_CALL_WITH_SESSION_OPTIONS_PATTERN =
  /onCall\(\s*(sessionCallableHttpsOptions|\{[^}]*\.\.\.sessionCallableHttpsOptions)/;

test("stable session callables import and pass sessionCallableHttpsOptions", () => {
  for (const relPath of STABLE_SESSION_CALLABLE_FILES) {
    const source = readFileSync(join(SRC_ROOT, relPath), "utf8");
    assert.match(
      source,
      IMPORT_PATTERN,
      `${relPath} must import sessionCallableHttpsOptions`,
    );
    const onCallMatches = source.match(
      new RegExp(ON_CALL_WITH_SESSION_OPTIONS_PATTERN.source, "g"),
    );
    assert.ok(
      onCallMatches && onCallMatches.length >= 1,
      `${relPath} must pass sessionCallableHttpsOptions to onCall`,
    );
  }
});

test("stable batch covers exactly fourteen onCall exports", () => {
  let count = 0;
  for (const relPath of STABLE_SESSION_CALLABLE_FILES) {
    const source = readFileSync(join(SRC_ROOT, relPath), "utf8");
    const matches = source.match(
      new RegExp(ON_CALL_WITH_SESSION_OPTIONS_PATTERN.source, "g"),
    );
    count += matches?.length ?? 0;
  }
  assert.equal(count, 14, "expected 14 stable-scope session callables");
});

test("index exports sessionReminders scheduled job", () => {
  const source = readFileSync(join(SRC_ROOT, "index.ts"), "utf8");
  assert.match(
    source,
    /export\s*{\s*sessionReminders\s*}\s*from\s*["'].*sessionReminders["']/,
    "index.ts must export sessionReminders for production reminders",
  );
});

test("wallet/payment callables remain excluded from shared App Check options", () => {
  for (const relPath of EXCLUDED_CALLABLE_FILES) {
    const source = readFileSync(join(SRC_ROOT, relPath), "utf8");
    assert.doesNotMatch(
      source,
      IMPORT_PATTERN,
      `${relPath} must not import sessionCallableHttpsOptions`,
    );
    assert.match(
      source,
      /enforceAppCheck:\s*false/,
      `${relPath} must keep enforceAppCheck: false`,
    );
  }
});

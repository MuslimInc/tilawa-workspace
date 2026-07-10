/**
 * Sets or clears a teacher's admin-controlled session price override, using the
 * Admin SDK directly (ops path until the Admin Panel Pricing UI ships).
 *
 * Reuses the exact `buildSessionPriceOverrideWrite` builder the
 * `setTeacherSessionPricing` callable uses, so the script and the callable
 * produce identical documents. An amount of 0 means the teacher is free even in
 * a paid market; clearing falls back to the market price.
 *
 * Dry-run by default — pass --apply to commit.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=... \
 *     npm run quran-sessions:set-teacher-pricing -- \
 *       --teacherId=ILAY73dMn4hZDuAWzzJ7 --mode=free
 *   ...:set-teacher-pricing:apply -- --teacherId=... --mode=fixed --amount=40 --currency=EGP
 *   ...:set-teacher-pricing:apply -- --teacherId=... --mode=clear
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

import {
  buildSessionPriceOverrideWrite,
  type SetTeacherSessionPricingRequest,
} from "../src/quranSessions/setTeacherSessionPricing";

initializeApp();

type Mode = "free" | "fixed" | "clear";

interface Args {
  teacherId: string;
  mode: Mode;
  amount?: number;
  currency?: string;
  apply: boolean;
}

function parseArgs(): Args {
  const args = process.argv.slice(2);
  let teacherId = "";
  let mode: Mode | "" = "";
  let amount: number | undefined;
  let currency: string | undefined;
  let apply = false;

  for (const arg of args) {
    if (arg.startsWith("--teacherId=")) {
      teacherId = arg.split("=")[1] ?? "";
    } else if (arg.startsWith("--mode=")) {
      mode = (arg.split("=")[1] ?? "") as Mode;
    } else if (arg.startsWith("--amount=")) {
      amount = Number(arg.split("=")[1]);
    } else if (arg.startsWith("--currency=")) {
      currency = arg.split("=")[1];
    } else if (arg === "--apply") {
      apply = true;
    }
  }

  if (!teacherId) throw new Error("--teacherId is required");
  if (mode !== "free" && mode !== "fixed" && mode !== "clear") {
    throw new Error("--mode must be one of: free | fixed | clear");
  }
  if (mode === "fixed" && (amount == null || Number.isNaN(amount))) {
    throw new Error("--amount is required (and numeric) when --mode=fixed");
  }

  return { teacherId, mode, amount, currency, apply };
}

function toRequest(args: Args): SetTeacherSessionPricingRequest {
  switch (args.mode) {
    case "clear":
      return { teacherId: args.teacherId, enabled: false };
    case "free":
      return { teacherId: args.teacherId, enabled: true, amount: 0 };
    case "fixed":
      return {
        teacherId: args.teacherId,
        enabled: true,
        amount: args.amount,
        currencyCode: args.currency,
      };
  }
}

async function main(): Promise<void> {
  const args = parseArgs();
  const db = getFirestore();

  const profileRef = db
    .collection("quran_teacher_profiles")
    .doc(args.teacherId);
  const snap = await profileRef.get();
  if (!snap.exists) {
    throw new Error(`Teacher profile not found: ${args.teacherId}`);
  }

  // Same validation + shape as the callable (throws on bad input).
  const patch = buildSessionPriceOverrideWrite(toRequest(args), "admin-script");
  const override = patch.sessionPriceOverride as Record<string, unknown>;

  console.log(
    `Teacher ${args.teacherId} (${snap.data()?.displayName ?? "?"})\n` +
      `  → sessionPriceOverride: enabled=${override.enabled}` +
      (override.enabled
        ? `, amount=${override.amount}, currency=${override.currencyCode ?? "(market)"}`
        : " (falls back to market price)"),
  );

  if (!args.apply) {
    console.log("\nDry run — pass --apply to commit.");
    return;
  }

  await profileRef.set(patch, { merge: true });
  await db.collection("quran_session_events").add({
    timestamp: FieldValue.serverTimestamp(),
    aggregateId: args.teacherId,
    teacherId: args.teacherId,
    actorId: "admin-script",
    actorRole: "admin",
    action: "set_teacher_session_pricing",
    source: "adminScript",
    overrideEnabled: override.enabled,
    overrideAmount: override.amount ?? null,
    overrideCurrencyCode: override.currencyCode ?? null,
  });

  console.log("\nApplied.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

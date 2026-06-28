import test from "node:test";
import assert from "node:assert/strict";

import {
  distributionDefaultBookingMode,
  resolveQuranTutorBookingMode,
} from "../../src/quranSessions/quranTutorBookingMode";

test("defaults staging/local to autoConfirm", () => {
  const prev = process.env.TILAWA_DISTRIBUTION;
  process.env.TILAWA_DISTRIBUTION = "staging";
  assert.equal(distributionDefaultBookingMode(), "autoConfirm");
  process.env.TILAWA_DISTRIBUTION = prev;
});

test("defaults play_production to requiresTutorApproval", () => {
  const prev = process.env.TILAWA_DISTRIBUTION;
  process.env.TILAWA_DISTRIBUTION = "play_production";
  assert.equal(distributionDefaultBookingMode(), "requiresTutorApproval");
  process.env.TILAWA_DISTRIBUTION = prev;
});

test("reads valid Firestore config", () => {
  assert.equal(
    resolveQuranTutorBookingMode({ quranTutorBookingMode: "autoConfirm" }),
    "autoConfirm",
  );
});

test("falls back when config invalid", () => {
  const prev = process.env.TILAWA_DISTRIBUTION;
  process.env.TILAWA_DISTRIBUTION = "staging";
  assert.equal(
    resolveQuranTutorBookingMode({ quranTutorBookingMode: "bogus" }),
    "autoConfirm",
  );
  process.env.TILAWA_DISTRIBUTION = prev;
});

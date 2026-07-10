import { test } from "node:test";
import assert from "node:assert/strict";

import {
  isMarketEnabled,
  normalizeMarketCodes,
  parseMarketGatePolicy,
} from "../../src/quranSessions/marketGate";

test("parseMarketGatePolicy fails closed on empty/missing config", () => {
  assert.deepEqual(parseMarketGatePolicy({}), {
    enableForAllMarkets: false,
    enabledMarketCodes: [],
  });
  assert.deepEqual(parseMarketGatePolicy(null), {
    enableForAllMarkets: false,
    enabledMarketCodes: [],
  });
});

test("normalizeMarketCodes trims, upper-cases, and de-duplicates", () => {
  assert.deepEqual(normalizeMarketCodes([" eg ", "EG", "sa", 5, null, ""]), [
    "EG",
    "SA",
  ]);
  assert.deepEqual(normalizeMarketCodes("EG"), []);
});

test("isMarketEnabled allows a code in the enabled list (case-insensitive)", () => {
  const gate = parseMarketGatePolicy({ enabledMarketCodes: ["EG"] });
  assert.equal(isMarketEnabled(gate, "EG"), true);
  assert.equal(isMarketEnabled(gate, "eg"), true);
  assert.equal(isMarketEnabled(gate, " eg "), true);
});

test("isMarketEnabled blocks a code not in the enabled list", () => {
  const gate = parseMarketGatePolicy({ enabledMarketCodes: ["EG"] });
  assert.equal(isMarketEnabled(gate, "SA"), false);
  assert.equal(isMarketEnabled(gate, null), false);
  assert.equal(isMarketEnabled(gate, undefined), false);
});

test("isMarketEnabled allows every market when enableForAllMarkets is true", () => {
  const gate = parseMarketGatePolicy({
    enableForAllMarkets: true,
    enabledMarketCodes: [],
  });
  assert.equal(isMarketEnabled(gate, "SA"), true);
  assert.equal(isMarketEnabled(gate, "XX"), true);
  // A null country is still blocked when relying on the allow-list only.
  const listOnly = parseMarketGatePolicy({ enabledMarketCodes: ["EG"] });
  assert.equal(isMarketEnabled(listOnly, null), false);
});

test("empty enabled list blocks all markets", () => {
  const gate = parseMarketGatePolicy({ enabledMarketCodes: [] });
  assert.equal(isMarketEnabled(gate, "EG"), false);
});

import test from "node:test";
import assert from "node:assert/strict";

import { assertClientSessionEpoch } from "../../src/quranSessions/sessionRegistration";

test("sessionAuth epoch guard rejects missing epoch", () => {
  assert.throws(
    () => assertClientSessionEpoch(undefined, 1),
    /session_epoch_required/,
  );
});

test("sessionAuth epoch guard rejects stale epoch", () => {
  assert.throws(
    () => assertClientSessionEpoch(1, 2),
    /session_epoch_stale/,
  );
});

test("sessionAuth epoch guard accepts current epoch", () => {
  assert.doesNotThrow(() => assertClientSessionEpoch(0, 0));
  assert.doesNotThrow(() => assertClientSessionEpoch(3, 3));
});

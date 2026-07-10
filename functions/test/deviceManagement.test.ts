import test from "node:test";
import assert from "node:assert/strict";

import { selectOtherDeviceIds } from "../src/deviceManagement";

test("selectOtherDeviceIds returns every id except the current device", () => {
  const result = selectOtherDeviceIds(["a", "b", "c"], "b");
  assert.deepEqual(result, ["a", "c"]);
});

test("selectOtherDeviceIds is empty when current is the only device", () => {
  assert.deepEqual(selectOtherDeviceIds(["only"], "only"), []);
});

test("selectOtherDeviceIds is empty when there are no devices", () => {
  assert.deepEqual(selectOtherDeviceIds([], "current"), []);
});

test("selectOtherDeviceIds keeps all when current is not in the list", () => {
  // Current device not yet registered — never sign out an unknown-to-list id,
  // but do target all the known ones.
  assert.deepEqual(selectOtherDeviceIds(["a", "b"], "z"), ["a", "b"]);
});

test("selectOtherDeviceIds preserves order and does not mutate input", () => {
  const input = ["x", "current", "y"];
  const result = selectOtherDeviceIds(input, "current");
  assert.deepEqual(result, ["x", "y"]);
  assert.deepEqual(input, ["x", "current", "y"]);
});

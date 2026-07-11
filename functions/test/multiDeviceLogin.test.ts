import test from "node:test";
import assert from "node:assert/strict";

import { isMultiDeviceLoginEnabled } from "../src/multiDeviceLogin";

function withEnv(
  value: string | undefined,
  run: () => void,
): void {
  const previous = process.env.MULTI_DEVICE_LOGIN_ENABLED;
  if (value == null) {
    delete process.env.MULTI_DEVICE_LOGIN_ENABLED;
  } else {
    process.env.MULTI_DEVICE_LOGIN_ENABLED = value;
  }
  try {
    run();
  } finally {
    if (previous == null) {
      delete process.env.MULTI_DEVICE_LOGIN_ENABLED;
    } else {
      process.env.MULTI_DEVICE_LOGIN_ENABLED = previous;
    }
  }
}

test("multi-device login is enabled by default when env is unset", () => {
  withEnv(undefined, () => {
    assert.equal(isMultiDeviceLoginEnabled(), true);
  });
});

test("multi-device login stays enabled when env is true", () => {
  withEnv("true", () => {
    assert.equal(isMultiDeviceLoginEnabled(), true);
  });
});

test("multi-device login is disabled only when env is false", () => {
  withEnv("false", () => {
    assert.equal(isMultiDeviceLoginEnabled(), false);
  });
});

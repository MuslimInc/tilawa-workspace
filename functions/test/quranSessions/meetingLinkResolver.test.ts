import test from "node:test";
import assert from "node:assert/strict";

import { resolveMeetingLink } from "../../src/quranSessions/meetingLinkResolver";

test("resolveMeetingLink returns teacher URL for externalMeeting", () => {
  const url = resolveMeetingLink(
    "externalMeeting",
    { externalMeetingUrl: " https://meet.example.com/t " },
    {},
  );
  assert.equal(url, "https://meet.example.com/t");
});

test("resolveMeetingLink falls back to platform default", () => {
  const url = resolveMeetingLink(
    "externalMeeting",
    {},
    { defaultExternalMeetingUrl: "https://meet.example.com/platform" },
  );
  assert.equal(url, "https://meet.example.com/platform");
});

test("resolveMeetingLink returns null when externalMeeting has no source", () => {
  assert.equal(resolveMeetingLink("externalMeeting", {}, {}), null);
});

test("resolveMeetingLink returns null for non-external call types", () => {
  assert.equal(
    resolveMeetingLink("videoCall", { externalMeetingUrl: "https://x" }, {}),
    null,
  );
});

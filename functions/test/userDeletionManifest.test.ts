import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";

import {
  COLLECTION_CLASSIFICATIONS,
  PURGE_STEPS,
} from "../src/userDeletion/deletionManifest";

/**
 * Guard against user-linked collections silently escaping the deletion flow:
 * every top-level collection in firestore.rules must be classified in the
 * deletion manifest, and vice versa. If this test fails after you added a
 * collection, classify it in deletionManifest.ts (delete / anonymize /
 * retain / unrelated) and — unless it is `unrelated` — handle it in
 * purgeUserData.ts.
 */

function topLevelRuleCollections(): Set<string> {
  const rulesPath = path.join(__dirname, "..", "..", "firestore.rules");
  const rules = readFileSync(rulesPath, "utf8");
  // Top-level matches sit at exactly 4-space indent inside the documents
  // block; deeper indents are subcollections. Collection-group wildcards
  // (match /{path=**}/...) are covered by their parent collection.
  const names = new Set<string>();
  for (const match of rules.matchAll(/^ {4}match \/([A-Za-z0-9_]+)\/\{/gm)) {
    names.add(match[1]);
  }
  return names;
}

test("every top-level rules collection is classified in the manifest", () => {
  const unclassified = [...topLevelRuleCollections()].filter(
    (name) => !(name in COLLECTION_CLASSIFICATIONS),
  );
  assert.deepEqual(
    unclassified,
    [],
    `Unclassified collections: ${unclassified.join(", ")} — add them to ` +
      "COLLECTION_CLASSIFICATIONS in deletionManifest.ts.",
  );
});

test("every manifest entry corresponds to a rules collection", () => {
  const ruleCollections = topLevelRuleCollections();
  const stale = Object.keys(COLLECTION_CLASSIFICATIONS).filter(
    (name) => !ruleCollections.has(name),
  );
  assert.deepEqual(
    stale,
    [],
    `Manifest entries without a rules match block: ${stale.join(", ")}.`,
  );
});

test("purge steps are unique and end with auth_user", () => {
  assert.equal(new Set(PURGE_STEPS).size, PURGE_STEPS.length);
  assert.equal(PURGE_STEPS[PURGE_STEPS.length - 1], "auth_user");
  // owned_tree (users/{uid} recursive delete) must precede auth deletion so
  // the uid stays resolvable while data is being removed.
  assert.ok(
    PURGE_STEPS.indexOf("owned_tree") < PURGE_STEPS.indexOf("auth_user"),
  );
});

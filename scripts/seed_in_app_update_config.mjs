#!/usr/bin/env node
/**
 * Seeds Firestore `app_config/in_app_update` for forced min-build gates.
 *
 * Auth: uses the local Firebase CLI session (`firebase login`) on this machine.
 *
 * Usage (from repo root):
 *   node scripts/seed_in_app_update_config.mjs
 *   node scripts/seed_in_app_update_config.mjs --android=79 --ios=79
 */

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const PROJECT_ID = 'quran-playera-app';
const DOCUMENT_PATH = 'app_config/in_app_update';
const CONFIG_PATH = path.join(
  os.homedir(),
  '.config',
  'configstore',
  'firebase-tools.json',
);

function parseIntFlag(name, fallback) {
  const prefix = `--${name}=`;
  const arg = process.argv.find((value) => value.startsWith(prefix));
  if (!arg) {
    return fallback;
  }
  const parsed = Number.parseInt(arg.slice(prefix.length), 10);
  if (!Number.isFinite(parsed)) {
    throw new Error(`Invalid --${name} value: ${arg}`);
  }
  return parsed;
}

const androidMinBuildNumber = parseIntFlag('android', 0);
const iosMinBuildNumber = parseIntFlag('ios', 0);

function readFirebaseAccessToken() {
  if (!fs.existsSync(CONFIG_PATH)) {
    throw new Error(
      'Firebase CLI config not found. Run `firebase login` first.',
    );
  }

  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  const accessToken = config?.tokens?.access_token;
  if (!accessToken) {
    throw new Error(
      'No Firebase CLI access token found. Run `firebase login` and retry.',
    );
  }
  return accessToken;
}

async function seedForcedUpdateConfig(accessToken) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/databases/(default)/documents/${DOCUMENT_PATH}`;

  const body = {
    fields: {
      android_min_build_number: { integerValue: String(androidMinBuildNumber) },
      ios_min_build_number: { integerValue: String(iosMinBuildNumber) },
      updated_at: { timestampValue: new Date().toISOString() },
    },
  };

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Firestore write failed (${response.status}). ` +
        'Re-run `firebase login`, then retry.\n' +
        text,
    );
  }

  return response.json();
}

async function main() {
  console.log(
    `Seeding ${DOCUMENT_PATH} ` +
      `(android_min_build_number=${androidMinBuildNumber}, ` +
      `ios_min_build_number=${iosMinBuildNumber}) on ${PROJECT_ID}…`,
  );
  const accessToken = readFirebaseAccessToken();
  const document = await seedForcedUpdateConfig(accessToken);
  console.log('Document ready:');
  console.log(`  path: ${document.name}`);
  console.log(`  android_min_build_number: ${androidMinBuildNumber}`);
  console.log(`  ios_min_build_number: ${iosMinBuildNumber}`);
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});

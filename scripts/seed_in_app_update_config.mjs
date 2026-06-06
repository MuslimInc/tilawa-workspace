#!/usr/bin/env node
/**
 * Seeds Firestore `app_config/in_app_update` for optional/forced in-app updates.
 *
 * Auth: uses the local Firebase CLI session (`firebase login`) on this machine.
 *
 * Usage (from repo root):
 *   node scripts/seed_in_app_update_config.mjs
 *   node scripts/seed_in_app_update_config.mjs --force
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

const forceUpdate = process.argv.includes('--force');

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

async function seedInAppUpdateConfig(accessToken) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/databases/(default)/documents/${DOCUMENT_PATH}`;

  const body = {
    fields: {
      force_update: { booleanValue: forceUpdate },
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
    `Seeding ${DOCUMENT_PATH} (force_update=${forceUpdate}) on ${PROJECT_ID}…`,
  );
  const accessToken = readFirebaseAccessToken();
  const document = await seedInAppUpdateConfig(accessToken);
  console.log('Document ready:');
  console.log(`  path: ${document.name}`);
  console.log(`  force_update: ${forceUpdate}`);
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});

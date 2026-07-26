#!/usr/bin/env node
/**
 * Seeds Sadaqah Jariyah founding dedication + config.
 *
 * Auth: Firebase CLI session (`firebase login`).
 *
 * Usage (from repo root):
 *   node scripts/seed_sadaqah_jariyah.mjs
 */

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const PROJECT_ID = 'quran-playera-app';
const FOUNDING_ID = 'ahmed-mohamed-tony';
const SLUG = 'ahmed-mohamed-tony';
const CONFIG_PATH = path.join(
  os.homedir(),
  '.config',
  'configstore',
  'firebase-tools.json',
);

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

function docUrl(docPath) {
  return (
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/databases/(default)/documents/${docPath}`
  );
}

async function patchDoc(accessToken, docPath, fields) {
  const response = await fetch(docUrl(docPath), {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Firestore write failed for ${docPath} (${response.status}).\n${text}`,
    );
  }
  return response.json();
}

function str(value) {
  return { stringValue: value };
}

function bool(value) {
  return { booleanValue: value };
}

function int(value) {
  return { integerValue: String(value) };
}

function ts(date = new Date()) {
  return { timestampValue: date.toISOString() };
}

async function main() {
  const accessToken = readFirebaseAccessToken();
  const now = new Date();

  console.log(`Seeding Sadaqah Jariyah on ${PROJECT_ID}…`);

  await patchDoc(accessToken, `dedications/${FOUNDING_ID}`, {
    displayName: str('Ahmed Mohamed Tony (Abu Hudhaifa)'),
    slug: str(SLUG),
    relation: { nullValue: null },
    relationOther: { nullValue: null },
    note: str('The reason MeMuslim began'),
    photoStoragePath: { nullValue: null },
    status: str('published'),
    isFounding: bool(true),
    isFeatured: bool(false),
    sortOrder: int(0),
    publishedAt: ts(now),
    createdAt: ts(now),
    updatedAt: ts(now),
    createdByAdminId: str('seed'),
    updatedByAdminId: str('seed'),
  });
  console.log(`  dedications/${FOUNDING_ID}`);

  await patchDoc(accessToken, `dedications_slugs/${SLUG}`, {
    dedicationId: str(FOUNDING_ID),
  });
  console.log(`  dedications_slugs/${SLUG}`);

  await patchDoc(accessToken, 'app_config/sadaqah_jariyah', {
    featureTitleAr: str('صدقة جارية'),
    featureTitleEn: str('Sadaqah Jariyah'),
    featureSubtitleAr: str('نيات دعم'),
    featureSubtitleEn: str('Dedications of intention'),
    whatsappE164: str(''),
    messageTemplateAr: str(
      'السلام عليكم،\nأريد دعم أنا مسلم كصدقة جارية.\n\nاسم المتوفى:\nصلة القرابة (اختياري):\nمبلغ الدعم / إثبات:\n\nأنوي هذا الدعم صدقة جارية عن المتوفى، وأسأل الله القبول.',
    ),
    messageTemplateEn: str(
      'Assalamu alaikum,\nI want to support MeMuslim as Sadaqah Jariyah.\n\nDeceased name:\nRelation (optional):\nSupport amount / proof:\n\nI intend this support as an ongoing charity for the deceased, and I ask Allah to accept it.',
    ),
    featureEnabled: bool(true),
  });
  console.log('  app_config/sadaqah_jariyah');
  console.log('Done.');
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});

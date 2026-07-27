#!/usr/bin/env node
/**
 * Seeds the Sadaqah Jariyah founding dedication and config without
 * overwriting existing documents, then backfills missing public projections
 * for existing published dedications.
 *
 * Auth: Firebase CLI session (`firebase login`).
 *
 * Dry run:
 *   node scripts/seed_sadaqah_jariyah.mjs --project <project-id>
 *
 * Apply to a non-production project:
 *   node scripts/seed_sadaqah_jariyah.mjs --project <project-id> --apply
 *
 * Apply to production:
 *   node scripts/seed_sadaqah_jariyah.mjs \
 *     --project quran-playera-app \
 *     --apply \
 *     --confirm-production quran-playera-app
 */

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const PRODUCTION_PROJECT_ID = 'quran-playera-app';
const FOUNDING_ID = 'ahmed-mohamed-tony';
const SLUG = 'ahmed-mohamed-tony';
const CONFIG_PATH = path.join(
  os.homedir(),
  '.config',
  'configstore',
  'firebase-tools.json',
);

function parseArguments(argv) {
  const options = {
    apply: false,
    confirmProduction: null,
    projectId: null,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--apply') {
      options.apply = true;
      continue;
    }
    if (argument === '--project') {
      options.projectId = argv[index + 1] ?? null;
      index += 1;
      continue;
    }
    if (argument === '--confirm-production') {
      options.confirmProduction = argv[index + 1] ?? null;
      index += 1;
      continue;
    }
    throw new Error(`Unknown argument: ${argument}`);
  }

  if (!options.projectId) {
    throw new Error('Missing required --project <project-id>.');
  }
  if (
    options.apply &&
    options.projectId === PRODUCTION_PROJECT_ID &&
    options.confirmProduction !== PRODUCTION_PROJECT_ID
  ) {
    throw new Error(
      `Production writes require --confirm-production ${PRODUCTION_PROJECT_ID}.`,
    );
  }
  return options;
}

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

function docUrl(projectId, docPath) {
  return (
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/${docPath}`
  );
}

function collectionUrl(projectId, collectionId, pageToken) {
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
      `/databases/(default)/documents/${collectionId}`,
  );
  url.searchParams.set('pageSize', '100');
  if (pageToken) {
    url.searchParams.set('pageToken', pageToken);
  }
  return url;
}

async function documentExists(accessToken, projectId, docPath) {
  const response = await fetch(docUrl(projectId, docPath), {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (response.status === 404) {
    return false;
  }
  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Firestore read failed for ${docPath} (${response.status}).\n${text}`,
    );
  }
  return true;
}

async function createDocIfAbsent(accessToken, projectId, docPath, fields) {
  if (await documentExists(accessToken, projectId, docPath)) {
    console.log(`  kept ${docPath}`);
    return;
  }

  const response = await fetch(
    `${docUrl(projectId, docPath)}?currentDocument.exists=false`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ fields }),
    },
  );
  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Firestore write failed for ${docPath} (${response.status}).\n${text}`,
    );
  }
  console.log(`  created ${docPath}`);
}

async function listDocuments(accessToken, projectId, collectionId) {
  const documents = [];
  let pageToken = null;

  do {
    const response = await fetch(
      collectionUrl(projectId, collectionId, pageToken),
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );
    if (!response.ok) {
      const text = await response.text();
      throw new Error(
        `Firestore list failed for ${collectionId} (${response.status}).\n${text}`,
      );
    }
    const page = await response.json();
    documents.push(...(page.documents ?? []));
    pageToken = page.nextPageToken ?? null;
  } while (pageToken);

  return documents;
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

function ts(date) {
  return { timestampValue: date.toISOString() };
}

function seedDocuments(now) {
  const publicDedication = {
    displayName: str('Ahmed Mohamed Tony (Abu Hudhaifa)'),
    photoStoragePath: { nullValue: null },
    status: str('published'),
    isFounding: bool(true),
    isFeatured: bool(false),
    sortOrder: int(0),
    publishedAt: ts(now),
    updatedAt: ts(now),
  };

  return new Map([
    [
      `dedications/${FOUNDING_ID}`,
      {
        ...publicDedication,
        slug: str(SLUG),
        relation: { nullValue: null },
        relationOther: { nullValue: null },
        note: { nullValue: null },
        createdAt: ts(now),
        createdByAdminId: str('seed'),
        updatedByAdminId: str('seed'),
      },
    ],
    [
      `dedications_slugs/${SLUG}`,
      { dedicationId: str(FOUNDING_ID) },
    ],
    [
      'app_config/sadaqah_jariyah',
      {
        featureTitleAr: str('الأسماء المسجلة'),
        featureTitleEn: str('Registered names'),
        featureSubtitleAr: str('صدقة جارية'),
        featureSubtitleEn: str('Sadaqah Jariyah'),
        whatsappE164: str('+201060099009'),
        messageTemplateAr: str(
          'السلام عليكم،\nأريد إضافة اسم إلى قائمة الصدقة الجارية في أنا مسلم.\n\nاسم المتوفى:\nصلة القرابة (اختياري):\nملاحظة قصيرة (اختياري):\n\nيرجى إضافتهم إلى القائمة. أسأل الله القبول.',
        ),
        messageTemplateEn: str(
          'Assalamu alaikum,\nI want to add a person to the Sadaqah Jariyah list in MeMuslim.\n\nDeceased name:\nRelation (optional):\nShort note (optional):\n\nPlease add them to the list. May Allah accept.',
        ),
        featureEnabled: bool(true),
      },
    ],
  ]);
}

function publicProjectionFor(document, now) {
  const fields = document.fields ?? {};
  const displayName = fields.displayName?.stringValue?.trim();
  if (!displayName) {
    throw new Error(
      `Published dedication is missing displayName: ${document.name}`,
    );
  }

  return {
    displayName: str(displayName),
    photoStoragePath:
      fields.photoStoragePath?.stringValue != null
        ? str(fields.photoStoragePath.stringValue)
        : { nullValue: null },
    status: str('published'),
    isFounding: bool(fields.isFounding?.booleanValue === true),
    isFeatured: bool(fields.isFeatured?.booleanValue === true),
    sortOrder: fields.sortOrder ?? int(0),
    publishedAt: fields.publishedAt ?? ts(now),
    updatedAt: fields.updatedAt ?? ts(now),
  };
}

async function backfillPublishedProjections(accessToken, projectId, now) {
  const sourceDocuments = await listDocuments(
    accessToken,
    projectId,
    'dedications',
  );
  for (const document of sourceDocuments) {
    if (document.fields?.status?.stringValue !== 'published') {
      continue;
    }
    const dedicationId = document.name.split('/').pop();
    await createDocIfAbsent(
      accessToken,
      projectId,
      `published_dedications/${dedicationId}`,
      publicProjectionFor(document, now),
    );
  }
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const now = new Date();
  const documents = seedDocuments(now);

  if (!options.apply) {
    console.log(`Dry run for ${options.projectId}; no writes will be made.`);
    for (const docPath of documents.keys()) {
      console.log(`  would create if absent: ${docPath}`);
    }
    console.log('  would backfill missing safe projections for published records');
    console.log('Re-run with --apply to write.');
    return;
  }

  const accessToken = readFirebaseAccessToken();
  console.log(`Seeding Sadaqah Jariyah on ${options.projectId}…`);
  for (const [docPath, fields] of documents) {
    await createDocIfAbsent(
      accessToken,
      options.projectId,
      docPath,
      fields,
    );
  }
  await backfillPublishedProjections(accessToken, options.projectId, now);
  console.log('Done.');
}

main().catch((error) => {
  console.error(error.message ?? error);
  process.exit(1);
});

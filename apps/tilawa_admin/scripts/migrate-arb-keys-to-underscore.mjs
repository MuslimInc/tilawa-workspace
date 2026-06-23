#!/usr/bin/env node
/**
 * ARB message IDs must be [a-zA-Z][a-zA-Z0-9_]* — no dots.
 * Renames keys in l10n/*.arb and updates template / TS translation references.
 */
import { readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

function toValidKey(key) {
  return key.replace(/\./g, '_');
}

function migrateArbFile(path) {
  const arb = JSON.parse(readFileSync(path, 'utf8'));
  const next = {};

  for (const [key, value] of Object.entries(arb)) {
    if (key === '@@locale') {
      next[key] = value;
      continue;
    }

    const baseKey = key.startsWith('@') ? key.slice(1) : key;
    const newBase = toValidKey(baseKey);
    const newKey = key.startsWith('@') ? `@${newBase}` : newBase;
    next[newKey] = value;
  }

  writeFileSync(path, `${JSON.stringify(next, null, 2)}\n`, 'utf8');
  console.log(`Migrated ARB: ${path}`);
}

function migrateSourceFile(path) {
  let text = readFileSync(path, 'utf8');
  const original = text;

  // 'section.key' | t  and  'section.key' | t:{ ... }
  text = text.replace(
    /'([a-zA-Z][a-zA-Z0-9_.]*)'(\s*\|\s*t)/g,
    (_, key, suffix) => `'${toValidKey(key)}'${suffix}`,
  );

  // i18n.t('section.key' ...)
  text = text.replace(
    /i18n\.t\(\s*'([a-zA-Z][a-zA-Z0-9_.]*)'/g,
    (_, key) => `i18n.t('${toValidKey(key)}'`,
  );

  // `status.${status}` in status-label pipe
  text = text.replace(
    /`status\.\$\{status\}`/g,
    '`status_${status}`',
  );

  if (text !== original) {
    writeFileSync(path, text, 'utf8');
    console.log(`Updated: ${path}`);
  }
}

function walk(dir, ext, fn) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) {
      if (name === 'node_modules' || name === 'dist') continue;
      walk(path, ext, fn);
    } else if (path.endsWith(ext)) {
      fn(path);
    }
  }
}

for (const arb of ['l10n/app_en.arb', 'l10n/app_ar.arb']) {
  migrateArbFile(resolve(root, arb));
}

walk(resolve(root, 'src'), '.html', migrateSourceFile);
walk(resolve(root, 'src'), '.ts', migrateSourceFile);

// README example
const readme = resolve(root, 'README.md');
let readmeText = readFileSync(readme, 'utf8');
const readmeOrig = readmeText;
readmeText = readmeText.replace(
  /'([a-zA-Z][a-zA-Z0-9_.]*)'(\s*\|\s*t)/g,
  (_, key, suffix) => `'${toValidKey(key)}'${suffix}`,
);
if (readmeText !== readmeOrig) {
  writeFileSync(readme, readmeText, 'utf8');
  console.log('Updated: README.md');
}

console.log('Done.');

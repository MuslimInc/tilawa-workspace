#!/usr/bin/env node
/**
 * One-time / maintenance helper: convert nested i18n JSON to flat ARB files.
 *
 * Usage:
 *   node scripts/flatten-json-to-arb.mjs \
 *     --input public/i18n/en.json --locale en --output l10n/app_en.arb
 */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

function parseArgs(argv) {
  const args = { input: '', locale: '', output: '' };
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--input') args.input = argv[++i];
    else if (arg === '--locale') args.locale = argv[++i];
    else if (arg === '--output') args.output = argv[++i];
  }
  if (!args.input || !args.locale || !args.output) {
    console.error(
      'Usage: node scripts/flatten-json-to-arb.mjs --input <json> --locale <en|ar> --output <arb>',
    );
    process.exit(1);
  }
  return args;
}

function flatten(obj, prefix = '') {
  const entries = [];
  for (const [key, value] of Object.entries(obj)) {
    const fullKey = prefix ? `${prefix}_${key}` : key;
    if (typeof value === 'string') {
      entries.push([fullKey, value]);
    } else if (value && typeof value === 'object') {
      entries.push(...flatten(value, fullKey));
    }
  }
  return entries;
}

function toArbPlaceholderSyntax(value) {
  return value.replace(/\{\{(\w+)\}\}/g, '{$1}');
}

function extractPlaceholders(value) {
  const names = [...value.matchAll(/\{(\w+)\}/g)].map((m) => m[1]);
  return [...new Set(names)];
}

function placeholderMetadata(names) {
  const placeholders = {};
  for (const name of names) {
    placeholders[name] = { type: 'String', example: name };
  }
  return placeholders;
}

function buildArb(locale, entries) {
  const arb = { '@@locale': locale };

  for (const [key, rawValue] of entries.sort((a, b) => a[0].localeCompare(b[0]))) {
    const value = toArbPlaceholderSyntax(rawValue);
    arb[key] = value;

    const placeholders = extractPlaceholders(value);
    if (placeholders.length > 0) {
      arb[`@${key}`] = {
        description: `Translation for ${key}`,
        placeholders: placeholderMetadata(placeholders),
      };
    }
  }

  return arb;
}

const { input, locale, output } = parseArgs(process.argv);
const inputPath = resolve(root, input);
const outputPath = resolve(root, output);
const json = JSON.parse(readFileSync(inputPath, 'utf8'));
const entries = flatten(json);
const arb = buildArb(locale, entries);

mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, `${JSON.stringify(arb, null, 2)}\n`, 'utf8');
console.log(`Wrote ${entries.length} messages to ${outputPath}`);

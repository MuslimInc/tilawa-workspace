/**
 * Seeds curated MVP market configs (EG, SA, AE) into Firestore via Admin SDK.
 * Bypasses firestore.rules client write denial.
 *
 * Document shape matches FirestoreMarketConfigSeeder / _countryDoc / _cityDoc
 * in apps/tilawa/.../firestore_market_config_repository.dart.
 *
 * Usage (from functions/):
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   # or: gcloud auth application-default login
 *   npx ts-node scripts/seedMarketConfigs.ts              # dry run
 *   npx ts-node scripts/seedMarketConfigs.ts --apply      # write to Firestore
 *
 * Data source: docs/seed/quran_session_market_configs.json
 */
import * as fs from "fs";
import * as path from "path";
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { FIREBASE_PROJECT_ID } from "../src/github";

const APPLY = process.argv.includes("--apply");
const COLLECTION = "quran_session_market_configs";
const CITIES = "cities";

const SEED_JSON = path.resolve(
  __dirname,
  "../../docs/seed/quran_session_market_configs.json"
);

interface CitySeedDoc {
  cityId: string;
  cityName: string;
  cityNameAr: string;
  cityNameEn?: string;
  timezone: string;
  currencyCode: string;
  isEnabled: boolean;
  sortOrder: number;
}

interface CountrySeedDoc {
  countryCode: string;
  countryName: string;
  countryNameAr: string;
  countryNameEn?: string;
  currencyCode: string;
  timezone: string;
  phoneCode?: string;
  flagEmoji?: string;
  minimumStudentAgeYears: number;
  minimumTeacherAgeYears: number;
  defaultCityId: string;
  minSessionPrice: number;
  maxSessionPrice: number;
  platformCommissionPercent: number;
  isEnabled: boolean;
  sortOrder: number;
  __collections__?: {
    cities?: Record<string, CitySeedDoc>;
  };
}

type SeedFile = Record<string, CountrySeedDoc>;

function loadSeedFile(): SeedFile {
  const raw = fs.readFileSync(SEED_JSON, "utf8");
  return JSON.parse(raw) as SeedFile;
}

function countryDoc(country: CountrySeedDoc): Record<string, unknown> {
  const { __collections__: _ignored, ...fields } = country;
  return {
    ...fields,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function cityDoc(city: CitySeedDoc): Record<string, unknown> {
  return {
    ...city,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

async function main(): Promise<void> {
  const seed = loadSeedFile();
  const countryCodes = Object.keys(seed).sort();
  let countryCount = 0;
  let cityCount = 0;

  for (const countryCode of countryCodes) {
    const country = seed[countryCode];
    const cities = country.__collections__?.cities ?? {};
    countryCount++;
    cityCount += Object.keys(cities).length;
  }

  if (!APPLY) {
    for (const countryCode of countryCodes) {
      const cityCountForCountry = Object.keys(
        seed[countryCode].__collections__?.cities ?? {}
      ).length;
      console.log(
        `would write ${countryCode} + ${cityCountForCountry} cities`
      );
    }
    console.log(
      `Dry run. ${countryCount} countries, ${cityCount} cities. Re-run with --apply.`
    );
    return;
  }

  initializeApp({ projectId: FIREBASE_PROJECT_ID });
  const db = getFirestore();
  const batch = db.batch();

  for (const countryCode of countryCodes) {
    const country = seed[countryCode];
    const cities = country.__collections__?.cities ?? {};
    const cityIds = Object.keys(cities);
    console.log(`write ${countryCode} + ${cityIds.length} cities`);

    const countryRef = db.collection(COLLECTION).doc(countryCode);
    batch.set(countryRef, countryDoc(country), { merge: true });

    for (const [cityId, city] of Object.entries(cities)) {
      const cityRef = countryRef.collection(CITIES).doc(cityId);
      batch.set(cityRef, cityDoc(city), { merge: true });
    }
  }

  await batch.commit();
  console.log(
    `Done. Wrote ${countryCount} countries and ${cityCount} cities to ` +
      `${COLLECTION} in project ${FIREBASE_PROJECT_ID}.`
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

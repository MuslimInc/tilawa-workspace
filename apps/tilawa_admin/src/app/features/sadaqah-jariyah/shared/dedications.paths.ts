export const DedicationsPaths = {
  collection: 'dedications',
  slugCollection: 'dedications_slugs',
  configDoc: 'app_config/sadaqah_jariyah',
  photoPath: (dedicationId: string) => `photos/dedications/${dedicationId}.webp`,
  privateOpsDoc: (dedicationId: string) =>
    `dedications/${dedicationId}/private/ops`,
} as const;

/** Locked founding seed id — slug and isFounding are immutable. */
export const FOUNDING_DEDICATION_ID = 'ahmed-mohamed-tony';

import { describe, expect, it } from 'vitest';

import { mapForcedUpdateConfig } from './forced-update-config.mapping';

describe('mapForcedUpdateConfig', () => {
  it('maps ints from firestore fields', () => {
    expect(
      mapForcedUpdateConfig({
        android_min_build_number: 80,
        ios_min_build_number: 81,
      }),
    ).toEqual({ androidMinBuildNumber: 80, iosMinBuildNumber: 81 });
  });

  it('parses numeric strings', () => {
    expect(
      mapForcedUpdateConfig({
        android_min_build_number: '82',
        ios_min_build_number: '83',
      }),
    ).toEqual({ androidMinBuildNumber: 82, iosMinBuildNumber: 83 });
  });

  it('defaults missing or invalid fields to 0', () => {
    expect(mapForcedUpdateConfig(undefined)).toEqual({
      androidMinBuildNumber: 0,
      iosMinBuildNumber: 0,
    });
    expect(
      mapForcedUpdateConfig({
        android_min_build_number: true,
        ios_min_build_number: ['x'],
      }),
    ).toEqual({ androidMinBuildNumber: 0, iosMinBuildNumber: 0 });
  });
});

import { describe, expect, it } from 'vitest';

import {
  isValidSlug,
  noteContainsUrl,
  proposeSlugFromDisplayName,
  suggestSlugVariant,
} from './slug.util';

describe('proposeSlugFromDisplayName', () => {
  it('transliterates Arabic and hyphenates', () => {
    expect(proposeSlugFromDisplayName('محمد أحمد')).toBe('mhmd-ahmd');
  });

  it('strips common honorifics', () => {
    expect(proposeSlugFromDisplayName('Ahmed Mohamed Tony (Abu Hudhaifa)')).toBe(
      'ahmed-mohamed-tony',
    );
  });

  it('returns empty when no ASCII remains', () => {
    expect(proposeSlugFromDisplayName('---')).toBe('');
  });
});

describe('isValidSlug', () => {
  it('accepts lowercase hyphenated slugs', () => {
    expect(isValidSlug('ahmed-mohamed-tony')).toBe(true);
  });

  it('rejects uppercase and invalid characters', () => {
    expect(isValidSlug('Ahmed_Tony')).toBe(false);
    expect(isValidSlug('')).toBe(false);
  });
});

describe('suggestSlugVariant', () => {
  it('appends numeric suffix', () => {
    expect(suggestSlugVariant('ahmed-mohamed-tony', 2)).toBe(
      'ahmed-mohamed-tony-2',
    );
  });
});

describe('noteContainsUrl', () => {
  it('detects http and https', () => {
    expect(noteContainsUrl('visit https://example.com')).toBe(true);
    expect(noteContainsUrl('plain dedication note')).toBe(false);
  });
});

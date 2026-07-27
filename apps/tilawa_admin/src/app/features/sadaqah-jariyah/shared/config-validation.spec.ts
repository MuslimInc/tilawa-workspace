import { describe, expect, it } from 'vitest';

import { isValidWhatsappE164 } from './config-validation';

describe('Sadaqah Jariyah config validation', () => {
  it.each([
    '+201001234567',
    '+12025550123',
    '+447911123456',
  ])('accepts canonical E.164 number %s', (phoneNumber) => {
    expect(isValidWhatsappE164(phoneNumber)).toBe(true);
  });

  it.each([
    '',
    'abc1',
    '+1',
    '+001001234567',
    '+20 100 123 4567',
    '+2010012345678901',
  ])('rejects malformed E.164 number %s', (phoneNumber) => {
    expect(isValidWhatsappE164(phoneNumber)).toBe(false);
  });
});

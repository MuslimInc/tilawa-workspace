import {
  extractAvatarInitials,
  resolveAvatarColors,
  resolveAvatarSeed,
  resolveDetailAvatarDisplayName,
} from './avatar.util';

describe('avatar.util', () => {
  describe('extractAvatarInitials', () => {
    it('uses first character for a single-word display name', () => {
      expect(extractAvatarInitials('Ahmed')).toBe('A');
    });

    it('uses first character of each word for multi-word names', () => {
      expect(extractAvatarInitials('Sheikh Ahmed')).toBe('SA');
    });

    it('skips Arabic honorific prefixes', () => {
      expect(extractAvatarInitials('الشيخ أحمد محمد')).toBe('أم');
    });

    it('falls back to email local-part when display name is empty', () => {
      expect(extractAvatarInitials(null, 'ahmed@example.com')).toBe('a');
    });

    it('returns empty string when both name and email are missing', () => {
      expect(extractAvatarInitials('', null)).toBe('');
    });
  });

  describe('resolveAvatarColors', () => {
    it('returns stable colours for the same seed', () => {
      const first = resolveAvatarColors('Sheikh Ahmed');
      const second = resolveAvatarColors('Sheikh Ahmed');
      expect(first).toEqual(second);
    });
  });

  describe('resolveAvatarSeed', () => {
    it('prefers display name over email', () => {
      expect(resolveAvatarSeed('Ahmed', 'other@example.com')).toBe('Ahmed');
    });

    it('uses email when display name is blank', () => {
      expect(resolveAvatarSeed('  ', 'ahmed@example.com')).toBe('ahmed@example.com');
    });
  });

  describe('resolveDetailAvatarDisplayName', () => {
    it('falls back to account name when public name is placeholder', () => {
      expect(resolveDetailAvatarDisplayName('—', 'Ahmad Ali', 'a@b.com')).toBe(
        'Ahmad Ali',
      );
    });

    it('falls back to email when names are placeholders', () => {
      expect(resolveDetailAvatarDisplayName('—', '—', 'ahmad@example.com')).toBe(
        'ahmad@example.com',
      );
    });
  });
});

const HONORIFIC_SKIP = new Set(['الشيخ', 'أ.', 'د.', 'أ', 'د']);
const DISPLAY_PLACEHOLDER = '—';

export interface AvatarColors {
  readonly bg: string;
  readonly fg: string;
}

/** Scheme-derived palette — mirrors mobile teacher_initials_avatar containers. */
export const AVATAR_COLOR_PALETTE: readonly AvatarColors[] = [
  { bg: 'var(--tilawa-avatar-1-bg)', fg: 'var(--tilawa-avatar-1-fg)' },
  { bg: 'var(--tilawa-avatar-2-bg)', fg: 'var(--tilawa-avatar-2-fg)' },
  { bg: 'var(--tilawa-avatar-3-bg)', fg: 'var(--tilawa-avatar-3-fg)' },
  { bg: 'var(--tilawa-avatar-4-bg)', fg: 'var(--tilawa-avatar-4-fg)' },
  { bg: 'var(--tilawa-avatar-5-bg)', fg: 'var(--tilawa-avatar-5-fg)' },
  { bg: 'var(--tilawa-avatar-6-bg)', fg: 'var(--tilawa-avatar-6-fg)' },
  { bg: 'var(--tilawa-avatar-7-bg)', fg: 'var(--tilawa-avatar-7-fg)' },
];

function firstChar(word: string): string {
  if (!word) {
    return '';
  }
  return [...word][0] ?? '';
}

function initialsFromName(name: string): string {
  if (!name) {
    return '';
  }

  const words = name.split(/\s+/).filter((word) => word.length > 0);
  if (words.length === 0) {
    return '';
  }

  if (words.length === 1) {
    return firstChar(words[0]);
  }

  const meaningful = words.filter((word) => !HONORIFIC_SKIP.has(word));
  if (meaningful.length === 0) {
    return firstChar(words[0]);
  }
  if (meaningful.length === 1) {
    return firstChar(meaningful[0]);
  }

  return `${firstChar(meaningful[0])}${firstChar(meaningful[1])}`;
}

/** Skips em-dash placeholders — falls back through account name and email. */
export function resolveDetailAvatarDisplayName(
  displayName: string | null | undefined,
  accountDisplayName?: string | null,
  email?: string | null,
): string {
  for (const candidate of [displayName, accountDisplayName, email]) {
    const trimmed = candidate?.trim();
    if (trimmed && trimmed !== DISPLAY_PLACEHOLDER) {
      return trimmed;
    }
  }
  return '';
}

/** Derives initials from display name, then email local-part fallback. */
export function extractAvatarInitials(
  displayName: string | null | undefined,
  email?: string | null,
): string {
  const fromName = initialsFromName(displayName?.trim() ?? '');
  if (fromName) {
    return fromName;
  }

  const mail = email?.trim();
  if (!mail) {
    return '';
  }

  const localPart = mail.split('@')[0]?.trim();
  return localPart ? firstChar(localPart) : '';
}

/** Stable colour seed — same person keeps the same avatar background. */
export function resolveAvatarSeed(
  displayName: string | null | undefined,
  email?: string | null,
): string {
  const name = displayName?.trim();
  if (name) {
    return name;
  }
  return email?.trim() ?? '';
}

export function resolveAvatarColors(seed: string): AvatarColors {
  const hash = [...seed].reduce((acc, char) => acc + char.charCodeAt(0), 0);
  return AVATAR_COLOR_PALETTE[hash % AVATAR_COLOR_PALETTE.length];
}

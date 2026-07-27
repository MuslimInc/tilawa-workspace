const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MAX_SLUG_LENGTH = 80;

const HONORIFIC_PATTERN =
  /\b(abu|umm|bin|bint|ibn|al|el|abu\s+hudhaifa)\b|\(abu[^)]*\)|\(أبو[^)]*\)/gi;

const ARABIC_CHAR_MAP: Record<string, string> = {
  ا: 'a',
  أ: 'a',
  إ: 'a',
  آ: 'a',
  ب: 'b',
  ت: 't',
  ث: 'th',
  ج: 'j',
  ح: 'h',
  خ: 'kh',
  د: 'd',
  ذ: 'dh',
  ر: 'r',
  ز: 'z',
  س: 's',
  ش: 'sh',
  ص: 's',
  ض: 'd',
  ط: 't',
  ظ: 'z',
  ع: 'a',
  غ: 'gh',
  ف: 'f',
  ق: 'q',
  ك: 'k',
  ل: 'l',
  م: 'm',
  ن: 'n',
  ه: 'h',
  و: 'w',
  ؤ: 'w',
  ي: 'y',
  ئ: 'y',
  ى: 'a',
  ة: 'h',
  ء: '',
  ' ': ' ',
  '-': '-',
};

function transliterateArabic(input: string): string {
  let output = '';
  for (const char of input.normalize('NFKC')) {
    if (ARABIC_CHAR_MAP[char] !== undefined) {
      output += ARABIC_CHAR_MAP[char];
      continue;
    }
    output += char;
  }
  return output;
}

export function proposeSlugFromDisplayName(displayName: string): string {
  let text = transliterateArabic(displayName.trim());
  text = text.replace(HONORIFIC_PATTERN, ' ');
  text = text.normalize('NFKD').replace(/[\u0300-\u036f]/g, '');
  text = text.toLowerCase();
  text = text.replace(/[^a-z0-9]+/g, '-');
  text = text.replace(/-+/g, '-').replace(/^-|-$/g, '');
  if (text.length > MAX_SLUG_LENGTH) {
    text = text.slice(0, MAX_SLUG_LENGTH).replace(/-$/, '');
  }
  return text;
}

export function isValidSlug(slug: string): boolean {
  const trimmed = slug.trim();
  return (
    trimmed.length >= 1 &&
    trimmed.length <= MAX_SLUG_LENGTH &&
    SLUG_PATTERN.test(trimmed)
  );
}

export function suggestSlugVariant(baseSlug: string, suffix: number): string {
  const candidate = `${baseSlug}-${suffix}`;
  if (candidate.length <= MAX_SLUG_LENGTH) {
    return candidate;
  }
  const trimmedBase = baseSlug.slice(0, Math.max(1, MAX_SLUG_LENGTH - String(suffix).length - 1));
  return `${trimmedBase}-${suffix}`;
}

export function noteContainsUrl(note: string): boolean {
  return /https?:\/\//i.test(note);
}

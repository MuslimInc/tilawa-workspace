export const WHATSAPP_E164_PATTERN = /^\+[1-9]\d{7,14}$/;

export function isValidWhatsappE164(value: string): boolean {
  return WHATSAPP_E164_PATTERN.test(value.trim());
}

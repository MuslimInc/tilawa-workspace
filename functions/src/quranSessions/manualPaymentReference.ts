function grouped(code: string): string {
  return code.match(/.{1,4}/g)?.join("-") ?? code;
}

export function generateManualPaymentReference(bookingId: string): string {
  const normalized = bookingId.replace(/[^a-z0-9]/gi, "").toUpperCase();
  const body =
    normalized.length <= 12
      ? normalized
      : `${normalized.slice(0, 6)}${normalized.slice(-6)}`;
  return `QS-${grouped(body || "UNKNOWN")}`;
}

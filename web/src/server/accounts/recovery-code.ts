/**
 * Recovery codes: 25 Crockford base32 characters (125 random bits), shown as
 * five hyphen-separated groups. Only the SHA-256 hash of the normalized code is
 * stored (adr/0015-anonymous-accounts-with-recovery-codes.md).
 */

const ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
const LENGTH = 25;
const GROUP = 5;

/** Generates a new code in its display form, e.g. `7K3QX-M2D9A-…`. */
export function generateRecoveryCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  let chars = "";
  for (let i = 0; i < LENGTH; i++) {
    let value = 0;
    for (let b = 0; b < 5; b++) {
      const bit = i * 5 + b;
      value = (value << 1) | ((bytes[bit >> 3]! >> (7 - (bit & 7))) & 1);
    }
    chars += ALPHABET[value];
  }
  return formatRecoveryCode(chars);
}

/**
 * Normalizes user input: case-insensitive, ignores spaces and hyphens, and maps
 * O→0 and I/L→1. Returns null when the result is not a 25-character code.
 */
export function normalizeRecoveryCode(input: string): string | null {
  const normalized = input
    .toUpperCase()
    .replace(/[\s-]/g, "")
    .replace(/O/g, "0")
    .replace(/[IL]/g, "1");
  if (normalized.length !== LENGTH) return null;
  for (const char of normalized) {
    if (!ALPHABET.includes(char)) return null;
  }
  return normalized;
}

export function formatRecoveryCode(normalized: string): string {
  const groups: string[] = [];
  for (let i = 0; i < normalized.length; i += GROUP)
    groups.push(normalized.slice(i, i + GROUP));
  return groups.join("-");
}

/** Lowercase hex SHA-256 of a normalized code. */
export async function hashRecoveryCode(normalized: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(normalized),
  );
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

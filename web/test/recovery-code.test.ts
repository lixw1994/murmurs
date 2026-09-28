import { describe, expect, it } from "vitest";

import {
  formatRecoveryCode,
  generateRecoveryCode,
  hashRecoveryCode,
  normalizeRecoveryCode,
} from "~/server/accounts/recovery-code";

const FORMAT = /^[0-9A-HJKMNP-TV-Z]{5}(-[0-9A-HJKMNP-TV-Z]{5}){4}$/;

describe("recovery codes", () => {
  it("generates codes in the display format", () => {
    for (let i = 0; i < 200; i++) expect(generateRecoveryCode()).toMatch(FORMAT);
  });

  it("generates distinct codes", () => {
    const codes = new Set(Array.from({ length: 1000 }, generateRecoveryCode));
    expect(codes.size).toBe(1000);
  });

  it("normalizes case, separators, and ambiguous letters", () => {
    const code = generateRecoveryCode();
    const canonical = code.replace(/-/g, "");
    expect(normalizeRecoveryCode(code.toLowerCase().replace(/-/g, " "))).toBe(canonical);
    expect(normalizeRecoveryCode("oiL00-11111-22222-33333-44444")).toBe(
      "0110011111222223333344444",
    );
  });

  it("rejects input that is not a 25-character code", () => {
    expect(normalizeRecoveryCode("")).toBeNull();
    expect(normalizeRecoveryCode("ABCDE-FGHJK")).toBeNull();
    expect(normalizeRecoveryCode("UUUUU-UUUUU-UUUUU-UUUUU-UUUUU")).toBeNull();
  });

  it("formats and hashes deterministically without exposing the code", async () => {
    const normalized = normalizeRecoveryCode(generateRecoveryCode())!;
    expect(formatRecoveryCode(normalized)).toMatch(FORMAT);
    const hash = await hashRecoveryCode(normalized);
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
    expect(hash).toBe(await hashRecoveryCode(normalized));
    expect(hash).not.toContain(normalized.toLowerCase());
  });
});

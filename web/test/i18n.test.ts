import { describe, expect, it } from "vitest";

import i18n from "~/i18n";

// localization-pipeline spec: generated %{n} placeholders interpolate on the
// web, and literal {{…}} text (prompt templates) is shown unchanged.
describe("web i18n interpolation", () => {
  it("substitutes %{n} placeholders", () => {
    i18n.addResource(
      "en",
      "translation",
      "test.formatted",
      "Summary for %{0} (%{1} memos)",
    );
    expect(i18n.t("test.formatted", { lng: "en", 0: "Monday", 1: 3 })).toBe(
      "Summary for Monday (3 memos)",
    );
  });

  it("keeps literal double braces", () => {
    i18n.addResource("en", "translation", "test.literal", "Diary for {{date}}");
    expect(i18n.t("test.literal", { lng: "en", date: "ignored" })).toBe(
      "Diary for {{date}}",
    );
  });

  it("serves generated strings in both languages", () => {
    expect(i18n.t("web.landing.tagline", { lng: "en" })).toBe("Your voice journal");
    expect(i18n.t("web.landing.tagline", { lng: "zh-Hans" })).toBe("你的语音日记");
  });
});

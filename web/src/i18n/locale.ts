// Pure locale constants/helpers — safe to import from anywhere (no server-only deps).

// Language tags match the columns of l10n/Localizable.csv.
export const LOCALES = ["en", "zh-Hans"] as const;
export type Locale = (typeof LOCALES)[number];

export const DEFAULT_LOCALE: Locale = "en";

/** Cookie that holds the chosen language so the server can read it during SSR. */
export const LOCALE_COOKIE = "language";

export function normalizeLocale(value: string | null | undefined): Locale {
  return LOCALES.includes(value as Locale) ? (value as Locale) : DEFAULT_LOCALE;
}

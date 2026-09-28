import i18n from "i18next";
import { initReactI18next } from "react-i18next";

import { DEFAULT_LOCALE, LOCALE_COOKIE } from "./locale";
// Generated from l10n/Localizable.csv by `rake l10n` — do not edit by hand.
import en from "./locales/en.json";
import zhHans from "./locales/zh-Hans.json";

i18n.use(initReactI18next).init({
  resources: {
    en: { translation: en },
    "zh-Hans": { translation: zhHans },
  },
  // The per-request language is applied in __root's beforeLoad via getLocale();
  // this is just the module-load default so server and client start identically.
  lng: DEFAULT_LOCALE,
  fallbackLng: DEFAULT_LOCALE,
  interpolation: {
    escapeValue: false,
    // The generator turns Apple placeholders (%@, %d) into %{0}, %{1}, … so that
    // literal "{{…}}" text (e.g. prompt templates) is never interpolated.
    prefix: "%{",
    suffix: "}",
  },
});

// Persist the chosen language to a cookie so the server can render the correct
// language on the next request (read back via getLocale()).
i18n.on("languageChanged", (lng) => {
  if (typeof document !== "undefined") {
    document.cookie = `${LOCALE_COOKIE}=${lng}; path=/; max-age=31536000; samesite=lax`;
  }
});

export default i18n;

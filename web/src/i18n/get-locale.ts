import { createIsomorphicFn } from "@tanstack/react-start";
import { getCookie } from "@tanstack/react-start/server";

import { LOCALE_COOKIE, normalizeLocale } from "./locale";

/**
 * Resolve the active locale from the `language` cookie, isomorphically:
 * - server: from the request cookie, so SSR renders in the correct language
 * - client: from document.cookie, so the first client render matches SSR
 *   (avoiding a hydration mismatch / language flash)
 *
 * The .server() implementation — and its server-only getCookie import — is
 * stripped from the client bundle by createIsomorphicFn.
 */
export const getLocale = createIsomorphicFn()
  .server(() => normalizeLocale(getCookie(LOCALE_COOKIE)))
  .client(() => {
    const match = document.cookie.match(/(?:^|;\s*)language=([^;]+)/);
    return normalizeLocale(match ? decodeURIComponent(match[1]) : null);
  });

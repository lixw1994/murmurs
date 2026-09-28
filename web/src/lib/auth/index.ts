import { betterAuth } from "better-auth";
import { DB, drizzleAdapter } from "better-auth/adapters/drizzle";
import { tanstackStartCookies } from "better-auth/tanstack-start";

import { getAuthEnv } from "~/server-env";

/**
 * Better Auth instance.
 *
 * Sign-in is intentionally disabled: no social providers and no email/password,
 * so sign-up and sign-in requests fail. The sign-in change adds providers here
 * (see adr/0011-authentication-apple-google-email-otp.md).
 */
export function getAuth(db: DB) {
  const env = getAuthEnv();

  return betterAuth({
    baseURL: env.BETTER_AUTH_URL,
    secret: env.BETTER_AUTH_SECRET,
    database: drizzleAdapter(db, {
      provider: "sqlite",
    }),

    plugins: [tanstackStartCookies()],

    session: {
      cookieCache: {
        enabled: true,
        maxAge: 5 * 60,
      },
    },

    emailAndPassword: {
      enabled: false,
    },
  });
}

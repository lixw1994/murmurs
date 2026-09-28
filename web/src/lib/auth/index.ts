import { betterAuth } from "better-auth";
import { DB, drizzleAdapter } from "better-auth/adapters/drizzle";
import { anonymous, bearer } from "better-auth/plugins";

import { type AuthBindings, getAuthEnv } from "~/server-env";

const YEAR_IN_SECONDS = 60 * 60 * 24 * 365;

/**
 * Better Auth instance: the user and session store.
 *
 * Accounts are anonymous and are created and restored only through /api/v1
 * (adr/0015-anonymous-accounts-with-recovery-codes.md), so Better Auth's own
 * sign-up and sign-in entry points are disabled. `bearer` lets native clients
 * authenticate with `Authorization: Bearer <session token>`.
 */
export function getAuth(db: DB, env: AuthBindings) {
  const authEnv = getAuthEnv(env);

  return betterAuth({
    baseURL: authEnv.BETTER_AUTH_URL,
    secret: authEnv.BETTER_AUTH_SECRET,
    database: drizzleAdapter(db, {
      provider: "sqlite",
    }),

    plugins: [anonymous({ emailDomainName: "anonymous.murmurs.denkit.app" }), bearer()],

    disabledPaths: [
      "/sign-in/anonymous",
      "/sign-up/email",
      "/sign-in/email",
      "/sign-in/social",
    ],

    session: {
      // Anonymous users can only sign in again with their recovery code, so
      // sessions are long-lived and extended on use (updateAge default: 1 day).
      expiresIn: YEAR_IN_SECONDS,
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

export type Auth = ReturnType<typeof getAuth>;

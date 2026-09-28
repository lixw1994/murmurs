import type { Context, MiddlewareHandler } from "hono";

import { type Auth, getAuth } from "~/lib/auth";
import { getDb } from "~/lib/db";

import { errorBody } from "./errors";

type SessionResult = NonNullable<Awaited<ReturnType<Auth["api"]["getSession"]>>>;

export type ApiEnv = {
  Bindings: Env;
  Variables: {
    db?: ReturnType<typeof getDb>;
    auth?: Auth;
    session: SessionResult;
  };
};

/** Per-request database handle, created on first use. */
export function db(c: Context<ApiEnv>) {
  let value = c.get("db");
  if (!value) {
    value = getDb(c.env);
    c.set("db", value);
  }
  return value;
}

/** Per-request Better Auth instance, created on first use. */
export function auth(c: Context<ApiEnv>) {
  let value = c.get("auth");
  if (!value) {
    value = getAuth(db(c), c.env);
    c.set("auth", value);
  }
  return value;
}

/** Requires `Authorization: Bearer <token>`; stores `{ user, session }` in `session`. */
export const requireSession: MiddlewareHandler<ApiEnv> = async (c, next) => {
  const result = c.req.header("authorization")
    ? await auth(c).api.getSession({ headers: c.req.raw.headers })
    : null;
  if (!result) {
    return c.json(errorBody("unauthorized", "A valid session token is required"), 401);
  }
  c.set("session", result);
  await next();
};

/** Client IP for rate limiting; a shared key when absent (local development, tests). */
export function clientKey(c: Context<ApiEnv>) {
  return c.req.header("cf-connecting-ip") ?? "local";
}

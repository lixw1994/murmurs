import handler from "@tanstack/react-start/server-entry";

import { getAuth } from "./lib/auth";
import { getDb } from "./lib/db";

export type RequestContext = {
  env: Env;
  executionCtx: ExecutionContext;
  db: ReturnType<typeof getDb>;
  /** Created on first call so requests that never touch auth do not need its secrets. */
  getAuth: () => ReturnType<typeof getAuth>;
  waitUntil: (promise: Promise<unknown>) => void;
  passThroughOnException: () => void;
};

declare module "@tanstack/react-start" {
  interface Register {
    server: {
      requestContext: RequestContext;
    };
  }
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext) {
    const db = getDb(env);
    let auth: ReturnType<typeof getAuth> | undefined;
    return handler.fetch(request, {
      context: {
        env,
        executionCtx: ctx,
        db,
        getAuth: () => (auth ??= getAuth(db, env)),
        waitUntil: ctx.waitUntil.bind(ctx),
        passThroughOnException: ctx.passThroughOnException.bind(ctx),
      },
    });
  },
};

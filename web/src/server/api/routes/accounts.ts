import { createRoute, z } from "@hono/zod-openapi";
import { eq } from "drizzle-orm";

import { recoveryCode } from "~/lib/db/schema";
import {
  generateRecoveryCode,
  hashRecoveryCode,
  normalizeRecoveryCode,
} from "~/server/accounts/recovery-code";

import type { ApiApp } from "../app";
import { auth, clientKey, db, requireSession } from "../context";
import {
  ErrorResponse,
  errorBody,
  errorResponses,
  rateLimitedResponse,
  unauthorizedResponse,
} from "../errors";

// Accounts are anonymous and recoverable with a recovery code (adr/0015).

const RecoveryCodeString = z.string().openapi({
  description:
    "Recovery code: 25 Crockford base32 characters in five hyphen-separated groups. Returned only when created or rotated.",
  example: "7K3QX-M2D9A-P4TVN-8HWRC-Z6E1B",
});

const AccountCredentials = z
  .object({
    userId: z.string(),
    token: z
      .string()
      .openapi({ description: "Session token for `Authorization: Bearer`" }),
    recoveryCode: RecoveryCodeString,
  })
  .openapi("AccountCredentials");

const SessionCredentials = z
  .object({
    userId: z.string(),
    token: z
      .string()
      .openapi({ description: "Session token for `Authorization: Bearer`" }),
  })
  .openapi("SessionCredentials");

const RecoverRequest = z.object({ recoveryCode: z.string() }).openapi("RecoverRequest");

const Account = z
  .object({
    userId: z.string(),
    isAnonymous: z.boolean(),
    createdAt: z.string().openapi({ format: "date-time" }),
    recoveryCodeCreatedAt: z.string().openapi({ format: "date-time" }).nullable(),
  })
  .openapi("Account");

const RecoveryCodeResponse = z
  .object({ recoveryCode: RecoveryCodeString })
  .openapi("RecoveryCode");

const bearer = [{ bearerAuth: [] }];
const json = <T extends z.ZodType>(schema: T, description: string) => ({
  description,
  content: { "application/json": { schema } },
});

async function storeRecoveryCode(database: ReturnType<typeof db>, userId: string) {
  const code = generateRecoveryCode();
  const codeHash = await hashRecoveryCode(normalizeRecoveryCode(code)!);
  const createdAt = new Date();
  await database
    .insert(recoveryCode)
    .values({ userId, codeHash, createdAt })
    .onConflictDoUpdate({ target: recoveryCode.userId, set: { codeHash, createdAt } });
  return code;
}

const createAccount = createRoute({
  method: "post",
  path: "/accounts",
  operationId: "createAccount",
  summary: "Create an anonymous account",
  responses: {
    201: json(AccountCredentials, "The account, a session token, and its recovery code"),
    ...rateLimitedResponse,
    ...errorResponses,
  },
});

const recover = createRoute({
  method: "post",
  path: "/sessions/recover",
  operationId: "recoverSession",
  summary: "Start a new session for the account that owns a recovery code",
  request: {
    body: { content: { "application/json": { schema: RecoverRequest } }, required: true },
  },
  responses: {
    200: json(SessionCredentials, "A new session for the account"),
    401: json(
      ErrorResponse,
      "Unknown or malformed recovery code (`invalid_recovery_code`)",
    ),
    ...rateLimitedResponse,
    ...errorResponses,
  },
});

const getMe = createRoute({
  method: "get",
  path: "/me",
  operationId: "getMe",
  summary: "The authenticated account",
  security: bearer,
  middleware: [requireSession] as const,
  responses: {
    200: json(Account, "The account"),
    ...unauthorizedResponse,
    ...errorResponses,
  },
});

const rotateCode = createRoute({
  method: "post",
  path: "/me/recovery-code",
  operationId: "rotateRecoveryCode",
  summary: "Replace the recovery code; the previous code stops working",
  security: bearer,
  middleware: [requireSession] as const,
  responses: {
    200: json(RecoveryCodeResponse, "The new recovery code"),
    ...unauthorizedResponse,
    ...errorResponses,
  },
});

const signOut = createRoute({
  method: "delete",
  path: "/sessions/current",
  operationId: "signOut",
  summary: "Revoke the session used for this request",
  security: bearer,
  middleware: [requireSession] as const,
  responses: {
    204: { description: "Signed out" },
    ...unauthorizedResponse,
    ...errorResponses,
  },
});

const deleteMe = createRoute({
  method: "delete",
  path: "/me",
  operationId: "deleteAccount",
  summary: "Permanently delete the account, its sessions, and its recovery code",
  security: bearer,
  middleware: [requireSession] as const,
  responses: {
    204: { description: "Deleted" },
    ...unauthorizedResponse,
    ...errorResponses,
  },
});

export function registerAccounts(app: ApiApp) {
  app.openAPIRegistry.registerComponent("securitySchemes", "bearerAuth", {
    type: "http",
    scheme: "bearer",
  });

  app.openapi(createAccount, async (c) => {
    const { success } = await c.env.ACCOUNT_CREATE_LIMITER.limit({ key: clientKey(c) });
    if (!success) return c.json(errorBody("rate_limited", "Too many requests"), 429);

    const { internalAdapter } = await auth(c).$context;
    const now = new Date();
    const user = await internalAdapter.createUser({
      name: "Anonymous",
      email: `temp-${crypto.randomUUID()}@anonymous.murmurs.denkit.app`,
      emailVerified: false,
      isAnonymous: true,
      createdAt: now,
      updatedAt: now,
    });
    const session = await internalAdapter.createSession(user.id);
    const code = await storeRecoveryCode(db(c), user.id);
    return c.json({ userId: user.id, token: session.token, recoveryCode: code }, 201);
  });

  app.openapi(recover, async (c) => {
    const { success } = await c.env.ACCOUNT_RECOVER_LIMITER.limit({ key: clientKey(c) });
    if (!success) return c.json(errorBody("rate_limited", "Too many requests"), 429);

    const invalid = () =>
      c.json(errorBody("invalid_recovery_code", "The recovery code is not valid"), 401);
    const normalized = normalizeRecoveryCode(c.req.valid("json").recoveryCode);
    if (!normalized) return invalid();
    const [row] = await db(c)
      .select({ userId: recoveryCode.userId })
      .from(recoveryCode)
      .where(eq(recoveryCode.codeHash, await hashRecoveryCode(normalized)))
      .limit(1);
    if (!row) return invalid();

    const { internalAdapter } = await auth(c).$context;
    const session = await internalAdapter.createSession(row.userId);
    return c.json({ userId: row.userId, token: session.token }, 200);
  });

  app.openapi(getMe, async (c) => {
    const { user } = c.get("session");
    const [code] = await db(c)
      .select({ createdAt: recoveryCode.createdAt })
      .from(recoveryCode)
      .where(eq(recoveryCode.userId, user.id))
      .limit(1);
    return c.json(
      {
        userId: user.id,
        isAnonymous: Boolean((user as { isAnonymous?: boolean | null }).isAnonymous),
        createdAt: new Date(user.createdAt).toISOString(),
        recoveryCodeCreatedAt: code ? code.createdAt.toISOString() : null,
      },
      200,
    );
  });

  app.openapi(rotateCode, async (c) => {
    const code = await storeRecoveryCode(db(c), c.get("session").user.id);
    return c.json({ recoveryCode: code }, 200);
  });

  app.openapi(signOut, async (c) => {
    const { internalAdapter } = await auth(c).$context;
    await internalAdapter.deleteSession(c.get("session").session.token);
    return c.body(null, 204);
  });

  app.openapi(deleteMe, async (c) => {
    const userId = c.get("session").user.id;
    const { internalAdapter } = await auth(c).$context;
    await internalAdapter.deleteSessions(userId);
    await db(c).delete(recoveryCode).where(eq(recoveryCode.userId, userId));
    await internalAdapter.deleteUser(userId);
    return c.body(null, 204);
  });
}

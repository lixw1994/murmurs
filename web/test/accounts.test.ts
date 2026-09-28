import { env } from "cloudflare:test";
import { exports } from "cloudflare:workers";
import { describe, expect, it } from "vitest";

import { ErrorResponse } from "~/server/api/errors";

const CODE_FORMAT = /^[0-9A-HJKMNP-TV-Z]{5}(-[0-9A-HJKMNP-TV-Z]{5}){4}$/;

// Each test uses its own client IP so the per-IP rate limits do not interfere.
const randomIp = () =>
  `10.${[0, 0, 0].map(() => Math.floor(Math.random() * 255)).join(".")}`;

function client(ip = randomIp()) {
  const call = (
    method: string,
    path: string,
    opts: { token?: string; body?: unknown } = {},
  ) =>
    exports.default.fetch(
      new Request(`http://localhost/api/v1${path}`, {
        method,
        headers: {
          "cf-connecting-ip": ip,
          ...(opts.token ? { authorization: `Bearer ${opts.token}` } : {}),
          ...(opts.body !== undefined ? { "content-type": "application/json" } : {}),
        },
        body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
      }),
    );
  return {
    call,
    async createAccount() {
      const res = await call("POST", "/accounts");
      expect(res.status).toBe(201);
      return (await res.json()) as {
        userId: string;
        token: string;
        recoveryCode: string;
      };
    },
    recover: (recoveryCode: string) =>
      call("POST", "/sessions/recover", { body: { recoveryCode } }),
    me: (token?: string) => call("GET", "/me", { token }),
  };
}

async function expectError(res: Response, status: number, code: string) {
  expect(res.status).toBe(status);
  expect(ErrorResponse.parse(await res.json()).error.code).toBe(code);
}

describe("POST /api/v1/accounts", () => {
  it("creates an anonymous account with a token and a recovery code", async () => {
    const api = client();
    const account = await api.createAccount();
    expect(account.recoveryCode).toMatch(CODE_FORMAT);

    const res = await api.me(account.token);
    expect(res.status).toBe(200);
    const me = (await res.json()) as Record<string, unknown>;
    expect(me.userId).toBe(account.userId);
    expect(me.isAnonymous).toBe(true);
    expect(typeof me.createdAt).toBe("string");
    expect(typeof me.recoveryCodeCreatedAt).toBe("string");
    expect(JSON.stringify(me)).not.toContain(account.recoveryCode);
  });

  it("stores only a hash of the recovery code", async () => {
    const account = await client().createAccount();
    const row = await env.DB.prepare("select * from recovery_code where user_id = ?")
      .bind(account.userId)
      .first<Record<string, unknown>>();
    const stored = JSON.stringify(row);
    expect(row?.code_hash).toMatch(/^[0-9a-f]{64}$/);
    expect(stored).not.toContain(account.recoveryCode);
    expect(stored).not.toContain(account.recoveryCode.replace(/-/g, ""));
  });

  it("issues a session that lasts about a year", async () => {
    const account = await client().createAccount();
    const row = await env.DB.prepare("select expires_at from session where token = ?")
      .bind(account.token)
      .first<{ expires_at: number }>();
    const expiresAtMs = row!.expires_at < 1e12 ? row!.expires_at * 1000 : row!.expires_at;
    expect(expiresAtMs - Date.now()).toBeGreaterThan(364 * 24 * 60 * 60 * 1000);
  });

  it("rate-limits account creation per client", async () => {
    const api = client("192.0.2.10");
    const statuses: number[] = [];
    for (let i = 0; i < 12; i++)
      statuses.push((await api.call("POST", "/accounts")).status);
    expect(statuses.filter((s) => s === 201).length).toBeLessThanOrEqual(10);
    const limited = await api.call("POST", "/accounts");
    await expectError(limited, 429, "rate_limited");
  });
});

describe("bearer authentication", () => {
  it("rejects a missing token", async () => {
    await expectError(await client().me(), 401, "unauthorized");
  });

  it("rejects an unknown token", async () => {
    await expectError(await client().me("not-a-real-token"), 401, "unauthorized");
  });
});

describe("POST /api/v1/sessions/recover", () => {
  it("starts a new session and keeps existing ones", async () => {
    const api = client();
    const account = await api.createAccount();
    const res = await api.recover(account.recoveryCode);
    expect(res.status).toBe(200);
    const recovered = (await res.json()) as { userId: string; token: string };
    expect(recovered.userId).toBe(account.userId);
    expect(recovered.token).not.toBe(account.token);
    expect((await api.me(recovered.token)).status).toBe(200);
    expect((await api.me(account.token)).status).toBe(200);
  });

  it("accepts lowercase codes without hyphens", async () => {
    const api = client();
    const account = await api.createAccount();
    const res = await api.recover(account.recoveryCode.toLowerCase().replace(/-/g, ""));
    expect(res.status).toBe(200);
  });

  it("rejects unknown and malformed codes the same way", async () => {
    const api = client();
    await expectError(
      await api.recover("00000-00000-00000-00000-00000"),
      401,
      "invalid_recovery_code",
    );
    await expectError(await api.recover("nonsense"), 401, "invalid_recovery_code");
  });

  it("rate-limits recovery attempts per client", async () => {
    const api = client("192.0.2.20");
    for (let i = 0; i < 5; i++) await api.recover("00000-00000-00000-00000-00000");
    await expectError(
      await api.recover("00000-00000-00000-00000-00000"),
      429,
      "rate_limited",
    );
  });
});

describe("account management", () => {
  it("rotates the recovery code and invalidates the previous one", async () => {
    const api = client();
    const account = await api.createAccount();
    const res = await api.call("POST", "/me/recovery-code", { token: account.token });
    expect(res.status).toBe(200);
    const { recoveryCode } = (await res.json()) as { recoveryCode: string };
    expect(recoveryCode).toMatch(CODE_FORMAT);
    expect(recoveryCode).not.toBe(account.recoveryCode);

    await expectError(
      await api.recover(account.recoveryCode),
      401,
      "invalid_recovery_code",
    );
    expect((await api.recover(recoveryCode)).status).toBe(200);
    expect((await api.me(account.token)).status).toBe(200);
  });

  it("signs out only the current session", async () => {
    const api = client();
    const account = await api.createAccount();
    const second = (await (await api.recover(account.recoveryCode)).json()) as {
      token: string;
    };

    const res = await api.call("DELETE", "/sessions/current", { token: account.token });
    expect(res.status).toBe(204);
    await expectError(await api.me(account.token), 401, "unauthorized");
    expect((await api.me(second.token)).status).toBe(200);
  });

  it("deletes the account, its sessions, and its recovery code", async () => {
    const api = client();
    const account = await api.createAccount();
    const second = (await (await api.recover(account.recoveryCode)).json()) as {
      token: string;
    };

    const res = await api.call("DELETE", "/me", { token: account.token });
    expect(res.status).toBe(204);
    await expectError(await api.me(account.token), 401, "unauthorized");
    await expectError(await api.me(second.token), 401, "unauthorized");
    await expectError(
      await api.recover(account.recoveryCode),
      401,
      "invalid_recovery_code",
    );
    const users = await env.DB.prepare("select count(*) as n from user where id = ?")
      .bind(account.userId)
      .first<{ n: number }>();
    expect(users?.n).toBe(0);
  });
});

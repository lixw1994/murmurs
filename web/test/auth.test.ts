import { env } from "cloudflare:test";
import { describe, expect, it } from "vitest";

import { getAuth } from "~/lib/auth";
import { getDb } from "~/lib/db";

// Accounts are created only through /api/v1 (adr/0015); Better Auth's own
// sign-up and sign-in entry points are closed.
describe("closed Better Auth entry points", () => {
  const auth = () => getAuth(getDb(env), env);
  const post = (path: string, body: unknown) =>
    auth().handler(
      new Request(`http://localhost/api/auth${path}`, {
        method: "POST",
        headers: { "content-type": "application/json", origin: "http://localhost" },
        body: JSON.stringify(body),
      }),
    );
  const userCount = async () =>
    (await env.DB.prepare("select count(*) as n from user").first<{ n: number }>())?.n;

  it("rejects email sign-up and creates no user", async () => {
    const res = await post("/sign-up/email", {
      email: "someone@example.com",
      password: "a-long-password-123",
      name: "Someone",
    });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(await userCount()).toBe(0);
  });

  it("rejects email sign-in", async () => {
    const res = await post("/sign-in/email", {
      email: "someone@example.com",
      password: "a-long-password-123",
    });
    expect(res.status).toBeGreaterThanOrEqual(400);
  });

  it("rejects anonymous sign-in and creates no user", async () => {
    const res = await post("/sign-in/anonymous", {});
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(await userCount()).toBe(0);
  });

  it("rejects social sign-in", async () => {
    const res = await post("/sign-in/social", { provider: "google" });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(await userCount()).toBe(0);
  });
});

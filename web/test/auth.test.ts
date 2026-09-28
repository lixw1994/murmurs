import { env } from "cloudflare:test";
import { describe, expect, it } from "vitest";

import { getAuth } from "~/lib/auth";
import { getDb } from "~/lib/db";

// Sign-in is disabled until the sign-in change adds providers (adr/0011).
describe("dormant auth", () => {
  const auth = () => getAuth(getDb(env));
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

  it("rejects social sign-in because no provider is configured", async () => {
    const res = await post("/sign-in/social", { provider: "google" });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(await userCount()).toBe(0);
  });
});

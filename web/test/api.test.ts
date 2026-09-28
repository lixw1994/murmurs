import { z } from "@hono/zod-openapi";
import { env } from "cloudflare:test";
import { exports } from "cloudflare:workers";
import { describe, expect, it } from "vitest";

import { createApiApp } from "~/server/api/app";
import { ErrorResponse } from "~/server/api/errors";

const api = (path: string, init?: RequestInit) =>
  exports.default.fetch(new Request(`http://localhost${path}`, init));

describe("GET /api/v1/health", () => {
  it("reports ok with version and environment", async () => {
    const res = await api("/api/v1/health");
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("application/json");
    expect(await res.json()).toEqual({
      status: "ok",
      version: __APP_VERSION__,
      environment: "development",
    });
  });
});

describe("error envelope", () => {
  it("returns 404 JSON for unknown /api/v1 paths", async () => {
    const res = await api("/api/v1/does-not-exist");
    expect(res.status).toBe(404);
    const body = ErrorResponse.parse(await res.json());
    expect(body.error.code).toBe("not_found");
  });

  it("returns 400 invalid_request with details when a request violates its schema", async () => {
    const app = createApiApp((a) => {
      a.openapi(
        {
          method: "get",
          path: "/echo",
          request: { query: z.object({ n: z.coerce.number().int() }) },
          responses: { 200: { description: "ok" } },
        },
        (c) => c.json({ n: c.req.valid("query").n }, 200),
      );
    });
    const res = await app.request("/api/v1/echo?n=abc", {}, env);
    expect(res.status).toBe(400);
    const body = ErrorResponse.parse(await res.json());
    expect(body.error.code).toBe("invalid_request");
    expect(body.error.details).toHaveProperty("issues");
  });

  it("returns 500 internal_error without leaking internals", async () => {
    const app = createApiApp((a) => {
      a.get("/boom", () => {
        throw new Error("secret database password in stack");
      });
    });
    const res = await app.request("/api/v1/boom", {}, env);
    expect(res.status).toBe(500);
    const text = await res.text();
    expect(text).not.toContain("secret database password");
    expect(ErrorResponse.parse(JSON.parse(text)).error.code).toBe("internal_error");
  });
});

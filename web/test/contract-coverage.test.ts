import { describe, expect, it } from "vitest";

import { type ApiApp, apiApp, createApiApp } from "~/server/api/app";

/** Routes registered on the app that are missing from its OpenAPI document. */
function undocumentedRoutes(app: ApiApp): string[] {
  const doc = app.getOpenAPIDocument({
    openapi: "3.0.3",
    info: { title: "t", version: "v1" },
  });
  const documented = new Set(
    Object.entries(doc.paths ?? {}).flatMap(([path, ops]) =>
      Object.keys(ops ?? {}).map((method) => `${method.toUpperCase()} ${path}`),
    ),
  );
  return app.routes
    .filter((r) => r.method !== "ALL")
    .map((r) => `${r.method} ${r.path.replace(/:(\w+)/g, "{$1}")}`)
    .filter((route) => !documented.has(route));
}

// api-contract spec: every /api/v1 endpoint must be defined with schemas so it
// appears in contract/openapi.json.
describe("contract coverage", () => {
  it("documents every registered /api/v1 route", () => {
    expect(undocumentedRoutes(apiApp)).toEqual([]);
  });

  it("detects a route added without schemas", () => {
    const app = createApiApp((a) => {
      a.get("/plain", (c) => c.json({}));
    });
    expect(undocumentedRoutes(app)).toEqual(["GET /api/v1/plain"]);
  });
});

import { createRoute, z } from "@hono/zod-openapi";

import type { ApiApp } from "../app";
import { errorResponses } from "../errors";

export const HealthResponse = z
  .object({
    status: z.literal("ok"),
    version: z.string().openapi({ example: "0.1.0" }),
    environment: z.enum(["development", "staging", "production"]),
  })
  .openapi("HealthResponse");

const route = createRoute({
  method: "get",
  path: "/health",
  operationId: "getHealth",
  summary: "Report that the API is up, with its version and environment",
  responses: {
    200: {
      description: "The API is up",
      content: { "application/json": { schema: HealthResponse } },
    },
    ...errorResponses,
  },
});

export function registerHealth(app: ApiApp) {
  app.openapi(route, (c) =>
    c.json(
      { status: "ok" as const, version: __APP_VERSION__, environment: c.env.ENVIRONMENT },
      200,
    ),
  );
}

import { OpenAPIHono } from "@hono/zod-openapi";

import type { ApiEnv } from "./context";
import { errorBody } from "./errors";
import { registerAccounts } from "./routes/accounts";
import { registerHealth } from "./routes/health";

export type { ApiEnv };
export type ApiApp = OpenAPIHono<ApiEnv>;

export const API_BASE_PATH = "/api/v1";

/**
 * Builds the /api/v1 Hono app. Native clients call only these endpoints
 * (adr/0004-single-worker-from-react-tanstarter.md); every route is defined
 * with schemas so it appears in contract/openapi.json.
 *
 * `extend` lets tests register extra routes (e.g. one that throws).
 */
export function createApiApp(extend?: (app: ApiApp) => void): ApiApp {
  const app = new OpenAPIHono<ApiEnv>({
    defaultHook: (result, c) => {
      if (!result.success) {
        return c.json(
          errorBody(
            "invalid_request",
            "The request does not match the endpoint's schema",
            {
              issues: result.error.issues,
            },
          ),
          400,
        );
      }
    },
  }).basePath(API_BASE_PATH);

  app.notFound((c) =>
    c.json(
      errorBody("not_found", `No API endpoint for ${c.req.method} ${c.req.path}`),
      404,
    ),
  );

  app.onError((err, c) => {
    console.error("Unhandled API error", err);
    return c.json(errorBody("internal_error", "Internal server error"), 500);
  });

  registerHealth(app);
  registerAccounts(app);
  extend?.(app);

  return app;
}

export const apiApp = createApiApp();

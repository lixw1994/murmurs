import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-pool-workers";
import { defineConfig } from "vitest/config";

import { version } from "./package.json";

/**
 * Tests run inside the Workers runtime (Miniflare) with the development
 * bindings from wrangler.toml. The Worker under test is test/api-worker.ts:
 * the real entry (src/server-entry.ts) depends on TanStack Start's Vite
 * virtual modules, so API behavior is tested against the Hono app directly.
 */
export default defineConfig(async () => {
  const migrations = await readD1Migrations("./drizzle");

  return {
    define: {
      __APP_VERSION__: JSON.stringify(version),
    },
    resolve: {
      tsconfigPaths: true,
    },
    plugins: [
      cloudflareTest({
        main: "./test/api-worker.ts",
        wrangler: { configPath: "./wrangler.toml" },
        miniflare: {
          bindings: {
            TEST_MIGRATIONS: migrations,
            BETTER_AUTH_SECRET: "test-secret-that-is-at-least-32-characters",
          },
        },
      }),
    ],
    test: {
      include: ["test/**/*.test.ts"],
      setupFiles: ["./test/apply-migrations.ts"],
      // Better Auth rejects 4xx requests inside AsyncLocalStorage.run(); workerd
      // reports that rejection before the awaiting caller attaches its handler,
      // although the handler does return the 4xx response. Ignore only those.
      onUnhandledError(error: unknown) {
        const e = error as { name?: string; statusCode?: number };
        if (
          e.name === "APIError" &&
          typeof e.statusCode === "number" &&
          e.statusCode < 500
        ) {
          return false;
        }
      },
    },
  };
});

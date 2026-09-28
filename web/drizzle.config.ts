import { defineConfig } from "drizzle-kit";

/**
 * Generates D1 migrations from the Drizzle schema:
 *
 *   pnpm db:generate            # write a new migration to ./drizzle
 *   pnpm db:migrate:local       # apply to the local D1 database
 *   pnpm db:migrate:staging     # apply to the staging D1 database
 *   pnpm db:migrate:production  # apply to the production D1 database
 */
export default defineConfig({
  schema: "./src/lib/db/schema/index.ts",
  out: "./drizzle",
  dialect: "sqlite",
  casing: "snake_case",
});

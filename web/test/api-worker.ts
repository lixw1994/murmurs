import { apiApp } from "~/server/api/app";

// Minimal Worker for tests: serves only the /api/v1 Hono app.
export default {
  fetch: (request, env, ctx) => apiApp.fetch(request, env, ctx),
} satisfies ExportedHandler<Env>;

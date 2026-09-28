import { createFileRoute } from "@tanstack/react-router";

import { apiApp } from "~/server/api/app";

// Forward every /api/v1/* request to the Hono app (adr/0004).
const forward = ({
  request,
  context,
}: {
  request: Request;
  context: { env: Env; executionCtx: ExecutionContext };
}) => apiApp.fetch(request, context.env, context.executionCtx);

export const Route = createFileRoute("/api/v1/$")({
  server: {
    handlers: {
      GET: forward,
      POST: forward,
      PUT: forward,
      PATCH: forward,
      DELETE: forward,
    },
  },
});

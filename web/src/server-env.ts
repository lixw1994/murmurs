import { z } from "zod";

const authEnvSchema = z.object({
  BETTER_AUTH_SECRET: z.string().min(32),
  BETTER_AUTH_URL: z.string().optional(),
});

export type AuthEnv = z.infer<typeof authEnvSchema>;

/**
 * Parse the auth-related bindings on first use, not at module load, so routes
 * that do not touch auth (e.g. /api/v1/health) work without them.
 */
export type AuthBindings = { BETTER_AUTH_SECRET?: unknown; BETTER_AUTH_URL?: unknown };

export function getAuthEnv(env: AuthBindings): AuthEnv {
  return authEnvSchema.parse(env);
}

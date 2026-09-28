import { z } from "zod";

const authEnvSchema = z.object({
  BETTER_AUTH_SECRET: z.string().min(32),
  BETTER_AUTH_URL: z.string().optional(),
});

export type AuthEnv = z.infer<typeof authEnvSchema>;

/**
 * Parse the auth-related secrets on first use, not at module load, so routes
 * that do not touch auth (e.g. /api/v1/health) work without them.
 */
export function getAuthEnv(): AuthEnv {
  return authEnvSchema.parse(process.env);
}

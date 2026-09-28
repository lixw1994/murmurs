import { z } from "@hono/zod-openapi";

/** Error codes returned by /api/v1. Add codes; never repurpose existing ones. */
export const ERROR_CODES = ["invalid_request", "not_found", "internal_error"] as const;
export type ErrorCode = (typeof ERROR_CODES)[number];

/** Shared error envelope for every /api/v1 error response. */
export const ErrorResponse = z
  .object({
    error: z.object({
      // A string, not an enum, in the contract: new codes will be added within v1
      // and generated clients must not fail to decode unknown values (adr/0014).
      code: z.string().openapi({
        description: `Machine-readable error code. Known values: ${ERROR_CODES.join(", ")}. New codes may be added; handle unknown codes as a generic error.`,
        example: "not_found",
      }),
      message: z.string(),
      details: z.record(z.string(), z.unknown()).optional(),
    }),
  })
  .openapi("ErrorResponse");
export type ErrorResponse = z.infer<typeof ErrorResponse>;

export function errorBody(
  code: ErrorCode,
  message: string,
  details?: Record<string, unknown>,
): ErrorResponse {
  return { error: details ? { code, message, details } : { code, message } };
}

/** Standard error responses to spread into a route's `responses`. */
export const errorResponses = {
  400: {
    description: "The request does not match the endpoint's schema",
    content: { "application/json": { schema: ErrorResponse } },
  },
  500: {
    description: "Unexpected server error",
    content: { "application/json": { schema: ErrorResponse } },
  },
} as const;

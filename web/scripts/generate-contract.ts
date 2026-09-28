/**
 * Writes the OpenAPI contract for /api/v1 (adr/0010, adr/0014).
 *
 *   pnpm contract:generate                 # writes ../contract/openapi.json
 *   pnpm contract:generate --out <file>    # writes elsewhere (used by the drift check)
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";

import { createApiApp } from "../src/server/api/app";

const outFlag = process.argv.indexOf("--out");
const out = resolve(
  outFlag === -1
    ? resolve(import.meta.dirname, "../../contract/openapi.json")
    : process.argv[outFlag + 1],
);

// OpenAPI 3.0.3: accepted by swift-openapi-generator and the Kotlin openapi-generator.
const document = createApiApp().getOpenAPIDocument({
  openapi: "3.0.3",
  info: {
    title: "Murmurs API",
    version: "v1",
    description:
      "Public HTTP API for Murmurs clients. Backward compatible within v1 (adr/0014).",
  },
});

mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, `${JSON.stringify(document, null, 2)}\n`);
console.log(`Wrote ${out}`);

import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

import { user } from "./auth.schema";

/**
 * One recovery code per account. Only the SHA-256 hash of the normalized code
 * is stored (adr/0015-anonymous-accounts-with-recovery-codes.md).
 */
export const recoveryCode = sqliteTable("recovery_code", {
  userId: text("user_id")
    .primaryKey()
    .references(() => user.id, { onDelete: "cascade" }),
  codeHash: text("code_hash").notNull().unique(),
  createdAt: integer("created_at", { mode: "timestamp" }).notNull(),
});

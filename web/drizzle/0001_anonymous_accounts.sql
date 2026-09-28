CREATE TABLE `recovery_code` (
	`user_id` text PRIMARY KEY NOT NULL,
	`code_hash` text NOT NULL,
	`created_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `recovery_code_code_hash_unique` ON `recovery_code` (`code_hash`);--> statement-breakpoint
ALTER TABLE `user` ADD `is_anonymous` integer DEFAULT false;
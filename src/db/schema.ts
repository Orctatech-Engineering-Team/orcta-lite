import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

/**
 * Example table - replace with your own schema.
 */
export const examples = pgTable("examples", {
	id: uuid("id").primaryKey().defaultRandom(),
	name: text("name").notNull(),
	createdAt: timestamp("created_at", { withTimezone: true })
		.notNull()
		.defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true })
		.notNull()
		.defaultNow(),
});

export type Example = typeof examples.$inferSelect;
export type NewExample = typeof examples.$inferInsert;

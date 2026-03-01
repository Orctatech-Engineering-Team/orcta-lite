import { Hono } from "hono";
import { logger } from "hono/logger";
import { prettyJSON } from "hono/pretty-json";
import { secureHeaders } from "hono/secure-headers";
import { cors } from "hono/cors";

import health from "@/modules/health";

const app = new Hono();

// Middleware
app.use("*", logger());
app.use("*", prettyJSON());
app.use("*", secureHeaders());
app.use("*", cors());

// Routes
app.route("/", health);

// 404 handler
app.notFound((c) => {
	return c.json(
		{
			success: false,
			error: { code: "NOT_FOUND", message: "Route not found" },
		},
		404,
	);
});

// Error handler
app.onError((err, c) => {
	console.error(err);
	return c.json(
		{
			success: false,
			error: { code: "INTERNAL_ERROR", message: "Internal server error" },
		},
		500,
	);
});

export default app;
export type AppType = typeof app;

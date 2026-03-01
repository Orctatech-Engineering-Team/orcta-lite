import { Hono } from "hono";
import { db } from "@/db";
import { sql } from "drizzle-orm";
import { HttpStatus, jsonError, jsonSuccess } from "@/lib/response";
import { tryInfra } from "@/lib/infra";

const health = new Hono();

/**
 * GET /health
 * Check API and database health.
 */
health.get("/health", async (c) => {
	const start = Date.now();

	// Check database connectivity
	const dbResult = await tryInfra(async () => {
		await db.execute(sql`SELECT 1`);
		return "up" as const;
	});

	const dbStatus = dbResult.ok ? "up" : "down";
	const status = dbStatus === "up" ? "healthy" : "degraded";

	const response = {
		status,
		timestamp: new Date().toISOString(),
		uptime: process.uptime(),
		latency_ms: Date.now() - start,
		services: {
			database: dbStatus,
		},
	};

	if (status === "degraded") {
		return c.json(response, HttpStatus.SERVICE_UNAVAILABLE);
	}

	return jsonSuccess(c, response);
});

/**
 * GET /ping
 * Simple connectivity check.
 */
health.get("/ping", (c) => {
	return jsonSuccess(c, { message: "pong" });
});

export default health;

import { describe, it, expect } from "vitest";
import app from "@/app";

describe("Health endpoints", () => {
	it("GET /ping returns pong", async () => {
		const res = await app.request("/ping");
		expect(res.status).toBe(200);

		const body = await res.json();
		expect(body).toEqual({
			success: true,
			data: { message: "pong" },
		});
	});
});

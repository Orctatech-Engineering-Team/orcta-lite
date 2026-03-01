import { serve } from "@hono/node-server";
import env from "./env";
import app from "./app";

const server = serve(
	{
		fetch: app.fetch,
		port: env.PORT,
	},
	(info) => {
		console.log(`Server running at http://localhost:${info.port}`);
	},
);

// Graceful shutdown
const shutdown = () => {
	console.log("Shutting down...");
	server.close(() => {
		console.log("Server closed");
		process.exit(0);
	});
};

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

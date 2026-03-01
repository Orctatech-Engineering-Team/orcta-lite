import { err, type Result } from "./result";

/**
 * Infrastructure error - represents system-level failures
 * (database, network, external services).
 */
export class InfrastructureError extends Error {
	readonly type = "INFRASTRUCTURE_ERROR" as const;
	readonly cause: unknown;

	constructor(message: string, cause?: unknown) {
		super(message);
		this.name = "InfrastructureError";
		this.cause = cause;
	}
}

/**
 * Wrap an async operation that might throw infrastructure errors.
 * Returns Result<T, InfrastructureError> instead of throwing.
 *
 * @example
 * const result = await tryInfra(() => db.query.users.findFirst(...));
 */
export async function tryInfra<T>(
	fn: () => Promise<T>,
): Promise<Result<T, InfrastructureError>> {
	try {
		const value = await fn();
		return { ok: true, value };
	} catch (cause) {
		const message = cause instanceof Error ? cause.message : "Unknown error";
		return err(new InfrastructureError(message, cause));
	}
}

/** Type guard for infrastructure errors */
export const isInfraError = (e: unknown): e is InfrastructureError =>
	e instanceof InfrastructureError;

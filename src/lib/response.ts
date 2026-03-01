import type { Context } from "hono";

/**
 * Standard success response shape.
 */
export type ApiSuccess<T> = { success: true; data: T };

/**
 * Standard error response shape.
 */
export type ApiError = {
	success: false;
	error: { code: string; message: string; details?: Record<string, unknown> };
};

/** Construct a success response payload */
export function success<T>(data: T): ApiSuccess<T> {
	return { success: true, data };
}

/** Construct an error response payload */
export function failure(error: {
	code: string;
	message: string;
	details?: Record<string, unknown>;
}): ApiError {
	return { success: false, error };
}

/** Common HTTP status codes */
export const HttpStatus = {
	OK: 200,
	CREATED: 201,
	NO_CONTENT: 204,
	BAD_REQUEST: 400,
	UNAUTHORIZED: 401,
	FORBIDDEN: 403,
	NOT_FOUND: 404,
	CONFLICT: 409,
	UNPROCESSABLE_ENTITY: 422,
	TOO_MANY_REQUESTS: 429,
	INTERNAL_SERVER_ERROR: 500,
	SERVICE_UNAVAILABLE: 503,
} as const;

/** Send a JSON success response */
export function jsonSuccess<T>(c: Context, data: T, status = HttpStatus.OK) {
	return c.json(success(data), status);
}

/** Send a JSON error response */
export function jsonError(
	c: Context,
	code: string,
	message: string,
	status = HttpStatus.BAD_REQUEST,
	details?: Record<string, unknown>,
) {
	return c.json(failure({ code, message, details }), status);
}

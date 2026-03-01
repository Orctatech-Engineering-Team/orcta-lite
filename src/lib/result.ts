/**
 * Result<T, E>
 *
 * Explicit error handling without exceptions.
 * Callers must handle both success and failure branches.
 */

export type Ok<T> = { ok: true; value: T };
export type Err<E> = { ok: false; error: E };
export type Result<T, E> = Ok<T> | Err<E>;

/** Construct a success result */
export const ok = <T>(value: T): Ok<T> => ({ ok: true, value });

/** Construct a failure result */
export const err = <E>(error: E): Err<E> => ({ ok: false, error });

/** Type guard for Ok */
export const isOk = <T, E>(result: Result<T, E>): result is Ok<T> => result.ok;

/** Type guard for Err */
export const isErr = <T, E>(result: Result<T, E>): result is Err<E> =>
	!result.ok;

/** Unsafe unwrap - throws if Err. Use only when you've verified ok === true */
export const unwrap = <T, E>(result: Result<T, E>): T => {
	if (!result.ok) throw new Error("Called unwrap on an Err result");
	return result.value;
};

/** Map the success value */
export const map = <T, E, U>(
	result: Result<T, E>,
	fn: (value: T) => U,
): Result<U, E> => (result.ok ? ok(fn(result.value)) : result);

/** Chain another Result onto success */
export const andThen = <T, E, U, F>(
	result: Result<T, E>,
	fn: (value: T) => Result<U, F>,
): Result<U, E | F> => (result.ok ? fn(result.value) : result);

/** Async variant of andThen */
export const andThenAsync = async <T, E, U, F>(
	result: Result<T, E>,
	fn: (value: T) => Promise<Result<U, F>>,
): Promise<Result<U, E | F>> => (result.ok ? fn(result.value) : result);

/** Exhaustively handle both branches */
export const match = <T, E, R1, R2>(
	result: Result<T, E>,
	handlers: { ok: (value: T) => R1; err: (error: E) => R2 },
): R1 | R2 =>
	result.ok ? handlers.ok(result.value) : handlers.err(result.error);

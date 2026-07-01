function isCallableError(
  error: unknown,
): error is { code: string; message: string } {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    typeof (error as { code: unknown }).code === 'string' &&
    'message' in error &&
    typeof (error as { message: unknown }).message === 'string'
  );
}

/** Maps Firebase callable errors to admin-facing messages. */
export function mapCallableFunctionError(
  error: unknown,
  functionName: string,
): string {
  if (isCallableError(error)) {
    const message = error.message?.trim();
    const hasSpecificMessage =
      message &&
      message !== 'internal' &&
      message !== 'INTERNAL' &&
      message !== 'NOT_FOUND' &&
      message !== 'not-found';

    if (hasSpecificMessage) {
      return message;
    }

    if (error.code === 'functions/not-found') {
      return `${functionName} is not deployed. Run firebase deploy --only functions.`;
    }

    return `${functionName} failed (${error.code}).`;
  }

  if (error instanceof Error) {
    if (error.message === 'internal' || error.message === 'INTERNAL') {
      return `${functionName} failed. Deploy Cloud Functions and retry.`;
    }

    return error.message;
  }

  return `${functionName} failed.`;
}

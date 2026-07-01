import { describe, expect, it } from 'vitest';

import { mapCallableFunctionError } from './callable-function-error.util';

describe('mapCallableFunctionError', () => {
  it('passes through specific not-found backend messages', () => {
    expect(
      mapCallableFunctionError(
        {
          code: 'functions/not-found',
          message: 'Target user not found.',
        },
        'requestUserDeletion',
      ),
    ).toBe('Target user not found.');
  });

  it('maps generic not-found to undeployed guidance', () => {
    expect(
      mapCallableFunctionError(
        { code: 'functions/not-found', message: 'NOT_FOUND' },
        'requestUserDeletion',
      ),
    ).toBe(
      'requestUserDeletion is not deployed. Run firebase deploy --only functions.',
    );
  });

  it('passes through failed-precondition messages', () => {
    expect(
      mapCallableFunctionError(
        {
          code: 'functions/failed-precondition',
          message: 'Cannot delete an admin account. Remove the admin claim first.',
        },
        'requestUserDeletion',
      ),
    ).toBe('Cannot delete an admin account. Remove the admin claim first.');
  });
});

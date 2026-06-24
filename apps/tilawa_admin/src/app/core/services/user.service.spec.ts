import { describe, expect, it } from 'vitest';

import { UserService } from './user.service';

describe('UserService', () => {
  it('does not expose unbounded getUsers stream', () => {
    const service = Object.getPrototypeOf(UserService.prototype);
    expect('getUsers' in service).toBe(false);
  });
});

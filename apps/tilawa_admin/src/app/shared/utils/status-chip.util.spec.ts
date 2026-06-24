import { describe, expect, it } from 'vitest';

import { resolveStatusVariant } from './status-chip.util';

describe('resolveStatusVariant', () => {
  it('maps approved session statuses to success', () => {
    expect(resolveStatusVariant('completed')).toBe('success');
    expect(resolveStatusVariant('approved')).toBe('success');
  });

  it('maps pending and review statuses to warning', () => {
    expect(resolveStatusVariant('pending')).toBe('warning');
    expect(resolveStatusVariant('under_review')).toBe('warning');
    expect(resolveStatusVariant('underReview')).toBe('warning');
  });

  it('maps rejected and cancelled statuses to danger', () => {
    expect(resolveStatusVariant('rejected')).toBe('danger');
    expect(resolveStatusVariant('cancelled_by_admin')).toBe('danger');
  });

  it('maps draft and unknown to neutral', () => {
    expect(resolveStatusVariant('draft')).toBe('neutral');
    expect(resolveStatusVariant('unknown')).toBe('neutral');
  });

  it('uses scholar variant when requested', () => {
    expect(resolveStatusVariant('anything', { scholar: true })).toBe('scholar');
  });
});

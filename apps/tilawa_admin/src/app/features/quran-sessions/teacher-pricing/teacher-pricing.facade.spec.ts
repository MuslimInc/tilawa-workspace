import { describe, it, expect, vi, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { TEACHER_PRICING_GATEWAY } from '../../../core/domain/repositories/teacher-pricing.gateway';
import {
  TeacherPricingFacade,
  buildSetPricingInput,
} from './teacher-pricing.facade';

describe('buildSetPricingInput', () => {
  it('inherit clears the override', () => {
    expect(buildSetPricingInput({ teacherId: 't1', mode: 'inherit' })).toEqual({
      teacherId: 't1',
      enabled: false,
    });
  });

  it('free writes amount 0', () => {
    expect(buildSetPricingInput({ teacherId: 't1', mode: 'free' })).toEqual({
      teacherId: 't1',
      enabled: true,
      amount: 0,
    });
  });

  it('fixed carries amount and normalizes currency', () => {
    expect(
      buildSetPricingInput({
        teacherId: 't1',
        mode: 'fixed',
        amount: 40,
        currencyCode: 'egp',
      }),
    ).toEqual({ teacherId: 't1', enabled: true, amount: 40, currencyCode: 'EGP' });
  });

  it('fixed rejects a non-positive amount (use Free instead)', () => {
    expect(() =>
      buildSetPricingInput({ teacherId: 't1', mode: 'fixed', amount: 0 }),
    ).toThrow(/greater than 0/);
  });

  it('rejects a missing teacherId', () => {
    expect(() => buildSetPricingInput({ teacherId: '', mode: 'free' })).toThrow(
      /teacherId is required/,
    );
  });
});

describe('TeacherPricingFacade', () => {
  let setTeacherPricing: ReturnType<typeof vi.fn>;
  let facade: TeacherPricingFacade;

  beforeEach(() => {
    setTeacherPricing = vi.fn().mockResolvedValue(undefined);
    TestBed.configureTestingModule({
      providers: [
        TeacherPricingFacade,
        { provide: TEACHER_PRICING_GATEWAY, useValue: { setTeacherPricing } },
      ],
    });
    facade = TestBed.inject(TeacherPricingFacade);
  });

  it('submits a free override and flags saved', async () => {
    const ok = await facade.submit({ teacherId: 't1', mode: 'free' });
    expect(ok).toBe(true);
    expect(setTeacherPricing).toHaveBeenCalledWith({
      teacherId: 't1',
      enabled: true,
      amount: 0,
    });
    expect(facade.saved()).toBe(true);
    expect(facade.error()).toBeNull();
  });

  it('surfaces a validation error without calling the gateway', async () => {
    const ok = await facade.submit({ teacherId: 't1', mode: 'fixed', amount: 0 });
    expect(ok).toBe(false);
    expect(setTeacherPricing).not.toHaveBeenCalled();
    expect(facade.error()).toMatch(/greater than 0/);
  });

  it('surfaces a gateway failure', async () => {
    setTeacherPricing.mockRejectedValueOnce(new Error('boom'));
    const ok = await facade.submit({ teacherId: 't1', mode: 'free' });
    expect(ok).toBe(false);
    expect(facade.error()).toBe('boom');
    expect(facade.saved()).toBe(false);
  });
});

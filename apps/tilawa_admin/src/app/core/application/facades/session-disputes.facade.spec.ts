import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { SessionDisputesFacade } from './session-disputes.facade';
import {
  ListSessionDisputesUseCase,
  GetSessionDisputeUseCase,
} from '../../domain/usecases/session-dispute.usecases';
import { ResolveSessionDisputeUseCase } from '../../domain/usecases/session-moderation.usecases';
import { SESSION_READ_REPOSITORY } from '../../domain/repositories/session-read.repository';
import { QURAN_SESSIONS_USER_REPOSITORY } from '../../domain/repositories/quran-sessions-user.repository';
import { SessionDisputeSummary } from '../../domain/entities/session-dispute-summary.entity';

function disputeSummary(overrides: Partial<SessionDisputeSummary> = {}): SessionDisputeSummary {
  return {
    id: 'dispute-1',
    bookingId: 'booking-1',
    sessionId: 'session-1',
    aggregateId: 'booking-1',
    status: 'opened',
    reason: 'Quality issue.',
    openedByUserId: 'student-1',
    openedByRole: 'student',
    resolutionReason: null,
    resolvedByUserId: null,
    createdAt: new Date('2026-07-01T10:00:00Z'),
    updatedAt: null,
    resolvedAt: null,
    ...overrides,
  };
}

describe('SessionDisputesFacade — dispute resolution actions', () => {
  let facade: SessionDisputesFacade;
  let getExecute: ReturnType<typeof vi.fn>;
  let resolveExecute: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    getExecute = vi.fn().mockResolvedValue(disputeSummary());
    resolveExecute = vi.fn().mockResolvedValue(undefined);

    TestBed.configureTestingModule({
      providers: [
        { provide: ListSessionDisputesUseCase, useValue: { execute: vi.fn() } },
        { provide: GetSessionDisputeUseCase, useValue: { execute: getExecute } },
        { provide: ResolveSessionDisputeUseCase, useValue: { execute: resolveExecute } },
        { provide: SESSION_READ_REPOSITORY, useValue: { getById: vi.fn().mockResolvedValue(null) } },
        {
          provide: QURAN_SESSIONS_USER_REPOSITORY,
          useValue: { getByIds: vi.fn().mockResolvedValue(new Map()) },
        },
      ],
    });

    facade = TestBed.inject(SessionDisputesFacade);
  });

  it('resolves through the use case and refreshes the authoritative detail', async () => {
    getExecute.mockResolvedValue(
      disputeSummary({
        status: 'resolved_favor_teacher',
        resolutionReason: 'Reviewed evidence.',
        resolvedByUserId: 'admin-1',
        resolvedAt: new Date('2026-07-02T09:00:00Z'),
      }),
    );

    const succeeded = await facade.resolveDispute(
      'booking-1',
      'dispute-1',
      'favor_teacher',
      'Reviewed evidence.',
    );

    expect(succeeded).toBe(true);
    expect(resolveExecute).toHaveBeenCalledWith(
      'booking-1',
      'dispute-1',
      'favor_teacher',
      'Reviewed evidence.',
    );
    expect(getExecute).toHaveBeenCalledWith('dispute-1');
    expect(facade.detail()?.status).toBe('resolved_favor_teacher');
    expect(facade.detail()?.resolvedByUserId).toBe('admin-1');
    expect(facade.actionErrorMessage()).toBeNull();
    expect(facade.isActionLoading()).toBe(false);
  });

  it('reports pending state while the action is in flight', async () => {
    let release!: () => void;
    resolveExecute.mockReturnValue(
      new Promise<void>((resolve) => {
        release = resolve;
      }),
    );

    const pending = facade.resolveDispute('booking-1', 'dispute-1', 'closed', 'Reviewed.');
    expect(facade.isActionLoading()).toBe(true);

    release();
    await pending;
    expect(facade.isActionLoading()).toBe(false);
  });

  it('retains the server failure and does not refresh the detail', async () => {
    resolveExecute.mockRejectedValue(new Error('Booking is not disputed.'));

    const succeeded = await facade.resolveDispute(
      'booking-1',
      'dispute-1',
      'favor_student',
      'Teacher fault.',
    );

    expect(succeeded).toBe(false);
    expect(facade.actionErrorMessage()).toBe('Booking is not disputed.');
    expect(getExecute).not.toHaveBeenCalled();
    expect(facade.isActionLoading()).toBe(false);
  });

  it('clears a previous failure when a new action starts', async () => {
    resolveExecute.mockRejectedValueOnce(new Error('boom'));
    await facade.resolveDispute('booking-1', 'dispute-1', 'closed', 'Reviewed.');
    expect(facade.actionErrorMessage()).toBe('boom');

    resolveExecute.mockResolvedValueOnce(undefined);
    await facade.resolveDispute('booking-1', 'dispute-1', 'closed', 'Reviewed.');
    expect(facade.actionErrorMessage()).toBeNull();
  });
});

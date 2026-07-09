import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';

import { SessionReportsFacade } from './session-reports.facade';
import {
  ListSessionReportsUseCase,
  GetSessionReportUseCase,
} from '../../domain/usecases/session-report.usecases';
import { ResolveSessionReportUseCase } from '../../domain/usecases/session-moderation.usecases';
import { SessionReportSummary } from '../../domain/entities/session-report-summary.entity';

function reportSummary(overrides: Partial<SessionReportSummary> = {}): SessionReportSummary {
  return {
    id: 'report-1',
    bookingId: 'booking-1',
    sessionId: 'session-1',
    category: 'other',
    description: 'Requires review.',
    severity: 'normal',
    status: 'open',
    reporterUserId: 'student-1',
    reporterRole: 'student',
    reportedUserId: 'teacher-1',
    resolutionReason: null,
    resolvedByUserId: null,
    resolvedAt: null,
    createdAt: new Date('2026-07-01T10:00:00Z'),
    updatedAt: null,
    ...overrides,
  };
}

describe('SessionReportsFacade — report resolution actions', () => {
  let facade: SessionReportsFacade;
  let getExecute: ReturnType<typeof vi.fn>;
  let resolveExecute: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    getExecute = vi.fn().mockResolvedValue(reportSummary());
    resolveExecute = vi.fn().mockResolvedValue(undefined);

    TestBed.configureTestingModule({
      providers: [
        { provide: ListSessionReportsUseCase, useValue: { execute: vi.fn() } },
        { provide: GetSessionReportUseCase, useValue: { execute: getExecute } },
        { provide: ResolveSessionReportUseCase, useValue: { execute: resolveExecute } },
      ],
    });

    facade = TestBed.inject(SessionReportsFacade);
  });

  it('maps terminal resolution metadata into the detail view model', async () => {
    getExecute.mockResolvedValue(
      reportSummary({
        status: 'resolved',
        resolutionReason: 'Handled by trust & safety.',
        resolvedByUserId: 'admin-1',
        resolvedAt: new Date('2026-07-02T09:00:00Z'),
      }),
    );

    await facade.loadDetail('report-1');

    const detail = facade.detail();
    expect(detail?.status).toBe('resolved');
    expect(detail?.resolutionReason).toBe('Handled by trust & safety.');
    expect(detail?.resolvedByUserId).toBe('admin-1');
    expect(detail?.resolvedAt).toEqual(new Date('2026-07-02T09:00:00Z'));
  });

  it('resolves through the use case and refreshes the authoritative detail', async () => {
    const succeeded = await facade.resolveReport('report-1', 'resolved', 'Handled.');

    expect(succeeded).toBe(true);
    expect(resolveExecute).toHaveBeenCalledWith('report-1', 'resolved', 'Handled.');
    expect(getExecute).toHaveBeenCalledWith('report-1');
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

    const pending = facade.resolveReport('report-1', 'under_review');
    expect(facade.isActionLoading()).toBe(true);

    release();
    await pending;
    expect(facade.isActionLoading()).toBe(false);
  });

  it('retains the failure message and does not refresh the detail on error', async () => {
    resolveExecute.mockRejectedValue(new Error('A resolution reason is required.'));

    const succeeded = await facade.resolveReport('report-1', 'dismissed', '');

    expect(succeeded).toBe(false);
    expect(facade.actionErrorMessage()).toBe('A resolution reason is required.');
    expect(getExecute).not.toHaveBeenCalled();
    expect(facade.isActionLoading()).toBe(false);
  });

  it('clears a previous failure when a new action starts', async () => {
    resolveExecute.mockRejectedValueOnce(new Error('boom'));
    await facade.resolveReport('report-1', 'resolved', 'Handled.');
    expect(facade.actionErrorMessage()).toBe('boom');

    resolveExecute.mockResolvedValueOnce(undefined);
    await facade.resolveReport('report-1', 'resolved', 'Handled.');
    expect(facade.actionErrorMessage()).toBeNull();
  });
});

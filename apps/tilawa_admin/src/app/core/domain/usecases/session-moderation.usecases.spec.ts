import { describe, expect, it, vi } from 'vitest';

import {
  ResolveSessionDisputeUseCase,
  ResolveSessionReportUseCase,
} from './session-moderation.usecases';
import { SessionModerationGateway } from '../repositories/session-moderation.gateway';

describe('ResolveSessionReportUseCase', () => {
  it('trims an under-review request before invoking the callable boundary', async () => {
    const resolveSessionReport = vi.fn().mockResolvedValue(undefined);
    const gateway = { resolveSessionReport } as Pick<
      SessionModerationGateway,
      'resolveSessionReport'
    >;
    const useCase = new ResolveSessionReportUseCase(gateway as SessionModerationGateway);

    await useCase.execute(' report-1 ', 'under_review', '  reviewing evidence  ');

    expect(resolveSessionReport).toHaveBeenCalledWith(
      'report-1',
      'under_review',
      'reviewing evidence',
    );
  });

  it('rejects terminal report resolutions without a reason', async () => {
    const gateway = {} as Pick<SessionModerationGateway, 'resolveSessionReport'>;
    const useCase = new ResolveSessionReportUseCase(gateway as SessionModerationGateway);

    await expect(useCase.execute('report-1', 'resolved', '  ')).rejects.toThrow(
      'A resolution reason is required.',
    );
  });
});

describe('ResolveSessionDisputeUseCase', () => {
  it('trims the request before invoking the callable boundary', async () => {
    const resolveSessionDispute = vi.fn().mockResolvedValue(undefined);
    const gateway = { resolveSessionDispute } as Pick<
      SessionModerationGateway,
      'resolveSessionDispute'
    >;
    const useCase = new ResolveSessionDisputeUseCase(gateway as SessionModerationGateway);

    await useCase.execute(' booking-1 ', ' dispute-1 ', 'favor_teacher', '  Reviewed evidence.  ');

    expect(resolveSessionDispute).toHaveBeenCalledWith(
      'booking-1',
      'dispute-1',
      'favor_teacher',
      'Reviewed evidence.',
    );
  });

  it('rejects an empty dispute reason before invoking the callable boundary', async () => {
    const gateway = {} as Pick<SessionModerationGateway, 'resolveSessionDispute'>;
    const useCase = new ResolveSessionDisputeUseCase(gateway as SessionModerationGateway);

    await expect(useCase.execute('booking-1', 'dispute-1', 'closed', ' ')).rejects.toThrow(
      'A dispute resolution reason is required.',
    );
  });

  it('preserves normalized callable errors from the gateway', async () => {
    const resolveSessionDispute = vi
      .fn()
      .mockRejectedValue(new Error('resolveSessionDispute is not deployed.'));
    const gateway = { resolveSessionDispute } as Pick<
      SessionModerationGateway,
      'resolveSessionDispute'
    >;
    const useCase = new ResolveSessionDisputeUseCase(gateway as SessionModerationGateway);

    await expect(
      useCase.execute('booking-1', 'dispute-1', 'closed', 'Reviewed evidence.'),
    ).rejects.toThrow('resolveSessionDispute is not deployed.');
  });
});

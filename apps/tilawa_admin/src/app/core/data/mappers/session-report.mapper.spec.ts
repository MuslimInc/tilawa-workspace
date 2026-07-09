import { describe, expect, it } from 'vitest';

import { SessionReportMapper } from './session-report.mapper';

describe('SessionReportMapper', () => {
  it('maps terminal resolution metadata from Firestore', () => {
    const report = SessionReportMapper.fromFirestore('report-1', {
      bookingId: 'booking-1',
      category: 'other',
      description: 'Requires review.',
      status: 'resolved',
      resolutionReason: 'Reviewed and resolved.',
      resolvedByUserId: 'admin-1',
      createdAt: 1_700_000_000_000,
      resolvedAt: 1_700_000_100_000,
    });

    expect(report.status).toBe('resolved');
    expect(report.resolutionReason).toBe('Reviewed and resolved.');
    expect(report.resolvedByUserId).toBe('admin-1');
    expect(report.resolvedAt).toEqual(new Date(1_700_000_100_000));
  });
});

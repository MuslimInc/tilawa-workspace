import { describe, it, expect } from 'vitest';

import {
  AdminSessionMapper,
  SessionCompensationMapper,
  SessionTimelineMapper,
  parseSessionLifecycleStatus,
  resolveLifecycleStatus,
} from './session-admin.mapper';
import { SessionLifecycleStatus } from '../../domain/entities/session-lifecycle-status.enum';

describe('AdminSessionMapper', () => {
  it('maps booking dto to AdminSessionSummary', () => {
    const entity = AdminSessionMapper.fromBookingDoc('booking-1', {
      aggregateId: 'agg-1',
      sessionId: 'session-1',
      studentId: 'student-1',
      teacherId: 'teacher-1',
      slotId: 'teacher-1_20260101T1000Z',
      startsAt: 1_700_000_000_000,
      endsAt: 1_700_000_900_000,
      lifecycleStatus: 'scheduled',
      callType: 'videoCall',
      pricingType: 'free',
      countryCode: 'EG',
      cityId: 'cairo',
      paymentStatus: 'none',
      paymentReference: 'MAN-123',
      paymentProvider: 'manual_off_app',
      priceAmount: 250,
      priceCurrency: 'EGP',
      amountPaidUsd: 0,
      createdAt: 1_700_000_000_000,
      updatedAt: 1_700_000_100_000,
    });

    expect(entity.id).toBe('booking-1');
    expect(entity.aggregateId).toBe('agg-1');
    expect(entity.sessionId).toBe('session-1');
    expect(entity.lifecycleStatus).toBe(SessionLifecycleStatus.Scheduled);
    expect(entity.countryCode).toBe('EG');
    expect(entity.paymentReference).toBe('MAN-123');
    expect(entity.paymentProvider).toBe('manual_off_app');
    expect(entity.priceAmount).toBe(250);
    expect(entity.priceCurrency).toBe('EGP');
  });

  it('falls back legacy status when lifecycleStatus missing', () => {
    expect(resolveLifecycleStatus({ status: 'completed' })).toBe(SessionLifecycleStatus.Completed);
  });
});

describe('parseSessionLifecycleStatus', () => {
  it('returns unknown for invalid values', () => {
    expect(parseSessionLifecycleStatus('not_a_status')).toBe(SessionLifecycleStatus.Unknown);
  });
});

describe('SessionTimelineMapper', () => {
  it('maps audit event dto', () => {
    const event = SessionTimelineMapper.fromFirestore('evt-1', {
      aggregateId: 'agg-1',
      bookingId: 'booking-1',
      sessionId: 'session-1',
      actorId: 'admin-1',
      actorRole: 'admin',
      action: 'cancel_session',
      previousStatus: 'scheduled',
      newStatus: 'cancelled_by_admin',
      reason: 'Policy violation',
      source: 'adminPanel',
      timestamp: 1_700_000_000_000,
    });

    expect(event.action).toBe('cancel_session');
    expect(event.newStatus).toBe('cancelled_by_admin');
    expect(event.reason).toBe('Policy violation');
  });
});

describe('SessionCompensationMapper', () => {
  it('maps compensation dto', () => {
    const row = SessionCompensationMapper.fromFirestore('comp-1', {
      compensationId: 'comp-1',
      aggregateId: 'agg-1',
      bookingId: 'booking-1',
      type: 'restore_credit',
      status: 'completed',
      policyRuleId: 'admin_manual',
      amountUsd: 12.5,
      issuedByActorId: 'admin-1',
      issuedByRole: 'admin',
      createdAt: 1_700_000_000_000,
      completedAt: 1_700_000_100_000,
    });

    expect(row.type).toBe('restore_credit');
    expect(row.amountUsd).toBe(12.5);
    expect(row.status).toBe('completed');
  });
});

import { describe, it, expect, vi } from 'vitest';
import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ActivatedRoute, provideRouter } from '@angular/router';

import { SessionDisputeDetailComponent } from './session-dispute-detail.component';
import {
  SessionDisputesFacade,
  SessionDisputeDetailVm,
} from '../../../core/application/facades/session-disputes.facade';
import { I18nService } from '../../../core/i18n/i18n.service';

function detailVm(overrides: Partial<SessionDisputeDetailVm> = {}): SessionDisputeDetailVm {
  return {
    id: 'dispute-1',
    status: 'opened',
    bookingId: 'booking-1',
    sessionId: 'session-1',
    aggregateId: 'booking-1',
    openedByUserId: 'student-1',
    openedByRole: 'student',
    createdAt: new Date('2026-07-01T10:00:00Z'),
    updatedAt: null,
    reason: 'Quality issue.',
    reasonPreview: 'Quality issue.',
    resolutionReason: null,
    resolvedByUserId: null,
    studentId: 'student-1',
    studentName: 'Fatima',
    teacherId: 'teacher-1',
    teacherName: 'Ustad Ahmad',
    resolvedAt: null,
    ...overrides,
  };
}

function makeFakeFacade(detailOverrides: Partial<SessionDisputeDetailVm> = {}) {
  return {
    detail: signal<SessionDisputeDetailVm | null>(detailVm(detailOverrides)),
    detailLoadState: signal<'idle' | 'loading' | 'success' | 'error'>('success'),
    detailErrorMessage: signal<string | null>(null),
    isActionLoading: signal(false),
    actionErrorMessage: signal<string | null>(null),
    loadDetail: vi.fn().mockResolvedValue(undefined),
    resolveDispute: vi.fn().mockResolvedValue(true),
    clearActionError: vi.fn(),
  };
}

type FakeFacade = ReturnType<typeof makeFakeFacade>;

async function setup(
  facade: FakeFacade,
  language: 'en' | 'ar' = 'en',
): Promise<ComponentFixture<SessionDisputeDetailComponent>> {
  await TestBed.configureTestingModule({
    imports: [SessionDisputeDetailComponent],
    providers: [
      provideRouter([]),
      { provide: SessionDisputesFacade, useValue: facade },
      {
        provide: I18nService,
        useValue: {
          language: signal(language),
          ready: signal(true),
          t: (key: string) => key,
        },
      },
      {
        provide: ActivatedRoute,
        useValue: { snapshot: { paramMap: { get: () => 'dispute-1' } } },
      },
    ],
  }).compileComponents();

  const fixture = TestBed.createComponent(SessionDisputeDetailComponent);
  fixture.detectChanges();
  return fixture;
}

function text(fixture: ComponentFixture<SessionDisputeDetailComponent>): string {
  return fixture.nativeElement.textContent as string;
}

describe('SessionDisputeDetailComponent — dispute resolution', () => {
  it('loads the dispute detail on init', async () => {
    const facade = makeFakeFacade();
    await setup(facade);
    expect(facade.loadDetail).toHaveBeenCalledWith('dispute-1');
  });

  it('shows the outcome selector with all allowed outcomes for an open dispute', async () => {
    const fixture = await setup(makeFakeFacade());
    const options = [
      ...fixture.nativeElement.querySelectorAll('#dispute-outcome option'),
    ] as HTMLOptionElement[];
    expect(options.map((option) => option.value)).toEqual([
      'favor_student',
      'favor_teacher',
      'with_compensation',
      'rejected',
      'closed',
    ]);
    expect(text(fixture)).toContain('disputes_resolve');
    expect(text(fixture)).not.toContain('disputes_terminalNotice');
  });

  it('shows effect copy matching the selected outcome', async () => {
    const fixture = await setup(makeFakeFacade());
    expect(text(fixture)).toContain('disputes_effectClosed');

    fixture.componentInstance.selectedResolution = 'favor_student';
    fixture.detectChanges();
    expect(text(fixture)).toContain('disputes_effectFavorStudent');
  });

  it('renders a terminal dispute read-only with no resolution controls', async () => {
    const fixture = await setup(
      makeFakeFacade({
        status: 'resolved_favor_student',
        resolutionReason: 'Teacher fault.',
        resolvedByUserId: 'admin-1',
        resolvedAt: new Date('2026-07-02T09:00:00Z'),
      }),
    );
    const body = text(fixture);
    expect(body).toContain('disputes_terminalNotice');
    expect(body).toContain('Teacher fault.');
    expect(body).toContain('admin-1');
    expect(fixture.nativeElement.querySelector('#dispute-outcome')).toBeNull();
    expect(fixture.nativeElement.querySelector('app-tilawa-button')).toBeNull();
  });

  it('requires a reason before submitting the resolution', async () => {
    const facade = makeFakeFacade();
    const fixture = await setup(facade);

    fixture.componentInstance.openResolve();
    fixture.detectChanges();

    const submitButtons = [
      ...fixture.nativeElement.querySelectorAll('app-reject-reason-dialog button'),
    ] as HTMLButtonElement[];
    expect(submitButtons.at(-1)?.disabled).toBe(true);

    fixture.componentInstance.selectedResolution = 'favor_teacher';
    await fixture.componentInstance.onSubmitReason('Reviewed evidence.');
    expect(facade.resolveDispute).toHaveBeenCalledWith(
      'booking-1',
      'dispute-1',
      'favor_teacher',
      'Reviewed evidence.',
    );
    expect(fixture.componentInstance.reasonOpen()).toBe(false);
  });

  it('keeps the dialog open when the server rejects the resolution', async () => {
    const facade = makeFakeFacade();
    facade.resolveDispute.mockImplementation(async () => {
      facade.actionErrorMessage.set('Booking is not disputed.');
      return false;
    });
    const fixture = await setup(facade);

    fixture.componentInstance.openResolve();
    await fixture.componentInstance.onSubmitReason('Reviewed.');
    fixture.detectChanges();

    expect(fixture.componentInstance.reasonOpen()).toBe(true);
    const alert = fixture.nativeElement.querySelector('[role="alert"]');
    expect(alert?.textContent).toContain('Booking is not disputed.');
  });

  it('prevents duplicate submission while an action is pending', async () => {
    const facade = makeFakeFacade();
    facade.isActionLoading.set(true);
    const fixture = await setup(facade);

    await fixture.componentInstance.onSubmitReason('Reviewed.');
    expect(facade.resolveDispute).not.toHaveBeenCalled();

    const select = fixture.nativeElement.querySelector('#dispute-outcome') as HTMLSelectElement;
    expect(select.disabled).toBe(true);
  });

  it('renders the resolution panel under the Arabic locale', async () => {
    const fixture = await setup(makeFakeFacade(), 'ar');
    const body = text(fixture);
    expect(body).toContain('disputes_resolve');
    expect(body).toContain('disputes_outcomeLabel');
  });
});

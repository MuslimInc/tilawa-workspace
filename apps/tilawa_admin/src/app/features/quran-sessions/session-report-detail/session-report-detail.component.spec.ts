import { describe, it, expect, vi } from 'vitest';
import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ActivatedRoute, provideRouter } from '@angular/router';

import { SessionReportDetailComponent } from './session-report-detail.component';
import {
  SessionReportsFacade,
  SessionReportDetailVm,
} from '../../../core/application/facades/session-reports.facade';
import { I18nService } from '../../../core/i18n/i18n.service';

function detailVm(overrides: Partial<SessionReportDetailVm> = {}): SessionReportDetailVm {
  return {
    id: 'report-1',
    category: 'other',
    severity: 'normal',
    status: 'open',
    reporterUserId: 'student-1',
    reporterRole: 'student',
    reportedUserId: 'teacher-1',
    bookingId: 'booking-1',
    sessionId: 'session-1',
    createdAt: new Date('2026-07-01T10:00:00Z'),
    updatedAt: null,
    description: 'Requires review.',
    descriptionPreview: 'Requires review.',
    resolutionReason: null,
    resolvedByUserId: null,
    resolvedAt: null,
    ...overrides,
  };
}

function makeFakeFacade(detailOverrides: Partial<SessionReportDetailVm> = {}) {
  return {
    detail: signal<SessionReportDetailVm | null>(detailVm(detailOverrides)),
    detailLoadState: signal<'idle' | 'loading' | 'success' | 'error'>('success'),
    detailErrorMessage: signal<string | null>(null),
    isActionLoading: signal(false),
    actionErrorMessage: signal<string | null>(null),
    loadDetail: vi.fn().mockResolvedValue(undefined),
    resolveReport: vi.fn().mockResolvedValue(true),
    clearActionError: vi.fn(),
  };
}

type FakeFacade = ReturnType<typeof makeFakeFacade>;

async function setup(
  facade: FakeFacade,
  language: 'en' | 'ar' = 'en',
): Promise<ComponentFixture<SessionReportDetailComponent>> {
  await TestBed.configureTestingModule({
    imports: [SessionReportDetailComponent],
    providers: [
      provideRouter([]),
      { provide: SessionReportsFacade, useValue: facade },
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
        useValue: { snapshot: { paramMap: { get: () => 'report-1' } } },
      },
    ],
  }).compileComponents();

  const fixture = TestBed.createComponent(SessionReportDetailComponent);
  fixture.detectChanges();
  return fixture;
}

function text(fixture: ComponentFixture<SessionReportDetailComponent>): string {
  return fixture.nativeElement.textContent as string;
}

describe('SessionReportDetailComponent — report triage actions', () => {
  it('loads the report detail on init', async () => {
    const facade = makeFakeFacade();
    await setup(facade);
    expect(facade.loadDetail).toHaveBeenCalledWith('report-1');
  });

  it('shows all triage actions for an open report', async () => {
    const fixture = await setup(makeFakeFacade());
    const body = text(fixture);
    expect(body).toContain('reports_setUnderReview');
    expect(body).toContain('reports_resolve');
    expect(body).toContain('reports_dismiss');
    expect(body).not.toContain('reports_terminalNotice');
  });

  it('hides the under-review action once the report is under review', async () => {
    const fixture = await setup(makeFakeFacade({ status: 'under_review' }));
    const body = text(fixture);
    expect(body).not.toContain('reports_setUnderReview');
    expect(body).toContain('reports_resolve');
    expect(body).toContain('reports_dismiss');
  });

  it('renders a terminal report read-only with its resolution metadata', async () => {
    const fixture = await setup(
      makeFakeFacade({
        status: 'resolved',
        resolutionReason: 'Handled by trust & safety.',
        resolvedByUserId: 'admin-1',
        resolvedAt: new Date('2026-07-02T09:00:00Z'),
      }),
    );
    const body = text(fixture);
    expect(body).toContain('reports_terminalNotice');
    expect(body).toContain('Handled by trust & safety.');
    expect(body).toContain('admin-1');
    expect(fixture.nativeElement.querySelector('app-tilawa-button')).toBeNull();
  });

  it('requires a reason before a terminal resolution is submitted', async () => {
    const facade = makeFakeFacade();
    const fixture = await setup(facade);

    fixture.componentInstance.openTerminal('dismissed');
    fixture.detectChanges();

    const submitButtons = [
      ...fixture.nativeElement.querySelectorAll('app-reject-reason-dialog button'),
    ] as HTMLButtonElement[];
    const submit = submitButtons.at(-1);
    expect(submit?.disabled).toBe(true);

    await fixture.componentInstance.onSubmitReason('Insufficient evidence.');
    expect(facade.resolveReport).toHaveBeenCalledWith(
      'report-1',
      'dismissed',
      'Insufficient evidence.',
    );
  });

  it('confirms before setting a report under review', async () => {
    const facade = makeFakeFacade();
    const fixture = await setup(facade);

    fixture.componentInstance.openUnderReview();
    fixture.detectChanges();
    expect(text(fixture)).toContain('reports_underReviewTitle');

    await fixture.componentInstance.onConfirmUnderReview();
    expect(facade.resolveReport).toHaveBeenCalledWith('report-1', 'under_review');
    expect(fixture.componentInstance.confirmUnderReviewOpen()).toBe(false);
  });

  it('keeps the dialog open when the action fails and surfaces the error', async () => {
    const facade = makeFakeFacade();
    facade.resolveReport.mockImplementation(async () => {
      facade.actionErrorMessage.set('resolveSessionReport is not deployed.');
      return false;
    });
    const fixture = await setup(facade);

    fixture.componentInstance.openTerminal('resolved');
    await fixture.componentInstance.onSubmitReason('Handled.');
    fixture.detectChanges();

    expect(fixture.componentInstance.reasonOpen()).toBe(true);
    const alert = fixture.nativeElement.querySelector('[role="alert"]');
    expect(alert?.textContent).toContain('resolveSessionReport is not deployed.');
  });

  it('prevents duplicate submission while an action is pending', async () => {
    const facade = makeFakeFacade();
    facade.isActionLoading.set(true);
    const fixture = await setup(facade);

    fixture.componentInstance.pendingResolution.set('resolved');
    await fixture.componentInstance.onSubmitReason('Handled.');
    await fixture.componentInstance.onConfirmUnderReview();

    expect(facade.resolveReport).not.toHaveBeenCalled();
    const buttons = [
      ...fixture.nativeElement.querySelectorAll('app-tilawa-button button'),
    ] as HTMLButtonElement[];
    expect(buttons.length).toBeGreaterThan(0);
    expect(buttons.every((button) => button.disabled)).toBe(true);
  });

  it('renders triage actions and metadata under the Arabic locale', async () => {
    const fixture = await setup(makeFakeFacade(), 'ar');
    const body = text(fixture);
    expect(body).toContain('reports_resolve');
    expect(body).toContain('reports_dismiss');
  });
});

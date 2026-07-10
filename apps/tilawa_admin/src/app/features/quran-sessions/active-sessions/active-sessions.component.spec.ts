import { describe, it, expect, beforeEach, vi } from 'vitest';
import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { ActiveSessionsComponent } from './active-sessions.component';
import { ActiveSessionsFacade } from '../../../core/application/facades/active-sessions.facade';
import { I18nService } from '../../../core/i18n/i18n.service';
import { ActiveSessionListItemVm } from '../../../core/data/view-models/active-sessions.view-model';
import {
  ActiveSessionOperationalFilter,
  ActiveSessionOperationalStatus,
} from '../../../core/domain/entities/active-session.entity';

function row(overrides: Partial<ActiveSessionListItemVm> = {}): ActiveSessionListItemVm {
  return {
    bookingId: 'booking-1',
    sessionId: 'session-1',
    startsAt: new Date('2026-06-25T12:00:00Z'),
    endsAt: null,
    lifecycleStatus: 'in_progress',
    callType: 'agora',
    operationalStatus: ActiveSessionOperationalStatus.Live,
    callPhase: 'active',
    teacherId: 'teacher-1',
    teacherName: 'Ustad Ahmad',
    teacherAccountStatus: 'active',
    teacherIsActive: true,
    teacherUserId: 'user-teacher',
    studentId: 'student-1',
    studentName: 'Fatima',
    studentAccountStatus: 'active',
    whoJoinedFirst: 'teacher',
    teacherJoinStatus: 'joined',
    studentJoinStatus: 'joined',
    teacherLate: false,
    studentLate: false,
    teacherNoShow: false,
    studentNoShow: false,
    connectedMinutes: 12,
    reconnectCount: 1,
    interruptionCount: 0,
    providerType: 'agora',
    trackingUpdatedAt: new Date('2026-06-25T12:10:00Z'),
    ...overrides,
  };
}

function makeFakeFacade() {
  const listItems = signal<ActiveSessionListItemVm[]>([row()]);
  const listLoadState = signal<'idle' | 'loading' | 'success' | 'error'>('success');
  const operationalFilter = signal(ActiveSessionOperationalFilter.All);

  return {
    items: listItems,
    listLoadState,
    listErrorMessage: signal<string | null>(null),
    canLoadMore: signal(false),
    filter: operationalFilter,
    loadList: vi.fn().mockResolvedValue(undefined),
    loadMore: vi.fn().mockResolvedValue(undefined),
    changeFilter: vi.fn().mockImplementation(async (filter: ActiveSessionOperationalFilter) => {
      operationalFilter.set(filter);
    }),
  };
}

type FakeFacade = ReturnType<typeof makeFakeFacade>;

describe('ActiveSessionsComponent', () => {
  let facade: FakeFacade;
  let fixture: ComponentFixture<ActiveSessionsComponent>;

  beforeEach(async () => {
    facade = makeFakeFacade();

    await TestBed.configureTestingModule({
      imports: [ActiveSessionsComponent],
      providers: [
        provideRouter([]),
        { provide: ActiveSessionsFacade, useValue: facade },
        {
          provide: I18nService,
          useValue: {
            language: signal('en'),
            ready: signal(true),
            t: (key: string) => key,
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(ActiveSessionsComponent);
    fixture.detectChanges();
  });

  function text(): string {
    return fixture.nativeElement.textContent as string;
  }

  it('loads active sessions on init', () => {
    expect(facade.loadList).toHaveBeenCalled();
  });

  it('renders active session rows with teacher and student', () => {
    expect(text()).toContain('Ustad Ahmad');
    expect(text()).toContain('Fatima');
    expect(text()).toContain('12');
    expect(text()).toContain('1');
  });

  it('renders empty state when no rows', () => {
    facade.items.set([]);
    fixture.detectChanges();
    expect(text()).toContain('activeSessions_empty');
  });

  it('renders loading state', () => {
    facade.listLoadState.set('loading');
    fixture.detectChanges();
    expect(text()).toContain('activeSessions_loading');
  });

  it('renders error state', () => {
    facade.listLoadState.set('error');
    fixture.detectChanges();
    expect(text()).toContain('Error');
  });

  it('changes filter via facade', () => {
    fixture.componentInstance.setFilter(ActiveSessionOperationalFilter.LiveNow);
    expect(facade.changeFilter).toHaveBeenCalledWith(ActiveSessionOperationalFilter.LiveNow);
  });

  it('renders session detail action', () => {
    expect(text()).toContain('common_view');
  });

  it('renders late/no-show chips when flagged', () => {
    facade.items.set([
      row({
        teacherLate: true,
        studentNoShow: true,
        operationalStatus: ActiveSessionOperationalStatus.NoShowCandidate,
      }),
    ]);
    fixture.detectChanges();
    expect(text()).toContain('callTracking_teacherLate');
    expect(text()).toContain('status_student_no_show');
  });
});

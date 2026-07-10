import { describe, expect, it, beforeEach, vi } from 'vitest';
import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ActivatedRoute, provideRouter } from '@angular/router';

import { TeacherApplicationDetailVm } from '../../../core/data/view-models/quran-sessions.view-model';
import { TeacherApplicationDetailComponent } from './teacher-application-detail.component';
import { TeacherApplicationsFacade } from '../../../core/application/facades/teacher-applications.facade';
import { I18nService } from '../../../core/i18n/i18n.service';

function makeDetail(
  overrides: Partial<TeacherApplicationDetailVm> = {},
): TeacherApplicationDetailVm {
  return {
    id: 'app-1',
    userId: 'user-1',
    publicDisplayName: '—',
    accountDisplayName: 'Ahmad Ali',
    avatarUrl: null,
    email: 'ahmad@example.com',
    phoneNumber: null,
    gender: null,
    dateOfBirth: null,
    country: 'EG',
    city: 'Cairo',
    contactMethod: null,
    languages: [],
    specializations: [],
    bio: null,
    submittedAt: new Date(),
    reviewedAt: null,
    reviewedBy: null,
    rejectionReason: null,
    status: 'pending',
    ...overrides,
  };
}

function makeFakeFacade() {
  return {
    detail: signal<TeacherApplicationDetailVm | null>(null),
    detailLoadState: signal<'idle' | 'loading' | 'success' | 'error'>('idle'),
    detailErrorMessage: signal<string | null>(null),
    isActionLoading: signal(false),
    loadDetail: vi.fn().mockResolvedValue(undefined),
    review: vi.fn().mockResolvedValue(undefined),
  };
}

describe('TeacherApplicationDetailComponent', () => {
  let fixture: ComponentFixture<TeacherApplicationDetailComponent>;
  let component: TeacherApplicationDetailComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TeacherApplicationDetailComponent],
      providers: [
        provideRouter([]),
        { provide: TeacherApplicationsFacade, useValue: makeFakeFacade() },
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: { get: () => 'app-1' } } },
        },
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

    fixture = TestBed.createComponent(TeacherApplicationDetailComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('falls back to account display name for avatar when public name is placeholder', () => {
    expect(component.avatarDisplayName(makeDetail())).toBe('Ahmad Ali');
  });

  it('falls back to email when names are placeholders', () => {
    expect(
      component.avatarDisplayName(makeDetail({ publicDisplayName: '—', accountDisplayName: '—' })),
    ).toBe('ahmad@example.com');
  });
});

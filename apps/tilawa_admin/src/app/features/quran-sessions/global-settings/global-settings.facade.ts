import { Injectable, inject } from '@angular/core';
import { Firestore, doc, docData } from '@angular/fire/firestore';
import { Functions, httpsCallable } from '@angular/fire/functions';
import { BehaviorSubject, Observable } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';

export type TeacherApplicationDiscoverability =
  | 'none'
  | 'profileOnly'
  | 'profileAndEmptyState';

export interface PlatformConfig {
  quranSessionsEnabled: boolean;
  studentEntryEnabled: boolean;
  bookingEnabled: boolean;
  sessionMode: 'videoOnly';
  bookingMode: 'requiresTutorApproval' | 'autoConfirm';
  defaultJoinWindowLeadMs: number;
  defaultTutorApprovalSlaMs: number;
  defaultMinBookingNoticeMs: number;
  defaultMaxUpcomingPerStudent: number;
  // Tutor (teacher application) entry — admin-controlled.
  teacherApplicationEnabled: boolean;
  teacherApplicationEntryEnabled: boolean;
  homeTeacherApplicationCardEnabled: boolean;
  teacherApplicationDiscoverability: TeacherApplicationDiscoverability;
}

type LegacyPlatformConfig = PlatformConfig & {
  defaultBookingMode?: PlatformConfig['bookingMode'];
  quranTutorBookingMode?: PlatformConfig['bookingMode'];
};

@Injectable({ providedIn: 'root' })
export class GlobalSettingsFacade {
  private firestore = inject(Firestore);
  private functions = inject(Functions);

  private loadingSubject = new BehaviorSubject<boolean>(true);
  loading$ = this.loadingSubject.asObservable();

  private savingSubject = new BehaviorSubject<boolean>(false);
  saving$ = this.savingSubject.asObservable();

  private errorSubject = new BehaviorSubject<string | null>(null);
  error$ = this.errorSubject.asObservable();

  private successSubject = new BehaviorSubject<string | null>(null);
  successMessage$ = this.successSubject.asObservable();

  getConfig(): Observable<PlatformConfig | undefined> {
    this.loadingSubject.next(true);
    const docRef = doc(this.firestore, 'quran_session_platform_config/global');
    return (docData(docRef) as Observable<LegacyPlatformConfig | undefined>).pipe(
      map(config => {
        if (!config) return undefined;
        return {
          ...config,
          bookingMode:
            config.bookingMode ??
            config.defaultBookingMode ??
            config.quranTutorBookingMode ??
            'requiresTutorApproval',
          // Tutor-entry fields default off / hidden when absent in Firestore.
          teacherApplicationEnabled: config.teacherApplicationEnabled ?? false,
          teacherApplicationEntryEnabled:
            config.teacherApplicationEntryEnabled ?? false,
          homeTeacherApplicationCardEnabled:
            config.homeTeacherApplicationCardEnabled ?? false,
          teacherApplicationDiscoverability:
            config.teacherApplicationDiscoverability ?? 'none'
        } satisfies PlatformConfig;
      }),
      tap(() => this.loadingSubject.next(false)),
      catchError(err => {
        this.errorSubject.next(err.message);
        this.loadingSubject.next(false);
        throw err;
      })
    );
  }

  async saveConfig(config: PlatformConfig): Promise<void> {
    this.savingSubject.next(true);
    this.errorSubject.next(null);
    this.successSubject.next(null);

    try {
      const updateFn = httpsCallable<PlatformConfig, any>(this.functions, 'updatePlatformConfig');
      await updateFn(config);
      this.successSubject.next('Global settings updated successfully');
      setTimeout(() => this.successSubject.next(null), 3000);
    } catch (err: any) {
      console.error('Error saving global settings', err);
      this.errorSubject.next(err.message || 'Failed to save settings');
      throw err;
    } finally {
      this.savingSubject.next(false);
    }
  }
}

import { Injectable, inject } from '@angular/core';
import {
  Firestore,
  doc,
  getDoc,
  setDoc,
  serverTimestamp,
} from '@angular/fire/firestore';
import { BehaviorSubject } from 'rxjs';

import {
  ForcedUpdateConfig,
  mapForcedUpdateConfig,
} from './forced-update-config.mapping';

export type { ForcedUpdateConfig } from './forced-update-config.mapping';

const DOC_PATH = 'app_config/in_app_update';

@Injectable({ providedIn: 'root' })
export class AppVersionFacade {
  private readonly firestore = inject(Firestore);

  private readonly loadingSubject = new BehaviorSubject<boolean>(true);
  readonly loading$ = this.loadingSubject.asObservable();

  private readonly savingSubject = new BehaviorSubject<boolean>(false);
  readonly saving$ = this.savingSubject.asObservable();

  private readonly errorSubject = new BehaviorSubject<string | null>(null);
  readonly error$ = this.errorSubject.asObservable();

  private readonly successSubject = new BehaviorSubject<string | null>(null);
  readonly successMessage$ = this.successSubject.asObservable();

  /** One-shot load — avoids overwriting an in-progress admin edit via live snapshots. */
  async loadConfig(): Promise<ForcedUpdateConfig> {
    this.loadingSubject.next(true);
    this.errorSubject.next(null);

    try {
      const docRef = doc(this.firestore, DOC_PATH);
      const snap = await getDoc(docRef);
      return mapForcedUpdateConfig(
        snap.exists() ? (snap.data() as Record<string, unknown>) : undefined,
      );
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : 'Failed to load version config';
      this.errorSubject.next(message);
      return { androidMinBuildNumber: 0, iosMinBuildNumber: 0 };
    } finally {
      this.loadingSubject.next(false);
    }
  }

  async saveConfig(config: ForcedUpdateConfig): Promise<void> {
    this.savingSubject.next(true);
    this.errorSubject.next(null);
    this.successSubject.next(null);

    try {
      const docRef = doc(this.firestore, DOC_PATH);
      await setDoc(
        docRef,
        {
          android_min_build_number: config.androidMinBuildNumber,
          ios_min_build_number: config.iosMinBuildNumber,
          updated_at: serverTimestamp(),
        },
        { merge: true },
      );
      this.successSubject.next('forcedUpdate_saveSuccess');
      setTimeout(() => this.successSubject.next(null), 3000);
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : 'Failed to save version config';
      this.errorSubject.next(message);
      throw err;
    } finally {
      this.savingSubject.next(false);
    }
  }
}

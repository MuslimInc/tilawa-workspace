import { InjectionToken } from '@angular/core';
import { Observable } from 'rxjs';

import { AdminSession } from '../entities/admin-session.entity';

export interface AuthSessionRepository {
  readonly session$: Observable<AdminSession | null>;

  signIn(email: string, password: string): Promise<AdminSession>;

  signOut(): Promise<void>;
}

export const AUTH_SESSION_REPOSITORY = new InjectionToken<AuthSessionRepository>(
  'AuthSessionRepository',
);

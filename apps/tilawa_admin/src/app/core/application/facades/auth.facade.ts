import { Injectable, inject, signal, computed } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';

import {
  AUTH_SESSION_REPOSITORY,
  AuthSessionRepository,
} from '../../domain/repositories/auth-session.repository';
import { AdminSession } from '../../domain/entities/admin-session.entity';

@Injectable({ providedIn: 'root' })
export class AuthFacade {
  private readonly authRepository = inject(AUTH_SESSION_REPOSITORY);

  private readonly sessionSignal = signal<AdminSession | null>(null);
  private readonly loadingSignal = signal(false);
  private readonly errorSignal = signal<string | null>(null);

  readonly session = this.sessionSignal.asReadonly();
  readonly loading = this.loadingSignal.asReadonly();
  readonly error = this.errorSignal.asReadonly();
  readonly isAuthenticated = computed(() => this.sessionSignal() != null);
  readonly isAdmin = computed(() => this.sessionSignal()?.isAdmin === true);

  readonly session$ = toObservable(this.sessionSignal);

  constructor() {
    this.authRepository.session$.subscribe((session) => {
      this.sessionSignal.set(session);
    });
  }

  async signIn(email: string, password: string): Promise<void> {
    this.loadingSignal.set(true);
    this.errorSignal.set(null);
    try {
      const session = await this.authRepository.signIn(email, password);
      this.sessionSignal.set(session);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Sign in failed.';
      this.errorSignal.set(message);
      throw error;
    } finally {
      this.loadingSignal.set(false);
    }
  }

  async signOut(): Promise<void> {
    await this.authRepository.signOut();
    this.sessionSignal.set(null);
  }
}

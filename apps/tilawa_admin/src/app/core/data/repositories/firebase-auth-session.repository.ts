import { Injectable, inject } from '@angular/core';
import { Auth, authState, signInWithEmailAndPassword, signOut } from '@angular/fire/auth';
import { map, Observable, shareReplay, switchMap, from, of } from 'rxjs';

import { AdminSession } from '../../domain/entities/admin-session.entity';
import { AuthSessionRepository } from '../../domain/repositories/auth-session.repository';

@Injectable({ providedIn: 'root' })
export class FirebaseAuthSessionRepository implements AuthSessionRepository {
  private readonly auth = inject(Auth);

  readonly session$: Observable<AdminSession | null> = authState(this.auth).pipe(
    switchMap((user) => {
      if (!user) {
        return of(null);
      }
      return from(user.getIdTokenResult()).pipe(
        map((token) => ({
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          isAdmin: token.claims['admin'] === true,
        })),
      );
    }),
    shareReplay({ bufferSize: 1, refCount: true }),
  );

  async signIn(email: string, password: string): Promise<AdminSession> {
    const credential = await signInWithEmailAndPassword(this.auth, email.trim(), password);
    const token = await credential.user.getIdTokenResult();
    const session: AdminSession = {
      uid: credential.user.uid,
      email: credential.user.email,
      displayName: credential.user.displayName,
      isAdmin: token.claims['admin'] === true,
    };

    if (!session.isAdmin) {
      await signOut(this.auth);
      throw new Error('Admin access required.');
    }

    return session;
  }

  async signOut(): Promise<void> {
    await signOut(this.auth);
  }
}

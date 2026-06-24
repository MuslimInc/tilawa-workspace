import { Injectable, inject } from '@angular/core';
import { Firestore, collection, collectionCount } from '@angular/fire/firestore';

import { QuranSessionsPaths } from '../data/paths/quran-sessions.paths';

/**
 * Legacy dashboard helper — count only. User listing uses TilawaUserRepository.
 */
@Injectable({
  providedIn: 'root',
})
export class UserService {
  private readonly firestore = inject(Firestore);

  getUsersCount() {
    const usersCollection = collection(this.firestore, QuranSessionsPaths.users);
    return collectionCount(usersCollection);
  }
}

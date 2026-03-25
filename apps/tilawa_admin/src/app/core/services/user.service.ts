import { Injectable, inject } from '@angular/core';
import { Firestore, collection, collectionData, collectionCount } from '@angular/fire/firestore';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private firestore = inject(Firestore);

  getUsers(): Observable<any[]> {
    const usersCollection = collection(this.firestore, 'users');
    return collectionData(usersCollection, { idField: 'id' });
  }

  getUsersCount(): Observable<number> {
    const usersCollection = collection(this.firestore, 'users');
    return collectionCount(usersCollection);
  }
}

import { Injectable, inject } from '@angular/core';
import { Firestore } from '@angular/fire/firestore';
import { collection, addDoc } from 'firebase/firestore';
import { NotificationEntity } from '../../domain/entities/notification.entity';
import { NotificationRepository } from '../../domain/repositories/notification.repository';
import { NotificationModelMapper } from '../models/notification.model';
import { TilawaPaths } from '../paths/quran-sessions.paths';

@Injectable({
  providedIn: 'root',
})
export class NotificationRepositoryImpl implements NotificationRepository {
  private firestore = inject(Firestore);

  async sendNotification(notification: NotificationEntity): Promise<void> {
    const notificationsCollection = collection(this.firestore, TilawaPaths.notifications);
    const dto = NotificationModelMapper.toFirestore(notification);

    await addDoc(notificationsCollection, dto);
  }
}

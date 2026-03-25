import { Injectable, Inject } from '@angular/core';
import { NotificationEntity } from '../entities/notification.entity';
import { NOTIFICATION_REPOSITORY, NotificationRepository } from '../repositories/notification.repository';

@Injectable({
  providedIn: 'root'
})
export class SendNotificationUseCase {
  constructor(
    @Inject(NOTIFICATION_REPOSITORY) private readonly repository: NotificationRepository
  ) {}

  async execute(notification: NotificationEntity): Promise<void> {
    if (!notification.isValid()) {
      throw new Error('Invalid notification payload.');
    }
    
    // Execute use case action
    await this.repository.sendNotification(notification);
  }
}

import { NotificationEntity } from '../entities/notification.entity';
import { InjectionToken } from '@angular/core';

export interface NotificationRepository {
  sendNotification(notification: NotificationEntity): Promise<void>;
}

export const NOTIFICATION_REPOSITORY = new InjectionToken<NotificationRepository>('NotificationRepository');

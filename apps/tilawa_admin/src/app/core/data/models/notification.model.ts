import { NotificationEntity, NotificationTargetType } from '../../domain/entities/notification.entity';

export interface NotificationFirestoreDto {
  title: string;
  body: string;
  targetType: NotificationTargetType;
  targetUserIds: string[];
  createdAt: number; // Storing as timestamp epoch
  sentAt?: number | null;
  status: 'pending' | 'sent' | 'failed';
}

export class NotificationModelMapper {
  static toFirestore(entity: NotificationEntity): NotificationFirestoreDto {
    return {
      title: entity.title,
      body: entity.body,
      targetType: entity.targetType,
      targetUserIds: entity.targetUserIds,
      createdAt: entity.createdAt.getTime(),
      status: 'pending'
    };
  }
}

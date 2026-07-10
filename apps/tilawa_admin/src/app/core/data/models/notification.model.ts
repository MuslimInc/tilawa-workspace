import {
  NotificationEntity,
  NotificationTargetType,
} from '../../domain/entities/notification.entity';

export interface NotificationFirestoreDto {
  title: string;
  body: string;
  targetType: NotificationTargetType;
  targetUserIds: string[];
  createdAt: number; // Storing as timestamp epoch
  sentAt?: number | null;
  status: 'pending' | 'sent' | 'failed';
  actionType: string;
  actionData?: string;
}

export class NotificationModelMapper {
  static toFirestore(entity: NotificationEntity): NotificationFirestoreDto {
    const dto: NotificationFirestoreDto = {
      title: entity.title,
      body: entity.body,
      targetType: entity.targetType,
      targetUserIds: entity.targetUserIds,
      createdAt: entity.createdAt.getTime(),
      status: 'pending',
      actionType: entity.actionType,
    };

    if (entity.actionData !== undefined) {
      dto.actionData = entity.actionData;
    }

    return dto;
  }
}

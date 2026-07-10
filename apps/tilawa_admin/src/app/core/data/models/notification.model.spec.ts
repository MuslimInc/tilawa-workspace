import { describe, it, expect } from 'vitest';
import { NotificationEntity } from '../../domain/entities/notification.entity';
import { NotificationModelMapper } from './notification.model';

describe('NotificationModelMapper', () => {
  it('should map NotificationEntity to Firestore DTO correctly including deep-links', () => {
    // Arrange
    const entity = new NotificationEntity(
      'id-123',
      'Test Title',
      'Test Body',
      'selected',
      ['user-1', 'user-2'],
      new Date(1774188547356),
      'reciter',
      'mishary_rashid',
    );

    // Act
    const dto = NotificationModelMapper.toFirestore(entity);

    // Assert
    expect(dto.title).toBe('Test Title');
    expect(dto.body).toBe('Test Body');
    expect(dto.targetType).toBe('selected');
    expect(dto.targetUserIds).toEqual(['user-1', 'user-2']);
    expect(dto.actionType).toBe('reciter');
    expect(dto.actionData).toBe('mishary_rashid');
    expect(dto.status).toBe('pending');
    expect(dto.createdAt).toBe(1774188547356);
  });

  it('should use default actionType if not provided', () => {
    // Arrange
    const entity = new NotificationEntity(null, 'Title', 'Body', 'all', [], new Date());

    // Act
    const dto = NotificationModelMapper.toFirestore(entity);

    // Assert
    expect(dto.actionType).toBe('home');
    expect(dto.actionData).toBeUndefined();
  });
});

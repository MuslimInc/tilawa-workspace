export type NotificationTargetType = 'all' | 'single' | 'selected';

export class NotificationEntity {
  constructor(
    public readonly id: string | null,
    public readonly title: string,
    public readonly body: string,
    public readonly targetType: NotificationTargetType,
    public readonly targetUserIds: string[],
    public readonly createdAt: Date,
    public readonly actionType: string = 'home',
    public readonly actionData?: string
  ) {}

  // Domain logic validation
  isValid(): boolean {
    if (!this.title || this.title.trim().length === 0) return false;
    if (!this.body || this.body.trim().length === 0) return false;
    if (this.targetType !== 'all' && this.targetUserIds.length === 0) return false;
    return true;
  }
}

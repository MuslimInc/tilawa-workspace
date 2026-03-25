import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UserService } from '../../core/services/user.service';
import { NotificationModalComponent } from './components/notification-modal/notification-modal.component';
import { SendNotificationUseCase } from '../../core/domain/usecases/send-notification.usecase';
import { NotificationEntity, NotificationTargetType } from '../../core/domain/entities/notification.entity';
import { NOTIFICATION_REPOSITORY } from '../../core/domain/repositories/notification.repository';
import { NotificationRepositoryImpl } from '../../core/data/repositories/notification.repository.impl';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [CommonModule, FormsModule, NotificationModalComponent],
  templateUrl: './users.component.html',
  styleUrl: './users.css'
})
export class UsersComponent {
  private userService = inject(UserService);
  private sendNotificationUseCase = inject(SendNotificationUseCase);

  users$ = this.userService.getUsers();
  
  // Selection State
  selectedUserIds = new Set<string>();
  
  // Modal State
  isModalOpen = false;
  notificationTargetType: NotificationTargetType = 'all';
  notificationTargetSummary = '';

  toggleSelection(userId: string) {
    if (this.selectedUserIds.has(userId)) {
      this.selectedUserIds.delete(userId);
    } else {
      this.selectedUserIds.add(userId);
    }
  }

  isAllSelected(totalUsers: number): boolean {
    return totalUsers > 0 && this.selectedUserIds.size === totalUsers;
  }

  toggleSelectAll(users: any[]) {
    if (this.isAllSelected(users.length)) {
      this.selectedUserIds.clear();
    } else {
      users.forEach(u => this.selectedUserIds.add(u.id));
    }
  }

  openNotificationModal(type: NotificationTargetType, singleUserId?: string) {
    this.notificationTargetType = type;
    
    if (type === 'all') {
      this.notificationTargetSummary = 'All Users';
      this.selectedUserIds.clear(); // We don't need a specific set if targetType='all'
    } else if (type === 'single' && singleUserId) {
      this.notificationTargetSummary = 'Single User';
      this.selectedUserIds.clear();
      this.selectedUserIds.add(singleUserId);
    } else if (type === 'selected') {
      this.notificationTargetSummary = `${this.selectedUserIds.size} Selected User(s)`;
    }
    
    this.isModalOpen = true;
  }

  async onSendNotification(payload: { title: string; body: string; type: string; data?: string }) {
    try {
      const entity = new NotificationEntity(
        null,
        payload.title,
        payload.body,
        this.notificationTargetType,
        Array.from(this.selectedUserIds),
        new Date(),
        payload.type,
        payload.data
      );
      
      await this.sendNotificationUseCase.execute(entity);
      
      this.isModalOpen = false;
      this.selectedUserIds.clear();
    } catch (error) {
      console.error('Failed to send notification:', error);
      alert('Failed to trigger notification. See console for details.');
    }
  }
}

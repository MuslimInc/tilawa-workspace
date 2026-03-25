import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserService } from '../../core/services/user.service';

@Component({
  selector: 'app-dashboard',
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.css',
})
export class DashboardComponent {
  private userService = inject(UserService);
  usersCount$ = this.userService.getUsersCount();
}

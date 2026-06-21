import { Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

import { AuthFacade } from '../../../core/application/facades/auth.facade';
import {
  loadAdminLoginPreferences,
  saveAdminLoginPreferences,
} from '../../../core/auth/admin-login-preferences';
import { environment } from '../../../../environments/environment';

const defaultLogin = loadAdminLoginPreferences() ?? environment.devAdminLogin;

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
})
export class LoginComponent {
  private readonly authFacade = inject(AuthFacade);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  email = defaultLogin?.email ?? '';
  password = defaultLogin?.password ?? '';
  readonly submitting = signal(false);
  readonly errorMessage = signal<string | null>(
    this.route.snapshot.queryParamMap.get('error') === 'admin-required'
      ? 'Admin access required.'
      : null,
  );

  async onSubmit(): Promise<void> {
    this.submitting.set(true);
    this.errorMessage.set(null);

    try {
      await this.authFacade.signIn(this.email, this.password);

      if (!environment.production) {
        saveAdminLoginPreferences(this.email, this.password);
      }

      await this.router.navigateByUrl('/dashboard');
    } catch (error) {
      this.errorMessage.set(
        error instanceof Error ? error.message : 'Sign in failed.',
      );
    } finally {
      this.submitting.set(false);
    }
  }
}

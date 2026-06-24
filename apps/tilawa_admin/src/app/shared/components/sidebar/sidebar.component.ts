import { Component, inject, signal } from '@angular/core';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';

import { AuthFacade } from '../../../core/application/facades/auth.facade';
import { TranslatePipe } from '../../../core/i18n/translate.pipe';
import { environment } from '../../../../environments/environment';

@Component({
  selector: 'app-sidebar',
  imports: [RouterLink, RouterLinkActive, TranslatePipe],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.css',
})
export class SidebarComponent {
  private readonly authFacade = inject(AuthFacade);
  private readonly router = inject(Router);

  readonly session = this.authFacade.session;
  readonly quranSessionsExpanded = signal(true);
  readonly walletNavEnabled = environment.quranSessionsWalletEnabled;

  toggleQuranSessions(): void {
    this.quranSessionsExpanded.update((value) => !value);
  }

  signOut(): void {
    void this.authFacade.signOut().then(() => this.router.navigateByUrl('/login'));
  }
}

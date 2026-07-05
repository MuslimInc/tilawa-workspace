import { Component, OnInit, signal, inject } from '@angular/core';
import { RouterOutlet, Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { SidebarComponent } from '../../shared/components/sidebar/sidebar.component';
import { LanguageSwitcherComponent } from '../../shared/components/language-switcher/language-switcher.component';
import { ThemeSwitcherComponent } from '../../shared/components/theme-switcher/theme-switcher.component';
import { TranslatePipe } from '../../core/i18n/translate.pipe';

@Component({
  selector: 'app-admin-layout',
  imports: [
    RouterOutlet,
    SidebarComponent,
    LanguageSwitcherComponent,
    ThemeSwitcherComponent,
    TranslatePipe,
  ],
  templateUrl: './admin-layout.component.html',
  styleUrl: './admin-layout.component.css',
})
export class AdminLayoutComponent implements OnInit {
  private router = inject(Router);
  
  isMobileMenuOpen = signal<boolean>(false);

  ngOnInit() {
    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd)
    ).subscribe(() => {
      this.isMobileMenuOpen.set(false);
    });
  }

  toggleMobileMenu() {
    this.isMobileMenuOpen.update(val => !val);
  }

  closeMobileMenu() {
    this.isMobileMenuOpen.set(false);
  }
}

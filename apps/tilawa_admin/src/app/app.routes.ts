import { Routes } from '@angular/router';
import { AdminLayoutComponent } from './layouts/admin-layout/admin-layout.component';
import { adminGuard, authGuard, guestGuard } from './core/auth/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    canActivate: [guestGuard],
    loadComponent: () =>
      import('./features/auth/login/login.component').then((m) => m.LoginComponent),
  },
  {
    path: '',
    component: AdminLayoutComponent,
    canActivate: [authGuard, adminGuard],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
      },
      {
        path: 'reciters',
        loadComponent: () =>
          import('./features/reciters/reciters.component').then((m) => m.RecitersComponent),
      },
      {
        path: 'surahs',
        loadComponent: () =>
          import('./features/surahs/surahs.component').then((m) => m.SurahsComponent),
      },
      {
        path: 'users',
        loadComponent: () =>
          import('./features/users/users.component').then((m) => m.UsersComponent),
      },
      {
        path: 'quran-sessions/teacher-applications',
        loadComponent: () =>
          import('./features/quran-sessions/teacher-applications/teacher-applications.component').then(
            (m) => m.TeacherApplicationsComponent,
          ),
      },
      {
        path: 'quran-sessions/teacher-applications/:id',
        loadComponent: () =>
          import('./features/quran-sessions/teacher-application-detail/teacher-application-detail.component').then(
            (m) => m.TeacherApplicationDetailComponent,
          ),
      },
      {
        path: 'quran-sessions/teachers',
        loadComponent: () =>
          import('./features/quran-sessions/teachers/teachers.component').then(
            (m) => m.TeachersComponent,
          ),
      },
      {
        path: 'quran-sessions/users',
        loadComponent: () =>
          import('./features/quran-sessions/users/quran-sessions-users.component').then(
            (m) => m.QuranSessionsUsersComponent,
          ),
      },
      {
        path: 'quran-sessions/duplicate-accounts',
        loadComponent: () =>
          import('./features/quran-sessions/duplicate-accounts/duplicate-accounts.component').then(
            (m) => m.DuplicateAccountsComponent,
          ),
      },
      {
        path: 'quran-sessions/sessions',
        loadComponent: () =>
          import('./features/quran-sessions/sessions/sessions.component').then(
            (m) => m.SessionsComponent,
          ),
      },
      {
        path: 'quran-sessions/active-sessions',
        loadComponent: () =>
          import('./features/quran-sessions/active-sessions/active-sessions.component').then(
            (m) => m.ActiveSessionsComponent,
          ),
      },
      {
        // Lazy-loaded: the session detail screen (incl. call tracking) is
        // pulled into its own chunk, keeping it out of the initial bundle.
        path: 'quran-sessions/sessions/:id',
        loadComponent: () =>
          import('./features/quran-sessions/session-detail/session-detail.component').then(
            (m) => m.SessionDetailComponent,
          ),
      },
      {
        path: 'quran-sessions/create-test-session',
        loadComponent: () =>
          import('./features/quran-sessions/create-test-session/create-test-session.component').then(
            (m) => m.CreateTestSessionComponent,
          ),
      },
      {
        path: 'quran-sessions/reports',
        loadComponent: () =>
          import('./features/quran-sessions/session-reports/session-reports.component').then(
            (m) => m.SessionReportsComponent,
          ),
      },
      {
        path: 'quran-sessions/reports/:id',
        loadComponent: () =>
          import('./features/quran-sessions/session-report-detail/session-report-detail.component').then(
            (m) => m.SessionReportDetailComponent,
          ),
      },
      {
        path: 'quran-sessions/disputes',
        loadComponent: () =>
          import('./features/quran-sessions/session-disputes/session-disputes.component').then(
            (m) => m.SessionDisputesComponent,
          ),
      },
      {
        path: 'quran-sessions/disputes/:id',
        loadComponent: () =>
          import('./features/quran-sessions/session-dispute-detail/session-dispute-detail.component').then(
            (m) => m.SessionDisputeDetailComponent,
          ),
      },
      {
        path: 'quran-sessions/wallets/:userId',
        loadComponent: () =>
          import('./features/quran-sessions/user-wallets/user-wallets.component').then(
            (m) => m.UserWalletsComponent,
          ),
      },
      {
        path: 'quran-sessions/wallets',
        loadComponent: () =>
          import('./features/quran-sessions/user-wallets/user-wallets.component').then(
            (m) => m.UserWalletsComponent,
          ),
      },
      {
        path: 'quran-sessions/market-pricing',
        loadComponent: () =>
          import('./features/quran-sessions/market-pricing/market-pricing.component').then(
            (m) => m.MarketPricingComponent,
          ),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];

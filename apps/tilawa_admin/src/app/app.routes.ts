import { Routes } from '@angular/router';
import { AdminLayoutComponent } from './layouts/admin-layout/admin-layout.component';
import { DashboardComponent } from './features/dashboard/dashboard.component';
import { RecitersComponent } from './features/reciters/reciters.component';
import { SurahsComponent } from './features/surahs/surahs.component';
import { UsersComponent } from './features/users/users.component';
import { LoginComponent } from './features/auth/login/login.component';
import { TeacherApplicationsComponent } from './features/quran-sessions/teacher-applications/teacher-applications.component';
import { TeachersComponent } from './features/quran-sessions/teachers/teachers.component';
import { QuranSessionsUsersComponent } from './features/quran-sessions/users/quran-sessions-users.component';
import { SessionsComponent } from './features/quran-sessions/sessions/sessions.component';
import { SessionReportsComponent } from './features/quran-sessions/session-reports/session-reports.component';
import { SessionDisputesComponent } from './features/quran-sessions/session-disputes/session-disputes.component';
import { UserWalletsComponent } from './features/quran-sessions/user-wallets/user-wallets.component';
import { adminGuard, authGuard, guestGuard } from './core/auth/auth.guard';

export const routes: Routes = [
  { path: 'login', component: LoginComponent, canActivate: [guestGuard] },
  {
    path: '',
    component: AdminLayoutComponent,
    canActivate: [authGuard, adminGuard],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: DashboardComponent },
      { path: 'reciters', component: RecitersComponent },
      { path: 'surahs', component: SurahsComponent },
      { path: 'users', component: UsersComponent },
      {
        path: 'quran-sessions/teacher-applications',
        component: TeacherApplicationsComponent,
      },
      {
        path: 'quran-sessions/teacher-applications/:id',
        loadComponent: () =>
          import(
            './features/quran-sessions/teacher-application-detail/teacher-application-detail.component'
          ).then((m) => m.TeacherApplicationDetailComponent),
      },
      { path: 'quran-sessions/teachers', component: TeachersComponent },
      { path: 'quran-sessions/users', component: QuranSessionsUsersComponent },
      { path: 'quran-sessions/sessions', component: SessionsComponent },
      {
        path: 'quran-sessions/active-sessions',
        loadComponent: () =>
          import(
            './features/quran-sessions/active-sessions/active-sessions.component'
          ).then((m) => m.ActiveSessionsComponent),
      },
      {
        // Lazy-loaded: the session detail screen (incl. call tracking) is
        // pulled into its own chunk, keeping it out of the initial bundle.
        path: 'quran-sessions/sessions/:id',
        loadComponent: () =>
          import(
            './features/quran-sessions/session-detail/session-detail.component'
          ).then((m) => m.SessionDetailComponent),
      },
      {
        path: 'quran-sessions/create-test-session',
        loadComponent: () =>
          import(
            './features/quran-sessions/create-test-session/create-test-session.component'
          ).then((m) => m.CreateTestSessionComponent),
      },
      { path: 'quran-sessions/reports', component: SessionReportsComponent },
      {
        path: 'quran-sessions/reports/:id',
        loadComponent: () =>
          import(
            './features/quran-sessions/session-report-detail/session-report-detail.component'
          ).then((m) => m.SessionReportDetailComponent),
      },
      { path: 'quran-sessions/disputes', component: SessionDisputesComponent },
      {
        path: 'quran-sessions/disputes/:id',
        loadComponent: () =>
          import(
            './features/quran-sessions/session-dispute-detail/session-dispute-detail.component'
          ).then((m) => m.SessionDisputeDetailComponent),
      },
      {
        path: 'quran-sessions/wallets/:userId',
        component: UserWalletsComponent,
      },
      { path: 'quran-sessions/wallets', component: UserWalletsComponent },
    ],
  },
  { path: '**', redirectTo: '' },
];

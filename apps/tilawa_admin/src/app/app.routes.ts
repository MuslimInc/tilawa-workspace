import { Routes } from '@angular/router';
import { AdminLayoutComponent } from './layouts/admin-layout/admin-layout.component';
import { DashboardComponent } from './features/dashboard/dashboard.component';
import { RecitersComponent } from './features/reciters/reciters.component';
import { SurahsComponent } from './features/surahs/surahs.component';
import { UsersComponent } from './features/users/users.component';
import { LoginComponent } from './features/auth/login/login.component';
import { TeacherApplicationsComponent } from './features/quran-sessions/teacher-applications/teacher-applications.component';
import { TeacherApplicationDetailComponent } from './features/quran-sessions/teacher-application-detail/teacher-application-detail.component';
import { TeachersComponent } from './features/quran-sessions/teachers/teachers.component';
import { QuranSessionsUsersComponent } from './features/quran-sessions/users/quran-sessions-users.component';
import { SessionsComponent } from './features/quran-sessions/sessions/sessions.component';
import { SessionDetailComponent } from './features/quran-sessions/session-detail/session-detail.component';
import { SessionReportsComponent } from './features/quran-sessions/session-reports/session-reports.component';
import { SessionReportDetailComponent } from './features/quran-sessions/session-report-detail/session-report-detail.component';
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
        component: TeacherApplicationDetailComponent,
      },
      { path: 'quran-sessions/teachers', component: TeachersComponent },
      { path: 'quran-sessions/users', component: QuranSessionsUsersComponent },
      { path: 'quran-sessions/sessions', component: SessionsComponent },
      {
        path: 'quran-sessions/sessions/:id',
        component: SessionDetailComponent,
      },
      { path: 'quran-sessions/reports', component: SessionReportsComponent },
      {
        path: 'quran-sessions/reports/:id',
        component: SessionReportDetailComponent,
      },
    ],
  },
  { path: '**', redirectTo: '' },
];

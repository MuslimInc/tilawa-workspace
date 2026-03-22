import { Routes } from '@angular/router';
import { AdminLayoutComponent } from './layouts/admin-layout/admin-layout.component';
import { DashboardComponent } from './features/dashboard/dashboard.component';
import { RecitersComponent } from './features/reciters/reciters.component';
import { SurahsComponent } from './features/surahs/surahs.component';
import { UsersComponent } from './features/users/users.component';

export const routes: Routes = [
  {
    path: '',
    component: AdminLayoutComponent,
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      { path: 'dashboard', component: DashboardComponent },
      { path: 'reciters', component: RecitersComponent },
      { path: 'surahs', component: SurahsComponent },
      { path: 'users', component: UsersComponent },
    ]
  },
  { path: '**', redirectTo: '' }
];

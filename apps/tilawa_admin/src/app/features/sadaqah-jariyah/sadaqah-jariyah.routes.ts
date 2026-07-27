import { Routes } from '@angular/router';

export const SADAQAH_JARIYAH_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./list/sadaqah-jariyah-list.component').then(
        (m) => m.SadaqahJariyahListComponent,
      ),
  },
  {
    path: 'config',
    loadComponent: () =>
      import('./config/sadaqah-jariyah-config.component').then(
        (m) => m.SadaqahJariyahConfigComponent,
      ),
  },
  {
    path: 'new',
    loadComponent: () =>
      import('./edit/sadaqah-jariyah-edit.component').then(
        (m) => m.SadaqahJariyahEditComponent,
      ),
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./edit/sadaqah-jariyah-edit.component').then(
        (m) => m.SadaqahJariyahEditComponent,
      ),
  },
];

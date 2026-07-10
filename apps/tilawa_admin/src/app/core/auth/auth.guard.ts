import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { Auth, authState } from '@angular/fire/auth';
import { from, of } from 'rxjs';
import { map, switchMap, take } from 'rxjs/operators';

export const authGuard: CanActivateFn = () => {
  const auth = inject(Auth);
  const router = inject(Router);

  return authState(auth).pipe(
    take(1),
    map((user) => (user ? true : router.createUrlTree(['/login']))),
  );
};

export const adminGuard: CanActivateFn = () => {
  const auth = inject(Auth);
  const router = inject(Router);

  return authState(auth).pipe(
    take(1),
    switchMap((user) => {
      if (!user) {
        return of(router.createUrlTree(['/login']));
      }

      return from(user.getIdTokenResult()).pipe(
        map((token) =>
          token.claims['admin'] === true
            ? true
            : router.createUrlTree(['/login'], {
                queryParams: { error: 'admin-required' },
              }),
        ),
      );
    }),
  );
};

export const guestGuard: CanActivateFn = () => {
  const auth = inject(Auth);
  const router = inject(Router);

  return authState(auth).pipe(
    take(1),
    switchMap((user) => {
      if (!user) {
        return of(true);
      }

      return from(user.getIdTokenResult()).pipe(
        map((token) =>
          token.claims['admin'] === true ? router.createUrlTree(['/dashboard']) : true,
        ),
      );
    }),
  );
};

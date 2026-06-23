export enum QuranSessionsAccountStatus {
  Active = 'active',
  UnderReview = 'underReview',
  Suspended = 'suspended',
  Blocked = 'blocked',
}

export enum UserGender {
  Male = 'male',
  Female = 'female',
}

/** Quran Sessions slice of a Tilawa user — no Firebase types. */
export interface QuranSessionsUser {
  readonly userId: string;
  readonly email: string | null;
  readonly displayName: string | null;
  readonly avatarUrl: string | null;
  readonly gender: UserGender | null;
  readonly countryCode: string | null;
  readonly countryName: string | null;
  readonly cityId: string | null;
  readonly cityName: string | null;
  readonly profileCompleted: boolean;
  readonly accountStatus: QuranSessionsAccountStatus;
  readonly createdAt: Date | null;
  readonly updatedAt: Date | null;
}

export interface QuranSessionsUserFilters {
  readonly countryCode?: string | null;
  readonly cityId?: string | null;
  readonly gender?: UserGender | null;
  readonly profileCompleted?: boolean | null;
  readonly accountStatus?: QuranSessionsAccountStatus | null;
  readonly search?: string | null;
}

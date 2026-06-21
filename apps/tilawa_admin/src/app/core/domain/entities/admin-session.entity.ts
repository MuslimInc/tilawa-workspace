/** Backend-agnostic authenticated admin session. */
export interface AdminSession {
  readonly uid: string;
  readonly email: string | null;
  readonly displayName: string | null;
  readonly isAdmin: boolean;
}

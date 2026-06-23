import { InjectionToken } from '@angular/core';

import { UserWalletDetail } from '../entities/user-wallet-summary.entity';

export interface WalletReadRepository {
  getByUserId(userId: string): Promise<UserWalletDetail>;
}

export const WALLET_READ_REPOSITORY = new InjectionToken<WalletReadRepository>(
  'WalletReadRepository',
);

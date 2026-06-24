import { InjectionToken } from '@angular/core';

import {
  UserWalletDetail,
} from '../entities/user-wallet-summary.entity';
import { PageRequest } from '../entities/pagination.types';

export interface WalletReadRepository {
  getByUserId(
    userId: string,
    transactionsPage?: PageRequest,
  ): Promise<UserWalletDetail>;
}

export const WALLET_READ_REPOSITORY = new InjectionToken<WalletReadRepository>(
  'WalletReadRepository',
);

import { Injectable, inject } from '@angular/core';

import { UserWalletDetail } from '../entities/user-wallet-summary.entity';
import { PageRequest } from '../entities/pagination.types';
import {
  WALLET_READ_REPOSITORY,
  WalletReadRepository,
} from '../repositories/wallet-read.repository';

@Injectable({ providedIn: 'root' })
export class GetUserWalletUseCase {
  private readonly repository = inject(WALLET_READ_REPOSITORY);

  execute(
    userId: string,
    transactionsPage?: PageRequest,
  ): Promise<UserWalletDetail> {
    return this.repository.getByUserId(userId, transactionsPage);
  }
}

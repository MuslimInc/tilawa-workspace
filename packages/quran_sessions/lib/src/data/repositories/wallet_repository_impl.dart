import 'package:dartz_plus/dartz_plus.dart';

import '../../domain/failures/quran_sessions_failure.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';
import '../mappers/wallet_mapper.dart';
import 'repository_error_mapper.dart';

class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._remote);

  final WalletRemoteDataSource _remote;

  @override
  Future<Either<QuranSessionsFailure, WalletSnapshot>> getWalletSnapshot(
    String userId,
  ) async {
    try {
      final dto = await _remote.getWalletSnapshot(userId);
      return Right(
        WalletSnapshot(
          userId: dto.userId,
          wallet: WalletMapper.toEntity(dto.wallet),
          transactions: dto.transactions
              .map(WalletMapper.toTransactionEntity)
              .toList(),
        ),
      );
    } on Exception catch (error) {
      return Left(mapRemoteException(error));
    }
  }
}

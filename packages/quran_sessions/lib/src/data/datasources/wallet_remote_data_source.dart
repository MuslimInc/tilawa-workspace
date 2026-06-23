import '../dtos/wallet_dto.dart';

/// Remote contract for wallet reads. Implemented in the host app (Firestore).
abstract interface class WalletRemoteDataSource {
  Future<WalletSnapshotDto> getWalletSnapshot(String userId);
}

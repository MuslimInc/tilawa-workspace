import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quran_sessions/quran_sessions.dart';

import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

DateTime? _readTimestamp(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

double _readAmount(Object? value) {
  if (value is num) return value.toDouble();
  return 0;
}

class FirestoreWalletDataSource implements WalletRemoteDataSource {
  const FirestoreWalletDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<WalletSnapshotDto> getWalletSnapshot(String userId) async {
    try {
      final walletId = 'wallet_$userId';
      final walletSnap = await _firestore
          .collection(FirestoreQuranSessionsPaths.userWallets)
          .doc(walletId)
          .get();

      final transactionsSnap = await _firestore
          .collection(FirestoreQuranSessionsPaths.walletTransactions)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return WalletSnapshotDto(
        userId: userId,
        wallet: walletSnap.exists
            ? _mapWallet(walletSnap.id, walletSnap.data() ?? const {})
            : null,
        transactions: transactionsSnap.docs
            .map((doc) => _mapTransaction(doc.id, doc.data()))
            .toList(),
      );
    } on FirebaseException catch (error) {
      throw mapFirebaseException(error);
    }
  }

  WalletDto _mapWallet(String walletId, Map<String, dynamic> data) {
    return WalletDto(
      walletId: walletId,
      userId: data['userId'] as String? ?? '',
      currency: data['currency'] as String? ?? 'EGP',
      status: data['status'] as String? ?? 'active',
      availableBalance: _readAmount(data['availableBalance']),
      heldBalance: _readAmount(data['heldBalance']),
      lastTransactionAt: _readTimestamp(data['lastTransactionAt']),
    );
  }

  WalletTransactionDto _mapTransaction(
    String transactionId,
    Map<String, dynamic> data,
  ) {
    return WalletTransactionDto(
      transactionId: transactionId,
      walletId: data['walletId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? 'refund_credit',
      direction: data['direction'] as String? ?? 'credit',
      amount: _readAmount(data['amount']),
      currency: data['currency'] as String? ?? 'EGP',
      description: data['description'] as String? ?? '',
      createdAt: _readTimestamp(data['createdAt']) ?? DateTime.now(),
      balanceAfter: data['balanceAfter'] == null
          ? null
          : _readAmount(data['balanceAfter']),
      sourceId: data['sourceId'] as String?,
    );
  }
}

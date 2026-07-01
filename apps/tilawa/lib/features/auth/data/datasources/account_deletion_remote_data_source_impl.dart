import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

import 'account_deletion_remote_data_source.dart';

@LazySingleton(as: AccountDeletionRemoteDataSource)
class AccountDeletionRemoteDataSourceImpl
    implements AccountDeletionRemoteDataSource {
  AccountDeletionRemoteDataSourceImpl(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<AccountDeletionRequestResult> requestSelfAccountDeletion({
    required String reason,
    required String confirmEmail,
  }) async {
    final callable = _functions.httpsCallable('requestSelfAccountDeletion');
    final response = await callable.call<Map<String, dynamic>>({
      'reason': reason,
      'confirmEmail': confirmEmail,
    });

    final data = response.data;
    return AccountDeletionRequestResult(
      status: data['status'] as String? ?? 'pending_deletion',
      purgeAfter: data['purgeAfter'] as String? ?? '',
    );
  }
}

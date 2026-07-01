class AccountDeletionRequestResult {
  const AccountDeletionRequestResult({
    required this.status,
    required this.purgeAfter,
  });

  final String status;
  final String purgeAfter;
}

abstract class AccountDeletionRemoteDataSource {
  Future<AccountDeletionRequestResult> requestSelfAccountDeletion({
    required String reason,
    required String confirmEmail,
  });
}

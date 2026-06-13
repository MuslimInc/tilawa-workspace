import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/constants/support_product_ids.dart';

/// Server-side Google Play purchase verification via Cloud Function.
abstract class PurchaseVerificationClient {
  Future<VerifiedPurchase> verify({
    required String productId,
    required String purchaseToken,
  });
}

class VerifiedPurchase {
  const VerifiedPurchase({
    required this.orderId,
    required this.productId,
  });

  final String orderId;
  final String productId;
}

@LazySingleton(as: PurchaseVerificationClient)
class FirebasePurchaseVerificationClient implements PurchaseVerificationClient {
  FirebasePurchaseVerificationClient(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<VerifiedPurchase> verify({
    required String productId,
    required String purchaseToken,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'verifySupportPurchase',
      );
      final HttpsCallableResult<Map<String, dynamic>> result = await callable
          .call<Map<String, dynamic>>(<String, String>{
            'productId': productId,
            'purchaseToken': purchaseToken,
            'packageName': SupportProductIds.androidPackageName,
          });
      final Map<String, dynamic> data = result.data;
      final bool verified = data['verified'] == true;
      if (!verified) {
        throw const PurchaseFailure.verificationFailed();
      }
      final String orderId = data['orderId'] as String? ?? '';
      return VerifiedPurchase(orderId: orderId, productId: productId);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        throw const PurchaseFailure.alreadyOwned();
      }
      throw PurchaseFailure(
        e.message,
        PurchaseFailureReason.verificationFailed,
      );
    } on PurchaseFailure {
      rethrow;
    } catch (e) {
      throw PurchaseFailure(e.toString(), PurchaseFailureReason.network);
    }
  }
}

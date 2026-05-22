import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tilawa/features/support/domain/constants/support_product_ids.dart';

PurchaseDetails supportPurchaseDetails({
  String productId = SupportProductIds.small,
  String serverToken = 'test-purchase-token',
  PurchaseStatus status = PurchaseStatus.purchased,
  bool pendingCompletePurchase = true,
}) {
  final PurchaseDetails details = PurchaseDetails(
    productID: productId,
    status: status,
    transactionDate: '2026-05-22',
    purchaseID: 'test-order-id',
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: serverToken,
      source: 'google_play',
    ),
  );
  details.pendingCompletePurchase = pendingCompletePurchase;
  return details;
}

ProductDetails supportProductDetails({
  String id = SupportProductIds.small,
  String price = r'$2.99',
  double rawPrice = 2.99,
}) {
  return ProductDetails(
    id: id,
    title: id,
    description: 'Support tier',
    price: price,
    rawPrice: rawPrice,
    currencyCode: 'USD',
  );
}

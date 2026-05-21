import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/support_product.dart';

part 'support_state.freezed.dart';

enum SupportStatus {
  initial,
  loading,
  ready,
  error,
}

enum SupportPurchasePhase {
  idle,
  confirming,
  purchasing,
  thanked,
}

@freezed
abstract class SupportState with _$SupportState {
  const factory SupportState({
    @Default(SupportStatus.initial) SupportStatus status,
    @Default(SupportPurchasePhase.idle) SupportPurchasePhase purchasePhase,
    @Default(<SupportProduct>[]) List<SupportProduct> products,
    String? selectedProductId,
    String? errorMessage,
    String? thankYouProductId,
    @Default(false) bool isOffline,
  }) = _SupportState;
}

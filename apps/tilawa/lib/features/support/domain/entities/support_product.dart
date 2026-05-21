import 'package:equatable/equatable.dart';

/// A one-time support tier offered via Google Play.
class SupportProduct extends Equatable {
  const SupportProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.displayOrder,
  });

  final String id;
  final String title;
  final String price;
  final double rawPrice;
  final String currencyCode;
  final int displayOrder;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    price,
    rawPrice,
    currencyCode,
    displayOrder,
  ];
}

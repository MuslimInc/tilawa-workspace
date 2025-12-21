import 'package:equatable/equatable.dart';

class AthkarItem extends Equatable {
  const AthkarItem({
    required this.id,
    required this.categoryId,
    required this.textAr,
    required this.textEn,
    required this.count,
    required this.reference,
  });

  const AthkarItem.empty()
    : id = 0,
      categoryId = 0,
      textAr = '',
      textEn = '',
      count = 0,
      reference = '';
  final int id;
  final int categoryId;
  final String textAr;
  final String textEn;
  final int count;
  final String reference;

  @override
  List<Object?> get props => [id, categoryId, textAr, textEn, count, reference];
}

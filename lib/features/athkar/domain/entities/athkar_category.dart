import 'package:equatable/equatable.dart';

class AthkarCategory extends Equatable {
  const AthkarCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
  });

  const AthkarCategory.empty() : id = 0, nameAr = '', nameEn = '', icon = '';
  final int id;
  final String nameAr;
  final String nameEn;
  final String icon;

  @override
  List<Object?> get props => [id, nameAr, nameEn, icon];
}

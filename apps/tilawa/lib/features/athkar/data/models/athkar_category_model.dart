import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/athkar_category.dart';

part 'athkar_category_model.freezed.dart';
part 'athkar_category_model.g.dart';

@freezed
abstract class AthkarCategoryModel extends AthkarCategory
    with _$AthkarCategoryModel {
  const factory AthkarCategoryModel({
    required int id,
    @JsonKey(name: 'name_ar') required String nameAr,
    @JsonKey(name: 'name_en') required String nameEn,
    required String icon,
  }) = _AthkarCategoryModel;
  const AthkarCategoryModel._() : super.empty();

  factory AthkarCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$AthkarCategoryModelFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/athkar_item.dart';

part 'athkar_item_model.freezed.dart';
part 'athkar_item_model.g.dart';

@freezed
abstract class AthkarItemModel extends AthkarItem with _$AthkarItemModel {
  const factory AthkarItemModel({
    required int id,
    @JsonKey(name: 'category_id') required int categoryId,
    @JsonKey(name: 'text_ar') required String textAr,
    @JsonKey(name: 'text_en') required String textEn,
    required int count,
    required String reference,
  }) = _AthkarItemModel;
  const AthkarItemModel._() : super.empty();

  factory AthkarItemModel.fromJson(Map<String, dynamic> json) =>
      _$AthkarItemModelFromJson(json);
}

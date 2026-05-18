// US1 옷 등록 폼 state. freezed 불변 모델.

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/item.dart';

part 'new_item_draft.freezed.dart';

@freezed
class NewItemDraft with _$NewItemDraft {
  const factory NewItemDraft({
    @Default('') String name,
    @Default('') String brand,
    @Default(Category.outer) Category category,
    @Default(5) int washCycle,
    @Default(CareMethod.machine) CareMethod careMethod,
    DateTime? purchasedAt,
    File? tempPhoto,
  }) = _NewItemDraft;

  const NewItemDraft._();

  /// FR-002 — 명칭이 비어 있으면 저장 불가.
  bool get canSave => name.trim().isNotEmpty;
}

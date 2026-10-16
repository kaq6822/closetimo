// US1 옷 등록 폼 state. freezed 불변 모델.

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/item.dart';

part 'new_item_draft.freezed.dart';

@freezed
abstract class NewItemDraft with _$NewItemDraft {
  const factory NewItemDraft({
    @Default('') String name,
    @Default('') String brand,
    // 2026-10-16 #42 — 카테고리 미선택은 `기타`(미분류)로 저장한다.
    @Default(Category.etc) Category category,
    @Default(5) int washCycle,
    @Default(CareMethod.machine) CareMethod careMethod,
    DateTime? purchasedAt,
    File? tempPhoto,
  }) = _NewItemDraft;

  const NewItemDraft._();

  /// 002 FR-001 — 수정 화면 prefill용. 기존 [Item]의 편집 가능 필드로 draft를
  /// 초기화한다. 사진(`tempPhoto`)은 새로 선택한 파일만 담으므로 null로 두고,
  /// 기존 `imagePath` 표시는 화면 로컬 상태에서 관리한다.
  factory NewItemDraft.fromItem(Item item) => NewItemDraft(
    name: item.name,
    brand: item.brand ?? '',
    category: item.category,
    washCycle: item.washCycle,
    careMethod: item.careMethod,
    purchasedAt: item.purchasedAt,
  );

  /// 사진만으로 등록할 때 채우는 기본 명칭(FR-002, 2026-10-16 #42).
  static const untitledName = '이름 없는 옷';

  /// FR-002 — 명칭이 비어 있으면 저장 불가(수정 모드 기준).
  bool get canSave => name.trim().isNotEmpty;

  /// FR-002 — 등록 모드는 명칭 또는 사진 중 하나만 있으면 저장할 수 있다.
  bool get canQuickSave => canSave || tempPhoto != null;

  /// 등록 저장용 draft. 명칭이 비어 있으면 [untitledName]으로 채운다.
  /// 저장소의 `name.isNotEmpty` 규칙은 그대로 유지된다.
  NewItemDraft forCreate() =>
      canSave ? this : copyWith(name: untitledName);
}

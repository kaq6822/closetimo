// US1 옷 등록 폼 state. freezed 불변 모델.

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/item.dart';
import '../../data/models/item_attributes.dart';

part 'new_item_draft.freezed.dart';

@freezed
abstract class NewItemDraft with _$NewItemDraft {
  const factory NewItemDraft({
    @Default('') String name,
    @Default('') String brand,
    // #41 — 종류를 고르지 않은 옷이 아우터로 집계되지 않도록 미분류가 기본값.
    // #42 빠른 등록도 이 미분류 기본값 위에서 동작한다.
    @Default(Category.uncategorized) Category category,
    @Default(<ItemPurpose>[]) List<ItemPurpose> purposes,
    @Default(5) int washCycle,
    @Default(CareMode.wearCycle) CareMode careMode,
    // #45 — 관리 방법을 임의로 가정하지 않는다.
    @Default(CareMethod.unspecified) CareMethod careMethod,
    DateTime? purchasedAt,
    File? tempPhoto,
    // #46 — 사용자 태그(선택). 저장 시 repository가 정규화한다.
    @Default(<String>[]) List<String> tags,
    // 005 — 구조화 속성(선택). 저장 시 repository가 카탈로그 기준으로 정규화한다.
    String? subType,
    @Default(<String>[]) List<String> colors,
    @Default(<Season>[]) List<Season> seasons,
    String? material,
    String? pattern,
    // 005 FR-513 — 사진 분석이 만든 배경 제거본 임시 파일(iOS 17+). 원본은 [tempPhoto].
    File? tempCutout,
  }) = _NewItemDraft;

  const NewItemDraft._();

  /// 002 FR-001 — 수정 화면 prefill용. 기존 [Item]의 편집 가능 필드로 draft를
  /// 초기화한다. 사진(`tempPhoto`)은 새로 선택한 파일만 담으므로 null로 두고,
  /// 기존 `imagePath` 표시는 화면 로컬 상태에서 관리한다.
  factory NewItemDraft.fromItem(Item item) => NewItemDraft(
    name: item.name,
    brand: item.brand ?? '',
    category: item.category,
    purposes: List.unmodifiable(item.purposes),
    washCycle: item.washCycle,
    careMode: item.careMode,
    careMethod: item.careMethod,
    purchasedAt: item.purchasedAt,
    tags: List.unmodifiable(item.tags),
    subType: item.subType,
    colors: List.unmodifiable(item.colors),
    seasons: List.unmodifiable(item.seasons),
    material: item.material,
    pattern: item.pattern,
  );

  /// 이름도 속성도 없을 때 채우는 기본 명칭(FR-002, 2026-10-16 #42).
  static const untitledName = untitledItemName;

  /// FR-002 — 명칭이 비어 있으면 저장 불가(수정 모드 기준).
  bool get canSave => name.trim().isNotEmpty;

  /// FR-002 — 등록 모드는 명칭 또는 사진 중 하나만 있으면 저장할 수 있다.
  /// 005 FR-502 — 자동 이름을 만들 속성(종류·세부 종류·색상)만 있어도 된다.
  bool get canQuickSave =>
      canSave || tempPhoto != null || autoName != untitledName;

  /// 지금 속성으로 만든 자동 이름(005 FR-502).
  String get autoName =>
      autoItemName(category: category, subType: subType, colors: colors);

  /// 등록 저장용 draft. 명칭이 비어 있으면 [autoName]으로 채운다.
  /// 저장소의 `name.isNotEmpty` 규칙은 그대로 유지된다.
  NewItemDraft forCreate() => canSave ? this : copyWith(name: autoName);

  /// 속성 값만 모은 것. 수정 저장([ItemPatch.attributes])에 쓴다.
  ItemAttributeValues get attributes => ItemAttributeValues(
    subType: subType,
    colors: colors,
    seasons: seasons,
    material: material,
    pattern: pattern,
  );
}

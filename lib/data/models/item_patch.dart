// 002 T001 — 옷 정보 수정 요청 DTO. 영속화 대상이 아닌 in-memory 값 객체다.
// data-model.md §3 / contracts/repositories.md §1 참조.

import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'item.dart';

part 'item_patch.freezed.dart';

@freezed
class ItemPatch with _$ItemPatch {
  const factory ItemPatch({
    required String name,
    String? brand,
    required Category category,
    required CareMethod careMethod,
    required int washCycle,
    DateTime? purchasedAt,

    /// 새로 선택한 사진. null이 아니면 sandbox 사본을 교체한다([removePhoto]보다 우선).
    File? newPhoto,

    /// true면 기존 사진을 제거하고 기본 플레이스홀더로 되돌린다.
    @Default(false) bool removePhoto,
  }) = _ItemPatch;

  const ItemPatch._();

  /// FR-003 — 명칭이 비어 있으면 저장 불가(등록과 동일 규칙).
  bool get canSave => name.trim().isNotEmpty;
}

// data-model.md §3 UserPreferences (single-row 컬렉션). FR-022.

import 'package:isar/isar.dart';

part 'user_preferences.g.dart';

@collection
class UserPreferences {
  UserPreferences({
    this.notifWash = true,
    this.notifWeekly = true,
    this.notifUnworn = false,
    this.accent = 'sage',
    this.lastTab,
    this.firstLaunchedAt,
  });

  factory UserPreferences.defaults() => UserPreferences();

  /// 단일 행 보장을 위한 고정 ID.
  static const int singletonId = 0;

  Id id = singletonId;

  bool notifWash;
  bool notifWeekly;
  bool notifUnworn;
  String accent;
  String? lastTab;

  /// 설정 화면 "2025.04부터 함께한 지 N개월" 계산 기준.
  DateTime? firstLaunchedAt;
}

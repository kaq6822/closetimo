// data-model.md §3 UserPreferences (single-row 컬렉션). FR-022.

import 'package:isar_plus/isar_plus.dart';

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
    this.removeBackground = true,
    this.onDeviceAi = false,
  });

  factory UserPreferences.defaults() => UserPreferences();

  /// 단일 행 보장을 위한 고정 ID.
  static const int singletonId = 0;

  int id = singletonId;

  bool notifWash;
  bool notifWeekly;
  bool notifUnworn;
  String accent;
  String? lastTab;

  /// 설정 화면 "2025.04부터 함께한 지 N개월" 계산 기준.
  DateTime? firstLaunchedAt;

  // ── 005 사진 분석 설정. 필드가 없는 구 데이터는 constructor 기본값으로 읽힌다. ──

  /// iOS 17+ 사진 배경 자동 제거(FR-513). 기본 켜짐.
  bool removeBackground;

  /// iOS 27 기기 내 AI 분석(FR-515). 기본 꺼짐이며 지원 기기에서만 노출한다.
  bool onDeviceAi;
}

// contracts/repositories.md §4.

import '../models/user_preferences.dart';

abstract interface class PreferencesRepository {
  Stream<UserPreferences> watch();
  Future<void> setNotifWash(bool v);
  Future<void> setNotifWeekly(bool v);
  Future<void> setNotifUnworn(bool v);
  Future<void> setAccent(String accentKey);
  Future<void> setLastTab(String tab);

  /// 005 FR-513 — 사진 배경 자동 제거(iOS 17+).
  Future<void> setRemoveBackground(bool v);

  /// 005 FR-515 — 기기 내 AI 분석(iOS 27+, Apple Intelligence).
  Future<void> setOnDeviceAi(bool v);
}

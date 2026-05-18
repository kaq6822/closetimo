// 단일 Isar 인스턴스 Riverpod provider. 앱 부트(main.dart)에서 watch하여
// 데이터 레이어 전체에 주입한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/item.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/wear_event.dart';
import '../utils/clock.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ItemSchema, WearEventSchema, UserPreferencesSchema],
    directory: dir.path,
    name: 'closetimo',
    inspector: false,
  );
  await _ensureDefaultPreferences(isar, ref.read(clockProvider));
  return isar;
});

/// 첫 부트 시 UserPreferences singleton(id=0)이 존재하지 않으면 생성하고,
/// firstLaunchedAt을 지금 시각으로 시드한다(설정 화면 "N개월 함께한" 카피용).
Future<void> _ensureDefaultPreferences(Isar isar, Clock clock) async {
  final existing = await isar.userPreferences.get(UserPreferences.singletonId);
  if (existing != null) return;
  await isar.writeTxn(() async {
    final prefs = UserPreferences.defaults()
      ..firstLaunchedAt = clock.now();
    await isar.userPreferences.put(prefs);
  });
}

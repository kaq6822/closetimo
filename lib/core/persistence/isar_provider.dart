// 단일 Isar 인스턴스 Riverpod provider. 앱 부트(main.dart)에서 watch하여
// 데이터 레이어 전체에 주입한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/item.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/wear_event.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [ItemSchema, WearEventSchema, UserPreferencesSchema],
    directory: dir.path,
    name: 'closetimo',
    inspector: false,
  );
});

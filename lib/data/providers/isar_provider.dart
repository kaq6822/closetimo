import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/clock.dart';
import '../migrations/storage_migrator.dart';
import '../models/item.dart';
import '../models/storage_metadata.dart';
import '../models/user_preferences.dart';
import '../models/wear_event.dart';

const String closetimoDatabaseName = 'closetimo_plus';

/// 이전이 완료된 단일 Isar Plus 인스턴스를 데이터 레이어에 제공한다.
final isarProvider = FutureProvider<Isar>((ref) async {
  final directory = await getApplicationDocumentsDirectory();
  final isar = Isar.open(
    schemas: [
      ItemSchema,
      WearEventSchema,
      UserPreferencesSchema,
      StorageMetadataSchema,
    ],
    directory: directory.path,
    name: closetimoDatabaseName,
    inspector: false,
  );

  try {
    final result = await const StorageMigrator().migrateIfNeeded(
      newStore: isar,
      directory: directory.path,
      clock: ref.read(clockProvider),
    );
    debugPrint(
      'Storage ready: source=${result.source.name}, '
      'items=${result.itemCount}, events=${result.eventCount}',
    );
  } catch (error) {
    debugPrint('Failed to initialize storage: $error');
    isar.close();
    rethrow;
  }

  ref.onDispose(() {
    if (isar.isOpen) {
      isar.close();
    }
  });
  return isar;
});

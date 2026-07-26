import 'package:isar_plus/isar_plus.dart';

part 'storage_metadata.g.dart';

/// 주 저장소의 초기화와 legacy 이전 완료 상태를 나타내는 singleton이다.
@collection
class StorageMetadata {
  StorageMetadata({
    required this.storageVersion,
    required this.migratedAt,
    required this.legacyItemCount,
    required this.legacyEventCount,
    required this.source,
  });

  static const int singletonId = 0;
  static const int currentStorageVersion = 1;

  int id = singletonId;
  int storageVersion;
  DateTime migratedAt;
  int legacyItemCount;
  int legacyEventCount;

  StorageSource source;
}

enum StorageSource { legacyV3, fresh }

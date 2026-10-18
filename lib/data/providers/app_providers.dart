// 데이터 레이어 Riverpod provider 모음. UI feature 모듈은 본 파일을 통해서만
// Repository 인스턴스를 획득한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/image_store.dart';
import '../../core/utils/clock.dart';
import '../models/item_tags.dart';
import '../models/user_preferences.dart';
import '../repositories/archive_repository.dart';
import '../repositories/backup_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/isar_archive_repository.dart';
import '../repositories/isar_backup_repository.dart';
import '../repositories/isar_event_repository.dart';
import '../repositories/isar_item_repository.dart';
import '../repositories/isar_laundry_repository.dart';
import '../repositories/isar_preferences_repository.dart';
import '../repositories/isar_tag_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/laundry_repository.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/shared_items_watcher.dart';
import '../repositories/tag_repository.dart';
import 'isar_provider.dart';

/// 옷 컬렉션 전체 watch를 공유하는 구독기(#53). 옷 목록을 파생하는 repository가 함께 쓴다.
final sharedItemsWatcherProvider = Provider<SharedItemsWatcher>((ref) {
  final watcher = SharedItemsWatcher(ref.watch(isarProvider).requireValue);
  ref.onDispose(watcher.dispose);
  return watcher;
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return IsarItemRepository(
    isar: isar,
    imageStore: ref.watch(imageStoreProvider),
    clock: ref.watch(clockProvider),
    watcher: ref.watch(sharedItemsWatcherProvider),
  );
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return IsarEventRepository(isar: isar, clock: ref.watch(clockProvider));
});

final laundryRepositoryProvider = Provider<LaundryRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return IsarLaundryRepository(
    isar: isar,
    clock: ref.watch(clockProvider),
    watcher: ref.watch(sharedItemsWatcherProvider),
  );
});

/// 옷 보관·복원(#44).
final archiveRepositoryProvider = Provider<ArchiveRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return IsarArchiveRepository(
    isar: isar,
    clock: ref.watch(clockProvider),
    watcher: ref.watch(sharedItemsWatcherProvider),
  );
});

/// 사용자 태그 일괄 편집(#46).
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return IsarTagRepository(isar: isar);
});

/// 사용자 태그 사용 현황(#46). 태그는 `Item.tags`에만 있으므로 전체 옷 스트림을
/// 집계한다. 등록 폼 제안·옷장 태그 필터·태그 관리 화면이 함께 쓴다.
final tagUsageProvider = StreamProvider<List<TagUsage>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAll().map(summarizeTags);
});

/// 사용자 실행형 백업·복원(#40).
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return IsarBackupRepository(
    isar: isar,
    imageStore: ref.watch(imageStoreProvider),
    clock: ref.watch(clockProvider),
  );
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return IsarPreferencesRepository(isar: isar);
});

final preferencesStreamProvider = StreamProvider<UserPreferences>((ref) {
  return ref.watch(preferencesRepositoryProvider).watch();
});

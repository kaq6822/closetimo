// 데이터 레이어 Riverpod provider 모음. UI feature 모듈은 본 파일을 통해서만
// Repository 인스턴스를 획득한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persistence/image_store.dart';
import '../../core/persistence/isar_provider.dart';
import '../../core/utils/clock.dart';
import '../repositories/isar_item_repository.dart';
import '../repositories/item_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return IsarItemRepository(
    isar: isar,
    imageStore: ref.watch(imageStoreProvider),
    clock: ref.watch(clockProvider),
  );
});

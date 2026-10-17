// #40 — 실기기 백업·복원 E2E. 실제 Isar·sandbox 사진·설정 화면 흐름으로
// 백업 → 데이터 변경 → 복원 후 옷·사진·기록·보관·설정이 되살아나는지 검증한다.
//
// OS 공유 시트·문서 선택기는 integration_test로 조작할 수 없으므로 그 경계
// (BackupFileGateway)만 대체한다. 백업 파일은 실제로 만들어지고, 복원은 같은 파일을
// 실제 repository가 검증·적용한다.
//
// 실행 (앱 데이터가 비어 있어야 한다):
//   xcrun simctl uninstall booted com.closetimo.app   # 또는 adb uninstall com.closetimo.app
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/backup_restore_test.dart -d <device-id>

import 'dart:io';
import 'dart:math';

import 'package:closetimo/core/persistence/image_store.dart';
import 'package:closetimo/data/models/item.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/providers/isar_provider.dart';
import 'package:closetimo/features/add_item/new_item_draft.dart';
import 'package:closetimo/features/settings/backup/backup_file_gateway.dart';
import 'package:closetimo/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'support/e2e_helpers.dart';

/// 공유 시트 대신 백업 파일을 보관하고, 문서 선택기 대신 그 파일을 돌려준다.
class _E2eGateway implements BackupFileGateway {
  final _platform = const PlatformBackupFileGateway();
  File? saved;

  @override
  Future<Directory> workDirectory() => _platform.workDirectory();

  @override
  Future<bool> share(File file) async {
    final docs = await getApplicationDocumentsDirectory();
    saved = await file.copy(p.join(docs.path, 'e2e-saved-backup.zip'));
    return true;
  }

  @override
  Future<File?> pickBackupFile() async => saved;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('백업 → 데이터 변경 → 복원 후 옷·사진·기록·보관·설정 복구', (tester) async {
    final gateway = _E2eGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backupFileGatewayProvider.overrideWithValue(gateway)],
        child: const ClosetimoApp(),
      ),
    );
    await pumpUntilFound(tester, find.text('설정'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ClosetimoApp)),
    );
    final items = container.read(itemRepositoryProvider);
    final events = container.read(eventRepositoryProvider);
    final archive = container.read(archiveRepositoryProvider);
    final prefs = container.read(preferencesRepositoryProvider);
    final imageStore = container.read(imageStoreProvider);
    final isar = container.read(isarProvider).requireValue;

    // ── 1. 원본 데이터(사진 포함) ──
    final tmp = await getTemporaryDirectory();
    // 주기적 패턴은 zip(deflate)에서 크게 줄어들므로 시드 난수로 압축이 안 되는 바이트를 만든다.
    final rng = Random(7);
    final photoBytes = List<int>.generate(8192, (_) => rng.nextInt(256));
    final photo = File(p.join(tmp.path, 'e2e-photo.jpg'))
      ..writeAsBytesSync(photoBytes);
    final coatId = await items.create(
      NewItemDraft(
        name: '백업 코트',
        category: Category.outer,
        washCycle: 3,
        tempPhoto: photo,
      ),
    );
    await events.recordWear(coatId, note: '백업 전 착용');
    final shirtId = await items.create(
      const NewItemDraft(name: '백업 보관 셔츠', category: Category.top),
    );
    await archive.archive(shirtId, reason: ArchiveReason.seasonal);
    await prefs.setNotifUnworn(true);

    // ── 2. 설정 → 데이터 백업 ──
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('데이터 백업'));
    await tester.pumpAndSettle();
    await takeShot(binding, tester, 'backup_01_settings');
    await tester.tap(find.text('데이터 백업'));
    await pumpUntilFound(tester, find.text('백업 파일을 내보냈어요'));
    expect(find.text('백업 파일을 내보냈어요'), findsOneWidget);
    expect(gateway.saved, isNotNull);
    expect(gateway.saved!.lengthSync(), greaterThan(photoBytes.length));
    await takeShot(binding, tester, 'backup_02_exported');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // ── 3. 백업 이후 데이터 변경(삭제·추가·설정 변경) ──
    await items.delete(coatId);
    await items.create(const NewItemDraft(name: '복원 후 사라질 옷'));
    await prefs.setNotifUnworn(false);
    expect(isar.items.where().nameEqualTo('백업 코트').findFirst(), isNull);

    // ── 4. 백업에서 복원 → 확인 안내 → 복원 ──
    await tester.ensureVisible(find.text('백업에서 복원'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('백업에서 복원'));
    await pumpUntilFound(tester, find.text('백업으로 복원할까요?'));
    expect(find.textContaining('옷 2벌 · 기록 1건 · 사진 1장'), findsOneWidget);
    await takeShot(binding, tester, 'backup_03_confirm');
    await tester.tap(find.text('복원'));
    await pumpUntilFound(tester, find.textContaining('백업을 복원했어요'));
    expect(find.text('백업을 복원했어요 · 옷 2벌, 기록 1건'), findsOneWidget);
    await takeShot(binding, tester, 'backup_04_restored');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // ── 5. 데이터 검증 ──
    final names = isar.items.where().findAll().map((i) => i.name).toSet();
    expect(names, {'백업 코트', '백업 보관 셔츠'});
    final coat = isar.items.where().nameEqualTo('백업 코트').findFirst()!;
    expect(coat.id, coatId, reason: '원본 id가 보존되어 기록 참조가 유지된다');
    expect(coat.totalWears, 1);
    expect(
      await File(await imageStore.absolutePath(coat.imagePath!)).readAsBytes(),
      photoBytes,
    );
    final coatEvents = isar.wearEvents.where().itemIdEqualTo(coat.id).findAll();
    expect(coatEvents.map((e) => (e.kind, e.note)), [
      (EventKind.wear, '백업 전 착용'),
    ]);
    final shirt = isar.items.where().nameEqualTo('백업 보관 셔츠').findFirst()!;
    expect(shirt.archiveReason, ArchiveReason.seasonal);
    expect(shirt.isArchived, isTrue);
    expect((await prefs.watch().first).notifUnworn, isTrue);

    // ── 6. 화면 반영(재시작 없이 스트림 갱신) ──
    await tester.tap(find.text('옷장'));
    await pumpUntilFound(tester, find.text('백업 코트'));
    expect(find.text('백업 코트'), findsWidgets);
    expect(find.text('복원 후 사라질 옷'), findsNothing);
    await takeShot(binding, tester, 'backup_05_wardrobe_after_restore');
  });
}

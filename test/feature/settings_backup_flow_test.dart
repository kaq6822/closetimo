// #40 — 설정 화면 백업·복원 흐름: 진입 행, 취소, 확인 안내, 실패 안내.

import 'dart:io';

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/backup/backup_format.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/backup_repository.dart';
import 'package:closetimo/data/repositories/preferences_repository.dart';
import 'package:closetimo/features/settings/backup/backup_file_gateway.dart';
import 'package:closetimo/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 17, 9, 30);

class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

class _FakePrefsRepo implements PreferencesRepository {
  @override
  Stream<UserPreferences> watch() =>
      Stream.value(UserPreferences.defaults()..firstLaunchedAt = _now);
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeBackupRepo implements BackupRepository {
  Object? createError;
  Object? inspectError;
  Object? restoreError;
  final calls = <String>[];

  static const _counts = BackupCounts(items: 3, wearEvents: 5, images: 2);

  @override
  Future<BackupCounts> currentCounts() async =>
      const BackupCounts(items: 1, wearEvents: 0, images: 0);

  @override
  Future<BackupExport> createBackup(Directory outputDir) async {
    calls.add('create:${outputDir.path}');
    if (createError != null) throw createError!;
    return BackupExport(
      file: File('${outputDir.path}/b.zip'),
      createdAt: _now,
      counts: _counts,
      missingImageCount: 0,
    );
  }

  @override
  Future<ValidatedBackup> inspect(File archive) async {
    calls.add('inspect:${archive.path}');
    if (inspectError != null) throw inspectError!;
    return ValidatedBackup(
      file: archive,
      formatVersion: 1,
      createdAt: DateTime(2026, 10, 1, 20, 5),
      counts: _counts,
    );
  }

  @override
  Future<RestoreResult> restore(ValidatedBackup backup) async {
    calls.add('restore');
    if (restoreError != null) throw restoreError!;
    return const RestoreResult(counts: _counts);
  }
}

class _FakeGateway implements BackupFileGateway {
  bool shareResult = true;
  File? picked = File('/tmp/picked.zip');
  final shared = <String>[];

  @override
  Future<Directory> workDirectory() async => Directory('/tmp/work');

  @override
  Future<bool> share(File file) async {
    shared.add(file.path);
    return shareResult;
  }

  @override
  Future<File?> pickBackupFile() async => picked;
}

void main() {
  late _FakeBackupRepo repo;
  late _FakeGateway gateway;

  setUp(() {
    repo = _FakeBackupRepo();
    gateway = _FakeGateway();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(_FakePrefsRepo()),
          clockProvider.overrideWithValue(_FixedClock()),
          backupRepositoryProvider.overrideWithValue(repo),
          backupFileGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp(
          theme: buildClosetimoTheme(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko', 'KR')],
          home: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapRow(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// 토스트 타이머를 흘려보낸다.
  Future<void> drainToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Finder chevronIn(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
    matching: find.byIcon(Icons.chevron_right_rounded),
  );

  testWidgets('백업·복원 행은 실제 동작 행(chevron)이고 준비 중이 아니다', (tester) async {
    await pumpSettings(tester);
    await tester.ensureVisible(find.text('백업에서 복원'));
    expect(chevronIn('데이터 백업'), findsOneWidget);
    expect(chevronIn('백업에서 복원'), findsOneWidget);
    expect(find.textContaining('iCloud Drive'), findsOneWidget);
  });

  group('백업', () {
    testWidgets('파일을 만들어 공유 시트로 내보낸다', (tester) async {
      await pumpSettings(tester);
      await tapRow(tester, '데이터 백업');
      expect(repo.calls, ['create:/tmp/work']);
      expect(gateway.shared, ['/tmp/work/b.zip']);
      expect(find.text('백업 파일을 내보냈어요'), findsOneWidget);
      await drainToast(tester);
    });

    testWidgets('공유 시트를 닫으면 취소 안내', (tester) async {
      gateway.shareResult = false;
      await pumpSettings(tester);
      await tapRow(tester, '데이터 백업');
      expect(find.text('백업 저장을 취소했어요'), findsOneWidget);
      await drainToast(tester);
    });

    testWidgets('공간 부족이면 공유하지 않고 안내한다', (tester) async {
      repo.createError = const BackupStorageFullException();
      await pumpSettings(tester);
      await tapRow(tester, '데이터 백업');
      expect(gateway.shared, isEmpty);
      expect(find.text('백업하지 못했어요'), findsOneWidget);
      expect(find.textContaining('저장 공간이 부족해요'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
    });
  });

  group('복원', () {
    testWidgets('파일 선택을 취소하면 아무것도 하지 않는다', (tester) async {
      gateway.picked = null;
      await pumpSettings(tester);
      await tapRow(tester, '백업에서 복원');
      expect(repo.calls, isEmpty);
      expect(find.text('복원을 취소했어요'), findsOneWidget);
      await drainToast(tester);
    });

    testWidgets('손상 파일은 확인 안내 전에 거부한다', (tester) async {
      repo.inspectError = const BackupFormatException('bad');
      await pumpSettings(tester);
      await tapRow(tester, '백업에서 복원');
      expect(repo.calls, ['inspect:/tmp/picked.zip']);
      expect(find.text('복원할 수 없어요'), findsOneWidget);
      expect(find.textContaining('백업 파일을 읽을 수 없어요'), findsOneWidget);
      expect(find.textContaining('기존 데이터는 그대로예요'), findsOneWidget);
      expect(find.text('백업으로 복원할까요?'), findsNothing);
    });

    testWidgets('더 새로운 버전의 백업은 업데이트를 안내한다', (tester) async {
      repo.inspectError = const BackupVersionException(found: 9, supported: 1);
      await pumpSettings(tester);
      await tapRow(tester, '백업에서 복원');
      expect(find.textContaining('최신 버전으로 업데이트'), findsOneWidget);
      expect(repo.calls, isNot(contains('restore')));
    });

    testWidgets('확인 안내에서 취소하면 복원하지 않는다', (tester) async {
      await pumpSettings(tester);
      await tapRow(tester, '백업에서 복원');
      expect(find.text('백업으로 복원할까요?'), findsOneWidget);
      expect(find.textContaining('2026.10.01 20:05'), findsOneWidget);
      expect(find.textContaining('옷 3벌 · 기록 5건 · 사진 2장'), findsOneWidget);
      expect(find.textContaining('모두 지워지고'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(repo.calls, isNot(contains('restore')));
      expect(find.text('복원을 취소했어요'), findsOneWidget);
      await drainToast(tester);
    });

    testWidgets('확정하면 복원하고 결과를 알린다', (tester) async {
      await pumpSettings(tester);
      await tapRow(tester, '백업에서 복원');
      await tester.tap(find.text('복원'));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'restore');
      expect(find.text('백업을 복원했어요 · 옷 3벌, 기록 5건'), findsOneWidget);
      await drainToast(tester);
    });

    testWidgets('적용 중 공간 부족이면 기존 데이터 유지를 안내한다', (tester) async {
      repo.restoreError = const BackupStorageFullException();
      await pumpSettings(tester);
      await tapRow(tester, '백업에서 복원');
      await tester.tap(find.text('복원'));
      await tester.pumpAndSettle();
      expect(find.text('복원하지 못했어요'), findsOneWidget);
      expect(find.textContaining('저장 공간이 부족해요'), findsOneWidget);
      expect(find.textContaining('기존 데이터는 그대로예요'), findsOneWidget);
    });
  });
}

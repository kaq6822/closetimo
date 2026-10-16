// #40 — 설정 화면의 백업·복원 흐름(진행 표시 → 확인 안내 → 결과 안내).
// specs/004-backup-restore/spec.md US1·US2, FR-006·FR-008.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/toast.dart';
import '../../../data/backup/backup_format.dart';
import '../../../data/providers/app_providers.dart';
import 'backup_file_gateway.dart';

/// 백업 파일을 만들고 OS 공유 시트로 내보낸다.
Future<void> runBackup(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(backupRepositoryProvider);
  final gateway = ref.read(backupFileGatewayProvider);

  final BackupExport export;
  try {
    export = await _withProgress(
      context,
      '백업 파일을 만들고 있어요',
      () async => repo.createBackup(await gateway.workDirectory()),
    );
  } catch (e) {
    debugPrint('Backup creation failed: $e');
    if (context.mounted) await _showError(context, '백업하지 못했어요', e);
    return;
  }

  final bool shared;
  try {
    shared = await gateway.share(export.file);
  } catch (e) {
    debugPrint('Backup share failed: $e');
    if (context.mounted) await _showError(context, '백업 파일을 내보내지 못했어요', e);
    return;
  }
  if (!context.mounted) return;
  if (!shared) {
    showClosetimoToast(context, '백업 저장을 취소했어요');
    return;
  }
  final missing = export.missingImageCount;
  showClosetimoToast(
    context,
    missing == 0 ? '백업 파일을 내보냈어요' : '백업 파일을 내보냈어요 · 사진 $missing장은 찾지 못했어요',
  );
}

/// 백업 파일을 골라 검증하고, 확인을 받은 뒤 현재 옷장을 전체 교체한다.
Future<void> runRestore(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(backupRepositoryProvider);
  final gateway = ref.read(backupFileGatewayProvider);

  final ValidatedBackup preview;
  final BackupCounts current;
  try {
    final file = await gateway.pickBackupFile();
    if (file == null) {
      if (context.mounted) showClosetimoToast(context, '복원을 취소했어요');
      return;
    }
    if (!context.mounted) return;
    preview = await _withProgress(
      context,
      '백업 파일을 확인하고 있어요',
      () => repo.inspect(file),
    );
    current = await repo.currentCounts();
  } catch (e) {
    debugPrint('Backup inspection failed: $e');
    if (context.mounted) await _showError(context, '복원할 수 없어요', e);
    return;
  }
  if (!context.mounted) return;

  final confirmed = await _confirmRestore(context, preview, current);
  if (!context.mounted) return;
  if (!confirmed) {
    showClosetimoToast(context, '복원을 취소했어요');
    return;
  }

  final RestoreResult result;
  try {
    result = await _withProgress(
      context,
      '복원하고 있어요',
      () => repo.restore(preview),
    );
  } catch (e) {
    debugPrint('Restore failed: $e');
    if (context.mounted) await _showError(context, '복원하지 못했어요', e);
    return;
  }
  if (!context.mounted) return;
  showClosetimoToast(
    context,
    '백업을 복원했어요 · 옷 ${result.counts.items}벌, 기록 ${result.counts.wearEvents}건',
  );
}

/// 실패 원인별 안내 문구(FR-008). 백업·복원 예외는 모두 기존 데이터를 바꾸지 않는다.
@visibleForTesting
String backupErrorMessage(Object error) => switch (error) {
  BackupFormatException() => '백업 파일을 읽을 수 없어요.\n손상되었거나 옷장이모 백업 파일이 아니에요.',
  BackupVersionException(isNewer: true) =>
    '더 새로운 버전의 앱에서 만든 백업이에요.\n앱을 최신 버전으로 업데이트한 뒤 다시 시도해 주세요.',
  BackupVersionException() => '지원하지 않는 백업 형식이에요.',
  BackupStorageFullException() => '저장 공간이 부족해요.\n공간을 확보한 뒤 다시 시도해 주세요.',
  BackupIoException() => '파일을 처리하지 못했어요.\n잠시 후 다시 시도해 주세요.',
  _ => '알 수 없는 문제가 생겼어요.\n잠시 후 다시 시도해 주세요.',
};

Future<void> _showError(BuildContext context, String title, Object error) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text('${backupErrorMessage(error)}\n기존 데이터는 그대로예요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

Future<bool> _confirmRestore(
  BuildContext context,
  ValidatedBackup preview,
  BackupCounts current,
) async {
  final created = DateFormat('yyyy.MM.dd HH:mm').format(preview.createdAt);
  final b = preview.counts;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('백업으로 복원할까요?'),
      content: Text(
        '백업: $created\n'
        '옷 ${b.items}벌 · 기록 ${b.wearEvents}건 · 사진 ${b.images}장\n\n'
        '지금 옷장(옷 ${current.items}벌 · 기록 ${current.wearEvents}건)은\n'
        '모두 지워지고 백업 내용으로 바뀌어요.\n'
        '되돌릴 수 없어요.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('복원'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// [task]가 끝날 때까지 닫을 수 없는 진행 표시를 띄운다.
Future<T> _withProgress<T>(
  BuildContext context,
  String message,
  Future<T> Function() task,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(width: ClosetimoSpacing.space20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

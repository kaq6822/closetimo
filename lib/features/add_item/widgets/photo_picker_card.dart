// US1 T034 / 002 T008 / 005 — 옷 사진 등록·수정 카드. surface-container-low 배경.
// 표시 우선순위: 새 배경 제거본 > 새 사진 > 기존 배경 제거본 > 기존 사진 > 플레이스홀더.
// 005 — 첫 화면에서 이름·종류까지 보이도록 높이를 [ClosetimoSize.photoCardHeight]로 낮췄다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';

class PhotoPickerCard extends StatelessWidget {
  const PhotoPickerCard({
    required this.tempPhoto,
    required this.onPicked,
    this.existingImagePath,
    this.tempCutout,
    this.existingCutoutPath,
    this.analyzing = false,
    this.onRemove,
    this.onUseOriginal,
    super.key,
  });

  /// 새로 선택한 임시 파일(등록·수정 공통).
  final File? tempPhoto;

  /// 002 — 수정 모드에서 표시할 기존 사진의 sandbox 절대 경로.
  final String? existingImagePath;

  /// 005 — 새 사진의 배경 제거본(임시 PNG).
  final File? tempCutout;

  /// 005 — 수정 모드의 기존 배경 제거본 절대 경로.
  final String? existingCutoutPath;

  /// 005 — 사진 분석(배경 제거·색상) 중이면 진행 표시를 겹친다.
  final bool analyzing;

  final ValueChanged<File> onPicked;

  /// 002 — 사진 제거 액션. null이면 제거 옵션을 노출하지 않는다(등록 모드).
  final VoidCallback? onRemove;

  /// 005 — 배경 제거본을 버리고 원본을 쓰는 액션. 배경 제거본이 보일 때만 노출한다.
  final VoidCallback? onUseOriginal;

  bool get _hasPhoto => tempPhoto != null || existingImagePath != null;

  /// 지금 보이는 사진이 배경 제거본인지.
  bool get _showsCutout =>
      tempCutout != null || (tempPhoto == null && existingCutoutPath != null);

  Future<void> _showSourceSheet(BuildContext context) async {
    final choice = await showModalBottomSheet<_PhotoAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('앨범에서 선택'),
              onTap: () => Navigator.pop(ctx, _PhotoAction.gallery),
            ),
            if (onUseOriginal != null && _showsCutout)
              ListTile(
                leading: const Icon(Icons.wallpaper_rounded),
                title: const Text('원본 사진 사용'),
                subtitle: const Text('배경을 지운 사진 대신 찍은 그대로 보여요'),
                onTap: () => Navigator.pop(ctx, _PhotoAction.useOriginal),
              ),
            if (onRemove != null && _hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('사진 제거'),
                onTap: () => Navigator.pop(ctx, _PhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    switch (choice) {
      case _PhotoAction.remove:
        onRemove?.call();
        return;
      case _PhotoAction.useOriginal:
        onUseOriginal?.call();
        return;
      case _PhotoAction.camera || _PhotoAction.gallery:
        break;
    }
    final source = choice == _PhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      onPicked(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return SizedBox(
      height: ClosetimoSize.photoCardHeight,
      child: Material(
        color: surfaces.containerLow,
        borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
        clipBehavior: Clip.antiAlias,
        // #17 N-01 — 사진이 붙으면 안내 텍스트가 사라져 라벨 없는 버튼이 되던 문제.
        // 상태별 라벨을 직접 붙이고 하위 텍스트는 중복 낭독되지 않게 뺀다.
        child: Semantics(
          container: true,
          button: true,
          label: _hasPhoto ? '의류 사진 변경' : '의류 사진 등록',
          excludeSemantics: true,
          onTap: () => _showSourceSheet(context),
          child: InkWell(
            onTap: () => _showSourceSheet(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildContent(),
                if (analyzing) const _AnalyzingBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (tempCutout != null) return _cutout(Image.file(tempCutout!));
    if (tempPhoto != null) {
      return Image.file(tempPhoto!, fit: BoxFit.cover);
    }
    if (existingCutoutPath != null) {
      return _cutout(Image.file(File(existingCutoutPath!)));
    }
    if (existingImagePath != null) {
      return Image.file(File(existingImagePath!), fit: BoxFit.cover);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: ClosetimoColors.bgMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              size: 26,
              color: ClosetimoColors.primary,
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.sm),
          const Text(
            '의류 사진 등록',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: ClosetimoColors.ink,
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.xs),
          const Text(
            '사진을 넣으면 색상을 골라 드려요',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: ClosetimoColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  /// 배경 제거본은 잘리지 않게 여백을 두고 contain으로 그린다.
  Widget _cutout(Image image) => Padding(
    padding: const EdgeInsets.all(ClosetimoSpacing.md),
    child: Image(image: image.image, fit: BoxFit.contain),
  );
}

class _AnalyzingBadge extends StatelessWidget {
  const _AnalyzingBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(ClosetimoSpacing.sm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ClosetimoColors.ink.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(ClosetimoRadius.full),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ClosetimoSpacing.space10,
              vertical: ClosetimoSpacing.space6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: ClosetimoSpacing.space12,
                  child: CircularProgressIndicator(
                    strokeWidth: ClosetimoSize.controlOutline,
                    color: ClosetimoColors.onPrimary,
                  ),
                ),
                SizedBox(width: ClosetimoSpacing.space6),
                Text(
                  '사진 분석 중…',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: ClosetimoColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PhotoAction { camera, gallery, useOriginal, remove }

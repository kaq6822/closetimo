// US1 T034 / 002 T008 — 옷 사진 등록·수정 카드. 3:4 비율, surface-container-low 배경.
// 표시 우선순위: 새로 선택한 tempPhoto > 기존 사진(existingImagePath) > 플레이스홀더.

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
    this.onRemove,
    super.key,
  });

  /// 새로 선택한 임시 파일(등록·수정 공통).
  final File? tempPhoto;

  /// 002 — 수정 모드에서 표시할 기존 사진의 sandbox 절대 경로.
  final String? existingImagePath;

  final ValueChanged<File> onPicked;

  /// 002 — 사진 제거 액션. null이면 제거 옵션을 노출하지 않는다(등록 모드).
  final VoidCallback? onRemove;

  bool get _hasPhoto => tempPhoto != null || existingImagePath != null;

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
    if (choice == _PhotoAction.remove) {
      onRemove?.call();
      return;
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
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Material(
        color: surfaces.containerLow,
        borderRadius: BorderRadius.circular(ClosetimoRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showSourceSheet(context),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (tempPhoto != null) {
      return Image.file(tempPhoto!, fit: BoxFit.cover);
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
        ],
      ),
    );
  }
}

enum _PhotoAction { camera, gallery, remove }

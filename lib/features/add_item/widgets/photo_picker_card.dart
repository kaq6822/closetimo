// US1 T034 — 옷 사진 등록 카드. 3:4 비율, surface-container-low 배경.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';

class PhotoPickerCard extends StatelessWidget {
  const PhotoPickerCard({
    required this.tempPhoto,
    required this.onPicked,
    super.key,
  });

  final File? tempPhoto;
  final ValueChanged<File> onPicked;

  Future<void> _showSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('앨범에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
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
          child: tempPhoto != null
              ? Image.file(tempPhoto!, fit: BoxFit.cover)
              : Center(
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
                ),
        ),
      ),
    );
  }
}

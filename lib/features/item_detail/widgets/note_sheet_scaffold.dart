// 공용 노트 시트 스캐폴드 — WearRecordSheet(T054a)와 EditNoteSheet(T054b)이
// 동일한 80자 단일행 메모 입력 UX를 공유한다.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/primary_button.dart';

const int kNoteMaxLength = 80;

class NoteSheetScaffold extends StatefulWidget {
  const NoteSheetScaffold({
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.subtitle,
    this.hint,
    this.initial,
    this.confirmIcon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? hint;
  final String? initial;
  final String confirmLabel;
  final IconData? confirmIcon;
  final ValueChanged<String?> onConfirm;

  @override
  State<NoteSheetScaffold> createState() => _NoteSheetScaffoldState();
}

class _NoteSheetScaffoldState extends State<NoteSheetScaffold> {
  late final TextEditingController _ctl =
      TextEditingController(text: widget.initial ?? '');
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _confirm() {
    final raw = _ctl.text.trim();
    widget.onConfirm(raw.isEmpty ? null : raw);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: surfaces.containerLowest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ClosetimoRadius.xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          ClosetimoSpacing.lg,
          ClosetimoSpacing.md,
          ClosetimoSpacing.lg,
          ClosetimoSpacing.lg,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: surfaces.containerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: ClosetimoSpacing.md + 2),
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ClosetimoColors.ink,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: ClosetimoSpacing.xs),
                Text(
                  widget.subtitle!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: ClosetimoColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: ClosetimoSpacing.lg),
              TextField(
                controller: _ctl,
                focusNode: _focus,
                maxLength: kNoteMaxLength,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirm(),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  color: ClosetimoColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  filled: true,
                  fillColor: surfaces.containerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ClosetimoRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: ClosetimoSpacing.md),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: widget.confirmLabel,
                    leading: widget.confirmIcon != null
                        ? Icon(widget.confirmIcon)
                        : null,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

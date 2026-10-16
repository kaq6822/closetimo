// #46 — 등록·수정 폼의 사용자 태그 입력. 이미 쓴 태그를 먼저 제안해
// 같은 뜻의 태그를 매번 새로 만들지 않게 한다.

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/chip_filter.dart';
import '../../../data/models/item_tags.dart';

class TagInput extends StatefulWidget {
  const TagInput({
    required this.value,
    required this.suggestions,
    required this.onChanged,
    super.key,
  });

  /// 현재 옷에 붙은 태그(정규화된 표기).
  final List<String> value;

  /// 이미 쓴 태그 이름(많이 쓴 순). 선택된 태그는 제외해 보여준다.
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  /// 한 번에 보여줄 제안 수. 많으면 입력으로 좁힌다.
  static const int maxSuggestions = 8;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _add(Iterable<String> tags) {
    final next = normalizeTags([...widget.value, ...tags]);
    _ctl.clear();
    if (next.length != widget.value.length) widget.onChanged(next);
  }

  void _remove(String tag) {
    widget.onChanged([
      for (final t in widget.value)
        if (t != tag) t,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _ctl,
      builder: (context, text, _) {
        final chosen = {for (final t in widget.value) t.toLowerCase()};
        final q = text.text.trim().toLowerCase();
        final suggestions = widget.suggestions
            .where((s) => !chosen.contains(s.toLowerCase()))
            .where((s) => q.isEmpty || s.toLowerCase().contains(q))
            .take(TagInput.maxSuggestions)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.value.isNotEmpty) ...[
              Wrap(
                spacing: ClosetimoSpacing.sm,
                runSpacing: ClosetimoSpacing.sm,
                children: [
                  for (final t in widget.value)
                    Semantics(
                      label: '$t 태그 빼기',
                      excludeSemantics: true,
                      button: true,
                      child: ChipFilter(
                        label: '$t ✕',
                        active: true,
                        onTap: () => _remove(t),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ClosetimoSpacing.sm),
            ],
            Semantics(
              label: '태그',
              child: TextField(
                controller: _ctl,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => _add(parseTagInput(v)),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  color: ClosetimoColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: '예) 검정, 여름',
                  filled: true,
                  fillColor: surfaces.containerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ClosetimoSpacing.space18,
                    vertical: ClosetimoSpacing.space16,
                  ),
                  suffixIcon: text.text.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: '태그 추가',
                          icon: const Icon(
                            Icons.add_rounded,
                            color: ClosetimoColors.ink,
                          ),
                          onPressed: () => _add(parseTagInput(_ctl.text)),
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
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: ClosetimoSpacing.sm),
              Wrap(
                spacing: ClosetimoSpacing.sm,
                runSpacing: ClosetimoSpacing.sm,
                children: [
                  for (final s in suggestions)
                    Semantics(
                      label: '$s 태그 붙이기',
                      excludeSemantics: true,
                      button: true,
                      child: ChipFilter(
                        label: '+ $s',
                        active: false,
                        onTap: () => _add([s]),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

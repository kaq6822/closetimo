// US2 T045 — 옷장 탭. 검색·필터·정렬 + 2 컬럼 그리드.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/providers/app_providers.dart';
import '../../data/repositories/item_repository.dart';
import 'widgets/garment_tile.dart';
import 'widgets/wardrobe_filter_bar.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({this.initialCategory, super.key});

  final Category? initialCategory;

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  late Category? _category = widget.initialCategory;
  String _query = '';
  WardrobeSort _sort = WardrobeSort.statusCleanFirst;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(itemRepositoryProvider);
    final stream = repo.watchFiltered(
      category: _category,
      query: _query,
      sort: _sort,
    );
    return Column(
      children: [
        TopBar(
          rightSlot: TopBarPlusAction(
            onTap: () => context.goNamed(Routes.addItem),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              ClosetimoSpacing.lg,
              ClosetimoSpacing.md,
              ClosetimoSpacing.lg,
              ClosetimoSpacing.huge + 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '내 옷장',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: ClosetimoSpacing.sm),
                const Text(
                  '당신만을 위해 큐레이션된 에센셜 컬렉션입니다.\n'
                  '청결도와 착용 빈도에 따라 정리되어 있습니다.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: ClosetimoColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: ClosetimoSpacing.xl),
                WardrobeFilterBar(
                  query: _query,
                  category: _category,
                  sort: _sort,
                  onQueryChanged: (v) => setState(() => _query = v),
                  onCategoryChanged: (c) => setState(() => _category = c),
                  onSortChanged: (s) => setState(() => _sort = s),
                ),
                const SizedBox(height: ClosetimoSpacing.xl),
                StreamBuilder<List<Item>>(
                  stream: stream,
                  builder: (ctx, snap) {
                    final items = snap.data ?? const [];
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: ClosetimoColors.muted,
                            ),
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.66,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => GarmentTile(item: items[i]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

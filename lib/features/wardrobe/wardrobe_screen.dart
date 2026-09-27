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
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(WardrobeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // indexedStack 셸이 State를 보존하므로, 홈 카테고리 카드가 새 `?category=`로
    // 진입하면 여기서 필터를 맞춘다(FR-019). 칩 선택은 URL에 먼저 반영되므로
    // `_category`와 같으면 건드리지 않는다. 목록이 통째로 바뀌므로 맨 위로 올린다.
    final next = widget.initialCategory;
    if (next != oldWidget.initialCategory && next != _category) {
      _category = next;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 칩 선택을 `?category=`에도 반영해, 이후 홈 카드가 같은 카테고리로
  /// 다시 진입해도 쿼리 변화로 감지되게 한다.
  void _onCategoryChanged(Category? c) {
    setState(() => _category = c);
    context.goNamed(
      Routes.wardrobe,
      queryParameters: {if (c != null) 'category': c.name},
    );
  }

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
            onTap: () => context.pushNamed(Routes.addItem),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
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
                  onCategoryChanged: _onCategoryChanged,
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
                      // 검색어·필터 없이 비어 있으면 옷장 자체가 빈 것이므로
                      // "검색 무결과"와 구분해 첫 등록을 유도한다.
                      final filtered =
                          _query.trim().isNotEmpty || _category != null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Text(
                            filtered
                                ? '검색 결과가 없습니다.'
                                : '아직 등록된 옷이 없어요.\n오른쪽 위 + 버튼으로 첫 옷을 등록해 보세요.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: ClosetimoColors.muted,
                              height: 1.5,
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
